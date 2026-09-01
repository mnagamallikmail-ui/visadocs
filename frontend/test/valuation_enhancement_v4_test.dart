import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/utils/indian_number_formatter.dart';

void main() {
  group('Valuation Enhancement V4 (Final) Test Suite', () {
    test('Phase 1: Land Unit & Rate Consistency', () {
      final itemSqYd = ValuationLandItemModel(
        enteredArea: 100,
        enteredUnit: 'Sq.Yd',
        rate: 2000,
      );
      ValuationCalculator.calculateLandItem(itemSqYd);

      // Value = enteredArea * rate = 100 * 2000 = 200,000
      expect(itemSqYd.value, equals(200000.0));
      // Standard Sq.Ft = 100 * 9 = 900
      expect(itemSqYd.standardAreaSqft, equals(900.0));

      final itemAcre = ValuationLandItemModel(
        enteredArea: 2.5,
        enteredUnit: 'Acre',
        rate: 5000000,
      );
      ValuationCalculator.calculateLandItem(itemAcre);

      // Value = 2.5 * 5,000,000 = 12,500,000
      expect(itemAcre.value, equals(12500000.0));
      // Standard Sq.Ft = 2.5 * 43560 = 108,900
      expect(itemAcre.standardAreaSqft, equals(108900.0));
    });

    test('Phase 2: Default Useful Life for PEB Structures and Steel Sheds is 40 Years', () {
      final peb = ValuationBuildingItemModel(
        buildingType: 'PEB Structure',
        enteredArea: 5000,
        replacementRate: 1800,
        buildingAge: 5,
        buildingUsefulLife: 0,
      );
      ValuationCalculator.calculateBuildingItem(peb);
      expect(peb.buildingUsefulLife, equals(40));

      final shed = ValuationBuildingItemModel(
        buildingType: 'Steel Shed',
        enteredArea: 3000,
        replacementRate: 1400,
        buildingAge: 3,
        buildingUsefulLife: 60,
      );
      ValuationCalculator.calculateBuildingItem(shed);
      expect(shed.buildingUsefulLife, equals(40));

      final rcc = ValuationBuildingItemModel(
        buildingType: 'RCC Residential',
        enteredArea: 2000,
        replacementRate: 2500,
        buildingAge: 10,
        buildingUsefulLife: 60,
      );
      ValuationCalculator.calculateBuildingItem(rcc);
      expect(rcc.buildingUsefulLife, equals(60));
    });

    test('Phase 4 & 9: Say Value Driven Model - Fair Value equals Say Land + Say Building', () {
      final data = ValuationDataModel(orderId: 101);

      final land = ValuationLandItemModel(
        enteredArea: 6736.4565,
        enteredUnit: 'Sq.Ft',
        rate: 2000,
      );

      final bldg = ValuationBuildingItemModel(
        buildingType: 'RCC Commercial',
        enteredArea: 25000,
        enteredUnit: 'Sq.Ft',
        replacementRate: 2500,
        buildingAge: 5,
        buildingUsefulLife: 60,
      );

      ValuationCalculator.recalculateSummary(data, [land], [bldg]);

      // Total Land Value: 1,34,72,913 -> Say Land Value: 1,35,00,000
      expect(data.totalLandValue.roundToDouble(), equals(13472913.0));
      expect(data.sayLandValue, equals(13500000.0));

      // Total Building Value: 5,78,12,500 -> Say Building Value: 5,78,00,000
      expect(data.totalBuildingValue, equals(57812500.0));
      expect(data.sayBuildingValue, equals(57800000.0));

      // Fair Value = Say Land (1,35,00,000) + Say Building (5,78,00,000) = 7,13,00,000 (NOT raw totals 7,12,85,413)
      expect(data.fairValue, equals(71300000.0));
    });

    test('Phase 6 & 7: Separate Realizable & Distress Percentages for Land and Building', () {
      final data = ValuationDataModel(
        orderId: 102,
        landRealizablePercentage: 90.0,
        buildingRealizablePercentage: 80.0,
        landDistressPercentage: 80.0,
        buildingDistressPercentage: 70.0,
      );

      // Land: 6,750 * 2,000 = 1,35,00,000 -> Say = 1,35,00,000
      final land = ValuationLandItemModel(enteredArea: 6750, rate: 2000);
      // Building: 24,729.73 Sq.Ft * 2500, age 5 -> Say = 5,73,00,000
      final bldg = ValuationBuildingItemModel(
        buildingType: 'RCC Commercial',
        enteredArea: 24783.7838,
        replacementRate: 2500,
        buildingAge: 5,
        buildingUsefulLife: 60,
      );

      ValuationCalculator.recalculateSummary(data, [land], [bldg]);

      expect(data.sayLandValue, equals(13500000.0));
      expect(data.sayBuildingValue, equals(57300000.0));

      // Land Realizable: 1,35,00,000 * 90% = 1,21,50,000
      expect(data.landRealizableValue, equals(12150000.0));
      // Building Realizable: 5,73,00,000 * 80% = 4,58,40,000
      expect(data.buildingRealizableValue, equals(45840000.0));
      // Total Realizable: 5,79,90,000
      expect(data.realizableValue, equals(57990000.0));

      // Land Distress: 1,35,00,000 * 80% = 1,08,00,000
      expect(data.landDistressValue, equals(10800000.0));
      // Building Distress: 5,73,00,000 * 70% = 4,01,10,000
      expect(data.buildingDistressValue, equals(40110000.0));
      // Total Distress: 5,09,10,000
      expect(data.distressSaleValue, equals(50910000.0));
    });

    test('Phase 17: Indian Number Formatting validation across components', () {
      expect(IndianNumberFormatter.format(13500000.0), equals('1,35,00,000'));
      expect(IndianNumberFormatter.format(57300000.0), equals('5,73,00,000'));
      expect(IndianNumberFormatter.format(70800000.0), equals('7,08,00,000'));
      expect(IndianNumberFormatter.format(12150000.0), equals('1,21,50,000'));
      expect(IndianNumberFormatter.format(45840000.0), equals('4,58,40,000'));
      expect(IndianNumberFormatter.format(57990000.0), equals('5,79,90,000'));
    });
  });
}
