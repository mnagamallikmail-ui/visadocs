import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/utils/indian_number_formatter.dart';

void main() {
  group('INTERIOR WORKS AMOUNT CALCULATION DEFECT VERIFICATION', () {
    test('TEST CASE 1: Qty = 1, Rate = 10,00,000, Depr = 3,00,000 -> Amount = 10,00,000, Fair Value = 7,00,000', () {
      final item = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORK',
        description: 'Interior Works & Improvements',
        enteredUnit: 'LS',
        quantity: 1.0,
        rate: 1000000.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 300000.0,
      );

      ValuationCalculator.calculateCompositeItem(item);

      // Verify mathematical calculation: Amount = Qty * Rate
      expect(item.amount, equals(1000000.0));
      // Fair Value = Amount - Depreciation
      expect(item.fairValue, equals(700000.0));

      // Verify formatted display strings
      expect(IndianNumberFormatter.format(item.amount), equals('10,00,000'));
      expect(IndianNumberFormatter.format(item.fairValue), equals('7,00,000'));
    });

    test('TEST CASE 2: Qty = 2, Rate = 5,00,000, Depr = 1,00,000 -> Amount = 10,00,000, Fair Value = 9,00,000', () {
      final item = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORK',
        description: 'Interior Works & Improvements',
        enteredUnit: 'LS',
        quantity: 2.0,
        rate: 500000.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 100000.0,
      );

      ValuationCalculator.calculateCompositeItem(item);

      // Verify mathematical calculation: Amount = Qty * Rate
      expect(item.amount, equals(1000000.0));
      // Fair Value = Amount - Depreciation
      expect(item.fairValue, equals(900000.0));

      // Verify formatted display strings
      expect(IndianNumberFormatter.format(item.amount), equals('10,00,000'));
      expect(IndianNumberFormatter.format(item.fairValue), equals('9,00,000'));
    });

    test('TEST CASE 3: Qty = 3, Rate = 2,00,000, Depr = 50,000 -> Amount = 6,00,000, Fair Value = 5,50,000', () {
      final item = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORK',
        description: 'Interior Works & Improvements',
        enteredUnit: 'LS',
        quantity: 3.0,
        rate: 200000.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 50000.0,
      );

      ValuationCalculator.calculateCompositeItem(item);

      // Verify mathematical calculation: Amount = Qty * Rate
      expect(item.amount, equals(600000.0));
      // Fair Value = Amount - Depreciation
      expect(item.fairValue, equals(550000.0));

      // Verify formatted display strings
      expect(IndianNumberFormatter.format(item.amount), equals('6,00,000'));
      expect(IndianNumberFormatter.format(item.fairValue), equals('5,50,000'));
    });

    test('DocumentWorkspaceProvider integration verifies full recalculation chain for Interior Works', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('SALEABLE_AREA', '1250');

      final interior = provider.compositeItems.firstWhere((i) => i.itemCategory.toUpperCase() == 'INTERIOR_WORK');
      interior.quantity = 1.0;
      interior.rate = 1000000.0;
      interior.amount = interior.quantity * interior.rate;
      interior.depreciationAmount = 300000.0;
      interior.depreciationMode = 'DIRECT_AMOUNT';

      provider.recalculateValuation();

      expect(interior.amount, equals(1000000.0));
      expect(interior.fairValue, equals(700000.0));
      expect(IndianNumberFormatter.format(interior.amount), equals('10,00,000'));
      expect(IndianNumberFormatter.format(interior.fairValue), equals('7,00,000'));
    });
  });
}
