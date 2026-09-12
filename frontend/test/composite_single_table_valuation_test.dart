import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';

void main() {
  group('Composite Property Table - Business Logic & Single Table Acceptance Tests', () {
    test('Mandatory Acceptance Test: 1250 sqft, rate 2000, cost 2000, age 5, life 55, interior 5L / 2L', () {
      final provider = DocumentWorkspaceProvider();

      // Setup inputs
      provider.updateValue('SALEABLE_AREA', '1250');
      provider.updateValue('MARKET_RATE_FLAT', '2000');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2000');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '5');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '55');

      // Setup interior item
      // Find interior item in compositeItems
      final interior = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'INTERIOR_WORK');
      interior.amount = 500000.0;
      interior.depreciationAmount = 200000.0;
      interior.depreciationMode = 'DIRECT_AMOUNT';

      // Recalculate
      provider.recalculateValuation();

      // Verification of Main Unit
      // UNIT_AMOUNT = 1250 * 2000 = 25,00,000
      expect(provider.getValue('UNIT_AMOUNT'), equals('25,00,000'));

      // MAIN_UNIT_DEPRECIATION = 1250 * 2000 * (5/55) * 0.90 = 2,04,545.45... -> 2,04,545
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals('2,04,545'));

      // MAIN_UNIT_FAIR_VALUE = 25,00,000 - 2,04,545 = 22,95,455
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('22,95,455'));

      // INTERIOR_FAIR_VALUE = 5,00,000 - 2,00,000 = 3,00,000
      expect(provider.getValue('INTERIOR_FAIR_VALUE'), equals('3,00,000'));

      // Proof that MAIN_UNIT_FAIR_VALUE does NOT equal or read FAIR_VALUE
      // TOTAL_FAIR_VALUE = 22,95,455 + 3,00,000 = 25,95,455
      expect(provider.getValue('TOTAL_FAIR_VALUE'), equals('25,95,455'));
      expect(provider.getValue('SAY_VALUE'), equals('25,95,000'));
      expect(provider.getValue('FAIR_VALUE'), equals('25,95,000')); // FAIR_VALUE consumes SAY_VALUE
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), isNot(equals(provider.getValue('FAIR_VALUE'))));
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals('22,95,455'));
    });

    test('Proof of Interior Isolation: Changing Interior Depreciation NEVER affects Main Unit Fair Value', () {
      final provider = DocumentWorkspaceProvider();

      provider.updateValue('SALEABLE_AREA', '1250');
      provider.updateValue('MARKET_RATE_FLAT', '2000');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2000');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '5');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '55');

      final interior = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'INTERIOR_WORK');
      interior.amount = 500000.0;
      interior.depreciationAmount = 200000.0;
      provider.recalculateValuation();

      final originalMainUnitFairValue = provider.getValue('MAIN_UNIT_FAIR_VALUE');
      final originalUnitAmount = provider.getValue('UNIT_AMOUNT');
      final originalMainUnitDepr = provider.getValue('MAIN_UNIT_DEPRECIATION');

      expect(originalMainUnitFairValue, equals('22,95,455'));
      expect(originalUnitAmount, equals('25,00,000'));
      expect(originalMainUnitDepr, equals('2,04,545'));

      // Change interior depreciation to ₹4,50,000 (huge change)
      interior.depreciationAmount = 450000.0;
      provider.recalculateValuation();

      // Interior fair value changes to 50,000
      expect(provider.getValue('INTERIOR_FAIR_VALUE'), equals('50,000'));

      // Main Unit values remain COMPLETELY UNCHANGED
      expect(provider.getValue('MAIN_UNIT_FAIR_VALUE'), equals(originalMainUnitFairValue));
      expect(provider.getValue('UNIT_AMOUNT'), equals(originalUnitAmount));
      expect(provider.getValue('MAIN_UNIT_DEPRECIATION'), equals(originalMainUnitDepr));
    });

    test('Row 3 Parking integration in the SAME table', () {
      final provider = DocumentWorkspaceProvider();

      provider.updateValue('SALEABLE_AREA', '1250');
      provider.updateValue('MARKET_RATE_FLAT', '2000');
      provider.updateValue('COMPOSITE_CONSTRUCTION_COST', '2000');
      provider.updateValue('COMPOSITE_BUILDING_AGE', '5');
      provider.updateValue('COMPOSITE_BUILDING_TOTAL_LIFE', '55');

      final interior = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'INTERIOR_WORK');
      interior.amount = 500000.0;
      interior.depreciationAmount = 200000.0;

      // Locate or add Parking item
      final parking = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'PARKING');
      parking.quantity = 2.0;
      parking.enteredUnit = 'Slot';
      parking.rate = 250000.0;
      parking.amount = 500000.0;
      parking.depreciationAmount = 0.0;

      provider.recalculateValuation();

      // Parking Fair Value = 5,00,000 - 0 = 5,00,000
      expect(provider.getValue('PARKING_AMOUNT'), equals('5,00,000'));
      expect(provider.getValue('PARKING_FAIR_VALUE'), equals('5,00,000'));

      // Total Amount = 25,00,000 (Main) + 5,00,000 (Interior) + 5,00,000 (Parking) = 35,00,000
      expect(provider.getValue('TOTAL_AMOUNT'), equals('35,00,000'));

      // Total Depreciation = 2,04,545 (Main) + 2,00,000 (Interior) + 0 (Parking) = 4,04,545
      expect(provider.getValue('TOTAL_DEPRECIATION'), equals('4,04,545'));

      // Total Fair Value = 22,95,455 + 3,00,000 + 5,00,000 = 30,95,455
      expect(provider.getValue('TOTAL_FAIR_VALUE'), equals('30,95,455'));

      // SAY_VALUE for 30,95,455 rounded to nearest 1000 = 30,95,000
      expect(provider.getValue('SAY_VALUE'), equals('30,95,000'));
    });

    test('Proof that compositeItems.first fallback is eliminated', () {
      final data = ValuationDataModel(orderId: 101, valuationMethodology: 'COMPOSITE');
      // Create list where Interior Work is index 0
      final items = [
        ValuationCompositeItemModel(
          itemCategory: 'INTERIOR_WORK',
          description: 'Woodwork',
          amount: 500000.0,
          depreciationAmount: 200000.0,
          fairValue: 300000.0,
        ),
      ];

      ValuationCalculator.recalculateCompositeSummary(data, items);
      final map = ValuationCalculator.generatePlaceholders(
        orderInfo: {'id': 101},
        data: data,
        landItems: [],
        buildingItems: [],
        comparables: [],
        compositeItems: items,
      );

      // Even when Interior Work is index 0, recalculateCompositeSummary auto-creates MAIN_UNIT
      // and generatePlaceholders explicitly binds UNIT_AMOUNT to MAIN_UNIT, not Interior Work!
      expect(map['unit_amount'], isNot(equals('5,00,000')));
      expect(map['interior_amount'], equals('5,00,000'));
      expect(map['interior_fair_value'], equals('3,00,000'));
    });
  });
}
