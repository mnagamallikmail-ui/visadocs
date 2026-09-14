import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';

void main() {
  group('Remediation Audit Sprint Verification Tests', () {
    late DocumentWorkspaceProvider provider;

    setUp(() {
      provider = DocumentWorkspaceProvider();
      final model = DocumentWorkspaceModel(
        orderId: 202,
        reportNumber: 'ORD-202',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat',
          'SALEABLE_AREA': '1000 Sq.Ft',
          'MARKET_RATE_FLAT': '₹5000',
        },
      );
      provider.setWorkspaceModelForTest(model);
    });

    test('Criterion 2: SALEABLE_AREA = 1000 Sq.Ft and MARKET_RATE_FLAT = ₹5000 immediately produces UNIT_AMOUNT = 50,00,000', () {
      provider.updateValue('SALEABLE_AREA', '1000 Sq.Ft');
      provider.updateValue('MARKET_RATE_FLAT', '₹5000');

      expect(provider.getValue('UNIT_AMOUNT'), equals('50,00,000'));
      expect(provider.getValue('unit_amount'), equals('50,00,000'));

      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnit.amount, equals(5000000.0));
      expect(mainUnit.quantity, equals(1000.0));
      expect(mainUnit.rate, equals(5000.0));
    });

    test('Criterion 3: SALEABLE_AREA = 2.5 Cents produces SALEABLE_AREA_STANDARD_SQFT = 1089.000 and valuation uses 1089.000, not 2.5', () {
      provider.updateValue('SALEABLE_AREA', '2.5 Cents');
      provider.updateValue('MARKET_RATE_FLAT', '₹5000');

      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('1089'));
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('2.5'));
      expect(provider.getValue('SALEABLE_AREA_UNIT'), equals('CENTS'));

      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnit.quantity, equals(1089.0));
      // 1089 * 5000 = 54,45,000
      expect(mainUnit.amount, equals(5445000.0));
      expect(provider.getValue('UNIT_AMOUNT'), equals('54,45,000'));
    });

    test('Validation 4: Additional Unit Conversions (Sq.Yd, Sq.M, Acres) and Valuation Math Certification', () {
      // Test 250 Sq.Yd -> 250 * 9 = 2250 Sq.Ft
      provider.updateValue('SALEABLE_AREA', '250 Sq.Yd');
      provider.updateValue('MARKET_RATE_FLAT', '5000');
      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('2250'));
      expect(provider.getValue('UNIT_AMOUNT'), equals('1,12,50,000'));

      // Test 100 Sq.M -> 100 * 10.7639104 = 1076.391 Sq.Ft
      provider.updateValue('SALEABLE_AREA', '100 Sq.M');
      provider.updateValue('MARKET_RATE_FLAT', '5000');
      final sqMStandard = double.parse(provider.getValue('SALEABLE_AREA_STANDARD_SQFT')!);
      expect((sqMStandard - 1076.391).abs() < 0.01, isTrue);
      final mainUnitSqM = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect((mainUnitSqM.amount - 5381955.0).abs() < 50.0, isTrue);

      // Test 2.375 Acres -> 2.375 * 43560 = 103455 Sq.Ft
      provider.updateValue('SALEABLE_AREA', '2.375 Acres');
      provider.updateValue('MARKET_RATE_FLAT', '500');
      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('103455'));
      // 103455 * 500 = 51,727,500
      final mainUnitAcre = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnitAcre.amount, equals(51727500.0));
      expect(provider.getValue('UNIT_AMOUNT'), equals('5,17,27,500'));
    });

    test('Criterion 4: Runtime values contain SALEABLE_AREA, SALEABLE_AREA_NUMERIC, SALEABLE_AREA_STANDARD_SQFT, MARKET_RATE_FLAT, MARKET_RATE_FLAT_NUMERIC', () {
      provider.updateValue('SALEABLE_AREA', '1250 Sq.Ft');
      provider.updateValue('MARKET_RATE_FLAT', '6200');

      expect(provider.getValue('SALEABLE_AREA'), equals('1250'));
      expect(provider.getValue('SALEABLE_AREA_RAW'), equals('1250 Sq.Ft'));
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1250'));
      expect(provider.getValue('SALEABLE_AREA_STANDARD_SQFT'), equals('1250'));
      expect(provider.getValue('MARKET_RATE_FLAT'), equals('6200'));
      expect(provider.getValue('MARKET_RATE_FLAT_NUMERIC'), equals('6200'));
    });

    testWidgets('Criterion 5: Narrative text inside Word table cell renders inline document flow via Text.rich and InlineEditablePlaceholderWidget', (tester) async {
      final domJson = {
        'sections': [
          {
            'sectionIndex': 0,
            'title': 'Valuation Certificate',
            'elements': [
              {
                'type': 'TABLE',
                'id': 'tbl_narrative',
                'rowCount': 1,
                'columnCount': 1,
                'rows': [
                  {
                    'rowIndex': 0,
                    'rowType': 'STATIC_ROW',
                    'cells': [
                      {
                        'cellId': 'c_narrative',
                        'plainText': 'Dear <<BANK_NAME>>, property owned by <<OWNER_NAME>> is valued at <<FAIR_VALUE>>.',
                        'placeholderBindings': [
                          {'key': 'BANK_NAME', 'questionText': 'Bank Name', 'fieldType': 'TEXT'},
                          {'key': 'OWNER_NAME', 'questionText': 'Owner Name', 'fieldType': 'TEXT'},
                          {'key': 'FAIR_VALUE', 'questionText': 'Fair Value', 'fieldType': 'TEXT'},
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      final dom = StudioDocumentModel.fromJson(domJson);

      final model = DocumentWorkspaceModel(
        orderId: 202,
        reportNumber: 'ORD-202',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat',
          'SALEABLE_AREA': '1000 Sq.Ft',
          'MARKET_RATE_FLAT': '₹5000',
          'BANK_NAME': 'State Bank of India',
          'OWNER_NAME': 'John Doe',
          'FAIR_VALUE': '50,00,000',
        },
        documentDom: dom,
      );
      provider.setWorkspaceModelForTest(model);

      await tester.pumpWidget(
        ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );

      // Verify that the table cell renders inline editable placeholders rather than question/answer form cards
      expect(find.byType(InlineEditablePlaceholderWidget), findsWidgets);
    });
  });
}
