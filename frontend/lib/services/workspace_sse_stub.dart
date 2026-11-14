import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef SseCallback = void Function(String eventType, Map<String, dynamic> data);
typedef SseDisconnectCallback = void Function();

CancelToken? _cancelToken;

void connectSsePlatform(String token, String baseUrl, SseCallback onEvent, SseDisconnectCallback onDisconnect) async {
  disconnectSsePlatform();
  _cancelToken = CancelToken();

  try {
    final dio = Dio();
    final streamUrl = '$baseUrl/api/v1/events/session-stream?token=${Uri.encodeComponent(token)}';

    final response = await dio.get<ResponseBody>(
      streamUrl,
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
      cancelToken: _cancelToken,
    );

    if (response.data != null) {
      onEvent('CONNECTED', {'status': 'CONNECTED'});
      response.data!.stream.listen((bytes) {
        final text = utf8.decode(bytes);
        final lines = text.split('\n');
        String currentEvent = 'MESSAGE';
        for (final line in lines) {
          if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            try {
              final decoded = jsonDecode(dataStr);
              if (decoded is Map<String, dynamic>) {
                onEvent(currentEvent, decoded);
              }
            } catch (_) {}
          }
        }
      }, onDone: () {
        onDisconnect();
      }, onError: (e) {
        onDisconnect();
      });
    }
  } catch (e) {
    debugPrint('[SSE-Stub] Connection error: $e');
    onDisconnect();
  }
}

void disconnectSsePlatform() {
  if (_cancelToken != null && !_cancelToken!.isCancelled) {
    _cancelToken!.cancel('Disconnected');
    _cancelToken = null;
  }
}

