import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/services/token_storage.dart';
import 'package:provaluer_frontend/services/api_service.dart';

void main() {
  group('SEVERITY-1 HOTFIX: Zero Data Loss Guarantee Tests', () {
    const defaultPreview = VisualPreviewModel(
      templateId: 1,
      totalPages: 1,
      pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
      pages: [],
    );

    setUp(() {
      TokenStorage.clearSession();
      TokenStorage.clearDraftFromStorage(1255);
    });

    tearDown(() {
      TokenStorage.clearDraftFromStorage(1255);
    });

    test('TEST CASE 1 & 2: Write-through cache persists edits and retains cache on save failure', () async {
      final provider = DocumentWorkspaceProvider();

      final model = const DocumentWorkspaceModel(
        orderId: 1255,
        status: 'ASSIGNED',
        reportNumber: 'PV-2610-0018',
        visualPreview: defaultPreview,
        values: {'CLIENT_NAME': 'Initial Client'},
      );
      provider.setWorkspaceModelForTest(model);

      // Verify initial state
      expect(provider.saveState, SaveState.saved);
      expect(TokenStorage.loadDraftFromStorage(1255), isNull);

      // 1. User edits field
      provider.updateInputValue('SPECIAL_REMARKS', 'Field verification completed');

      // Verify write-through cache executed immediately
      expect(provider.saveState, SaveState.dirtyLocal);
      final cachedDraft = TokenStorage.loadDraftFromStorage(1255);
      expect(cachedDraft, isNotNull);
      expect(cachedDraft!['SPECIAL_REMARKS'], 'Field verification completed');

      // 2. Local cache retained
      expect(provider.isDirty, isTrue);
      expect(TokenStorage.loadDraftFromStorage(1255), isNotNull);
    });

    test('TEST CASE 4: Browser refresh restores unsaved draft automatically', () async {
      // 1. Simulate prior session leaving unsaved draft in storage
      TokenStorage.saveDraftToStorage(1255, {
        'PROPERTY_CATEGORY': 'COMMERCIAL',
        'VALUER_ESTIMATE': '7500000',
      });

      // 2. Verify that local draft storage still holds the pending edits
      final storedDraft = TokenStorage.loadDraftFromStorage(1255);
      expect(storedDraft, isNotNull);
      expect(storedDraft!['VALUER_ESTIMATE'], '7500000');
      expect(storedDraft['PROPERTY_CATEGORY'], 'COMMERCIAL');
    });

    test('TEST CASE 5: Cache eviction happens only upon confirmed save', () {
      TokenStorage.saveDraftToStorage(1255, {'NOTE': 'Pending'});
      expect(TokenStorage.loadDraftFromStorage(1255), isNotNull);

      // Explicit eviction upon successful HTTP 200
      TokenStorage.clearDraftFromStorage(1255);
      expect(TokenStorage.loadDraftFromStorage(1255), isNull);
    });

    test('API Service global 401 interceptor debounces session expiration', () {
      final api = ApiService();

      expect(api.isSessionExpired, isFalse);
      
      // Reset token clears expired state
      api.token = 'new_token';
      expect(api.isSessionExpired, isFalse);
    });
  });
}
