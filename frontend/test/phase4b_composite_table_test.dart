import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Phase 4B Composite Table Validation & Backward Compatibility Tests', () {
    test('Pure integer inputs (1000, 5000) continue functioning unchanged (Backward Compatibility)', () {
      final provider = DocumentWorkspaceProvider();
      final model = DocumentWorkspaceModel(
        orderId: 201,
        reportNumber: 'ORD-201',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat',
          'SALEABLE_AREA': '1000',
          'MARKET_RATE_FLAT': '5000',
        },
      );
      provider.setWorkspaceModelForTest(model);

      expect(provider.getValue('SALEABLE_AREA'), equals('1000'));
      expect(provider.getValue('MARKET_RATE_FLAT'), equals('5000'));
      expect(provider.getValue('unit_amount'), equals('50,00,000'));
    });

    test('Composite Table items consume normalized numeric quantities and rates for exact calculations', () {
      final item = ValuationCompositeItemModel(
        orderId: 301,
        itemCategory: 'MAIN_UNIT',
        description: 'Commercial Flat',
        enteredUnit: 'Sq.Ft',
        quantity: 1000.125,
        rate: 5000.250,
        constructionCost: 2000.0,
        buildingAge: 10,
        totalLife: 60,
      );

      ValuationCalculator.calculateCompositeItem(item);

      // Amount = 1000.125 * 5000.250 = 5000875.03125
      expect(item.amount, closeTo(5000875.03125, 0.001));

      // Depreciation = Area * Cost * 90% * Age / Life
      // = 1000.125 * 2000 * 0.90 * (10 / 60) = 300037.5
      expect(item.depreciationAmount, closeTo(300037.5, 0.01));

      // Fair Value = Amount - Depr
      expect(item.fairValue, closeTo(5000875.03125 - 300037.5, 0.01));
    });
  });
}
