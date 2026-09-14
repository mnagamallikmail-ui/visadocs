import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/value_normalization_engine.dart';

void main() {
  group('Phase 4B Reactive Dependency Cascade & Human-Friendly Input Tests', () {
    late DocumentWorkspaceProvider provider;

    setUp(() {
      provider = DocumentWorkspaceProvider();
      final model = DocumentWorkspaceModel(
        orderId: 101,
        reportNumber: 'ORD-101',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat',
          'SALEABLE_AREA': '1000',
          'MARKET_RATE_FLAT': '5000',
        },
      );
      provider.setWorkspaceModelForTest(model);
    });

    test('Entering "1000 sq.ft" and "Rs 5000" normalizes to numeric for valuation while preserving raw text', () {
      provider.updateValue('SALEABLE_AREA', '1000 sq.ft');
      provider.updateValue('MARKET_RATE_FLAT', 'Rs 5000');

      // 1. Normalized values in base keys and raw values in _RAW
      expect(provider.getValue('SALEABLE_AREA'), equals('1000'));
      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('1000 sq.ft'));
      expect(provider.getValue('MARKET_RATE_FLAT'), equals('5000'));
      expect(provider.getValue('MARKET_RATE_FLAT_RAW'), equals('Rs 5000'));

      // 2. Numeric and unit values are cleanly derived
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1000'));
      expect(provider.getValue('SALEABLE_AREA_UNIT'), equals('SQFT'));
      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('1000'));
      expect(provider.getValue('MARKET_RATE_FLAT_NUMERIC'), equals('5000'));

      // 3. Alias propagation
      expect(provider.getValue('SUPER_BUILT_UP_AREA'), equals('1000'));
      expect(provider.getValue('SUPER_BUILT_UP_AREA_RAW'), equals('1000 sq.ft'));
      expect(provider.getValue('SUPER_BUILT_UP_AREA_NUMERIC'), equals('1000'));
      expect(provider.getValue('SUPER_BUILT_UP_AREA_STANDARD_SQFT'), equals('1000'));
      expect(provider.getValue('COMPOSITE_RATE'), equals('5000'));
      expect(provider.getValue('COMPOSITE_RATE_RAW'), equals('Rs 5000'));
      expect(provider.getValue('COMPOSITE_RATE_NUMERIC'), equals('5000'));

      // 4. Valuation calculations are exact
      // 1000 * 5000 = 50,00,000 (Unit Amount)
      expect(provider.getValue('unit_amount'), equals('50,00,000'));
      expect(provider.getValue('fair_value'), isNotEmpty);
      expect(provider.validationError, isNull);
    });

    test('Entering "2.375 Acres" authoritatively uses STANDARD_AREA_SQFT for calculation', () {
      provider.updateValue('SALEABLE_AREA', '2.375 Acres');
      provider.updateValue('MARKET_RATE_FLAT', 'Rs 5000');

      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('2.375 Acres'));
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('2.375'));
      expect(provider.getValue('SALEABLE_AREA_UNIT'), equals('ACRES'));
      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('103455'));

      // 103455 * 5000 = 51,72,75,000 (Unit Amount)
      expect(provider.getValue('unit_amount'), contains('51,72,75,000'));
      expect(provider.validationError, isNull);
    });

    test('3-Decimal Precision Governance in reactive calculations', () {
      provider.updateValue('SALEABLE_AREA', '1000.125 sq.ft');
      provider.updateValue('MARKET_RATE_FLAT', 'Rs 5000.250');

      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('1000.125 sq.ft'));
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1000.125'));
      expect(provider.getValue('MARKET_RATE_FLAT_RAW'), equals('Rs 5000.250'));
      expect(provider.getValue('MARKET_RATE_FLAT_NUMERIC'), equals('5000.25'));

      // 1000.125 * 5000.250 = 5000875.03125 formatted with Indian grouping
      expect(provider.getValue('unit_amount'), contains('50,00,875'));
      expect(provider.validationError, isNull);
    });

    test('Invalid input "abc" sets validation error, does NOT overwrite valid data, does NOT recalculate to zero', () {
      provider.updateValue('SALEABLE_AREA', '1000 sq.ft');
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1000'));

      // Attempt invalid input
      provider.updateValue('SALEABLE_AREA', 'abc');

      expect(provider.validationError, equals(ValueNormalizationEngine.validationErrorMsg));
      // Preserves existing valid numeric value
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1000'));
      expect(provider.getValue('SALEABLE_AREA'), equals('1000'));
      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('1000 sq.ft'));
    });

    test('Invalid rate "Rs only" sets validation error and halts overwrite', () {
      provider.updateValue('MARKET_RATE_FLAT', 'Rs 5000');
      expect(provider.getValue('MARKET_RATE_FLAT_NUMERIC'), equals('5000'));

      provider.updateValue('MARKET_RATE_FLAT', 'Rs only');
      expect(provider.validationError, equals(ValueNormalizationEngine.validationErrorMsg));
      expect(provider.getValue('MARKET_RATE_FLAT_NUMERIC'), equals('5000'));
    });
  });
}
