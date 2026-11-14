import 'dart:async';
import 'indexed_db_draft_service_stub.dart'
    if (dart.library.html) 'indexed_db_draft_service_web.dart';

/// IndexedDB V2 Workspace Draft Data Model
class WorkspaceDraftModel {
  final int orderId;
  final int draftVersion;
  final int revision;
  final String sourceSession;
  final DateTime savedAt;
  final Map<String, String> deltaValues;
  final Map<String, String> fullSnapshot;

  WorkspaceDraftModel({
    required this.orderId,
    this.draftVersion = 2,
    required this.revision,
    required this.sourceSession,
    required this.savedAt,
    required this.deltaValues,
    required this.fullSnapshot,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'draftVersion': draftVersion,
        'revision': revision,
        'sourceSession': sourceSession,
        'savedAt': savedAt.toIso8601String(),
        'deltaValues': deltaValues,
        'fullSnapshot': fullSnapshot,
      };

  factory WorkspaceDraftModel.fromJson(Map<String, dynamic> json) =>
      WorkspaceDraftModel(
        orderId: json['orderId'] is int
            ? json['orderId']
            : int.tryParse(json['orderId']?.toString() ?? '0') ?? 0,
        draftVersion: json['draftVersion'] is int
            ? json['draftVersion']
            : int.tryParse(json['draftVersion']?.toString() ?? '2') ?? 2,
        revision: json['revision'] is int
            ? json['revision']
            : int.tryParse(json['revision']?.toString() ?? '1') ?? 1,
        sourceSession: json['sourceSession']?.toString() ?? '',
        savedAt: DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
            DateTime.now(),
        deltaValues: json['deltaValues'] is Map
            ? Map<String, String>.from((json['deltaValues'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
            : {},
        fullSnapshot: json['fullSnapshot'] is Map
            ? Map<String, String>.from((json['fullSnapshot'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? '')))
            : {},
      );
}

/// Abstract/Cross-platform Interface for IndexedDB V2 Draft Management
class IndexedDbDraftService {
  static final IndexedDbDraftService instance = IndexedDbDraftService._();
  IndexedDbDraftService._();

  /// Saves a workspace draft to local storage / IndexedDB V2
  Future<void> saveDraft(WorkspaceDraftModel draft) =>
      saveDraftPlatform(draft);

  /// Loads an existing workspace draft for given orderId
  Future<WorkspaceDraftModel?> getDraft(int orderId) =>
      getDraftPlatform(orderId);

  /// Deletes draft on discard or successful server commit
  Future<void> deleteDraft(int orderId) =>
      deleteDraftPlatform(orderId);

  /// Checks if an uncommitted draft exists for orderId
  Future<bool> hasDraft(int orderId) =>
      hasDraftPlatform(orderId);
}

