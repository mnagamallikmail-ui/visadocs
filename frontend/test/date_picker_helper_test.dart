import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/utils/date_picker_helper.dart';

void main() {
  group('DatePickerHelper Governance Tests', () {
    test('Strict format dd-MMM-yyyy', () {
      expect(DatePickerHelper.formatDate(DateTime(2026, 9, 3)), '03-Sep-2026');
      expect(DatePickerHelper.formatDate(DateTime(2027, 1, 15)), '15-Jan-2027');
      expect(DatePickerHelper.formatDate(DateTime(2028, 12, 1)), '01-Dec-2028');
    });

    test('Flexible Date Parsing across formats', () {
      // dd-MMM-yyyy
      final d1 = DatePickerHelper.parseFlexibleDate('03-Sep-2026');
      expect(d1, isNotNull);
      expect(d1!.year, 2026);
      expect(d1.month, 9);
      expect(d1.day, 3);
      expect(DatePickerHelper.formatDate(d1), '03-Sep-2026');

      // dd-MM-yyyy (e.g. database stored value)
      final d2 = DatePickerHelper.parseFlexibleDate('13-09-2026');
      expect(d2, isNotNull);
      expect(d2!.year, 2026);
      expect(d2.month, 9);
      expect(d2.day, 13);
      expect(DatePickerHelper.formatDate(d2), '13-Sep-2026');

      // yyyy-MM-dd (ISO)
      final d3 = DatePickerHelper.parseFlexibleDate('2026-09-13');
      expect(d3, isNotNull);
      expect(d3!.year, 2026);
      expect(d3.month, 9);
      expect(d3.day, 13);
      expect(DatePickerHelper.formatDate(d3), '13-Sep-2026');

      // Slash delimiters: 15/01/2027
      final d4 = DatePickerHelper.parseFlexibleDate('15/01/2027');
      expect(d4, isNotNull);
      expect(d4!.year, 2027);
      expect(d4.month, 1);
      expect(d4.day, 15);
      expect(DatePickerHelper.formatDate(d4), '15-Jan-2027');

      // Slash delimiters with text month: 15/Jan/2027
      final d5 = DatePickerHelper.parseFlexibleDate('15/Jan/2027');
      expect(d5, isNotNull);
      expect(d5!.year, 2027);
      expect(d5.month, 1);
      expect(d5.day, 15);
      expect(DatePickerHelper.formatDate(d5), '15-Jan-2027');

      // Full month name: 01-December-2028
      final d6 = DatePickerHelper.parseFlexibleDate('01-December-2028');
      expect(d6, isNotNull);
      expect(d6!.year, 2028);
      expect(d6.month, 12);
      expect(d6.day, 1);
      expect(DatePickerHelper.formatDate(d6), '01-Dec-2028');

      // Invalid input returns null safely
      expect(DatePickerHelper.parseFlexibleDate(''), isNull);
      expect(DatePickerHelper.parseFlexibleDate(null), isNull);
      expect(DatePickerHelper.parseFlexibleDate('invalid_date_text'), isNull);
    });

    test('Date key classification governance', () {
      expect(DatePickerHelper.isDateKey('VALUATION_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('INSPECTION_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('VISIT_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('REPORT_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('LEGAL_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('APPLICATION_DATE'), isTrue);
      expect(DatePickerHelper.isDateKey('DATE_OF_REPORT'), isTrue);
      expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION'), isTrue);
      expect(DatePickerHelper.isDateKey('<<DATE>>'), isTrue);
      expect(DatePickerHelper.isDateKey('DT_INSPECTION'), isTrue);
      expect(DatePickerHelper.isDateKey('SANCTION_DT'), isTrue);
      expect(DatePickerHelper.isDateKey('PROPERTY_DT_VISIT'), isTrue);
      expect(DatePickerHelper.isDateKey('SOME_FIELD', 'DATE'), isTrue);

      // Non-dates must NOT be classified as date
      expect(DatePickerHelper.isDateKey('COMPOSITE_PROPERTY_TABLE'), isFalse);
      expect(DatePickerHelper.isDateKey('VALUATION_RATE'), isFalse);
      expect(DatePickerHelper.isDateKey('TOTAL_AMOUNT'), isFalse);
      expect(DatePickerHelper.isDateKey('WIDTH'), isFalse);
      expect(DatePickerHelper.isDateKey('ADDITIONAL_REMARKS'), isFalse);
      expect(DatePickerHelper.isDateKey('CREDIT_PERIOD'), isFalse);
    });

    group('FIELD TYPE PRECEDENCE GOVERNANCE', () {
      test('Priority 1: Explicit fieldType=TEXT overrides date keys unconditionally', () {
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('DATE_001', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('VALUATION_DATE', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('<<DATE>>', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('DT_INSPECTION', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('DATE_OF_REPORT', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('REPORT_DATE', 'TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('SANCTION_DT', 'TEXT'), isFalse);
      });

      test('Priority 1: Explicit fieldType=NUMBER/IMAGE/MULTILINE overrides date keys', () {
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'NUMBER'), isFalse);
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'IMAGE'), isFalse);
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'MULTILINE'), isFalse);
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'CALCULATED'), isFalse);
      });

      test('Priority 1: Explicit fieldType=DATE activates date picker', () {
        expect(DatePickerHelper.isDateKey('CUSTOM_FIELD', 'DATE'), isTrue);
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', 'DATE'), isTrue);
      });

      test('Priority 2: Placeholder classification hard-stops', () {
        expect(DatePickerHelper.isDateKey('TEXT'), isFalse);
        expect(DatePickerHelper.isDateKey('TXT'), isFalse);
        expect(DatePickerHelper.isDateKey('TEXT_001'), isFalse);
        expect(DatePickerHelper.isDateKey('TXT_002'), isFalse);
        expect(DatePickerHelper.isDateKey('TEXT_PLACEHOLDER'), isFalse);
      });

      test('Priority 3: Name-based inference when fieldType is undeclared or empty', () {
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', null), isTrue);
        expect(DatePickerHelper.isDateKey('DATE_OF_INSPECTION', ''), isTrue);
        expect(DatePickerHelper.isDateKey('VALUATION_DATE', null), isTrue);
        expect(DatePickerHelper.isDateKey('DATE_001', null), isTrue);
        expect(DatePickerHelper.isDateKey('DT_INSPECTION', null), isTrue);
      });

      test('Priority 4: Fallback heuristics for non-date keys', () {
        expect(DatePickerHelper.isDateKey('OWNER_NAME', null), isFalse);
        expect(DatePickerHelper.isDateKey('PROPERTY_ADDRESS', ''), isFalse);
      });
    });
  });
}
