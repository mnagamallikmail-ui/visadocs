import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';

void main() {
  group('Final Remediation Approval: Workspace Runtime & Hydration Certification', () {
    late DocumentWorkspaceProvider provider;

    setUp(() {
      provider = DocumentWorkspaceProvider();
    });

    test('TEST A & B & K: Report open with persisted values hydrates and calculates Composite Table & Valuation Summary immediately without user edit', () {
      final initialValues = <String, String>{
        'SALEABLE_AREA': '1425',
        'SALEABLE_RATE': '7000',
        'MARKET_RATE_FLAT': '7000',
        'COMPOSITE_GOVERNMENT_RATE': '3500',
        'COMPOSITE_CONSTRUCTION_COST': '2000',
        'PROPERTY_CATEGORY': 'Flat',
        'PROPERTY_SUB_TYPE': 'Apartment',
        'CLIENT_NAME': 'Rajesh Sharma',
        'BANK_NAME': 'State Bank of India',
        'BRANCH_NAME': 'Bengaluru',
      };

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 101,
        status: 'DRAFT',
        reportNumber: 'VR-101',
        visualPreview: VisualPreviewModel.fromJson(const {}),
        values: initialValues,
      );

      // Hydrate workspace model directly as happens on report open
      provider.setWorkspaceModelForTest(workspaceModel);

      // TEST A: Composite Property Table calculated immediately on load
      expect(provider.isCompositeProperty, isTrue);
      expect(provider.compositeItems.isNotEmpty, isTrue);

      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'MAIN_UNIT');
      expect(mainUnit.quantity, equals(1425.0));
      expect(mainUnit.rate, equals(7000.0));

      // 1425 * 7000 = 99,75,000
      expect(mainUnit.amount, equals(9975000.0));

      // TEST B: Valuation Summary populated immediately without touching any field
      expect(provider.getValue('unit_amount'), equals('99,75,000'));
      expect(provider.getValue('composite_value'), equals('99,75,000'));
      expect(provider.getValue('fair_value'), equals('99,80,000'));
      expect(provider.getValue('say_value'), equals('99,80,000'));
    });

    test('TEST E: Upload IMG_COVER_PAGE propagates to Workspace and synchronizes aliases', () {
      const dummyBase64 = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP...';
      provider.updateValue('IMG_COVER_PAGE', dummyBase64);

      expect(provider.getValue('IMG_COVER_PAGE'), equals(dummyBase64));
      expect(provider.getValue('IMG_FRONT_PAGE'), equals(dummyBase64));
      expect(provider.getValue('COVER_IMAGE'), equals(dummyBase64));
    });

    test('TEST L & M: Modifying Saleable Area or Rate updates calculations immediately', () {
      final workspaceModel = DocumentWorkspaceModel(
        orderId: 102,
        status: 'DRAFT',
        reportNumber: 'VR-102',
        visualPreview: VisualPreviewModel.fromJson(const {}),
        values: {
          'SALEABLE_AREA': '1000',
          'SALEABLE_RATE': '5000',
          'PROPERTY_CATEGORY': 'Flat',
        },
      );
      provider.setWorkspaceModelForTest(workspaceModel);

      // TEST L: Modify Saleable Area to 1500 sft
      provider.updateValue('SALEABLE_AREA', '1500 sft');
      expect(provider.getValue('SALEABLE_AREA'), equals('1500'));
      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('1500 sft'));
      // 1500 * 5000 = 75,00,000
      expect(provider.getValue('unit_amount'), equals('75,00,000'));

      // TEST M: Modify Saleable Rate to 6000
      provider.updateValue('SALEABLE_RATE', '6000');
      expect(provider.getValue('SALEABLE_RATE'), equals('6000'));
      // 1500 * 6000 = 90,00,000
      expect(provider.getValue('unit_amount'), equals('90,00,000'));
    });

    test('TEST J: Certificate Page contains ONLY template content, ZERO auto-injected tables', () {
      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'CERTIFICATE OF VALUATION',
            elements: [
              StudioParagraph(
                id: 'p_cert_title',
                runs: [
                  StudioRun(text: 'CERTIFICATE OF VALUATION', isPlaceholder: false),
                ],
              ),
              StudioParagraph(
                id: 'p_cert_body',
                runs: [
                  StudioRun(text: 'This is to certify that the property owned by ', isPlaceholder: false),
                  StudioRun(text: '<<owner_name>>', isPlaceholder: true, placeholderKey: 'OWNER_NAME'),
                  StudioRun(text: ' has a total land value of ', isPlaceholder: false),
                  StudioRun(text: '<<total_land_value>>', isPlaceholder: true, placeholderKey: 'TOTAL_LAND_VALUE'),
                  StudioRun(text: ', a fair market value of ', isPlaceholder: false),
                  StudioRun(text: '<<fair_value>>', isPlaceholder: true, placeholderKey: 'FAIR_VALUE'),
                  StudioRun(text: ', and a say value of ', isPlaceholder: false),
                  StudioRun(text: '<<say_value>>', isPlaceholder: true, placeholderKey: 'SAY_VALUE'),
                  StudioRun(text: '.', isPlaceholder: false),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'OWNER_NAME', label: 'Owner Name', occurrences: 1, type: 'TEXT'),
          PlaceholderSummaryItem(key: 'TOTAL_LAND_VALUE', label: 'Total Land Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'FAIR_VALUE', label: 'Fair Value', occurrences: 1, type: 'CALCULATED'),
          PlaceholderSummaryItem(key: 'SAY_VALUE', label: 'Say Value', occurrences: 1, type: 'CALCULATED'),
        ],
      );

      final values = {
        'OWNER_NAME': 'Rajesh Sharma',
        'TOTAL_LAND_VALUE': '50,00,000',
        'FAIR_VALUE': '99,75,000',
        'SAY_VALUE': '99,80,000',
        'PROPERTY_CATEGORY': 'Flat',
      };

      final vm = DocumentWorkspaceVm.fromDocumentDom(dom, values);
      expect(vm.sections.length, 1);
      final certSection = vm.sections.first;

      // Assert ZERO auto-injected valuation table blocks
      final compositeTables = certSection.orderedBlocks.whereType<ValuationCompositeBlockVm>().toList();
      final summaryTables = certSection.orderedBlocks.whereType<ValuationSummaryBlockVm>().toList();
      final landTables = certSection.orderedBlocks.whereType<ValuationLandBlockVm>().toList();
      final buildingTables = certSection.orderedBlocks.whereType<ValuationBuildingBlockVm>().toList();
      final propertyTables = certSection.orderedBlocks.whereType<ValuationPropertyBlockVm>().toList();

      expect(compositeTables.isEmpty, isTrue, reason: 'Certificate page must NOT auto-inject Composite Property Table');
      expect(summaryTables.isEmpty, isTrue, reason: 'Certificate page must NOT auto-inject Valuation Summary Table');
      expect(landTables.isEmpty, isTrue, reason: 'Certificate page must NOT auto-inject Land Table');
      expect(buildingTables.isEmpty, isTrue, reason: 'Certificate page must NOT auto-inject Building Table');
      expect(propertyTables.isEmpty, isTrue, reason: 'Certificate page must NOT auto-inject Property Table');

      // Assert ONLY clean paragraph blocks
      final paragraphBlocks = certSection.orderedBlocks.whereType<ParagraphBlockWrapperVm>().toList();
      expect(paragraphBlocks.length, 2);
    });

    testWidgets('TEST N: DocumentInputSlotWidget rebuild performance with context.select', (WidgetTester tester) async {
      final fieldVm = InputFieldVm(
        key: 'TEST_KEY',
        questionText: 'Enter test value',
        fieldType: 'TEXT',
        occurrences: 1,
        currentValue: 'Initial',
      );

      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: provider,
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  buildCount++;
                  return DocumentInputSlotWidget(fieldVm: fieldVm);
                },
              ),
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Updating a DIFFERENT key in provider should NOT cause this builder to rebuild
      provider.updateValue('UNRELATED_KEY', 'Some Value');
      await tester.pump();
      expect(buildCount, 1); // Builder not rebuilt

      // Updating THIS key updates the widget cleanly
      provider.updateValue('TEST_KEY', 'Updated Value');
      await tester.pump();
      expect(find.text('Updated Value'), findsOneWidget);
    });
  });
}
