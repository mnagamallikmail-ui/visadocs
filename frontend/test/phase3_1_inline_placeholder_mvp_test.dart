import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';

void main() {
  group('Phase 3.1: Inline Placeholder Editing MVP (Core Document Flow)', () {
    testWidgets('Target UX: Prose with inline placeholders, Read Mode by default, and Click-to-Edit', (tester) async {
      final docDom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Valuation Preamble',
            elements: [
              StudioParagraph(
                id: 'p_narrative',
                alignment: 'LEFT',
                runs: const [
                  StudioRun(text: 'Dear '),
                  StudioRun(text: '<<BANK_NAME>>', isPlaceholder: true, placeholderKey: 'BANK_NAME'),
                  StudioRun(text: ',\n\nWe have inspected the property owned by '),
                  StudioRun(text: '<<OWNER_NAME>>', isPlaceholder: true, placeholderKey: 'OWNER_NAME'),
                  StudioRun(text: ' and assessed its value at '),
                  StudioRun(text: '<<FAIR_VALUE>>', isPlaceholder: true, placeholderKey: 'FAIR_VALUE'),
                  StudioRun(text: '.'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'BANK_NAME', label: 'Bank Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'OWNER_NAME', label: 'Owner Name', occurrences: 2),
          PlaceholderSummaryItem(key: 'FAIR_VALUE', label: 'Fair Value', occurrences: 1),
        ],
      );

      final values = <String, String>{
        'BANK_NAME': 'State Bank of India',
        'CLIENT_NAME': 'M/s ABC Infrastructure Pvt Ltd',
        'OWNER_NAME': 'M/s ABC Infrastructure Pvt Ltd',
        'FAIR_VALUE': '1,25,00,000',
      };

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 301,
        reportNumber: 'VAL-MVP-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: values,
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. ACCEPTANCE: Document renders as continuous narrative prose
      expect(find.textContaining('Dear '), findsOneWidget);
      expect(find.textContaining('We have inspected the property owned by '), findsOneWidget);
      expect(find.textContaining(' and assessed its value at '), findsOneWidget);

      // 2. ACCEPTANCE: Placeholders appear inline with subtle visual styling
      expect(find.text('State Bank of India'), findsOneWidget);
      expect(find.text('M/s ABC Infrastructure Pvt Ltd'), findsOneWidget);

      // 3. ACCEPTANCE: No visible TextFields in Read Mode by default
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // 4. ACCEPTANCE: Placeholder click enters edit mode (No modal, no dialog, no side panel)
      await tester.tap(find.text('M/s ABC Infrastructure Pvt Ltd'));
      await tester.pumpAndSettle();

      // Active TextField is now rendered ONLY for that single placeholder
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);

      // 5. ACCEPTANCE: Editing updates value and auto-reflows
      await tester.enterText(find.byType(TextFormField), 'M/s Global Megatech Projects Private Limited');
      // Unfocus (clicking away) commits value and returns to Read Mode
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // 6. ACCEPTANCE: Exit edit mode commits value and returns to Read Mode
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('M/s Global Megatech Projects Private Limited'), findsOneWidget);
      expect(provider.getValue('OWNER_NAME'), 'M/s Global Megatech Projects Private Limited');
    });

    testWidgets('ACCEPTANCE: Repeated Placeholders Synchronize Reactively', (tester) async {
      final docDom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Section 1 - Schedule',
            elements: [
              StudioParagraph(
                id: 'p1',
                runs: const [
                  StudioRun(text: 'First Reference: '),
                  StudioRun(text: '<<CLIENT_NAME>>', isPlaceholder: true, placeholderKey: 'CLIENT_NAME'),
                  StudioRun(text: '.'),
                ],
              ),
              StudioParagraph(
                id: 'p2',
                runs: const [
                  StudioRun(text: 'Second Reference: '),
                  StudioRun(text: '<<CLIENT_NAME>>', isPlaceholder: true, placeholderKey: 'CLIENT_NAME'),
                  StudioRun(text: '.'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'CLIENT_NAME', label: 'Client Name', occurrences: 2),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 302,
        reportNumber: 'VAL-SYNC-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: {'CLIENT_NAME': 'John Doe'},
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both instances render John Doe
      expect(find.text('John Doe'), findsNWidgets(2));

      // Click first instance to edit
      await tester.tap(find.text('John Doe').first);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsOneWidget);

      // Change value to Jane Smith
      await tester.enterText(find.byType(TextFormField), 'Jane Smith');
      // Unfocus (clicking away) commits value and returns to Read Mode
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Both instances must now display 'Jane Smith'
      expect(find.text('Jane Smith'), findsNWidgets(2));
      expect(find.text('John Doe'), findsNothing);
      expect(provider.getValue('CLIENT_NAME'), 'Jane Smith');
    });
  });
}
