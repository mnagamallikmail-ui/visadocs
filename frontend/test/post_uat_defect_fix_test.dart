import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';

void main() {
  group('Post-UAT Defect Fix Verification Suite (Defects 1 to 7)', () {
    testWidgets('DEFECT 1 & 2: Paragraph Placeholders and Observation Fields Render as Inputs', (tester) async {
      final docDom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Cover Page & Observations',
            elements: [
              StudioParagraph(
                id: 'p_obs',
                runs: [
                  const StudioRun(text: 'Detailed Notes: '),
                  const StudioRun(text: '<<OBSERVATION_1>>', isPlaceholder: true, placeholderKey: 'OBSERVATION_1'),
                ],
              ),
              StudioParagraph(
                id: 'p_prop',
                runs: [
                  const StudioRun(text: 'Property: '),
                  const StudioRun(text: '<<Property_Description>>', isPlaceholder: true, placeholderKey: 'Property_Description'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          const PlaceholderSummaryItem(key: 'OBSERVATION_1', label: 'Observation 1', questionText: 'Observation 1', occurrences: 1),
          const PlaceholderSummaryItem(key: 'Property_Description', label: 'Property Description', questionText: 'Property Description', occurrences: 1),
        ],
      );

      final initialValues = <String, String>{
        'OBSERVATION_1': 'First line observation\nSecond line observation\nThird line observation',
        'PROPERTY_DESCRIPTION': 'Commercial Office Complex',
      };

      final vm = DocumentWorkspaceVm.fromDocumentDom(docDom, initialValues);

      // Verify ViewModel logic
      expect(vm.sections[0].orderedBlocks.length, 2);
      final pBlock1 = (vm.sections[0].orderedBlocks[0] as ParagraphBlockWrapperVm).block;
      expect(pBlock1.hasInputs, isTrue);
      expect(pBlock1.inputFields[0].key, 'OBSERVATION_1');
      expect(pBlock1.inputFields[0].isMultiline, isTrue);
      expect(pBlock1.inputFields[0].questionText, 'Observation 1');

      final pBlock2 = (vm.sections[0].orderedBlocks[1] as ParagraphBlockWrapperVm).block;
      expect(pBlock2.hasInputs, isTrue);
      expect(pBlock2.inputFields[0].key, 'PROPERTY_DESCRIPTION');
      expect(pBlock2.inputFields[0].isMultiline, isTrue);
      expect(pBlock2.inputFields[0].questionText, 'Property Description');

      // Test Widget Tree
      final workspaceModel = DocumentWorkspaceModel(
        orderId: 101,
        status: 'IN_PROGRESS',
        reportNumber: 'VAL-TEST-001',
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
        values: initialValues,
        documentDom: docDom,
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);
      provider.setActiveSectionIndex(0);

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

      // Verify no raw token '<<OBSERVATION_1>>' is displayed
      expect(find.text('<<OBSERVATION_1>>'), findsNothing);
      expect(find.text('<<Property_Description>>'), findsNothing);

      // Verify humanized labels and input slots are rendered
      expect(find.text('Observation 1'), findsOneWidget);
      expect(find.text('Property Description'), findsOneWidget);
      expect(find.byType(DocumentInputSlotWidget), findsNWidgets(2));
    });

    testWidgets('DEFECT 3: Image Placeholders Render Upload Control and Preview', (tester) async {
      const imgKey = 'IMG_PROPERTY_FRONT';
      const imgField = InputFieldVm(
        key: imgKey,
        questionText: 'Front Elevation Photograph',
        fieldType: 'IMAGE',
        occurrences: 1,
        currentValue: '',
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 102,
        status: 'IN_PROGRESS',
        reportNumber: 'VAL-TEST-002',
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
        values: {},
        documentDom: const StudioDocumentModel(sections: []),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: imgField),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Front Elevation Photograph'), findsOneWidget);
      expect(find.text('Upload Image'), findsOneWidget);

      // Tap upload button to simulate image attachment
      await tester.tap(find.text('Upload Image'));
      await tester.pumpAndSettle();

      expect(provider.getValue(imgKey), startsWith('data:image/png;base64,'));
      expect(find.text('Image Attached & Ready for DOCX/PDF'), findsOneWidget);
      expect(find.text('Replace'), findsOneWidget);
    });

    testWidgets('DEFECT 4, 6 & 7: Date Picker and Formatting Test', (tester) async {
      const dateField = InputFieldVm(
        key: 'DATE_OF_REPORT',
        questionText: 'Date of Report',
        fieldType: 'DATE',
        occurrences: 1,
        currentValue: '2026-08-30',
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 103,
        status: 'IN_PROGRESS',
        reportNumber: 'VAL-TEST-003',
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
        values: {
          'DATE_OF_REPORT': '2026-08-30',
        },
        documentDom: const StudioDocumentModel(sections: []),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: dateField),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify date is normalized to strict dd-MMM-yyyy format
      expect(find.text('30-Aug-2026'), findsOneWidget);
    });
  });
}
