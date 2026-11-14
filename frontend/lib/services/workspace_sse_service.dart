import 'dart:async';
import 'workspace_sse_stub.dart'
    if (dart.library.html) 'workspace_sse_web.dart';

class WorkspaceSseEvent {
  final String eventType;
  final Map<String, dynamic> data;

  WorkspaceSseEvent({required this.eventType, required this.data});

  int? get orderId => data['orderId'] is int
      ? data['orderId']
      : int.tryParse(data['orderId']?.toString() ?? '');

  String? get reason => data['reason']?.toString();
  String? get newEditor => data['newEditor']?.toString();
  String? get challengeSessionId => data['challengeSessionId']?.toString() ?? data['pendingSessionId']?.toString();
  String? get requestingDevice => data['requestingDevice']?.toString() ?? data['incomingDevice']?.toString();
  String? get requestingPlatform => data['requestingPlatform']?.toString() ?? data['incomingPlatform']?.toString() ?? 'Desktop';
  String? get approximateLocation => data['approximateLocation']?.toString() ?? data['incomingLocation']?.toString() ?? 'India';
  int get timeoutSeconds => data['timeoutSeconds'] is int
      ? data['timeoutSeconds'] as int
      : int.tryParse(data['timeoutSeconds']?.toString() ?? data['expiresInSeconds']?.toString() ?? '30') ?? 30;
}

class WorkspaceSseService {
  static final WorkspaceSseService instance = WorkspaceSseService._();
  WorkspaceSseService._();

  final StreamController<WorkspaceSseEvent> _eventController =
      StreamController<WorkspaceSseEvent>.broadcast();

  Stream<WorkspaceSseEvent> get eventStream => _eventController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  void connect(String token, String baseUrl) {
    connectSsePlatform(token, baseUrl, (eventType, data) {
      _isConnected = true;
      _eventController.add(WorkspaceSseEvent(eventType: eventType, data: data));
    }, () {
      _isConnected = false;
    });
  }

  void disconnect() {
    disconnectSsePlatform();
    _isConnected = false;
  }
}

