import 'dart:html' as html;
import 'package:dio/dio.dart';

class ApiService {
  static String _determineBaseUrl() {
    try {
      final String origin = html.window.location.origin;
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return 'https://visadocs.online';
      }
      return origin;
    } catch (_) {
      return 'https://visadocs.online';
    }
  }

  final Dio dio = Dio(
    BaseOptions(
      baseUrl: _determineBaseUrl(),
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
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
}