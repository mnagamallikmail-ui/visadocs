import 'package:dio/dio.dart';

class ApiService {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://visadocs.online',
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
                      ? e.response!.data
                      : {'activeVersion': 'v1.0'};

              final String activeVer