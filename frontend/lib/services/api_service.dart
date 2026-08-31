import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiService {
  static String _determineBaseUrl() {
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && !origin.contains('localhost') && !origin.contains('127.0.0.1')) {
          return origin;
        }
      } catch (_) {}
    }
    return 'https://visadocs.online';
  }

  // 0.3 Dio Timeouts: Connect = 30s, Receive = 120s, Send = 30s
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _determineBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  String? token;
  Function(String)? onTcRequired;

  ApiService._internal() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          if (e.response?.statusCode == 451) {
            if (onTcRequired != null) {
              final Map<String, dynamic> body =
                  e.response?.data is Map<String, dynamic>
                      ? e.response!.data as Map<String, dynamic>
                      : {'activeVersion': 'v1.0'};

              final String activeVer =
                  body['activeVersion']?.toString() ?? 'v1.0';

              onTcRequired!(activeVer);
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  /// User-friendly error message resolution for API exceptions
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
          return 'Connection timed out. Please check your internet or server status.';
        case DioExceptionType.receiveTimeout:
          return 'The server took too long to respond. The document may still be processing in the background.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is String && data.isNotEmpty) return data;
          if (data is Map && data.containsKey('message')) return data['message'].toString();
          return 'Server returned error (${error.response?.statusCode ?? 'unknown'}).';
        case DioExceptionType.connectionError:
          return 'Unable to reach the server. Please verify your connection.';
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        default:
          return 'Network error: ${error.message ?? 'An unexpected network error occurred.'}';
      }
    }
    return error?.toString() ?? 'An unexpected error occurred.';
  }
}