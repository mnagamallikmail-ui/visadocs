import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/services/alias_resolution_engine.dart';
import 'package:provaluer_frontend/features/document_workspace/services/value_normalization_engine.dart';

void main() {
  group('Value Normalization Engine (Dart)', () {
    test('Unit-Aware Area Normalization correctly derives raw, numeric, detected unit, and standard sqft', () {
      // 2.375 Acres
      final acreVal = ValueNormalizationEngine.normalizeAreaValue('2.375 Acres');
      expect(acreVal.rawValue, equals('2.375 Acres'));
      expect(acreVal.numericValue, equals(2.375));
      expect(acreVal.detectedUnit, equals('ACRES'));
      expect(acreVal.standardSqftValue, equals(103455.0));

      // 250 Sq.Yd
      final sqydVal = ValueNormalizationEngine.normalizeAreaValue('250 Sq.Yd');
      expect(sqydVal.rawValue, equals('250 Sq.Yd'));
      expect(sqydVal.numericValue, equals(250.0));
      expect(sqydVal.detectedUnit, equals('SQYD'));
      expect(sqydVal.standardSqftValue, equals(2250.0));

      // 100 Sq.M
      final sqmVal = ValueNormalizationEngine.normalizeAreaValue('100 Sq.M');
      expect(sqmVal.rawValue, equals('100 Sq.M'));
      expect(sqmVal.numericValue, equals(100.0));
      expect(sqmVal.detectedUnit, equals('SQM'));
      expect(sqmVal.standardSqftValue, equals(1076.391));

      // 40 Cents
      final centsVal = ValueNormalizationEngine.normalizeAreaValue('40 Cents');
      expect(centsVal.rawValue, equals('40 Cents'));
      expect(centsVal.numericValue, equals(40.0));
      expect(centsVal.detectedUnit, equals('CENTS'));
      expect(centsVal.standardSqftValue, equals(17424.0));

      // 5 Grounds
      final groundsVal = ValueNormalizationEngine.normalizeAreaValue('5 Grounds');
      expect(groundsVal.rawValue, equals('5 Grounds'));
      expect(groundsVal.numericValue, equals(5.0));
      expect(groundsVal.detectedUnit, equals('GROUNDS'));
      expect(groundsVal.standardSqftValue, equals(12000.0));

      // 1000.125 Sq.Ft
      final sqftVal = ValueNormalizationEngine.normalizeAreaValue('1000.125 Sq.Ft');
      expect(sqftVal.rawValue, equals('1000.125 Sq.Ft'));
      expect(sqftVal.numericValue, equals(1000.125));
      expect(sqftVal.detectedUnit, equals('SQFT'));
      expect(sqftVal.standardSqftValue, equals(1000.125));
    });

    test('Area Normalization extracts exact numeric values up to 3 decimal places', () {
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000 sq.ft'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000.125 sq.ft'), equals(1000.125));
      expect(ValueNormalizationEngine.normalize('SUPER_BUILT_UP_AREA', '1000 sqft'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('PROPERTY_AREA_SFT', '1000 SFT'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('SBUA', '1000 Square Feet'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('FLAT_AREA', 'Approx 1000 Sq.Ft'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', 'Approx. 1000 Sq.Ft'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', 'Area = 1000 Sq Ft'), equals(1000.0));
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', '1,250.50 sq.ft'), equals(1250.5));
      expect(ValueNormalizationEngine.normalize('LAND_AREA', '2.5 Acres'), equals(2.5));
      expect(ValueNormalizationEngine.normalize('LAND_AREA', '2.375 Acres'), equals(2.375));
      expect(ValueNormalizationEngine.normalize('PLOT_AREA', '5.0 Grounds'), equals(5.0));
      expect(ValueNormalizationEngine.normalize('PLOT_AREA', '5.125 Grounds'), equals(5.125));
    });

    test('Rate Normalization extracts exact numeric rates', () {
      expect(ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs 5000'), equals(5000.0));
      expect(ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs. 5000'), equals(5000.0));
      expect(ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs 5000.125'), equals(5000.125));
      expect(ValueNormalizationEngine.normalize('COMPOSITE_RATE', 'INR 6000'), equals(6000.0));
      expect(ValueNormalizationEngine.normalize('CURRENT_MARKET_RATE', '₹5000'), equals(5000.0));
      expect(ValueNormalizationEngine.normalize('FLAT_MARKET_RATE', '₹ 7,500'), equals(7500.0));
      expect(ValueNormalizationEngine.normalize('BUILDING_MARKET_RATE', '₹ 7,500 per sq.ft'), equals(7500.0));
      expect(ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', '₹ 7500.750 per sq.ft'), equals(7500.75));
      expect(ValueNormalizationEngine.normalize('LAND_RATE', 'Rs. 8,500/SFT'), equals(8500.0));
      expect(ValueNormalizationEngine.normalize('GOVERNMENT_RATE', '5000/-'), equals(5000.0));
    });

    test('Percentage Normalization handles percentages, decimals, and negative values', () {
      expect(ValueNormalizationEngine.normalize('REALIZABLE_PERCENTAGE', '85%'), equals(85.0));
      expect(ValueNormalizationEngine.normalize('REALIZABLE_PERCENTAGE', '90 %'), equals(90.0));
      expect(ValueNormalizationEngine.normalize('DISTRESS_SALE_PERCENTAGE', '12.5%'), equals(12.5));
      expect(ValueNormalizationEngine.normalize('DISTRESS_SALE_PERCENTAGE', '12.875%'), equals(12.875));
      expect(ValueNormalizationEngine.normalize('COMPOSITE_BUILDING_DEPRECIATION_PCT', '-10%'), equals(-10.0));
    });

    test('Decimal Precision Governance preserves up to 3 decimals and rounds > 3 with HALF_UP', () {
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000.1234 sq.ft'), equals(1000.123));
      expect(ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000.56789 sq.ft'), equals(1000.568));
      expect(ValueNormalizationEngine.normalize('LAND_AREA', '2.9999 Acres'), equals(3.0));
    });

    test('Validation Rejections: Non-numeric inputs reject with expected error message', () {
      expect(
        () => ValueNormalizationEngine.normalize('SALEABLE_AREA', 'abc'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', ValueNormalizationEngine.validationErrorMsg)),
      );
      expect(
        () => ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs only'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', ValueNormalizationEngine.validationErrorMsg)),
      );
      expect(
        () => ValueNormalizationEngine.normalize('SUPER_BUILT_UP_AREA', 'sq.ft only'),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', ValueNormalizationEngine.validationErrorMsg)),
      );
      expect(
        () => ValueNormalizationEngine.normalize('REALIZABLE_PERCENTAGE', ''),
        throwsA(isA<FormatException>().having((e) => e.message, 'message', ValueNormalizationEngine.validationErrorMsg)),
      );
    });

    test('Calculation Accuracy: Arithmetic preserves 100% calculation accuracy', () {
      final area1 = ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000 sq.ft');
      final rate1 = ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs 5000');
      expect(area1 * rate1, equals(5000000.0));

      final area2 = ValueNormalizationEngine.normalize('SUPER_BUILT_UP_AREA', '1200 sqft');
      final rate2 = ValueNormalizationEngine.normalize('COMPOSITE_RATE', 'INR 6000');
      expect(area2 * rate2, equals(7200000.0));

      final area3 = ValueNormalizationEngine.normalize('SALEABLE_AREA', '1000.125 sq.ft');
      final rate3 = ValueNormalizationEngine.normalize('MARKET_RATE_FLAT', 'Rs 5000.250');
      expect(area3 * rate3, equals(5000875.03125));
    });

    test('Authoritative Area Calculation: Uses Standard Area in Sq.Ft', () {
      // 2.375 Acres @ Rs 5000/Sq.Ft
      final acreVal = ValueNormalizationEngine.normalizeAreaValue('2.375 Acres');
      final rate = ValueNormalizationEngine.normalizeRate('Rs 5000');
      final unitAmount = acreVal.standardSqftValue * rate;
      expect(unitAmount, equals(517275000.0)); // 103455 * 5000
    });

    test('Alias Resolution maps canonical keys and preserves suffixes', () {
      expect(AliasResolutionEngine.resolveCanonical('SUPER_BUILT_UP_AREA'), equals('SALEABLE_AREA'));
      expect(AliasResolutionEngine.resolveCanonical('PROPERTY_AREA_SFT'), equals('SALEABLE_AREA'));
      expect(AliasResolutionEngine.resolveCanonical('SBUA'), equals('SALEABLE_AREA'));
      expect(AliasResolutionEngine.resolveCanonical('FLAT_AREA'), equals('SALEABLE_AREA'));
      expect(AliasResolutionEngine.resolveCanonical('SALEABLE_AREA_SQFT'), equals('SALEABLE_AREA'));

      expect(AliasResolutionEngine.resolveCanonical('COMPOSITE_RATE'), equals('MARKET_RATE_FLAT'));
      expect(AliasResolutionEngine.resolveCanonical('CURRENT_MARKET_RATE'), equals('MARKET_RATE_FLAT'));
      expect(AliasResolutionEngine.resolveCanonical('FLAT_MARKET_RATE'), equals('MARKET_RATE_FLAT'));
      expect(AliasResolutionEngine.resolveCanonical('BUILDING_MARKET_RATE'), equals('MARKET_RATE_FLAT'));

      expect(AliasResolutionEngine.resolveCanonical('SUPER_BUILT_UP_AREA_RAW'), equals('SALEABLE_AREA_RAW'));
      expect(AliasResolutionEngine.resolveCanonical('SBUA_NUMERIC'), equals('SALEABLE_AREA_NUMERIC'));
    });
  });
}
