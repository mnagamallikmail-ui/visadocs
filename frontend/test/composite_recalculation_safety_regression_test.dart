import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';

void main() {
  group('COMPOSITE VALUATION RECALCULATION & MULTI-PROPERTY REGRESSION TEST SUITE', () {
    test('A. Composite Property: Real-time recalculation on Area, Rate, Cost, Age, Useful Life changes', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Commercial Complex');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_BUILDING'); // Default stored in DB

      // Confirm gate detection priority: Category 'Commercial Complex' correctly yields isCompositeProperty = true
      expect(provider.isCompositeProperty, isTrue);

      // 1. Enter initial inputs
      provider.updateValue('SALEABLE_AREA', '1250');
      provider.updateValue('MARKET_RATE_FLAT', '2000');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2000');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '5');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '55');

      provider.recalculateValuation();

      // Main Unit Amount: 1250 * 2000 = 25,00,000
      expect(provider.getValue('UNIT_AMOUNT'), equals('25,00,000'));
      // Main Unit Depreciation: 1250 * 2000 * (5/55) * 0.90 = 2,04,545
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('2,04,545'));
      // Main Unit Fair Value: 25,00,000 - 2,04,545 = 22,95,455
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('22,95,455'));
      expect(provider.getValue('TOTAL_VALUATION'), equals('23,00,000'));
      expect(provider.getValue('SAY_VALUE'), equals('23,00,000'));

      // 2. Modify Area to 1500 sqft and Rate to ₹2500
      provider.updateValue('SALEABLE_AREA', '1500');
      provider.updateValue('MARKET_RATE_FLAT', '2500');
      provider.recalculateValuation();

      // New Amount: 1500 * 2500 = 37,50,000
      expect(provider.getValue('UNIT_AMOUNT'), equals('37,50,000'));
      // New Depreciation: 1500 * 2000 (cost) * (5/55) * 0.90 = 2,45,455
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('2,45,455'));
      // New Fair Value: 37,50,000 - 2,45,455 = 35,04,545
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('35,04,545'));
      expect(provider.getValue('TOTAL_VALUATION'), equals('35,00,000'));
      expect(provider.getValue('SAY_VALUE'), equals('35,00,000'));

      // 3. Modify Construction Cost to ₹2400 and Age to 10
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2400');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '10');
      provider.recalculateValuation();

      // New Depreciation: 1500 * 2400 * (10/55) * 0.90 = 5,89,091
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('5,89,091'));
      // New Fair Value: 37,50,000 - 5,89,091 = 31,60,909
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('31,60,909'));
      expect(provider.getValue('TOTAL_VALUATION'), equals('31,60,000'));
      expect(provider.getValue('SAY_VALUE'), equals('31,60,000'));
    });

    test('B. Apartment: Real-time recalculation with Apartment category and DB default methodology', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Flat / Apartment');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_BUILDING'); // Stored DB default

      expect(provider.isCompositeProperty, isTrue);

      provider.updateValue('SALEABLE_AREA', '1150');
      provider.updateValue('MARKET_RATE_FLAT', '4500');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2200');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '4');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '60');

      // Add parking slot
      final parking = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'PARKING');
      parking.quantity = 1.0;
      parking.rate = 200000.0;
      parking.amount = 200000.0;
      parking.fairValue = 200000.0;

      provider.recalculateValuation();

      // Main Unit Amount: 1150 * 4500 = 51,75,000
      expect(provider.getValue('UNIT_AMOUNT'), equals('51,75,000'));
      // Main Unit Depr: 1150 * 2200 * (4/60) * 0.90 = 1,51,800
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('1,51,800'));
      // Main Unit Fair Value: 51,75,000 - 1,51,800 = 50,23,200
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('50,23,200'));
      // Total Fair Value: 50,23,200 + 2,00,000 = 52,23,200
      expect(provider.getValue('TOTAL_FAIR_VALUE'), equals('52,23,200'));
      // Say Value (rounded to nearest 10,000): 52,20,000
      expect(provider.getValue('SAY_VALUE'), equals('52,20,000'));
    });

    test('C. Commercial Unit: Real-time recalculation for Commercial Office', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Commercial Office');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_BUILDING');

      expect(provider.isCompositeProperty, isTrue);

      provider.updateValue('SALEABLE_AREA', '2400');
      provider.updateValue('MARKET_RATE_FLAT', '8000');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2800');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '3');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '60');

      provider.recalculateValuation();

      // Main Unit Amount: 2400 * 8000 = 1,92,00,000
      expect(provider.getValue('UNIT_AMOUNT'), equals('1,92,00,000'));
      // Main Unit Depr: 2400 * 2800 * (3/60) * 0.90 = 3,02,400
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('3,02,400'));
      // Main Unit Fair Value: 1,92,00,000 - 3,02,400 = 1,88,97,600
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('1,88,97,600'));
      expect(provider.getValue('SAY_VALUE'), equals('1,89,00,000'));
    });

    test('D. Land Only: Unaffected baseline verification', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Vacant Land / Plot');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_ONLY');

      // Must be false
      expect(provider.isCompositeProperty, isFalse);

      // Add a Land Item
      provider.landItems.add(ValuationLandItemModel(
        description: 'Open Plot No. 42',
        enteredArea: 3600.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 3600.0,
        rate: 1200.0,
        value: 4320000.0,
      ));

      provider.recalculateValuation();

      // Land Only summary calculations must be untouched
      expect(provider.getValue('TOTAL_LAND_VALUE'), equals('43,20,000'));
      expect(provider.getValue('SAY_VALUE'), equals('43,20,000'));
    });

    test('E. Land & Building: Unaffected traditional 2-table baseline verification', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Land & Building');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_BUILDING');

      // Traditional Land & Building must not be detected as composite
      expect(provider.isCompositeProperty, isFalse);

      provider.landItems.add(ValuationLandItemModel(
        description: 'Plot Area',
        enteredArea: 2400.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 2400.0,
        rate: 1500.0,
        value: 3600000.0,
      ));

      provider.buildingItems.add(ValuationBuildingItemModel(
        description: 'Ground Floor RCC',
        enteredArea: 1800.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 1800.0,
        replacementRate: 2200.0,
        replacementCost: 3960000.0,
        buildingAge: 10,
        buildingUsefulLife: 60,
        depreciationAmount: 594000.0,
        buildingValue: 3366000.0,
      ));

      provider.recalculateValuation();

      expect(provider.getValue('TOTAL_LAND_VALUE'), equals('36,00,000'));
      expect(provider.getValue('TOTAL_BUILDING_VALUE'), equals('33,66,000'));
      expect(provider.getValue('TOTAL_FAIR_VALUE'), equals('69,66,000'));
      expect(provider.getValue('SAY_VALUE'), equals('69,70,000'));
    });

    test('F. Industrial Property: Unaffected PEB/Shed rules', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('PROPERTY_CATEGORY', 'Industrial Shed / Factory');
      provider.updateValue('VALUATION_METHODOLOGY', 'LAND_BUILDING');

      expect(provider.isCompositeProperty, isFalse);

      final buildingItem = ValuationBuildingItemModel(
        description: 'PEB Industrial Steel Shed',
        structureType: 'PEB Steel Shed',
        enteredArea: 5000.0,
        enteredUnit: 'Sq.Ft',
        standardAreaSqft: 5000.0,
        replacementRate: 1800.0,
        replacementCost: 9000000.0,
        buildingAge: 8,
        buildingUsefulLife: 40, // PEB default is 40 years
      );

      ValuationCalculator.calculateBuildingItem(buildingItem);

      // Salvage factor = 90% (10% salvage), ageRatio = 8/40 = 0.2
      // Depr Amount = 90,00,000 * 0.2 * 0.9 = 16,20,000
      expect(buildingItem.depreciationAmount, equals(1620000.0));
      expect(buildingItem.buildingValue, equals(7380000.0));
    });

    test('G. Whitelist Protection: Calculated keys cannot be overwritten by raw placeholder merge', () {
      expect(isCalculatedValuationKey('UNIT_AMOUNT'), isTrue);
      expect(isCalculatedValuationKey('MAIN_UNIT_DEPRECIATION'), isTrue);
      expect(isCalculatedValuationKey('MAIN_UNIT_FAIR_VALUE'), isTrue);
      expect(isCalculatedValuationKey('TOTAL_AMOUNT'), isTrue);
      expect(isCalculatedValuationKey('TOTAL_DEPRECIATION'), isTrue);
      expect(isCalculatedValuationKey('TOTAL_FAIR_VALUE'), isTrue);
      expect(isCalculatedValuationKey('SAY_VALUE'), isTrue);
    });
  });
}
