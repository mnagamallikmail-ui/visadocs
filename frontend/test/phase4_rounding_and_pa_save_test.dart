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
  });
}
