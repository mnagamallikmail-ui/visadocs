import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Land Valuation Methodology Remediation Certification Tests', () {
    test('FIX 1 & FIX 2 & FIX 4: Land valuation calculations (Area = 542 Sq.Yd @ 200,000)', () {
      final landItem = ValuationLandItemModel(
        description: 'Commercial Land Parcel',
        enteredArea: 542,
        enteredUnit: 'Sq.Yards',
        rate: 200000,
      );

      // 1. Direct Land Item Calculation
      ValuationCalculator.calculateLandItem(landItem);

      // Standard Sq.Ft = 542 * 9 = 4,878
      expect(landItem.standardAreaSqft, 4878.0);
      // Amount = 542 * 200,000 = 10,84,00,000
      expect(landItem.value, 108400000.0);

      // 2. Summary Calculation
      final valData = ValuationDataModel(orderId: 101);
      ValuationCalculator.recalculateSummary(valData, [landItem], []);

      expect(valData.totalLandValue, 108400000.0);
      expect(valData.totalBuildingValue, 0.0);
      expect(valData.totalReplacementCost, 0.0);
      expect(valData.fairValue, 108400000.0); // Say value for 10.84 Cr
      expect(valData.insurableValue, 0.0); // Land has NO insurable value

      // 3. Placeholders Generation
      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': 101, 'clientName': 'Test Land Owner'},
        data: valData,
        landItems: [landItem],
        buildingItems: [],
        comparables: [],
      );

      expect(placeholders['total_land_value'], '10,84,00,000');
      expect(placeholders['fair_value'], '10,84,00,000');
      expect(placeholders['final_value'], '10,84,00,000');
      expect(placeholders['insurable_value'], '0');
    });

    test('FIX 1: DocumentWorkspaceProvider with PROPERTY_CATEGORY=Land forces land methodology', () {
      final provider = DocumentWorkspaceProvider();
      final dom = StudioDocumentModel(sections: []);
      final model = DocumentWorkspaceModel(
        orderId: 328,
        reportNumber: 'PV-2610-0328',
        status: 'DRAFTING',
        workspaceRevision: 2,
        values: {
          'PROPERTY_CATEGORY': 'Land',
          'LAND_AREA': '542',
          'LAND_RATE': '200000',
        },
        readOnly: false,
        documentDom: dom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      provider.setWorkspaceModelForTest(model);

      // Verify isCompositeProperty evaluates to false
      expect(provider.isCompositeProperty, isFalse);
      expect(provider.compositeItems.isEmpty, isTrue);

      // Add land parcel
      provider.addLandItem();
      expect(provider.landItems.length, 1);

      provider.landItems[0].enteredArea = 542;
      provider.landItems[0].enteredUnit = 'Sq.Yards';
      provider.landItems[0].rate = 200000;

      provider.recalculateValuation();

      // Verify calculations
      expect(provider.landItems[0].value, 108400000.0);
      expect(provider.valuationData!.totalLandValue, 108400000.0);
      expect(provider.valuationData!.fairValue, 108400000.0);
      expect(provider.valuationData!.insurableValue, 0.0);
      expect(provider.activeValues['total_land_value'], '10,84,00,000');
      expect(provider.activeValues['fair_value'], '10,84,00,000');
      expect(provider.activeValues['final_value'], '10,84,00,000');
      expect(provider.activeValues['insurable_value'], '0');
    });

    testWidgets('FIX 3: Valuation Summary hides Insurable Value for land-only report in UI', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = DocumentWorkspaceProvider();
      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Valuation Section',
            elements: [
              StudioParagraph(
                id: 'p1',
                runs: [
                  StudioRun(text: '<<VALUATION_SUMMARY_TABLE>>', isPlaceholder: true, placeholderKey: 'VALUATION_SUMMARY_TABLE'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(
            key: 'VALUATION_SUMMARY_TABLE',
            label: 'Summary Table',
            occurrences: 1,
            type: 'DYNAMIC_VALUATION_SUMMARY_TABLE',
          ),
        ],
      );

      final model = DocumentWorkspaceModel(
        orderId: 328,
        reportNumber: 'PV-2610-0328',
        status: 'DRAFTING',
        workspaceRevision: 2,
        values: {
          'PROPERTY_CATEGORY': 'Commercial Land',
        },
        readOnly: false,
        documentDom: dom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      provider.setWorkspaceModelForTest(model);
      provider.addLandItem();
      provider.landItems[0].enteredArea = 542;
      provider.landItems[0].enteredUnit = 'Sq.Yards';
      provider.landItems[0].rate = 200000;
      provider.recalculateValuation();

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

      // Verify Fair Value, Realizable Value, Distress Sale Value, Government Value are visible
      expect(find.text('Fair Market Value (Say Land + Say Bldg)'), findsOneWidget);
      expect(find.text('Government / Guideline Value'), findsOneWidget);

      // Verify Insurable Value row is HIDDEN because buildingItems is empty
      expect(find.text('Insurable Value (Replacement Cost)'), findsNothing);
    });
  });
}
