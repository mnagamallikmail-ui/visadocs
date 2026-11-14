import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../services/api_service.dart';

class WorkspaceLeaseResult {
  final String lockStatus; // 'ACTIVE', 'CONFLICT_DIFFERENT_USER', 'CONFLICT_SAME_USER', 'RELEASED', 'EXPIRED'
  final bool readOnly;
  final String? currentEditor;
  final String? currentEditorFullName;
  final String? currentEditorRole;
  final String? acquiredAt;
  final int? workspaceRevision;
  final String? message;

  WorkspaceLeaseResult({
    required this.lockStatus,
    required this.readOnly,
    this.currentEditor,
    this.currentEditorFullName,
    this.currentEditorRole,
    this.acquiredAt,
    this.workspaceRevision,
    this.message,
  });

  bool get isActiveEditor => lockStatus == 'ACTIVE' && !readOnly;
  bool get isSameUserConflict => lockStatus == 'CONFLICT_SAME_USER';
  bool get isDifferentUserConflict => lockStatus == 'CONFLICT_DIFFERENT_USER';

  factory WorkspaceLeaseResult.fromJson(Map<String, dynamic> json) =>
      WorkspaceLeaseResult(
        lockStatus: json['lockStatus']?.toString() ?? 'RELEASED',
        readOnly: json['readOnly'] == true || json['read_only'] == true,
        currentEditor: json['currentEditor']?.toString() ?? json['current_editor']?.toString(),
        currentEditorFullName: json['currentEditorFullName']?.toString() ?? json['current_editor_full_name']?.toString(),
        currentEditorRole: json['currentEditorRole']?.toString() ?? json['current_editor_role']?.toString(),
        acquiredAt: json['acquiredAt']?.toString() ?? json['acquired_at']?.toString(),
        workspaceRevision: json['workspaceRevision'] is int
            ? json['workspaceRevision']
            : int.tryParse(json['workspaceRevision']?.toString() ?? ''),
        message: json['message']?.toString(),
      );
}

class WorkspaceLeaseClient {
  final ApiService _api = ApiService();

  /// POST /api/v1/orders/{id}/acquire-lock
  Future<WorkspaceLeaseResult> acquireLock({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
    String? machineName,
    String? platformInfo,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/orders/$orderId/acquire-lock',
        data: {
          'sessionId': sessionId,
          'tabSessionId': tabSessionId,
          if (machineName != null) 'machineName': machineName,
          if (platformInfo != null) 'platformInfo': platformInfo,
        },
        options: Options(
          headers: {
            'X-Session-ID': sessionId,
            'X-Tab-Session-ID': tabSessionId,
          },
        ),
      );

      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (raw is Map<String, dynamic>) {
        return WorkspaceLeaseResult.fromJson(raw);
      }
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final dynamic raw = e.response!.data is String
            ? jsonDecode(e.response!.data as String)
            : e.response!.data;
        if (raw is Map<String, dynamic>) {
          return WorkspaceLeaseResult.fromJson(raw);
        }
      }
      debugPrint('[WorkspaceLeaseClient] acquireLock error: $e');
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] acquireLock unexpected error: $e');
    }

    return WorkspaceLeaseResult(
      lockStatus: 'CONFLICT_DIFFERENT_USER',
      readOnly: true,
      message: 'Network error communicating with lock coordinator',
    );
  }

  /// POST /api/v1/orders/{id}/heartbeat
  /// Isolated Non-Entity Heartbeat Update (Execution < 1ms, 0 Order version touch)
  Future<bool> renewHeartbeat({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/orders/$orderId/heartbeat',
        data: {
          'sessionId': sessionId,
          'tabSessionId': tabSessionId,
        },
        options: Options(
          headers: {
            'X-Session-ID': sessionId,
            'X-Tab-Session-ID': tabSessionId,
          },
        ),
      );

      if (response.statusCode == 200) {
        final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
        if (raw is Map && raw['status'] == 'ALIVE') {
          return true;
        }
      }
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] renewHeartbeat error for order $orderId: $e');
    }
    return false;
  }

  /// POST /api/v1/orders/{id}/release-lock
  Future<void> releaseLock({
    required int orderId,
    required String sessionId,
  }) async {
    try {
      await _api.dio.post(
        '/api/v1/orders/$orderId/release-lock',
        data: {'sessionId': sessionId},
        options: Options(
          headers: {'X-Session-ID': sessionId},
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] releaseLock error: $e');
    }
  }

  /// POST /api/v1/orders/{id}/switch-tab
  /// Smooth same-user tab transfer
  Future<WorkspaceLeaseResult> switchTab({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/orders/$orderId/switch-tab',
        data: {
          'sessionId': sessionId,
          'tabSessionId': tabSessionId,
        },
        options: Options(
          headers: {
            'X-Session-ID': sessionId,
            'X-Tab-Session-ID': tabSessionId,
          },
        ),
      );

      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (raw is Map<String, dynamic>) {
        return WorkspaceLeaseResult.fromJson(raw);
      }
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] switchTab error: $e');
    }

    return WorkspaceLeaseResult(
      lockStatus: 'CONFLICT_SAME_USER',
      readOnly: true,
      message: 'Failed to transfer lease to current tab',
    );
  }

  /// POST /api/v1/orders/{id}/takeover-lock
  /// Admin Break-Glass Takeover
  Future<WorkspaceLeaseResult> takeoverLock({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
    required String reason,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/orders/$orderId/takeover-lock',
        data: {
          'sessionId': sessionId,
          'tabSessionId': tabSessionId,
          'reason': reason,
        },
        options: Options(
          headers: {
            'X-Session-ID': sessionId,
            'X-Tab-Session-ID': tabSessionId,
          },
        ),
      );

      final dynamic raw = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (raw is Map<String, dynamic>) {
        return WorkspaceLeaseResult.fromJson(raw);
      }
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] takeoverLock error: $e');
    }

    return WorkspaceLeaseResult(
      lockStatus: 'CONFLICT_DIFFERENT_USER',
      readOnly: true,
      message: 'Admin takeover failed',
    );
  }

  /// POST /api/v1/orders/{id}/sync-events
  /// Forensic event logging
  Future<void> recordSyncEvent({
    required int orderId,
    required String sessionId,
    required String tabSessionId,
    required String eventType,
    required String payload,
  }) async {
    try {
      await _api.dio.post(
        '/api/v1/orders/$orderId/sync-events',
        data: {
          'sessionId': sessionId,
          'tabSessionId': tabSessionId,
          'eventType': eventType,
          'payload': payload,
        },
        options: Options(
          headers: {
            'X-Session-ID': sessionId,
            'X-Tab-Session-ID': tabSessionId,
          },
        ),
      );
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] recordSyncEvent warning: $e');
    }
  }

  /// POST /api/v1/auth/challenge/respond
  /// Responds to Single Login Challenge (KEEP or ALLOW)
  Future<bool> respondToLoginChallenge({
    required String decision, // 'KEEP' or 'ALLOW'
    required String pendingSessionId,
  }) async {
    try {
      final response = await _api.dio.post(
        '/api/v1/auth/challenge/respond',
        data: {
          'decision': decision,
          'pendingSessionId': pendingSessionId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[WorkspaceLeaseClient] respondToLoginChallenge error: $e');
      return false;
    }
  }
}

