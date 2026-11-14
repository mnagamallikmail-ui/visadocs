import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
);

SharedPreferences? _prefs;
final Map<String, String> _memoryStorage = {};

Future<void> initPlatformStorage() async {
  try {
    _prefs = await SharedPreferences.getInstance();
    final keys = [
      'auth_token',
      'auth_username',
      'auth_email',
      'auth_role',
      'auth_full_name',
      'auth_mobile',
      'auth_user_id',
      'auth_biometric_enabled',
    ];
    for (final key in keys) {
      final secureVal = await _secureStorage.read(key: key);
      if (secureVal != null) {
        _memoryStorage[key] = secureVal;
      } else {
        final prefVal = _prefs?.getString(key);
        if (prefVal != null) {
          _memoryStorage[key] = prefVal;
        }
      }
    }
  } catch (_) {}
}

String? getStorageItem(String key) {
  return _memoryStorage[key] ?? _prefs?.getString(key);
}

void setStorageItem(String key, String value) {
  _memoryStorage[key] = value;
  _prefs?.setString(key, value);
  _secureStorage.write(key: key, value: value).catchError((_) {});
}

void removeStorageItem(String key) {
  _memoryStorage.remove(key);
  _prefs?.remove(key);
  _secureStorage.delete(key: key).catchError((_) {});
}

void clearStorage() {
  _memoryStorage.clear();
  _prefs?.clear();
  _secureStorage.deleteAll().catchError((_) {});
}
