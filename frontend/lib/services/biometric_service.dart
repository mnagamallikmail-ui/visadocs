import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if the device hardware supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Availability check failed: $e');
      return false;
    }
  }

  /// Get list of enrolled biometric types (fingerprint, face, iris)
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Enrolled biometrics query failed: $e');
      return [];
    }
  }

  /// Prompt the user for biometric or device PIN/Pattern authentication
  static Future<bool> authenticate({
    String reason = 'Authenticate to access Pro Valuer',
  }) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows Fingerprint, Face Unlock, Device PIN & Pattern
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('[BiometricService] Authentication failed: $e');
      return false;
    }
  }
}

