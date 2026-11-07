import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static final StreamController<bool> _connectionChangeController =
      StreamController<bool>.broadcast();

  static Stream<bool> get connectionStream => _connectionChangeController.stream;
  static bool _hasConnection = true;
  static bool get isConnected => _hasConnection;

  static void initialize() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    checkConnection();
  }

  static Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      return _hasConnection;
    } catch (e) {
      debugPrint('[ConnectivityService] Error checking connectivity: $e');
      return true;
    }
  }

  static void _updateConnectionStatus(List<ConnectivityResult> results) {
    final connected = results.any((r) => r != ConnectivityResult.none);
    if (_hasConnection != connected) {
      _hasConnection = connected;
      _connectionChangeController.add(_hasConnection);
      debugPrint('[ConnectivityService] Network status changed: connected=$_hasConnection');
    }
  }
}

