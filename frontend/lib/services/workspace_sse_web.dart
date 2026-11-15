// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

html.EventSource? _eventSource;

typedef SseCallback = void Function(String eventType, Map<String, dynamic> data);
typedef SseDisconnectCallback = void Function();

void connectSsePlatform(String token, String baseUrl, SseCallback onEvent, SseDisconnectCallback onDisconnect) {
  disconnectSsePlatform();

  try {
    final streamUrl = '$baseUrl/api/v1/events/session-stream?token=${Uri.encodeComponent(token)}';
    _eventSource = html.EventSource(streamUrl);

    _eventSource!.onOpen.listen((_) {
      debugPrint('[SSE-Web] Connected to real-time session stream');
      onEvent('CONNECTED', {'status': 'CONNECTED'});
    });

    _eventSource!.onError.listen((e) {
      debugPrint('[SSE-Web] Connection lost or error: $e');
      onDisconnect();
    });

    _eventSource!.onMessage.listen((html.MessageEvent event) {
      _parseAndDispatch(event.data, onEvent);
    });

    // Custom named SSE event listeners
    const customEvents = [
      'FORCE_AUTOSAVE_REQUEST',
      'LEASE_LOST',
      'WORKSPACE_INVALIDATED',
      'SESSION_EVICTED',
      'CONNECTED'
    ];

    for (final evName in customEvents) {
      _eventSource!.addEventListener(evName, (html.Event ev) {
        if (ev is html.MessageEvent) {
          _parseAndDispatch(ev.data, onEvent, defaultType: evName);
        }
      });
    }
  } catch (e) {
    debugPrint('[SSE-Web] Error initializing EventSource: $e');
    onDisconnect();
  }
}

void _parseAndDispatch(dynamic rawData, SseCallback onEvent, {String defaultType = 'MESSAGE'}) {
  try {
    if (rawData == null) return;
    final String text = rawData.toString();
    if (text.isEmpty) return;

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      final type = decoded['type']?.toString() ?? decoded['status']?.toString() ?? defaultType;
      onEvent(type, decoded);
    } else {
      onEvent(defaultType, {'raw': text});
    }
  } catch (e) {
    debugPrint('[SSE-Web] JSON parse error on SSE payload: $e');
  }
}

void disconnectSsePlatform() {
  if (_eventSource != null) {
    try {
      _eventSource!.close();
    } catch (_) {}
    _eventSource = null;
  }
}

