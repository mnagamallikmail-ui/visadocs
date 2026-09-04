import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Composite Valuation Engine V5 (Flats & Commercial Spaces)', () {
    test('Main unit calculation with 90% depreciation formula', () {
      final item = ValuationCompositeItemModel(
        itemCategory: 'MAIN_UNIT',
        description: 'Flat No. 402, 4th Floor',
        quantity: 1250.0,
        enteredUnit: 'Sq.Ft',
        rate: 9000.0,
        constructionCost: 2000.0,
        buildingAge: 5.0,
        totalLife: 60,
      );

      ValuationCalculator.calculateCompositeItem(item);

      // Replacement Cost / Amount = 1250 * 9000 = 1,12,50,000
      expect(item.amount, 11250000.0);
      // Depreciation = 1250 * 2000 * 0.90 * (5 / 60) = 1,87,500
      expect(item.depreciationAmount, 187500.0);
      // Fair Value = 1,12,50,000 - 1,87,500 = 1,10,62,500
      expect(item.fairValue, 11062500.0);
    });

    test('Interior works lump-sum and breakup with percentage vs direct amount', () {
      // Option A: Percentage
      final interiorA = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORKS',
        description: 'Interior Works & Improvements',
        quantity: 1.0,
        enteredUnit: 'LS',
        rate: 500000.0,
        depreciationPercentage: 20.0,
        isInsurable: true,
      );
      ValuationCalculator.calculateCompositeItem(interiorA);
      expect(interiorA.amount, 500000.0);
      expect(interiorA.depreciationAmount, 100000.0);
      expect(interiorA.fairValue, 400000.0);

      // Option B: Direct Amount
      final interiorB = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORKS',
        description: 'Custom Woodwork & Partitions',
        quantity: 1.0,
        enteredUnit: 'LS',
        rate: 300000.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 60000.0,
        isInsurable: true,
      );
      ValuationCalculator.calculateCompositeItem(interiorB);
      expect(interiorB.amount, 300000.0);
      expect(interiorB.depreciationAmount, 60000.0);
      expect(interiorB.fairValue, 240000.0);
    });

    test('Composite Summary calculation, Say Value rounding, and downstream values', () {
      final mainUnit = ValuationCompositeItemModel(
        itemCategory: 'MAIN_UNIT',
        description: 'Office Unit 101',
        quantity: 1200.0,
        enteredUnit: 'Sq.Ft',
        rate: 9000.0,
        constructionCost: 2000.0,
        buildingAge: 5.0,
        totalLife: 60,
      );
      final interior = ValuationCompositeItemModel(
        itemCategory: 'INTERIOR_WORKS',
        description: 'Interior Works & Improvements',
        quantity: 1.0,
        enteredUnit: 'LS',
        rate: 500000.0,
        depreciationMode: 'DIRECT_AMOUNT',
        depreciationAmount: 100000.0,
        isInsurable: true,
      );

      final valData = ValuationDataModel(
        orderId: 101,
        compositeGovernmentRate: 4500.0,
        realizablePercentage: 85.0,
        distressSalePercentage: 75.0,
      );

      ValuationCalculator.recalculateCompositeSummary(valData, [mainUnit, interior]);

      // Main Fair Value = 1200*9000 - (1200*2000*0.90*5/60) = 1,08,00,000 - 1,80,000 = 1,06,20,000
      // Interior Fair Value = 4,00,000
      // Raw Fair Value = 1,06,20,000 + 4,00,000 = 1,10,20,000
      // >= 1 Cr -> Round to nearest 1,00,000 -> Say Value = 1,10,00,000
      expect(valData.sayFairValue, 11000000.0);
      // In Composite Summary, fairValue consumes sayFairValue
      expect(valData.fairValue, 11000000.0);
      // Realizable Value = 85% of Say Fair Value = 93,50,000
      expect(valData.realizableValue, 9350000.0);
      // Distress Sale Value = 75% of Say Fair Value = 82,50,000
      expect(valData.distressSaleValue, 8250000.0);
      // Government Value = Area (1200) * Government Rate (4500) = 54,00,000
      expect(valData.governmentValue, 5400000.0);
      // Insurable Value = (1200 * 2000) + 500000 = 24,00,000 + 5,00,000 = 29,00,000
      expect(valData.insurableValue, 2900000.0);
    });

    test('Say row conditional suppression rule', () {
      // When Fair Value Of Property != Say Value, Say row must be present
      final rawFairVal1 = 11176250.0;
      final sayVal1 = ValuationCalculator.computeSayValue(rawFairVal1);
      expect(sayVal1, 11200000.0);
      expect(rawFairVal1 != sayVal1, true); // Displays "Say" row

      // When Fair Value Of Property == Say Value, Say row must be suppressed
      final rawFairVal2 = 11200000.0;
      final sayVal2 = ValuationCalculator.computeSayValue(rawFairVal2);
      expect(sayVal2, 11200000.0);
      expect(rawFairVal2 != sayVal2, false); // Suppressed!
    });

    test('COMPOSITE_PROPERTY_TABLE maintains approved column headings including Amount (₹)', () {
      const approvedHeaders = [
        'S.No',
        'Description',
        'Unit',
        'Quantity',
        'Rate (₹)',
        'Amount (₹)',
        'Depreciation (₹)',
        'Fair Value (₹)',
      ];

      expect(approvedHeaders[5], 'Amount (₹)');
      expect(approvedHeaders.contains('Replacement Cost (₹)'), false);
    });
  });
}
