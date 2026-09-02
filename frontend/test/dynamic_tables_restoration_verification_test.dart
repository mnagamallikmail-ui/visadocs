import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';
import 'package:provaluer_frontend/utils/indian_number_formatter.dart';

void main() {
  group('DYNAMIC TABLES RESTORATION VERIFICATION SUITE (PHASES 1 - 6)', () {
    test('PHASE 5: Say Value Rounding Rule - Tiered Rounding Verification', () {
      // 1. Lakhs (< 50 Lakhs): Round to nearest ₹ 1,000
      expect(ValuationCalculator.computeSayValue(2312500.0), 2313000.0);
      expect(ValuationCalculator.computeSayValue(2312499.0), 2312000.0);
      expect(ValuationCalculator.computeSayValue(1550200.0), 1550000.0);
      expect(ValuationCalculator.computeSayValue(4999600.0), 5000000.0);

      // 2. Tens of Lakhs (50 Lakhs to 1 Crore): Round to nearest ₹ 10,000
      expect(ValuationCalculator.computeSayValue(6875000.0), 6880000.0);
      expect(ValuationCalculator.computeSayValue(5004000.0), 5000000.0);
      expect(ValuationCalculator.computeSayValue(7542380.0), 7540000.0);
      expect(ValuationCalculator.computeSayValue(9996000.0), 10000000.0);

      // 3. Crores (>= 1 Crore): Round to nearest ₹ 1,00,000
      expect(ValuationCalculator.computeSayValue(70812500.0), 70800000.0);
      expect(ValuationCalculator.computeSayValue(89997730.0), 90000000.0);
      expect(ValuationCalculator.computeSayValue(243872110.0), 243900000.0);
      expect(ValuationCalculator.computeSayValue(10049000.0), 10000000.0);
    });

    test('PHASE 1 & 2: Dynamic Tables Valuation Calculations and State Persistence', () {
      final provider = DocumentWorkspaceProvider();
      final freshOrderModel = DocumentWorkspaceModel(
        orderId: 999,
        reportNumber: 'PV-2609-0999',
        status: 'ASSIGNED',
        readOnly: false,
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {},
      );
      provider.setWorkspaceModelForTest(freshOrderModel);

      // Fresh report starts completely blank
      expect(provider.landItems, isEmpty);
      expect(provider.buildingItems, isEmpty);
      expect(provider.comparables, isEmpty);

      // 1. Add Land Parcel inside Dynamic Tables
      provider.addLandItem();
      expect(provider.landItems.length, 1);
      final parcel = provider.landItems[0];
      parcel.description = 'Commercial Plot 1';
      parcel.enteredArea = 2000;
      parcel.enteredUnit = 'Sq.Ft';
      parcel.standardAreaSqft = 2000;
      parcel.rate = 1500;
      parcel.value = 3000000;
      provider.recalculateValuation();

      // Land Value = 30,00,000 (< 50L) -> Say Land Value = 30,00,000
      expect(provider.valuationData!.totalLandValue, 3000000.0);
      expect(provider.valuationData!.sayLandValue, 3000000.0);

      // 2. Add Building Structure inside Dynamic Tables
      provider.addBuildingItem();
      expect(provider.buildingItems.length, 1);
      final structure = provider.buildingItems[0];
      structure.description = 'Ground Floor RCC';
      structure.buildingType = 'RCC Commercial';
      structure.enteredArea = 1500;
      structure.replacementRate = 2500;
      structure.replacementCost = 3750000;
      structure.buildingAge = 5;
      structure.buildingUsefulLife = 60;
      structure.salvagePercentage = 10;
      // Recalculate summary
      provider.recalculateValuation();

      expect(provider.valuationData!.totalBuildingValue, greaterThan(0));
      expect(provider.valuationData!.sayBuildingValue, greaterThan(0));

      // 3. Fair Value = Say Land + Say Building
      final expectedFair = provider.valuationData!.sayLandValue + provider.valuationData!.sayBuildingValue;
      expect(provider.valuationData!.fairValue, expectedFair);

      // 4. Update Summary Controls: Separate Percentages & Government Value
      provider.setLandRealizablePercentage(80.0);
      provider.setBuildingRealizablePercentage(90.0);
      provider.setLandDistressPercentage(70.0);
      provider.setBuildingDistressPercentage(75.0);
      provider.setGovernmentValue(5500000.0);

      expect(provider.valuationData!.landRealizablePercentage, 80.0);
      expect(provider.valuationData!.buildingRealizablePercentage, 90.0);
      expect(provider.valuationData!.landDistressPercentage, 70.0);
      expect(provider.valuationData!.buildingDistressPercentage, 75.0);
      expect(provider.valuationData!.governmentValue, 5500000.0);

      // Verify Realizable Values
      final expectedLandReal = provider.valuationData!.sayLandValue * 0.80;
      final expectedBldgReal = provider.valuationData!.sayBuildingValue * 0.90;
      expect(provider.valuationData!.landRealizableValue, closeTo(expectedLandReal, 1.0));
      expect(provider.valuationData!.buildingRealizableValue, closeTo(expectedBldgReal, 1.0));
      expect(provider.valuationData!.realizableValue, closeTo(expectedLandReal + expectedBldgReal, 1.0));

      // 5. Add Comparable Sale inside Dynamic Tables
      provider.addComparableItem();
      expect(provider.comparables.length, 1);
      final comp = provider.comparables[0];
      comp.location = 'Adjacent Plot Sy.No 45';
      comp.enteredArea = 1800;
      comp.rate = 1600;
      comp.saleValue = 1800 * 1600;
      provider.recalculateValuation();

      expect(provider.comparables[0].saleValue, 2880000.0);

      // 6. Ability to remove rows down to zero (blank)
      provider.removeLandItem(0);
      expect(provider.landItems, isEmpty);
      provider.removeBuildingItem(0);
      expect(provider.buildingItems, isEmpty);
      provider.removeComparableItem(0);
      expect(provider.comparables, isEmpty);
    });

    testWidgets('PHASE 1, 2, 6: DocumentTableWorkspaceWidget Renders Interactive Dynamic Tables & 4-Column Summary', (tester) async {
      final provider = DocumentWorkspaceProvider();

      final docDom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION DETAILS',
            elements: [
              StudioParagraph(
                id: 'p1',
                runs: const [StudioRun(text: '<<LAND_TABLE>>', isPlaceholder: true, placeholderKey: 'LAND_TABLE')],
              ),
              StudioParagraph(
                id: 'p2',
                runs: const [StudioRun(text: '<<BUILDING_TABLE>>', isPlaceholder: true, placeholderKey: 'BUILDING_TABLE')],
              ),
              StudioParagraph(
                id: 'p3',
                runs: const [StudioRun(text: '<<COMPARABLES_TABLE>>', isPlaceholder: true, placeholderKey: 'COMPARABLES_TABLE')],
              ),
              StudioParagraph(
                id: 'p4',
                runs: const [StudioRun(text: '<<PROPERTY_VALUE_TABLE>>', isPlaceholder: true, placeholderKey: 'PROPERTY_VALUE_TABLE')],
              ),
              StudioParagraph(
                id: 'p5',
                runs: const [StudioRun(text: '<<VALUATION_SUMMARY_TABLE>>', isPlaceholder: true, placeholderKey: 'VALUATION_SUMMARY_TABLE')],
              ),
            ],
          ),
        ],
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'LAND_TABLE', label: 'Land Table', occurrences: 1),
          PlaceholderSummaryItem(key: 'BUILDING_TABLE', label: 'Building Table', occurrences: 1),
          PlaceholderSummaryItem(key: 'COMPARABLES_TABLE', label: 'Comparables Table', occurrences: 1),
          PlaceholderSummaryItem(key: 'PROPERTY_VALUE_TABLE', label: 'Property Value Table', occurrences: 1),
          PlaceholderSummaryItem(key: 'VALUATION_SUMMARY_TABLE', label: 'Summary Table', occurrences: 1),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 777,
        reportNumber: 'VAL-2026-777',
        status: 'ASSIGNED',
        readOnly: false,
        visualPreview: VisualPreviewModel.fromJson({}),
        documentDom: docDom,
        values: {
          'LAND_TABLE': '',
          'BUILDING_TABLE': '',
          'COMPARABLES_TABLE': '',
          'PROPERTY_VALUE_TABLE': '',
          'VALUATION_SUMMARY_TABLE': '',
        },
      );

      provider.setWorkspaceModelForTest(workspaceModel);

      tester.view.physicalSize = const Size(1600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Verify Headers & Add buttons are present in Dynamic Tables
      expect(find.text('VALUE OF LAND'), findsOneWidget);
      expect(find.text('+ Add Parcel'), findsOneWidget);

      expect(find.text('VALUE OF BUILDING'), findsOneWidget);
      expect(find.text('+ Add Structure'), findsOneWidget);

      expect(find.text('COMPARABLE SALES GRID'), findsOneWidget);
      expect(find.text('+ Add Comparable'), findsOneWidget);

      expect(find.text('VALUE OF THE PROPERTY'), findsOneWidget);
      expect(find.text('SUMMARY OF VALUATION'), findsOneWidget);

      // Verify "Edit in Valuation Engine" buttons are COMPLETELY GONE from Dynamic Tables
      expect(find.text('Edit in Valuation Engine'), findsNothing);

      // Verify Summary Controls are present directly inside Dynamic Tables
      expect(find.text('VALUATION CONTROLS & OVERRIDES'), findsOneWidget);
      expect(find.text('Land Realizable %'), findsOneWidget);
      expect(find.text('Bldg Realizable %'), findsOneWidget);
      expect(find.text('Land Distress %'), findsOneWidget);
      expect(find.text('Bldg Distress %'), findsOneWidget);
      expect(find.text('Statutory Government Guideline Value (₹)'), findsOneWidget);

      // Verify 4-Column Table Header in Dynamic Tables
      expect(find.text('VALUATION PARAMETER'), findsOneWidget);
      expect(find.text('LAND (₹)'), findsOneWidget);
      expect(find.text('BUILDING (₹)'), findsOneWidget);
      expect(find.text('TOTAL (₹)'), findsOneWidget);

      // Test Adding a Parcel inside Dynamic Tables UI
      await tester.tap(find.text('+ Add Parcel'));
      await tester.pumpAndSettle();

      expect(provider.landItems.length, 1);
      expect(find.byType(TextFormField), findsWidgets);

      // Test Adding a Structure inside Dynamic Tables UI
      await tester.tap(find.text('+ Add Structure'));
      await tester.pumpAndSettle();

      expect(provider.buildingItems.length, 1);

      // Test Adding a Comparable inside Dynamic Tables UI
      await tester.ensureVisible(find.text('+ Add Comparable'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ Add Comparable'));
      await tester.pumpAndSettle();

      expect(provider.comparables.length, 1);
    });
  });
}
