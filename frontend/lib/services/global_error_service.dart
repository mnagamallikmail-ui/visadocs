import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

enum ErrorSeverity { info, warn, error, critical }

/// Enterprise Production Governance: Global Error Service.
/// Phase 1: Centralized Error Tracking capturing frontend exceptions,
/// Dio network failures (401, 403, 404, 500), widget crashes, and provider errors.
class GlobalErrorService {
  static final GlobalErrorService _instance = GlobalErrorService._internal();
  factory GlobalErrorService() => _instance;
  GlobalErrorService._internal();

  static final List<Map<String, dynamic>> _inMemoryBuffer = [];
  static const int _maxBufferSize = 200;

  /// Initializes framework-level crash and uncaught exception handlers.
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      recordException(
        error,
        stack,
        screen: 'PlatformDispatcher',
        action: 'ASYNC_UNCAUGHT',
        severity: ErrorSeverity.critical,
      );
      return true;
    };
  }

  static void recordFlutterError(FlutterErrorDetails details) {
    recordException(
      details.exception,
      details.stack,
      screen: details.context?.toString() ?? 'FlutterTree',
      action: 'WIDGET_BUILD_CRASH',
      severity: ErrorSeverity.critical,
    );
  }

  static void recordDioError(
    DioException e, {
    String? screen,
    String? action,
    int? orderId,
    String? reportNumber,
  }) {
    final status = e.response?.statusCode;
    ErrorSeverity severity;
    if (status == 401 || status == 403) {
      severity = ErrorSeverity.warn;
    } else if (status != null && status >= 500) {
      severity = ErrorSeverity.critical;
    } else {
      severity = ErrorSeverity.error;
    }

    final data = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'orderId': orderId,
      'reportNumber': reportNumber,
      'screen': screen ?? 'NetworkLayer',
      'action': action ?? e.requestOptions.path,
      'errorMessage': e.message ?? e.toString(),
      'stackTrace': e.stackTrace.toString(),
      'statusCode': status,
      'severity': severity.name.toUpperCase(),
      'requestId': e.requestOptions.headers['X-Request-ID']?.toString(),
    };

    _dispatchError(data);
  }

  static void recordException(
    Object error,
    StackTrace? stack, {
    String? screen,
    String? action,
    int? orderId,
    String? reportNumber,
    ErrorSeverity severity = ErrorSeverity.error,
  }) {
    final data = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'orderId': orderId,
      'reportNumber': reportNumber,
      'screen': screen ?? 'UnknownScreen',
      'action': action ?? 'UNKNOWN_ACTION',
      'errorMessage': error.toString(),
      'stackTrace': stack?.toString() ?? '',
      'severity': severity.name.toUpperCase(),
    };

    _dispatchError(data);
  }

  static void _dispatchError(Map<String, dynamic> errorPayload) {
    _inMemoryBuffer.add(errorPayload);
    if (_inMemoryBuffer.length > _maxBufferSize) {
      _inMemoryBuffer.removeAt(0);
    }

    // Asynchronously transmit to backend telemetry endpoint without blocking the UI
    Timer.run(() async {
      try {
        final api = ApiService();
        await api.dio.post(
          '/api/v1/telemetry/errors',
          data: errorPayload,
          options: Options(
            headers: {'Content-Type': 'application/json'},
            sendTimeout: const Duration(seconds: 5),
            receiveTimeout: const Duration(seconds: 5),
          ),
        );
      } catch (_) {
        // Preserved in local buffer if offline
      }
    });
  }

  static List<Map<String, dynamic>> get bufferedErrors => List.unmodifiable(_inMemoryBuffer);
}
