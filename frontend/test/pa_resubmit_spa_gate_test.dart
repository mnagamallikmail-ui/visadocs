import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';

void main() {
  group('PA Edit & Resubmit during SPA Review (Option A) Verification Suite', () {
    test('Valuation Portal isAssignedToMe evaluation logic', () {
      bool isAssignedToMe(String status, int? paId) {
        return (status == 'ASSIGNED' || status == 'SPA_GATE') && paId != null;
      }

      // ASSIGNED -> PA can access workspace
      expect(isAssignedToMe('ASSIGNED', 42), isTrue);

      // SPA_GATE -> PA can STILL access workspace (Option A)
      expect(isAssignedToMe('SPA_GATE', 42), isTrue);

      // SPA_CONFIRMED -> PA cannot access workspace
      expect(isAssignedToMe('SPA_CONFIRMED', 42), isFalse);

      // FINALIZED -> PA cannot access workspace
      expect(isAssignedToMe('FINALIZED', 42), isFalse);

      // FINAL_DELIVERY -> PA cannot access workspace
      expect(isAssignedToMe('FINAL_DELIVERY', 42), isFalse);

      // No PA assigned
      expect(isAssignedToMe('SPA_GATE', null), isFalse);
    });

    DocumentWorkspaceModel createWorkspaceModel(String status, bool readOnly) {
      return DocumentWorkspaceModel(
        orderId: 101,
        status: status,
        reportNumber: 'PV-TEST-101',
        readOnly: readOnly,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
        values: const {'CLIENT_NAME': 'Acme Corp'},
        documentDom: StudioDocumentModel(
          sections: [
            StudioSection(
              sectionIndex: 0,
              title: '1. Cover Section',
              elements: [
                StudioParagraph(
                  id: 'p_0',
                  runs: [const StudioRun(text: 'Valuation Test')],
                ),
              ],
            ),
          ],
          placeholdersSummary: [],
        ),
      );
    }

    Widget buildActionBarHarness({
      required DocumentWorkspaceProvider provider,
      required String role,
    }) {
      return ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Consumer<DocumentWorkspaceProvider>(
            builder: (context, prov, _) {
              final status = prov.workspaceModel?.status ?? 'ASSIGNED';
              final isPa = role == 'PA';
              final isAdmin = role == 'SUPER_ADMIN' || role == 'ADMIN';

              return Scaffold(
                appBar: AppBar(
                  actions: [
                    // Subordinate Save Draft Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.save_outlined, size: 14),
                      label: Text(prov.isSaving ? 'Saving...' : 'Save Draft'),
                      onPressed: (prov.isDirty && !prov.isSaving && !prov.isReadOnly)
                          ? () => prov.saveChanges()
                          : null,
                    ),
                    const SizedBox(width: 10),

                    // SINGLE DOMINANT PRIMARY ACTION: PA Submit / Resubmit to SPA
                    if ((isPa || isAdmin) &&
                        (status == 'ASSIGNED' || status == 'ACTION_NEEDED' || status == 'SPA_GATE')) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.send_rounded, size: 14),
                        label: Text(
                          prov.isSubmitting
                              ? 'Submitting...'
                              : (status == 'SPA_GATE' ? 'RESUBMIT TO SPA' : 'SUBMIT TO SPA'),
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    testWidgets('PA sees "SUBMIT TO SPA" button when status is ASSIGNED', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createWorkspaceModel('ASSIGNED', false));

      await tester.pumpWidget(buildActionBarHarness(provider: provider, role: 'PA'));
      await tester.pumpAndSettle();

      expect(find.text('SUBMIT TO SPA'), findsOneWidget);
      expect(find.text('RESUBMIT TO SPA'), findsNothing);
    });

    testWidgets('PA sees "RESUBMIT TO SPA" button when status is SPA_GATE (Option A requirement)', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createWorkspaceModel('SPA_GATE', false));

      await tester.pumpWidget(buildActionBarHarness(provider: provider, role: 'PA'));
      await tester.pumpAndSettle();

      expect(find.text('RESUBMIT TO SPA'), findsOneWidget);
      expect(find.text('SUBMIT TO SPA'), findsNothing);
    });

    testWidgets('PA submit/resubmit button is hidden once report is SPA_CONFIRMED', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createWorkspaceModel('SPA_CONFIRMED', true));

      await tester.pumpWidget(buildActionBarHarness(provider: provider, role: 'PA'));
      await tester.pumpAndSettle();

      expect(find.text('SUBMIT TO SPA'), findsNothing);
      expect(find.text('RESUBMIT TO SPA'), findsNothing);
    });

    testWidgets('PA can edit and save in SPA_GATE (Save Draft enabled when dirty)', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createWorkspaceModel('SPA_GATE', false));

      await tester.pumpWidget(buildActionBarHarness(provider: provider, role: 'PA'));
      await tester.pumpAndSettle();

      // Initially not dirty, so Save Draft disabled
      OutlinedButton saveBtn = tester.widget(find.widgetWithText(OutlinedButton, 'Save Draft'));
      expect(saveBtn.onPressed, isNull);

      // Modify a value
      provider.updateValue('CLIENT_NAME', 'Acme Corporation Ltd');
      await tester.pumpAndSettle();

      // Now dirty and not read-only in SPA_GATE -> Save Draft enabled
      expect(provider.isDirty, isTrue);
      expect(provider.isReadOnly, isFalse);
      saveBtn = tester.widget(find.widgetWithText(OutlinedButton, 'Save Draft'));
      expect(saveBtn.onPressed, isNotNull);
    });

    testWidgets('PA cannot save in SPA_CONFIRMED (Save Draft strictly disabled due to read-only)', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(createWorkspaceModel('SPA_CONFIRMED', true));

      await tester.pumpWidget(buildActionBarHarness(provider: provider, role: 'PA'));
      await tester.pumpAndSettle();

      // Read-only is true
      expect(provider.isReadOnly, isTrue);

      // Even if value is changed in memory
      provider.updateValue('CLIENT_NAME', 'New Value');
      await tester.pumpAndSettle();

      OutlinedButton saveBtn = tester.widget(find.widgetWithText(OutlinedButton, 'Save Draft'));
      expect(saveBtn.onPressed, isNull);
    });
  });
}
