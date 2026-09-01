import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';

void main() {
  group('Dynamic Valuation Injection & Question Suppression Tests', () {
    test('DOM Parser correctly creates ValuationBlockVm and suppresses calculated question cards', () {
      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION OF LAND AND BUILDINGS',
            elements: [
              StudioParagraph(
                id: 'p_land_directive',
                runs: [
                  StudioRun(text: '<<LAND_TABLE>>', isPlaceholder: true, placeholderKey: 'LAND_TABLE'),
                ],
              ),
              StudioParagraph(
                id: 'p_bldg_directive',
                runs: [
                  StudioRun(text: '<<BUILDING_TABLE>>', isPlaceholder: true, placeholderKey: 'BUILDING_TABLE'),
                ],
              ),
              StudioParagraph(
                id: 'p_prop_value_directive',
                runs: [
                  StudioRun(text: 'VALUE OF THE PROPERTY', isPlaceholder: false),
                  StudioRun(text: '<<total_land_value>>', isPlaceholder: true, placeholderKey: 'TOTAL_LAND_VALUE'),
                  StudioRun(text: '<<total_building_value>>', isPlaceholder: true, placeholderKey: 'TOTAL_BUILDING_VALUE'),
                  StudioRun(text: '<<fair_value>>', isPlaceholder: true, placeholderKey: 'FAIR_VALUE'),
                  StudioRun(text: '<<say_value>>', isPlaceholder: true, placeholderKey: 'SAY_VALUE'),
                ],
              ),
              StudioParagraph(
                id: 'p_summary_directive',
                runs: [
                  StudioRun(text: '<<VALUATION_SUMMARY_TABLE>>', isPlaceholder: true, placeholderKey: 'VALUATION_SUMMARY_TABLE'),
                ],
              ),
              StudioParagraph(
                id: 'p_normal_question',
                runs: [
                  StudioRun(text: '<<client_name>>', isPlaceholder: true, placeholderKey: 'CLIENT_NAME'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'LAND_TABLE', label: 'Land Table', occurrences: 1, type: 'DYNAMIC_LAND_TABLE'),
          PlaceholderSummaryItem(key: 'BUILDING_TABLE', label: 'Building Table', occurrences: 1, type: 'DYNAMIC_BUILDING_TABLE'),
          PlaceholderSummaryItem(key: 'VALUATION_SUMMARY_TABLE', label: 'Valuation Summary Table', occurrences: 1, type: 'DYNAMIC_VALUATION_SUMMARY_TABLE'),
          PlaceholderSummaryItem(key: 'TOTAL_LAND_VALUE', label: 'Total Land Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'TOTAL_BUILDING_VALUE', label: 'Total Building Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'FAIR_VALUE', label: 'Fair Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'SAY_VALUE', label: 'Say Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'CLIENT_NAME', label: 'Client Name', occurrences: 1, type: 'TEXT', questionText: 'Name of Client'),
        ],
      );

      final values = <String, String>{
        'CLIENT_NAME': 'Acme Corp',
        'TOTAL_LAND_VALUE': '15,00,000',
        'TOTAL_BUILDING_VALUE': '23,12,500',
        'FAIR_VALUE': '38,12,500',
        'SAY_VALUE': '38,12,500',
      };

      final vm = DocumentWorkspaceVm.fromDocumentDom(dom, values);

      expect(vm.sections.length, 1);
      final section = vm.sections.first;

      // Verify orderedBlocks contains the 4 valuation blocks
      final landBlocks = section.orderedBlocks.whereType<ValuationLandBlockVm>().toList();
      final bldgBlocks = section.orderedBlocks.whereType<ValuationBuildingBlockVm>().toList();
      final propBlocks = section.orderedBlocks.whereType<ValuationPropertyBlockVm>().toList();
      final summaryBlocks = section.orderedBlocks.whereType<ValuationSummaryBlockVm>().toList();
      final paragraphBlocks = section.orderedBlocks.whereType<ParagraphBlockWrapperVm>().toList();

      expect(landBlocks.length, 1, reason: 'LAND_TABLE should generate ValuationLandBlockVm');
      expect(bldgBlocks.length, 1, reason: 'BUILDING_TABLE should generate ValuationBuildingBlockVm');
      expect(propBlocks.length, 1, reason: 'Property Value section should generate ValuationPropertyBlockVm');
      expect(summaryBlocks.length, 1, reason: 'VALUATION_SUMMARY_TABLE should generate ValuationSummaryBlockVm');

      // Verify calculated outputs are NOT in standard paragraph input fields
      expect(paragraphBlocks.length, 1);
      final clientField = paragraphBlocks.first.block.inputFields.first;
      expect(clientField.key, 'CLIENT_NAME');

      final allInputKeys = <String>[];
      for (final p in paragraphBlocks) {
        for (final f in p.block.inputFields) {
          allInputKeys.add(f.key);
        }
      }

      expect(allInputKeys.contains('TOTAL_LAND_VALUE'), isFalse, reason: 'TOTAL_LAND_VALUE must not be a question card');
      expect(allInputKeys.contains('TOTAL_BUILDING_VALUE'), isFalse, reason: 'TOTAL_BUILDING_VALUE must not be a question card');
      expect(allInputKeys.contains('FAIR_VALUE'), isFalse, reason: 'FAIR_VALUE must not be a question card');
      expect(allInputKeys.contains('SAY_VALUE'), isFalse, reason: 'SAY_VALUE must not be a question card');
      expect(allInputKeys.contains('LAND_TABLE'), isFalse, reason: 'LAND_TABLE directive must not be a question card');
      expect(allInputKeys.contains('BUILDING_TABLE'), isFalse, reason: 'BUILDING_TABLE directive must not be a question card');
      expect(allInputKeys.contains('VALUATION_SUMMARY_TABLE'), isFalse, reason: 'VALUATION_SUMMARY_TABLE directive must not be a question card');
    });

    testWidgets('DocumentTableWorkspaceWidget renders Land, Building, Property Value, and Summary sections inline', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION SECTION',
            elements: [
              StudioParagraph(
                id: 'p_land',
                runs: [StudioRun(text: '<<LAND_TABLE>>', isPlaceholder: true, placeholderKey: 'LAND_TABLE')],
              ),
              StudioParagraph(
                id: 'p_bldg',
                runs: [StudioRun(text: '<<BUILDING_TABLE>>', isPlaceholder: true, placeholderKey: 'BUILDING_TABLE')],
              ),
              StudioParagraph(
                id: 'p_prop',
                runs: [StudioRun(text: '<<PROPERTY_VALUE_TABLE>>', isPlaceholder: true, placeholderKey: 'PROPERTY_VALUE_TABLE')],
              ),
              StudioParagraph(
                id: 'p_sum',
                runs: [StudioRun(text: '<<VALUATION_SUMMARY_TABLE>>', isPlaceholder: true, placeholderKey: 'VALUATION_SUMMARY_TABLE')],
              ),
            ],
          ),
        ],
        placeholdersSummary: [],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 101,
        reportNumber: 'PV-101',
        status: 'IN_PROGRESS',
        readOnly: false,
        documentDom: dom,
        values: {},
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

      // Verify LAND_TABLE UI & Edit in Valuation Engine
      expect(find.text('VALUE OF LAND'), findsOneWidget);
      expect(find.text('<<LAND_TABLE>>'), findsOneWidget);
      expect(find.text('Edit in Valuation Engine'), findsWidgets);

      // Verify BUILDING_TABLE UI
      expect(find.text('VALUE OF BUILDING'), findsOneWidget);
      expect(find.text('<<BUILDING_TABLE>>'), findsOneWidget);

      // Verify VALUE OF THE PROPERTY UI
      expect(find.text('VALUE OF THE PROPERTY'), findsOneWidget);
      expect(find.text('VALUATION PARAMETER'), findsWidgets);
      expect(find.text('LAND (₹)'), findsWidgets);
      expect(find.text('BUILDING (₹)'), findsWidgets);
      expect(find.text('TOTAL (₹)'), findsWidgets);

      // Verify VALUATION_SUMMARY_TABLE UI
      expect(find.text('SUMMARY OF VALUATION'), findsOneWidget);
      expect(find.text('<<VALUATION_SUMMARY_TABLE>>'), findsOneWidget);
    });
  });
}
