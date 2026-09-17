import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/services/numeric_formula_engine.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';

void main() {
  group('Critical Numeric Formula Engine - Core Calculations & Scenarios', () {
    test('Scenario 1: N1=4700, N2=2026, <<CALC:N1*N2>> displays 9522200', () {
      final inputs = {'N1': '4700', 'N2': '2026'};
      final expr = NumericFormulaEngine.extractFormulaExpression('<<CALC:N1*N2>>');
      expect(expr, 'N1*N2');

      final result = NumericFormulaEngine.evaluate(expr, inputs);
      expect(result.isValid, isTrue);
      expect(result.formattedValue, '9522200');
      expect(result.value, 9522200.0);
    });

    test('Scenario 2: N1=10, N2=20, N3=5, <<CALC:(N1+N2)*N3>> displays 150', () {
      final inputs = {'N1': '10', 'N2': '20', 'N3': '5'};
      final expr = NumericFormulaEngine.extractFormulaExpression('<<CALC:(N1+N2)*N3>>');
      expect(expr, '(N1+N2)*N3');

      final result = NumericFormulaEngine.evaluate(expr, inputs);
      expect(result.isValid, isTrue);
      expect(result.formattedValue, '150');
      expect(result.value, 150.0);
    });

    test('Scenario 3: Live dynamic update - changing N1 from 4700 to 5000 immediately recalculates to 10130000', () {
      final inputs = {'N1': '4700', 'N2': '2026'};
      final expr = 'N1*N2';

      var result = NumericFormulaEngine.evaluate(expr, inputs);
      expect(result.formattedValue, '9522200');

      // Update N1 immediately
      inputs['N1'] = '5000';
      result = NumericFormulaEngine.evaluate(expr, inputs);
      expect(result.formattedValue, '10130000');
      expect(result.value, 10130000.0);
    });

    test('Whitespace invariance: ignores spaces in formulas', () {
      final inputs = {'N1': '10', 'N2': '20', 'N3': '5'};

      final res1 = NumericFormulaEngine.evaluate('N1*N2', inputs);
      final res2 = NumericFormulaEngine.evaluate('N1 * N2', inputs);
      final res3 = NumericFormulaEngine.evaluate('( N1 + N2 ) * N3', inputs);

      expect(res1.formattedValue, '200');
      expect(res2.formattedValue, '200');
      expect(res3.formattedValue, '150');
    });

    test('Complex expression: (N1+N2)*N3/(N4-N5)', () {
      final inputs = {
        'N1': '15',
        'N2': '25',
        'N3': '10',
        'N4': '12',
        'N5': '4',
      };
      // (15+25)*10 / (12-4) = 400 / 8 = 50
      final result = NumericFormulaEngine.evaluate('(N1+N2)*N3/(N4-N5)', inputs);
      expect(result.isValid, isTrue);
      expect(result.formattedValue, '50');
    });

    test('Unary minus support: -N1 + (-N2 * -N3)', () {
      final inputs = {'N1': '5', 'N2': '4', 'N3': '3'};
      final result = NumericFormulaEngine.evaluate('-N1 + (-N2 * -N3)', inputs);
      expect(result.isValid, isTrue);
      expect(result.formattedValue, '7');
    });
  });

  group('Critical Numeric Formula Engine - Validation & Error Reporting', () {
    test('Detects unknown variable e.g. CALC:N1+UNKNOWN_VAR', () {
      final inputs = {'N1': '10'};
      final result = NumericFormulaEngine.evaluate('N1+UNKNOWN_VAR', inputs);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains("Unknown variable: UNKNOWN_VAR"));
    });

    test('Issue 1: Default N values internally initialize to 0', () {
      final inputs = <String, String>{};
      final result = NumericFormulaEngine.evaluate('N1*N2', inputs);
      expect(result.isValid, isTrue);
      expect(result.value, 0.0);
      expect(result.allInputsUntouched, isTrue);
    });

    test('Issue 2: Zero display governance - genuine calculation to 0', () {
      final inputs = {'N1': '500', 'N2': '500'};
      final result = NumericFormulaEngine.evaluate('N1-N2', inputs);
      expect(result.isValid, isTrue);
      expect(result.value, 0.0);
      expect(result.allInputsUntouched, isFalse);
      expect(result.formattedValue, '0');
    });

    test('Decision 1: Rounding governance - Lakhs nearest 1,000, Crores nearest 10,000', () {
      // Lakhs
      expect(NumericFormulaEngine.applyRoundingGovernance('REALIZABLE_VALUE', 9522650.0), 9523000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('REALIZABLE_VALUE', 9522200.0), 9522000.0);

      // Crores
      expect(NumericFormulaEngine.applyRoundingGovernance('REALIZABLE_VALUE', 17048900.0), 17050000.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('REALIZABLE_VALUE', 17042350.0), 17040000.0);

      // Never apply to Government Value or Fair Value
      expect(NumericFormulaEngine.applyRoundingGovernance('GOVERNMENT_VALUE', 9522650.0), 9522650.0);
      expect(NumericFormulaEngine.applyRoundingGovernance('FAIR_VALUE', 9522650.0), 9522650.0);
    });

    test('Detects division by zero e.g. CALC:N1/N2 where N2=0', () {
      final inputs = {'N1': '100', 'N2': '0'};
      final result = NumericFormulaEngine.evaluate('N1/N2', inputs);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Division by zero'));
    });

    test('Detects invalid syntax expression e.g. CALC:N1+*N2', () {
      final inputs = {'N1': '10', 'N2': '20'};
      final result = NumericFormulaEngine.evaluate('N1+*N2', inputs);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, isNotEmpty);
    });

    test('Detects mismatched parentheses e.g. CALC:(N1+N2', () {
      final inputs = {'N1': '10', 'N2': '20'};
      final result = NumericFormulaEngine.evaluate('(N1+N2', inputs);
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('Mismatched parentheses'));
    });

    test('Detects circular dependencies e.g. CALC_A -> CALC_B -> CALC_A', () {
      final cycle = NumericFormulaEngine.detectCircularDependencies({
        'CALC_A': 'CALC_B + 1',
        'CALC_B': 'CALC_A * 2',
      });
      expect(cycle, isNotNull);
      expect(cycle, contains('Circular dependency detected'));
    });
  });

  group('Scenario 4 & Workspace Behavior: CALC field read-only and un-editable', () {
    test('Field classification: N1 is NUMBER, CALC:N1*N2 is CALCULATED', () {
      final n1Field = InputFieldVm(
        key: 'N1',
        questionText: 'N1',
        fieldType: 'NUMBER',
      );
      expect(n1Field.isNumericInputN, isTrue);
      expect(n1Field.isFormulaCalc, isFalse);
      expect(n1Field.isReadOnly, isFalse);

      final calcField = InputFieldVm(
        key: 'CALC:N1*N2',
        questionText: 'CALC:N1*N2',
        fieldType: 'CALCULATED',
      );
      expect(calcField.isFormulaCalc, isTrue);
      expect(calcField.isNumericInputN, isFalse);
      expect(calcField.isReadOnly, isTrue);
    });
  });
}
