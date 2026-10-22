import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/document_workspace_api_service.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/services/token_storage.dart';

void main() {
  group('P0 Concurrency Hardening & Data Integrity Frontend Tests', () {
    const defaultPreview = VisualPreviewModel(
      templateId: 1,
      totalPages: 1,
      pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
      pages: [],
    );

    setUp(() {
      TokenStorage.clearSession();
      TokenStorage.clearDraftFromStorage(9999);
    });

    tearDown(() {
      TokenStorage.clearDraftFromStorage(9999);
    });

    test('FIX 6: Local draft includes workspaceRevision, timestamp, and owner metadata', () {
      TokenStorage.saveDraftToStorage(
        9999,
        {'PROPERTY_ADDRESS': '123 Test Street'},
        workspaceRevision: 4,
        owner: 'pa_user_1',
      );

      final metadata = TokenStorage.loadDraftMetadataFromStorage(9999);
      expect(metadata, isNotNull);
      expect(metadata!['orderId'], 9999);
      expect(metadata['workspaceRevision'], 4);
      expect(metadata['owner'], 'pa_user_1');
      expect(metadata['timestamp'], isNotNull);
      expect(metadata['values']['PROPERTY_ADDRESS'], '123 Test Street');
    });

    test('FIX 4: Multi-tab session lease isolation prevents simultaneous editing', () {
      // Simulate Tab 1 claiming active workspace lease
      TokenStorage.claimActiveWorkspaceSession(9999, 'tab_session_alpha');

      final activeLease = TokenStorage.getActiveWorkspaceSession(9999);
      expect(activeLease, isNotNull);
      expect(activeLease!['tabSessionId'], 'tab_session_alpha');

      // Release lease
      TokenStorage.releaseActiveWorkspaceSession(9999, 'tab_session_alpha');
      expect(TokenStorage.getActiveWorkspaceSession(9999), isNull);
    });

    test('FIX 1 & FIX 3: Read-only protection enforced when revision conflict exists', () {
      final provider = DocumentWorkspaceProvider();

      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-2610-TEST',
        visualPreview: defaultPreview,
        values: {'CLIENT_NAME': 'Initial Client'},
        workspaceRevision: 2,
      );
      provider.setWorkspaceModelForTest(model);

      expect(provider.isReadOnly, isFalse);

      // Trigger revision conflict
      provider.hasRevisionConflict = true;
      provider.notifyChanges();

      // Workspace must now be strictly locked to read-only
      expect(provider.isReadOnly, isTrue);
    });

    test('FIX 8: Invalidation notice locks workspace into read-only mode immediately', () {
      final provider = DocumentWorkspaceProvider();

      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-2610-TEST',
        visualPreview: defaultPreview,
        values: {},
        workspaceRevision: 1,
      );
      provider.setWorkspaceModelForTest(model);
      expect(provider.isReadOnly, isFalse);

      // Simulate reassignment or status lock invalidation notice
      provider.invalidationNotice = 'Order reassigned to another Property Analyst.';
      provider.notifyChanges();

      // Workspace locked immediately
      expect(provider.isReadOnly, isTrue);
    });

    test('1. test_live_preview_synchronizes_revision: refreshLivePreview routes through saveChanges and advances workspaceRevision', () async {
      final fakeApi = FakeDocumentWorkspaceApiService(serverRevision: 1);
      final provider = DocumentWorkspaceProvider(apiService: fakeApi);

      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-TEST',
        visualPreview: defaultPreview,
        values: {'PROPERTY_ADDRESS': 'Old Address'},
        workspaceRevision: 1,
      );
      provider.setWorkspaceModelForTest(model);

      // Analyst types an edit
      provider.updateInputValue('PROPERTY_ADDRESS', 'New Updated Address');
      expect(provider.isDirty, isTrue);

      // Switching to compiled preview calls refreshLivePreview()
      await provider.refreshLivePreview();

      // Verify save succeeded, revision advanced to 2 in provider, delta cleared, isDirty reset
      expect(fakeApi.lastSubmittedRevision, 1);
      expect(provider.workspaceModel!.workspaceRevision, 2);
      expect(provider.isDirty, isFalse);
      expect(provider.activeValues['PROPERTY_ADDRESS'], 'New Updated Address');
      expect(provider.errorMessage, isNull);
    });

    test('2. test_takeover_session_reloads_authoritative_revision: takeOverSession reloads workspace at latest revision and reapplies pending local deltas without data loss', () async {
      // Server is already at Revision 3
      final fakeApi = FakeDocumentWorkspaceApiService(serverRevision: 3);
      final provider = DocumentWorkspaceProvider(apiService: fakeApi);

      // Client was locally on Revision 1
      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-TEST',
        visualPreview: defaultPreview,
        values: {'CLIENT_NAME': 'Initial Name'},
        workspaceRevision: 1,
      );
      provider.setWorkspaceModelForTest(model);

      // User in this tab made uncommitted edits
      provider.updateInputValue('CLIENT_NAME', 'Uncommitted Local Tab Work');
      expect(provider.isDirty, isTrue);

      // User takes over session
      await provider.takeOverSession();

      // Verify workspace reloaded to Server Revision 3
      expect(provider.workspaceModel!.workspaceRevision, 3);
      // Verify local uncommitted work was preserved and reapplied (Zero Data Loss)
      expect(provider.activeValues['CLIENT_NAME'], 'Uncommitted Local Tab Work');
      expect(provider.isDirty, isTrue);
      // Verify localStorage metadata updated to Revision 3
      final draftMeta = TokenStorage.loadDraftMetadataFromStorage(9999);
      expect(draftMeta, isNotNull);
      expect(draftMeta!['workspaceRevision'], 3);
      expect(draftMeta['values']['CLIENT_NAME'], 'Uncommitted Local Tab Work');
    });

    test('3. test_autosave_manual_save_mutual_exclusion: saveChanges rejects concurrent execution when auto-save or manual save is in flight', () async {
      final fakeApi = FakeDocumentWorkspaceApiService(serverRevision: 1);
      final provider = DocumentWorkspaceProvider(apiService: fakeApi);

      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-TEST',
        visualPreview: defaultPreview,
        values: {},
        workspaceRevision: 1,
      );
      provider.setWorkspaceModelForTest(model);
      provider.updateInputValue('NOTES', 'Important Valuation Notes');

      // Simulate auto-save in progress
      provider.setAutoSavingForTest(true);
      expect(provider.isAutoSaving, isTrue);

      // Attempt manual save while auto-save is in progress -> Must be rejected immediately by mutex guard
      final resultDuringAutoSave = await provider.saveChanges(isAutoSave: false);
      expect(resultDuringAutoSave, isFalse);

      // Reset auto-save and simulate manual save in progress
      provider.setAutoSavingForTest(false);
      provider.setSavingForTest(true);
      expect(provider.isSaving, isTrue);

      // Attempt auto-save while manual save is in progress -> Must be rejected immediately by mutex guard
      final resultDuringManualSave = await provider.saveChanges(isAutoSave: true);
      expect(resultDuringManualSave, isFalse);
    });

    test('4. test_revision_conflict_banner_message_fidelity: 409 conflict captures exact server message and sets revision conflict state cleanly', () async {
      const serverErrorReason = 'Workspace updated elsewhere (Server revision: 3, Submitted revision: 2). Refresh required.';
      final fakeApi = FakeDocumentWorkspaceApiService(serverRevision: 3)
        ..shouldFailWith409 = true
        ..conflictErrorReason = serverErrorReason;

      final provider = DocumentWorkspaceProvider(apiService: fakeApi);
      final model = const DocumentWorkspaceModel(
        orderId: 9999,
        status: 'DRAFTING',
        reportNumber: 'PV-TEST',
        visualPreview: defaultPreview,
        values: {},
        workspaceRevision: 2,
      );
      provider.setWorkspaceModelForTest(model);
      provider.updateInputValue('OWNER_NAME', 'New Owner');

      // Attempt save -> Server returns 409
      final saveResult = await provider.saveChanges();
      expect(saveResult, isFalse);

      // Verify exact server message is preserved in saveErrorMessage
      expect(provider.hasRevisionConflict, isTrue);
      expect(provider.saveState, SaveState.error);
      expect(provider.saveErrorMessage, serverErrorReason);
      expect(provider.errorMessage, serverErrorReason);
    });
  });
}

class FakeDocumentWorkspaceApiService extends Fake implements DocumentWorkspaceApiService {
  int serverRevision;
  Map<String, dynamic> lastSavedValues = {};
  int? lastSubmittedRevision;
  bool shouldFailWith409 = false;
  String conflictErrorReason = 'Workspace updated elsewhere (Server revision: 3, Submitted revision: 2). Refresh required.';

  FakeDocumentWorkspaceApiService({this.serverRevision = 1});

  @override
  Future<DocumentWorkspaceModel> getDocumentWorkspace(int orderId) async {
    return DocumentWorkspaceModel(
      orderId: orderId,
      status: 'DRAFTING',
      reportNumber: 'PV-TEST',
      visualPreview: const VisualPreviewModel(
        templateId: 1,
        totalPages: 1,
        pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
        pages: [],
      ),
      values: {'PROPERTY_ADDRESS': 'Server Address'},
      workspaceRevision: serverRevision,
    );
  }

  @override
  Future<Map<String, dynamic>?> saveDocumentValues(
    int orderId,
    Map<String, String> values, {
    int? workspaceRevision,
  }) async {
    lastSavedValues = Map.from(values);
    lastSubmittedRevision = workspaceRevision;

    if (shouldFailWith409 || (workspaceRevision != null && workspaceRevision != serverRevision)) {
      final reqOptions = RequestOptions(path: '/api/v1/orders/$orderId/save-document-values');
      throw DioException(
        requestOptions: reqOptions,
        response: Response(
          requestOptions: reqOptions,
          statusCode: 409,
          data: {'error': conflictErrorReason},
        ),
      );
    }

    serverRevision++;
    return {
      'status': 'SAVED',
      'workspaceRevision': serverRevision,
    };
  }

  @override
  Future<VisualPreviewModel> compileLivePreview(int orderId) async {
    return const VisualPreviewModel(
      templateId: 1,
      totalPages: 1,
      pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
      pages: [],
    );
  }

  @override
  Future<Map<String, dynamic>?> checkWorkspaceTelemetry(int orderId) async {
    return {
      'orderId': orderId,
      'status': 'DRAFTING',
      'workspaceRevision': serverRevision,
      'isPaused': false,
    };
  }
}
