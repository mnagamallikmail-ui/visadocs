import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/valuation_models.dart';
import 'package:provaluer_frontend/features/document_workspace/services/valuation_calculator.dart';

void main() {
  group('Authority Governance & Recalculation Protection', () {
    test('ValuationCalculator.generatePlaceholders never injects metadata fields', () {
      final data = ValuationDataModel(orderId: 1);
      final placeholders = ValuationCalculator.generatePlaceholders(
        orderInfo: {
          'id': 1,
          'clientName': 'ABC Industries',
          'bankName': 'Test Bank',
          'branchName': 'Main Branch',
        },
        data: data,
        landItems: const [],
        buildingItems: const [],
        comparables: const [],
      );

      expect(placeholders.containsKey('owner_name'), isFalse);
      expect(placeholders.containsKey('OWNER_NAME'), isFalse);
      expect(placeholders.containsKey('client_name'), isFalse);
      expect(placeholders.containsKey('CLIENT_NAME'), isFalse);
      expect(placeholders.containsKey('bank_name'), isFalse);
      expect(placeholders.containsKey('branch_name'), isFalse);
    });

    test('DocumentWorkspaceModel parses fieldAuthorities map in uppercase', () {
      final model = DocumentWorkspaceModel.fromJson({
        'orderId': 10,
        'status': 'SPA_CONFIRMED',
        'reportNumber': 'PV-10',
        'values': {'owner_name': 'PQR', 'market_value': '11,00,00,000'},
        'fieldAuthorities': {'owner_name': 'admin', 'market_value': 'spa'},
      });

      expect(model.values['OWNER_NAME'], equals('PQR'));
      expect(model.fieldAuthorities['OWNER_NAME'], equals('ADMIN'));
      expect(model.fieldAuthorities['MARKET_VALUE'], equals('SPA'));
    });
  });
}
