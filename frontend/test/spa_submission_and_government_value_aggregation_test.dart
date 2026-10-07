import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Final Valuation Submission & Government Value Aggregation Certification Tests', () {
    test('TEST 1 & TEST 5: Land Valuation SPA Submission & Final Valuation Amount Synchronization', () {
      final valData = ValuationDataModel(
        orderId: 101,
        valuationMethodology: 'LAND_AND_BUILDING',
        governmentRate: 73000.0,
      );

      final landItem = ValuationLandItemModel(
        orderId: 101,
        description: 'Plot A',
        enteredArea: 542.0,
        enteredUnit: 'Sq.Yards',
        standardAreaSqft: 4878.0,
        rate: 200000.0,
        value: 108400000.0,
      );

      final landItems = [landItem];
      final buildingItems = <ValuationBuildingItemModel>[];

      ValuationCalculator.recalculateSummary(valData, landItems, buildingItems);

      // Verify Fair Market Value
      expect(valData.totalLandValue, equals(108400000.0));
      expect(valData.sayLandValue, equals(108400000.0));
      expect(valData.fairValue, equals(108400000.0));

      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': 101, 'propertyCategory': 'Land'},
        data: valData,
        landItems: landItems,
        buildingItems: buildingItems,
        comparables: [],
      );

      // Verify all SPA validation aliases are synchronized to Fair Market Value
      expect(placeholders['fair_value'], equals('10,84,00,000'));
      expect(placeholders['final_valuation_amount'], equals('10,84,00,000'));
      expect(placeholders['FINAL_VALUATION_AMOUNT'], equals('10,84,00,000'));
      expect(placeholders['total_valuation'], equals('10,84,00,000'));
      expect(placeholders['TOTAL_VALUATION'], equals('10,84,00,000'));
      expect(placeholders['fair_market_value'], equals('10,84,00,000'));
      expect(placeholders['FAIR_MARKET_VALUE'], equals('10,84,00,000'));
      expect(placeholders['final_value'], equals('10,84,00,000'));
      expect(placeholders['market_value'], equals('10,84,00,000'));
    });

    test('TEST 2: Government Value Summary - Land + Building = Total Always', () {
      final valData = ValuationDataModel(
        orderId: 102,
        valuationMethodology: 'LAND_AND_BUILDING',
        governmentRate: 73000.0,
      );

      final landItem = ValuationLandItemModel(
        orderId: 102,
        description: 'Commercial Plot',
        enteredArea: 542.0,
        enteredUnit: 'Sq.Yards',
        standardAreaSqft: 4878.0,
        rate: 200000.0,
        value: 108400000.0,
      );

      final landItems = [landItem];
      final buildingItems = <ValuationBuildingItemModel>[];

      ValuationCalculator.recalculateSummary(valData, landItems, buildingItems);

      // 542 * 73,000 = 3,95,66,000
      expect(valData.landGovernmentValue, equals(39566000.0));
      expect(valData.buildingGovernmentValue, equals(0.0));
      expect(valData.governmentValue, equals(39566000.0));
      expect(valData.governmentValue, equals(valData.landGovernmentValue + valData.buildingGovernmentValue));

      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': 102, 'propertyCategory': 'Land'},
        data: valData,
        landItems: landItems,
        buildingItems: buildingItems,
        comparables: [],
      );

      expect(placeholders['land_government_value'], equals('3,95,66,000'));
      expect(placeholders['building_government_value'], equals('0'));
      expect(placeholders['government_value'], equals('3,95,66,000'));
      expect(placeholders['total_government_value'], equals('3,95,66,000'));
      expect(placeholders['government_rate'], equals('73,000'));
      expect(placeholders['guideline_rate'], equals('73,000'));
    });

    test('TEST 2 (Fallback Statutory Rate): Government Value when governmentRate is 0', () {
      final valData = ValuationDataModel(
        orderId: 103,
        valuationMethodology: 'LAND_AND_BUILDING',
        governmentRate: 0.0,
      );

      final landItem = ValuationLandItemModel(
        orderId: 103,
        description: 'Standard Plot',
        enteredArea: 542.0,
        enteredUnit: 'Sq.Yards',
        standardAreaSqft: 4878.0,
        rate: 200000.0,
        value: 108400000.0,
      );

      final landItems = [landItem];
      final buildingItems = <ValuationBuildingItemModel>[];

      ValuationCalculator.recalculateSummary(valData, landItems, buildingItems);

      // 4878 standard sqft * 5,500 = 2,68,29,000
      expect(valData.landGovernmentValue, equals(26829000.0));
      expect(valData.buildingGovernmentValue, equals(0.0));
      expect(valData.governmentValue, equals(26829000.0));
      expect(valData.governmentValue, equals(valData.landGovernmentValue + valData.buildingGovernmentValue));
    });

    test('TEST 3: Building Report Government Summary & Insurable Value', () {
      final valData = ValuationDataModel(
        orderId: 104,
        valuationMethodology: 'LAND_AND_BUILDING',
        governmentRate: 5000.0,
      );

      final landItem = ValuationLandItemModel(
        orderId: 104,
        description: 'Plot',
        enteredArea: 1000.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 1000.0,
        rate: 10000.0,
        value: 10000000.0,
      );

      final bldgItem = ValuationBuildingItemModel(
        orderId: 104,
        buildingType: 'RCC Structure',
        structureType: 'G+1',
        enteredArea: 1000.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 1000.0,
        replacementRate: 2500.0,
        replacementCost: 2500000.0,
        buildingAge: 5.0,
        buildingUsefulLife: 60,
        depreciationPercentage: 7.5,
        depreciationAmount: 187500.0,
        buildingValue: 2312500.0,
      );

      ValuationCalculator.recalculateSummary(valData, [landItem], [bldgItem]);

      // Land govt: 1000 * 5000 = 50,00,000
      // Bldg govt: 1000 * 2400 (RCC) = 24,00,000
      // Total govt: 74,00,000
      expect(valData.landGovernmentValue, equals(5000000.0));
      expect(valData.buildingGovernmentValue, equals(2400000.0));
      expect(valData.governmentValue, equals(7400000.0));
      expect(valData.governmentValue, equals(valData.landGovernmentValue + valData.buildingGovernmentValue));
      expect(valData.insurableValue, equals(2500000.0));
    });

    test('TEST 4: Composite Report Government Summary', () {
      final valData = ValuationDataModel(
        orderId: 105,
        valuationMethodology: 'COMPOSITE',
        compositeGovernmentRate: 3500.0,
      );

      final mainUnit = ValuationCompositeItemModel(
        orderId: 105,
        itemCategory: 'MAIN_UNIT',
        enteredUnit: 'Sq.Ft',
        quantity: 1200.0,
        rate: 6000.0,
        amount: 7200000.0,
        fairValue: 7200000.0,
      );

      ValuationCalculator.recalculateCompositeSummary(valData, [mainUnit]);

      // Govt value = 1200 * 3500 = 42,00,000
      expect(valData.governmentValue, equals(4200000.0));

      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': 105, 'propertyCategory': 'Apartment'},
        data: valData,
        landItems: [],
        buildingItems: [],
        compositeItems: [mainUnit],
        comparables: [],
      );

      expect(placeholders['government_value'], equals('42,00,000'));
      expect(placeholders['total_government_value'], equals('42,00,000'));
      expect(placeholders['composite_government_rate'], equals('3,500'));
      expect(placeholders['final_valuation_amount'], equals(placeholders['fair_value']));
    });
  });
}
