import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'token_storage.dart';

class QueuedSyncItem {
  final String id;
  final String reportId;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;

  QueuedSyncItem({
    required this.id,
    required this.reportId,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.queuedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reportId': reportId,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'queuedAt': queuedAt.toIso8601String(),
      };

  factory QueuedSyncItem.fromJson(Map<String, dynamic> json) => QueuedSyncItem(
        id: json['id']?.toString() ?? '',
        reportId: json['reportId']?.toString() ?? '',
        endpoint: json['endpoint']?.toString() ?? '',
        method: json['method']?.toString() ?? 'POST',
        payload: Map<String, dynamic>.from(json['payload'] ?? {}),
        queuedAt: DateTime.tryParse(json['queuedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class OfflineSyncService {
  OfflineSyncService._() {
    _initConnectivityListener();
  }
  static final OfflineSyncService instance = OfflineSyncService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final ValueNotifier<int> pendingSyncCount = ValueNotifier<int>(0);
  bool _isSyncing = false;

  void _initConnectivityListener() {
    _refreshPendingCount();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && !_isSyncing) {
        syncPendingQueue();
      }
    });
  }

  /// Queues a valuation update or photo upload for offline sync.
  Future<void> queueForSync({
    required String reportId,
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];

      final item = QueuedSyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reportId: reportId,
        endpoint: endpoint,
        method: method,
        payload: payload,
        queuedAt: DateTime.now(),
      );

      queue.add(jsonEncode(item.toJson()));
      await prefs.setStringList('offline_sync_queue', queue);
      pendingSyncCount.value = queue.length;
      debugPrint('[OfflineSyncService] Queued offline item for report $reportId. Queue depth: ${queue.length}');
    } catch (e) {
      debugPrint('[OfflineSyncService] Error queuing item: $e');
    }
  }

  /// Synchronizes all queued payloads with the Spring Boot backend.
  Future<int> syncPendingQueue() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int syncedCount = 0;

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];
      if (queue.isEmpty) {
        _isSyncing = false;
        pendingSyncCount.value = 0;
        return 0;
      }

      final token = await TokenStorage.getToken();
      final List<String> remainingQueue = [];

      for (final rawItem in queue) {
        try {
          final item = QueuedSyncItem.fromJson(jsonDecode(rawItem));
          final response = await _dio.request(
            'https://visadocs.online${item.endpoint}',
            data: item.payload,
            options: Options(
              method: item.method,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
            syncedCount++;
          } else {
            remainingQueue.add(rawItem);
          }
        } catch (e) {
          debugPrint('[OfflineSyncService] Item sync failed, retaining in queue: $e');
          remainingQueue.add(rawItem);
        }
      }

      await prefs.setStringList('offline_sync_queue', remainingQueue);
      pendingSyncCount.value = remainingQueue.length;

      if (syncedCount > 0) {
        final now = DateTime.now().toIso8601String();
        await prefs.setString('last_offline_sync_time', now);
        debugPrint('[OfflineSyncService] Synced $syncedCount items. Remaining: ${remainingQueue.length}');
      }
    } catch (e) {
      debugPrint('[OfflineSyncService] Sync loop error: $e');
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  Future<void> _refreshPendingCount() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> queue = prefs.getStringList('offline_sync_queue') ?? [];
    pendingSyncCount.value = queue.length;
  }

  void dispose() {
    _subscription?.cancel();
  }
}

