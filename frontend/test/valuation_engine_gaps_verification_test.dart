import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Valuation Module Gaps Verification Tests', () {
    test('ValuationCalculator computes Insurable Value equal to Building Replacement Cost and preserves Government Value', () {
      final data = ValuationDataModel(
        orderId: 101,
        realizablePercentage: 85.0,
        distressSalePercentage: 75.0,
        governmentValue: 7500000.0,
      );

      final landItems = [
        ValuationLandItemModel(
          description: 'Land Parcel 1',
          enteredArea: 2400,
          enteredUnit: 'Sq.Ft',
          rate: 2500, // Value = 60,00,000
        ),
      ];

      final buildingItems = [
        ValuationBuildingItemModel(
          structureType: 'Ground Floor',
          buildingType: 'RCC Residential',
          enteredArea: 1500,
          enteredUnit: 'Sq.Ft',
          replacementRate: 2000, // Replacement Cost = 30,00,000
          buildingAge: 10,
          buildingUsefulLife: 60,
          salvagePercentage: 10.0,
        ),
        ValuationBuildingItemModel(
          structureType: 'First Floor',
          buildingType: 'RCC Residential',
          enteredArea: 1000,
          enteredUnit: 'Sq.Ft',
          replacementRate: 2000, // Replacement Cost = 20,00,000
          buildingAge: 5,
          buildingUsefulLife: 60,
          salvagePercentage: 10.0,
        ),
      ];

      ValuationCalculator.recalculateSummary(data, landItems, buildingItems);

      // 1. Total Land Value = 60,00,000
      expect(data.totalLandValue, 6000000.0);

      // 2. Total Replacement Cost = 30,00,000 + 20,00,000 = 50,00,000
      expect(data.totalReplacementCost, 5000000.0);

      // 3. Insurable Value = Total Building Replacement Cost = 50,00,000 (Excludes Land)
      expect(data.insurableValue, 5000000.0);

      // 4. Fair Value = Total Land + Total Building
      expect(data.fairValue, greaterThan(6000000.0));

      // 5. Government Value remains independently preserved
      expect(data.governmentValue, 7500000.0);
    });

    test('ValuationCalculator exports insurable_value and government_value placeholders with Indian words formatting', () {
      final data = ValuationDataModel(
        orderId: 202,
        totalLandValue: 6000000,
        totalBuildingValue: 4250000,
        totalReplacementCost: 5000000,
        fairValue: 10250000,
        realizablePercentage: 85,
        realizableValue: 8712500,
        distressSalePercentage: 75,
        distressSaleValue: 7687500,
        governmentValue: 9500000,
        insurableValue: 5000000,
      );

      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': 202,
          'reportNumber': 'PV-2026-0099',
          'clientName': 'State Bank of India',
        },
        data: data,
        landItems: [],
        buildingItems: [],
        comparables: [],
      );

      // Check Insurable Value Placeholders
      expect(placeholders['insurable_value'], '50,00,000');
      expect(placeholders['insurable_value_words'], 'Rupees Fifty Lakh Only');
      expect(placeholders['INSURABLE_VALUE'], '50,00,000');
      expect(placeholders['INSURABLE_VALUE_WORDS'], 'Rupees Fifty Lakh Only');

      // Check Government Value Placeholders
      expect(placeholders['government_value'], '95,00,000');
      expect(placeholders['government_value_words'], 'Rupees Ninety Five Lakh Only');
      expect(placeholders['GOVERNMENT_VALUE'], '95,00,000');
      expect(placeholders['GOVERNMENT_VALUE_WORDS'], 'Rupees Ninety Five Lakh Only');

      // Check Fair Value & Totals
      expect(placeholders['fair_value'], '1,02,50,000');
      expect(placeholders['fair_value_words'], 'Rupees One Crore Two Lakh Fifty Thousand Only');
    });

    test('ValuationDataModel serialization roundtrip preserves insurableValue and governmentValue', () {
      final original = ValuationDataModel(
        orderId: 303,
        totalLandValue: 1000000,
        totalBuildingValue: 2000000,
        totalReplacementCost: 2500000,
        fairValue: 3000000,
        governmentValue: 2800000,
        insurableValue: 2500000,
      );

      final jsonMap = original.toJson();
      expect(jsonMap['governmentValue'], 2800000.0);
      expect(jsonMap['insurableValue'], 2500000.0);

      final reconstructed = ValuationDataModel.fromJson(jsonMap);
      expect(reconstructed.governmentValue, 2800000.0);
      expect(reconstructed.insurableValue, 2500000.0);
      expect(reconstructed.fairValue, 3000000.0);
    });
  });
}
