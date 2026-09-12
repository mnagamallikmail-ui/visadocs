import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Say Value & Final Report Value Governance Verification', () {
    test('ValuationCalculator.computeSayValue verifies authoritative nearest 10,000 rounding', () {
      // Lakh Examples from user governance specification:
      // ₹81,22,000 -> ₹81,20,000
      expect(ValuationCalculator.computeSayValue(8122000.0), equals(8120000.0));
      // ₹73,47,000 -> ₹73,50,000
      expect(ValuationCalculator.computeSayValue(7347000.0), equals(7350000.0));
      // ₹56,61,000 -> ₹56,60,000
      expect(ValuationCalculator.computeSayValue(5661000.0), equals(5660000.0));

      // Crore Examples from user governance specification:
      // ₹1,47,86,000 -> ₹1,47,90,000
      expect(ValuationCalculator.computeSayValue(14786000.0), equals(14790000.0));
      // ₹2,83,42,000 -> ₹2,83,40,000
      expect(ValuationCalculator.computeSayValue(28342000.0), equals(28340000.0));
    });

    test('Runtime Scenario: TOTAL_FAIR_VALUE = 81,22,000 -> SAY_VALUE & all report aliases = 81,20,000', () {
      final data = ValuationDataModel(
        orderId: 999,
        valuationMethodology: 'COMPOSITE',
        compositeBuildingAge: 5,
        compositeBuildingTotalLife: 60,
        compositeConstructionCost: 2500,
      );

      final items = [
        // Main Unit: 75,22,000
        ValuationCompositeItemModel(
          orderId: 999,
          itemCategory: 'MAIN_UNIT',
          description: 'Main Unit',
          enteredUnit: 'Sq.Ft',
          quantity: 1000,
          rate: 7522,
          amount: 7522000,
          depreciationAmount: 0,
          fairValue: 7522000,
          sortOrder: 0,
        ),
        // Interior Woodwork: 3,00,000
        ValuationCompositeItemModel(
          orderId: 999,
          itemCategory: 'INTERIOR_WORK',
          description: 'Interior Woodwork',
          enteredUnit: 'LS',
          quantity: 1,
          rate: 300000,
          amount: 300000,
          depreciationAmount: 0,
          fairValue: 300000,
          sortOrder: 1,
        ),
        // Car Parking: 3,00,000
        ValuationCompositeItemModel(
          orderId: 999,
          itemCategory: 'PARKING',
          description: 'Car Parking',
          enteredUnit: 'Slot',
          quantity: 1,
          rate: 300000,
          amount: 300000,
          depreciationAmount: 0,
          fairValue: 300000,
          sortOrder: 2,
        ),
      ];

      ValuationCalculator.recalculateCompositeSummary(data, items);

      // Level 1: TOTAL_FAIR_VALUE must preserve exact mathematical valuation (no rounding)
      expect(data.totalFairValue, equals(8122000.0));
      expect(data.rawFairValue, equals(8122000.0));

      // Level 2: SAY_VALUE = computeSayValue(81,22,000) = 81,20,000
      expect(data.sayFairValue, equals(8120000.0));

      // Report display: FAIR_VALUE = SAY_VALUE
      expect(data.fairValue, equals(8120000.0));

      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': 999,
          'clientName': 'Client X',
          'propertyCategory': 'Commercial',
        },
        data: data,
        landItems: const [],
        buildingItems: const [],
        comparables: const [],
        compositeItems: items,
      );

      // LEVEL 1: TOTAL_FAIR_VALUE
      expect(placeholders['TOTAL_FAIR_VALUE'], equals('81,22,000'));
      expect(placeholders['TOTAL_FAIR_VALUE_WORDS'], equals('Rupees Eighty One Lakh Twenty Two Thousand Only'));

      // LEVEL 2 & REPORT-FACING ALIASES: Must all be 81,20,000
      expect(placeholders['SAY_VALUE'], equals('81,20,000'));
      expect(placeholders['SAY_FAIR_VALUE'], equals('81,20,000'));
      expect(placeholders['REPORT_FAIR_VALUE'], equals('81,20,000'));
      expect(placeholders['FAIR_VALUE'], equals('81,20,000'));
      expect(placeholders['MARKET_VALUE'], equals('81,20,000'));
      expect(placeholders['PROPERTY_VALUE'], equals('81,20,000'));
      expect(placeholders['FINAL_VALUE'], equals('81,20,000'));
      expect(placeholders['VALUATION_AMOUNT'], equals('81,20,000'));
      expect(placeholders['OPINION_OF_VALUE'], equals('81,20,000'));
      expect(placeholders['RECOMMENDED_VALUE'], equals('81,20,000'));

      // WORDS GOVERNANCE: Must all be generated from SAY_VALUE (81,20,000)
      const expectedWords = 'Rupees Eighty One Lakh Twenty Thousand Only';
      expect(placeholders['SAY_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['FAIR_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['MARKET_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['PROPERTY_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['FINAL_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['VALUATION_AMOUNT_WORDS'], equals(expectedWords));
      expect(placeholders['OPINION_OF_VALUE_WORDS'], equals(expectedWords));
      expect(placeholders['RECOMMENDED_VALUE_WORDS'], equals(expectedWords));
    });

    test('DocumentWorkspaceProvider protects calculated valuation keys from SAY_VALUE_RAW collision', () {
      final provider = DocumentWorkspaceProvider();

      provider.updateValue('PROPERTY_CATEGORY', 'Commercial Property');
      provider.updateValue('SALEABLE_AREA', '1000');
      provider.updateValue('MARKET_RATE_FLAT', '7522');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2500');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '0');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '60');

      // Inject a stale raw key that previously caused the defect:
      provider.updateValue('SAY_VALUE_RAW', '3,00,000');
      provider.updateValue('FAIR_VALUE_RAW', '3,00,000');

      // Setup Interior Work (3,00,000) and Parking (3,00,000)
      // Main unit is 1000 * 7522 = 75,22,000
      // Interior = 3,00,000
      // Parking = 3,00,000
      // Total = 81,22,000
      // Say = 81,20,000
      final interior = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'INTERIOR_WORK');
      interior.rate = 300000.0;
      interior.amount = 300000.0;
      interior.depreciationAmount = 0.0;
      interior.depreciationMode = 'DIRECT_AMOUNT';

      final parking = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'PARKING');
      parking.rate = 300000.0;
      parking.amount = 300000.0;
      parking.depreciationAmount = 0.0;

      provider.recalculateValuation();

      // Verify Level 1
      expect(provider.getValue('TOTAL_FAIR_VALUE'), equals('81,22,000'));

      // Verify Level 2: SAY_VALUE is NOT 3,00,000! It must be 81,20,000
      expect(provider.getValue('SAY_VALUE'), equals('81,20,000'));
      expect(provider.getValue('FAIR_VALUE'), equals('81,20,000'));
      expect(provider.getValue('REPORT_FAIR_VALUE'), equals('81,20,000'));
      expect(provider.getValue('MARKET_VALUE'), equals('81,20,000'));
      expect(provider.getValue('PROPERTY_VALUE'), equals('81,20,000'));
      expect(provider.getValue('FINAL_VALUE'), equals('81,20,000'));
      expect(provider.getValue('VALUATION_AMOUNT'), equals('81,20,000'));
      expect(provider.getValue('OPINION_OF_VALUE'), equals('81,20,000'));
      expect(provider.getValue('RECOMMENDED_VALUE'), equals('81,20,000'));

      // Words must match 81,20,000
      expect(provider.getValue('SAY_VALUE_WORDS'), equals('Rupees Eighty One Lakh Twenty Thousand Only'));
      expect(provider.getValue('FAIR_VALUE_WORDS'), equals('Rupees Eighty One Lakh Twenty Thousand Only'));
    });
  });
}
