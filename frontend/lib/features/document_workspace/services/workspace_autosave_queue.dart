import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../../../services/indexed_db_draft_service.dart';
import 'document_workspace_api_service.dart';
import 'workspace_lease_client.dart';

enum QueueSyncStatus {
  idle,
  queued,
  syncing,
  saved,
  error,
  offline,
}

class WorkspaceAutosaveQueue {
  final int orderId;
  final String sessionId;
  final String tabSessionId;
  final DocumentWorkspaceApiService apiService;
  final WorkspaceLeaseClient leaseClient;

  final Map<String, String> _pendingDeltas = {};
  final ValueNotifier<int> pendingSyncCount = ValueNotifier<int>(0);
  final ValueNotifier<QueueSyncStatus> syncStatus =
      ValueNotifier<QueueSyncStatus>(QueueSyncStatus.idle);

  Timer? _debounceTimer;
  Timer? _retryTimer;
  StreamSubscription? _connectivitySub;
  bool _isFlushing = false;
  Future<bool>? _inFlightFlush;
  bool _isOnline = true;
  int _workspaceRevision = 1;

  bool get isFlushing => _isFlushing;
  Future<bool> waitForInFlight() async => _inFlightFlush != null ? await _inFlightFlush! : true;

  void cancelPendingDebounce() {
    _debounceTimer?.cancel();
  }

  void clearPendingKeys(Iterable<String> keys) {
    for (final k in keys) {
      _pendingDeltas.remove(k);
    }
    pendingSyncCount.value = _pendingDeltas.length;
    if (_pendingDeltas.isEmpty) {
      syncStatus.value = QueueSyncStatus.saved;
    }
  }

  VoidCallback? onConflictOrReadOnly;
  VoidCallback? onRevisionConflict;
  void Function(int newRevision)? onRevisionUpdated;
  void Function(Map<String, String> committedKeys, int? serverRevision)? onCommitSuccess;
  bool Function()? canSaveCheck;

  WorkspaceAutosaveQueue({
    required this.orderId,
    required this.sessionId,
    required this.tabSessionId,
    required this.apiService,
    required this.leaseClient,
    int initialRevision = 1,
  }) : _workspaceRevision = initialRevision {
    _initConnectivity();
  }

  void updateRevision(int rev) {
    _workspaceRevision = rev;
  }

  void _initConnectivity() {
    // WidgetsBinding.instance is non-null in test harness too; keep online
    _isOnline = true;
    try {
      _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
        final hasConn = results.any((r) => r != ConnectivityResult.none);
        _isOnline = hasConn;
        if (hasConn) {
          if (_pendingDeltas.isNotEmpty && !_isFlushing) {
            syncStatus.value = QueueSyncStatus.queued;
            flushImmediately();
          }
        } else {
          syncStatus.value = QueueSyncStatus.offline;
        }
      });
    } catch (_) {
      _isOnline = true;
    }
  }

  /// Step 2 Workflow: Edit -> Queue
  void enqueueEdit(
    String key,
    String value, {
    required Map<String, String> currentFullSnapshot,
  }) {
    _pendingDeltas[key] = value;
    pendingSyncCount.value = _pendingDeltas.length;
    syncStatus.value = _isOnline ? QueueSyncStatus.queued : QueueSyncStatus.offline;

    // Immediately persist to IndexedDB V2 for offline safety
    final draft = WorkspaceDraftModel(
      orderId: orderId,
      revision: _workspaceRevision,
      sourceSession: '${sessionId}_$tabSessionId',
      savedAt: DateTime.now(),
      deltaValues: Map.unmodifiable(_pendingDeltas),
      fullSnapshot: Map.unmodifiable(currentFullSnapshot),
    );
    IndexedDbDraftService.instance.saveDraft(draft);

    // If online, debounce flush by 1500ms
    if (_isOnline) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        flushImmediately();
      });
    }
  }

  /// Step 2 Workflow: Pending Sync -> API Commit -> Success -> Queue Removal
  Future<bool> flushImmediately() async {
    if (_isFlushing) {
      return _inFlightFlush != null ? await _inFlightFlush! : false;
    }
    if (_pendingDeltas.isEmpty) return true;
    if (canSaveCheck != null && !canSaveCheck!()) {
      return false;
    }
    _debounceTimer?.cancel();
    _retryTimer?.cancel();

    if (!_isOnline) {
      syncStatus.value = QueueSyncStatus.offline;
      return false;
    }

    _isFlushing = true;
    final completer = Completer<bool>();
    _inFlightFlush = completer.future;
    syncStatus.value = QueueSyncStatus.syncing;

    final batchToCommit = Map<String, String>.from(_pendingDeltas);

    try {
      final result = await apiService.saveDocumentValues(
        orderId,
        batchToCommit,
        workspaceRevision: _workspaceRevision,
      );

      if (result != null) {
        // Success: Step 2 Workflow -> Success -> Queue Removal
        for (final k in batchToCommit.keys) {
          if (_pendingDeltas[k] == batchToCommit[k]) {
            _pendingDeltas.remove(k);
          }
        }
        pendingSyncCount.value = _pendingDeltas.length;

        final serverRev = result['workspaceRevision'] is int
            ? result['workspaceRevision'] as int
            : int.tryParse(result['workspaceRevision']?.toString() ?? '');
        if (serverRev != null && serverRev > _workspaceRevision) {
          _workspaceRevision = serverRev;
          onRevisionUpdated?.call(serverRev);
        }
        onCommitSuccess?.call(batchToCommit, serverRev);

        // Record forensic sync event in PostgreSQL
        leaseClient.recordSyncEvent(
          orderId: orderId,
          sessionId: sessionId,
          tabSessionId: tabSessionId,
          eventType: 'AUTOSAVE_FLUSH',
          payload: '{"committedKeys": ${batchToCommit.length}}',
        );

        if (_pendingDeltas.isEmpty) {
          syncStatus.value = QueueSyncStatus.saved;
          // Clear or mark draft committed in IndexedDB
          await IndexedDbDraftService.instance.deleteDraft(orderId);
        } else {
          syncStatus.value = QueueSyncStatus.queued;
        }

        _isFlushing = false;
        _inFlightFlush = null;
        if (!completer.isCompleted) completer.complete(true);
        return true;
      }
    } catch (e) {
      debugPrint('[WorkspaceAutosaveQueue] Commit failed: $e');
      final int? statusCode = e is DioException ? e.response?.statusCode : null;
      final errStr = e.toString().toLowerCase();
      if (statusCode == 409 || errStr.contains('409') || errStr.contains('conflict')) {
        syncStatus.value = QueueSyncStatus.error;
        onRevisionConflict?.call();
        _isFlushing = false;
        _inFlightFlush = null;
        if (!completer.isCompleted) completer.complete(false);
        return false;
      }
      if (statusCode == 403 || errStr.contains('403') || errStr.contains('locked') || errStr.contains('read-only')) {
        syncStatus.value = QueueSyncStatus.error;
        onConflictOrReadOnly?.call();
        _isFlushing = false;
        _inFlightFlush = null;
        if (!completer.isCompleted) completer.complete(false);
        return false;
      }

      // Retry mechanism for transient network dropouts
      syncStatus.value = QueueSyncStatus.error;
      _retryTimer = Timer(const Duration(seconds: 4), () {
        if (_pendingDeltas.isNotEmpty && !_isFlushing) {
          flushImmediately();
        }
      });
    }

    _isFlushing = false;
    _inFlightFlush = null;
    if (!completer.isCompleted) completer.complete(false);
    return false;
  }

  void dispose() {
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
    _connectivitySub?.cancel();
  }
}
