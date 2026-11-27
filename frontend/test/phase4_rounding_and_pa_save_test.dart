import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/numeric_formula_engine.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Phase 4 Rounding Governance (< 1Cr -> 1,000; >= 1Cr -> 10,000)', () {
    test('All 6 benchmark rounding examples match specification', () {
      expect(ValuationCalculator.roundValuationOutput(1234567), 1235000.0);
      expect(ValuationCalculator.roundValuationOutput(8749251), 8749000.0);
      expect(ValuationCalculator.roundValuationOutput(8749751), 8750000.0);

      expect(ValuationCalculator.roundValuationOutput(16749500), 16750000.0);
      expect(ValuationCalculator.roundValuationOutput(23423100), 23420000.0);
      expect(ValuationCalculator.roundValuationOutput(54396501), 54400000.0);
    });

    test('Composite summary rounds Fair, Realizable, Distress, Insurable; leaves Government untouched', () {
      final data = ValuationDataModel(
        orderId: 101,
        valuationMethodology: 'COMPOSITE',
        compositeGovernmentRate: 3333.0,
      );
      final unit = ValuationCompositeItemModel(
        orderId: 101,
        itemCategory: 'MAIN_UNIT',
        description: 'Flat 302',
        enteredUnit: 'Sq.Ft',
        quantity: 1234.0,
        rate: 6543.0, // 80,74,062 -> 80,74,000
        constructionCost: 2123.0, // 26,19,782 -> 26,20,000
        buildingAge: 0.0,
        totalLife: 60.0,
      );

      ValuationCalculator.recalculateCompositeSummary(data, [unit]);

      expect(data.sayFairValue, 8074000.0);
      expect(data.fairValue, 8074000.0);
      expect(data.realizableValue, 6863000.0);
      expect(data.distressSaleValue, 6056000.0);
      expect(data.insurableValue, 2620000.0);
      expect(data.governmentValue, 4112922.0); // Untouched!
    });

    test('NumericFormulaEngine.applyRoundingGovernance matches for all 4 fields and skips Government', () {
      expect(NumericFormulaEngine.applyRoundingGovernance('FAIR_VALUE', 8749251), 8749000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('SAY_VALUE', 16749500), 16750000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('REALIZABLE_VALUE', 6862900), 6863000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('DISTRESS_SALE_VALUE', 6055500), 6056000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('INSURABLE_VALUE', 2619782), 2620000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('GOVERNMENT_VALUE', 4112922), 4112922.0);
    });

    test('Land & Building: No double rounding when crossing 1 Crore threshold', () {
      final data = ValuationDataModel(
        orderId: 102,
        valuationMethodology: 'LAND_AND_BUILDING',
        landRealizablePercentage: 75.0,
        buildingRealizablePercentage: 75.0,
        landDistressPercentage: 75.0,
        buildingDistressPercentage: 75.0,
      );
      final land = ValuationLandItemModel(
        orderId: 102,
        enteredArea: 6669.0,
        enteredUnit: 'Sq.Ft',
        rate: 1000.0, // 66,69,000 -> 75% = 50,01,750
      );
      final bldg = ValuationBuildingItemModel(
        orderId: 102,
        enteredArea: 6670.0,
        enteredUnit: 'Sq.Ft',
        replacementRate: 1000.0,
        buildingAge: 0.0,
        buildingUsefulLife: 60, // 66,70,000 -> 75% = 50,02,500
      );

      ValuationCalculator.recalculateSummary(data, [land], [bldg]);

      expect(data.landRealizableValue, 5001750.0);
      expect(data.buildingRealizableValue, 5002500.0);
      // Sum of raw = 1,00,04,250 -> rounded ONCE = 1,00,00,000 (not double-rounded to 1,00,10,000)
      final expected = ValuationCalculator.roundValuationOutput(data.landRealizableValue + data.buildingRealizableValue);
      expect(expected, 10000000.0);
      expect(data.realizableValue, expected);
      expect(data.distressSaleValue, expected);
    });
  });
}

