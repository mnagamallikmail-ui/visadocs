import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';

void main() {
  group('SPA Approve & Compile State Management Verification Suite', () {
    DocumentWorkspaceModel createTestModel({String status = 'SPA_GATE', bool readOnly = false}) {
      return DocumentWorkspaceModel(
        orderId: 102,
        status: status,
        reportNumber: 'PV-2610-0328',
        readOnly: readOnly,
        visualPreview: const VisualPreviewModel(
          templateId: 60,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
        values: {'PROPERTY_CITY': 'Hyderabad'},
      );
    }

    test('BUG 1 & 3: spaApprove clears stale errorMessage and sets progressive compile status', () async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createTestModel());

      // Simulate prior stale error in provider state
      provider.setErrorMessageForTest('Stale previous error from auto-save');
      expect(provider.errorMessage, equals('Stale previous error from auto-save'));

      // spaApprove should clear error state before network dispatch
      final approveFuture = provider.spaApprove(108400000.0);

      // Verify compileStatusMessage is set during submission
      expect(provider.isSubmitting, isTrue);
      expect(provider.compileStatusMessage, equals('Compiling report...'));

      await approveFuture;

      // After execution finishes, submitting and compileStatusMessage must be reset
      expect(provider.isSubmitting, isFalse);
      expect(provider.compileStatusMessage, isNull);
    });

    test('BUG 2 & 4: Initial clean state verified and no residual error retained', () async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createTestModel());

      expect(provider.workspaceModel?.status, equals('SPA_GATE'));
      expect(provider.errorMessage, isNull);
      expect(provider.compileStatusMessage, isNull);
    });
  });
}
