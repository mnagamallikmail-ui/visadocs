// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'indexed_db_draft_service.dart';

const String _dbName = 'provaluer_workspace_v2';
const int _dbVersion = 1;
const String _storeName = 'drafts_v2';

dynamic get _idb => html.window.indexedDB;

Future<dynamic> _openDb() async {
  if (_idb == null) return null;
  final completer = Completer<dynamic>();

  try {
    final dynamic request = _idb.open(_dbName, version: _dbVersion,
        onUpgradeNeeded: (html.Event e) {
      final dynamic db = (e.target as dynamic).result;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName, keyPath: 'orderId');
      }
    });

    request.onSuccess.listen((_) {
      completer.complete(request.result);
    });

    request.onError.listen((e) {
      debugPrint('[IndexedDbWeb] openDb error: $e');
      completer.complete(null);
    });
  } catch (e) {
    debugPrint('[IndexedDbWeb] IndexedDB open exception: $e');
    completer.complete(null);
  }

  return completer.future;
}

Future<void> saveDraftPlatform(WorkspaceDraftModel draft) async {
  final jsonMap = draft.toJson();

  // Primary: IndexedDB V2
  try {
    final dynamic db = await _openDb();
    if (db != null) {
      final dynamic tx = db.transaction(_storeName, 'readwrite');
      final dynamic store = tx.objectStore(_storeName);
      store.put(jsonMap);
      await tx.completed;
      db.close();
      return;
    }
  } catch (e) {
    debugPrint('[IndexedDbWeb] Fallback to localStorage due to IDB error: $e');
  }

  // Secondary fallback: localStorage
  try {
    final key = 'pv_idb_draft_v2_${draft.orderId}';
    html.window.localStorage[key] = jsonEncode(jsonMap);
  } catch (e) {
    debugPrint('[IndexedDbWeb] localStorage save error: $e');
  }
}

Future<WorkspaceDraftModel?> getDraftPlatform(int orderId) async {
  // Primary: IndexedDB V2
  try {
    final dynamic db = await _openDb();
    if (db != null) {
      final dynamic tx = db.transaction(_storeName, 'readonly');
      final dynamic store = tx.objectStore(_storeName);
      final dynamic req = store.getObject(orderId);
      final completer = Completer<WorkspaceDraftModel?>();

      req.onSuccess.listen((_) {
        final result = req.result;
        if (result != null) {
          try {
            final map = Map<String, dynamic>.from(result as Map);
            completer.complete(WorkspaceDraftModel.fromJson(map));
          } catch (e) {
            completer.complete(null);
          }
        } else {
          completer.complete(null);
        }
      });

      req.onError.listen((_) => completer.complete(null));
      final res = await completer.future;
      db.close();
      if (res != null) return res;
    }
  } catch (e) {
    debugPrint('[IndexedDbWeb] IDB read exception: $e');
  }

  // Secondary fallback: localStorage
  try {
    final key = 'pv_idb_draft_v2_$orderId';
    final raw = html.window.localStorage[key];
    if (raw != null) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return WorkspaceDraftModel.fromJson(decoded);
    }
  } catch (_) {}

  return null;
}

Future<void> deleteDraftPlatform(int orderId) async {
  try {
    final dynamic db = await _openDb();
    if (db != null) {
      final dynamic tx = db.transaction(_storeName, 'readwrite');
      final dynamic store = tx.objectStore(_storeName);
      store.delete(orderId);
      await tx.completed;
      db.close();
    }
  } catch (e) {
    debugPrint('[IndexedDbWeb] IDB delete error: $e');
  }

  try {
    final key = 'pv_idb_draft_v2_$orderId';
    html.window.localStorage.remove(key);
  } catch (_) {}
}

Future<bool> hasDraftPlatform(int orderId) async {
  final draft = await getDraftPlatform(orderId);
  return draft != null;
}
