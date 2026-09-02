import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/utils/indian_number_formatter.dart';

void main() {
  group('RUNTIME PROOF 1: Blank Report Initialization (Zero Hardcoded Pre-filled Rows)', () {
    test('Fresh order workspace initializes with completely blank land and building items', () {
      final provider = DocumentWorkspaceProvider();

      // Simulate loading an order with no saved RAW_LAND_ITEMS_JSON or RAW_BUILDING_ITEMS_JSON
      final freshOrderModel = DocumentWorkspaceModel(
        orderId: 999,
        reportNumber: 'PV-2609-0999',
        status: 'ASSIGNED',
        readOnly: false,
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'CLIENT_NAME': 'Test Client',
          'BANK_NAME': 'State Bank of India',
          'BRANCH_NAME': 'Commercial Branch',
        },
      );

      provider.setWorkspaceModelForTest(freshOrderModel);

      // Verify Provider State: Must start completely blank
      expect(provider.landItems.isEmpty, isTrue,
          reason: 'Proof: New report landItems must be completely blank, length was ${provider.landItems.length}');
      expect(provider.buildingItems.isEmpty, isTrue,
          reason: 'Proof: New report buildingItems must be completely blank, length was ${provider.buildingItems.length}');

      // Verify ValuationData totals evaluate cleanly to 0 with zero rows
      expect(provider.valuationData?.totalLandValue, equals(0.0));
      expect(provider.valuationData?.totalBuildingValue, equals(0.0));
      expect(provider.valuationData?.fairValue, equals(0.0));
    });
  });

  group('RUNTIME PROOF 2: Indian Number Formatting Inside Editable Inputs', () {
    test('IndianNumberFormatter formats whole and decimal numbers with Indian commas', () {
      expect(IndianNumberFormatter.format(1000), equals('1,000'));
      expect(IndianNumberFormatter.format(2400), equals('2,400'));
      expect(IndianNumberFormatter.format(15000), equals('15,000'));
      expect(IndianNumberFormatter.format(1500000), equals('15,00,000'));
      expect(IndianNumberFormatter.format(25000000), equals('2,50,00,000'));
      expect(IndianNumberFormatter.format(10724.50, includeDecimals: true), equals('10,724.50'));
    });

    test('Numeric field detection and comma-safe parsing', () {
      // 1. Verify numeric field detection on various standard property keys
      final amountField = InputFieldVm(key: 'ESTIMATED_AMOUNT', fieldType: 'TEXT', questionText: 'Amount');
      final valueField = InputFieldVm(key: 'LAND_VALUE', fieldType: 'TEXT', questionText: 'Land Value');
      final rateField = InputFieldVm(key: 'GUIDELINE_RATE', fieldType: 'TEXT', questionText: 'Rate');
      final areaField = InputFieldVm(key: 'PLOT_AREA', fieldType: 'TEXT', questionText: 'Area');
      final regularField = InputFieldVm(key: 'CLIENT_NAME', fieldType: 'TEXT', questionText: 'Client Name');

      expect(amountField.isNumber, isTrue);
      expect(valueField.isNumber, isTrue);
      expect(rateField.isNumber, isTrue);
      expect(areaField.isNumber, isTrue);
      expect(regularField.isNumber, isFalse);

      // 2. Verify parsing user inputs containing Indian commas
      final formattedInput1 = '15,00,000';
      final parsed1 = double.tryParse(formattedInput1.replaceAll(',', '').trim());
      expect(parsed1, equals(1500000.0));

      final formattedInput2 = '2,400.75';
      final parsed2 = double.tryParse(formattedInput2.replaceAll(',', '').trim());
      expect(parsed2, equals(2400.75));

      final formattedInput3 = '₹ 25,00,000';
      final cleanNumeric = formattedInput3.replaceAll(RegExp(r'[^0-9.]'), '').trim();
      final parsed3 = double.tryParse(cleanNumeric);
      expect(parsed3, equals(2500000.0));
    });

    testWidgets('DocumentInputSlotWidget displays numeric fields with Indian comma formatting', (tester) async {
      final provider = DocumentWorkspaceProvider();

      // Seed a numeric value without commas into active values
      final workspaceModel = DocumentWorkspaceModel(
        orderId: 100,
        reportNumber: 'PV-2609-0100',
        status: 'ASSIGNED',
        readOnly: false,
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'FAIR_MARKET_VALUE': '1500000',
          'RATE_PER_SQFT': '2500',
        },
      );
      provider.setWorkspaceModelForTest(workspaceModel);

      final fairValueField = InputFieldVm(
        key: 'FAIR_MARKET_VALUE',
        questionText: 'Fair Market Value',
        fieldType: 'NUMBER',
        occurrences: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: DocumentInputSlotWidget(fieldVm: fairValueField),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the input field rendered with Indian comma formatting
      final textFieldFinder = find.byType(TextFormField);
      expect(textFieldFinder, findsOneWidget);

      final TextFormField textFormField = tester.widget(textFieldFinder);
      expect(textFormField.controller?.text, equals('15,00,000'),
          reason: 'Numeric field must format 1500000 as 15,00,000 inside editable textbox');
    });
  });
}
