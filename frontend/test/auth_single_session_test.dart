import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/providers/auth_provider.dart';

void main() {
  group('Single Active Session Authentication Tests', () {
    test('LoginResult correctly captures SESSION_ALREADY_ACTIVE with metadata', () {
      final result = LoginResult.sessionAlreadyActive(
        deviceName: 'Chrome on Windows 11',
        location: 'Mumbai, Maharashtra, India',
        loginTime: '2026-11-15T09:30:00Z',
      );

      expect(result.isSessionAlreadyActive, isTrue);
      expect(result.success, isFalse);
      expect(result.activeDeviceName, 'Chrome on Windows 11');
      expect(result.activeLocation, 'Mumbai, Maharashtra, India');
      expect(result.activeLoginTime, '2026-11-15T09:30:00Z');
      expect(result.errorMessage, isNull);
    });

    test('LoginResult completed factory behaves normally', () {
      final result = LoginResult.completed();

      expect(result.success, isTrue);
      expect(result.isSessionAlreadyActive, isFalse);
      expect(result.activeDeviceName, isNull);
    });
  });
}

