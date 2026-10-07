import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
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
  });
}
