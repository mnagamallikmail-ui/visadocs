import 'dart:convert';
import 'token_storage_stub.dart'
    if (dart.library.html) 'token_storage_web.dart';

class TokenStorage {
  static const String keyToken = 'auth_token';
  static const String keyUsername = 'auth_username';
  static const String keyEmail = 'auth_email';
  static const String keyRole = 'auth_role';
  static const String keyFullName = 'auth_full_name';
  static const String keyMobile = 'auth_mobile';
  static const String keyUserId = 'auth_user_id';

  static String? getToken() => getStorageItem(keyToken);
  static void saveToken(String token) => setStorageItem(keyToken, token);
  static void clearToken() => removeStorageItem(keyToken);

  static void saveSession({
    required String token,
    String? username,
    String? email,
    String? role,
    String? fullName,
    String? mobile,
    int? userId,
  }) {
    setStorageItem(keyToken, token);
    if (username != null) setStorageItem(keyUsername, username);
    if (email != null) setStorageItem(keyEmail, email);
    if (role != null) setStorageItem(keyRole, role);
    if (fullName != null) setStorageItem(keyFullName, fullName);
    if (mobile != null) setStorageItem(keyMobile, mobile);
    if (userId != null) setStorageItem(keyUserId, userId.toString());
  }

  static Map<String, dynamic> loadSession() {
    final token = getStorageItem(keyToken);
    final username = getStorageItem(keyUsername);
    final email = getStorageItem(keyEmail);
    final role = getStorageItem(keyRole);
    final fullName = getStorageItem(keyFullName);
    final mobile = getStorageItem(keyMobile);
    final userIdStr = getStorageItem(keyUserId);
    final userId = userIdStr != null ? int.tryParse(userIdStr) : null;

    return {
      'token': token,
      'username': username,
      'email': email,
      'role': role,
      'fullName': fullName,
      'mobile': mobile,
      'userId': userId,
    };
  }

  static void clearSession() {
    removeStorageItem(keyToken);
    removeStorageItem(keyUsername);
    removeStorageItem(keyEmail);
    removeStorageItem(keyRole);
    removeStorageItem(keyFullName);
    removeStorageItem(keyMobile);
    removeStorageItem(keyUserId);
  }

  static String _draftKey(int orderId) => 'pv_draft_order_$orderId';

  /// SPRINT 6 EMERGENCY HOTFIX: Zero data loss write-through draft cache
  static void saveDraftToStorage(int orderId, Map<String, String> values) {
    try {
      final clean = <String, String>{};
      values.forEach((k, v) {
        // Exclude large binary/base64 images to conserve localStorage
        if (!v.startsWith('data:image')) {
          clean[k] = v;
        }
      });
      setStorageItem(_draftKey(orderId), jsonEncode({
        'orderId': orderId,
        'timestamp': DateTime.now().toIso8601String(),
        'values': clean,
      }));
    } catch (_) {}
  }

  /// SPRINT 6 EMERGENCY HOTFIX: Hydrate unsaved local edits
  static Map<String, String>? loadDraftFromStorage(int orderId) {
    try {
      final raw = getStorageItem(_draftKey(orderId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic> && decoded['values'] is Map) {
        return Map<String, String>.from(
          (decoded['values'] as Map).map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
        );
      }
    } catch (_) {}
    return null;
  }

  /// SPRINT 6 EMERGENCY HOTFIX: Evict cache upon confirmed backend HTTP 200
  static void clearDraftFromStorage(int orderId) {
    try {
      removeStorageItem(_draftKey(orderId));
    } catch (_) {}
  }
}
