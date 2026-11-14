import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'indexed_db_draft_service.dart';

final Map<int, WorkspaceDraftModel> _inMemoryStore = {};

Future<void> saveDraftPlatform(WorkspaceDraftModel draft) async {
  _inMemoryStore[draft.orderId] = draft;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'pv_idb_draft_v2_${draft.orderId}', jsonEncode(draft.toJson()));
  } catch (_) {}
}

Future<WorkspaceDraftModel?> getDraftPlatform(int orderId) async {
  if (_inMemoryStore.containsKey(orderId)) {
    return _inMemoryStore[orderId];
  }
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('pv_idb_draft_v2_$orderId');
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final draft = WorkspaceDraftModel.fromJson(decoded);
      _inMemoryStore[orderId] = draft;
      return draft;
    }
  } catch (_) {}
  return null;
}

Future<void> deleteDraftPlatform(int orderId) async {
  _inMemoryStore.remove(orderId);
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pv_idb_draft_v2_$orderId');
  } catch (_) {}
}

Future<bool> hasDraftPlatform(int orderId) async {
  if (_inMemoryStore.containsKey(orderId)) return true;
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('pv_idb_draft_v2_$orderId');
  } catch (_) {
    return false;
  }
}
