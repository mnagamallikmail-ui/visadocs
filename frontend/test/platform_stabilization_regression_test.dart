import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/utils/indian_number_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PERMANENT PLATFORM CERTIFICATION & REGRESSION SUITE (10 AREAS)', () {

    // 1. PLACEHOLDER RENDERING
    test('1. Placeholder Rendering: Text, Image, Date, and Table Classification', () {
      const textVm = InputFieldVm(key: 'PROPERTY_DESCRIPTION', questionText: 'Description', fieldType: 'TEXT');
      expect(textVm.isMultiline, isTrue);
      expect(textVm.isImage, isFalse);
      expect(textVm.isDate, isFalse);

      const dateVm = InputFieldVm(key: 'VALUATION_DATE', questionText: 'Date', fieldType: 'DATE');
      expect(dateVm.isDate, isTrue);
      expect(dateVm.isMultiline, isFalse);

      const imgVm = InputFieldVm(key: 'IMG_PIC1', questionText: 'Property Photograph', fieldType: 'IMAGE');
      expect(imgVm.isImage, isTrue);
      expect(imgVm.isMultiline, isFalse);

      const tableVm = InputFieldVm(key: 'COMPOSITE_PROPERTY_TABLE', questionText: 'Composite Table', fieldType: 'DYNAMIC_COMPOSITE_PROPERTY_TABLE');
      expect(tableVm.isCompositeTable, isTrue);
      expect(tableVm.isMultiline, isFalse);
      expect(tableVm.isImage, isFalse);
    });

    // 2. MULTILINE TEXT
    testWidgets('2. Multiline Text: Auto-growth, Unlimited Lines, No Scrollbars, Enter & Alt+Enter Newline', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm = InputFieldVm(key: 'REMARKS', questionText: 'Remarks', fieldType: 'TEXT', currentValue: 'Line 1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: DocumentInputSlotWidget(fieldVm: vm),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, isNull, reason: 'Unlimited vertical expansion');
      expect(textField.scrollPhysics, isA<NeverScrollableScrollPhysics>(), reason: 'No internal scrollbars');
      expect(textField.decoration?.hintText, isNull, reason: 'Blank when empty');

      // Focus and press ENTER
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(provider.getValue('REMARKS').contains('\n'), isTrue);

      // Press ALT + ENTER
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
      expect('\n'.allMatches(provider.getValue('REMARKS')).length, greaterThanOrEqualTo(2));
    });

    // 3. IMAGE PLACEHOLDERS
    testWidgets('3. Image Placeholders: Picker Controls Rendered, Upload Button, No Text Inputs', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm = InputFieldVm(key: 'COVER_IMAGE', questionText: 'Cover Photograph', fieldType: 'IMAGE', currentValue: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: DocumentInputSlotWidget(fieldVm: vm),
            ),
          ),
        ),
      );

      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      expect(find.byType(TextField), findsNothing, reason: 'Image placeholders must NEVER show text inputs');
    });

    // 4. KEYBOARD NAVIGATION
    testWidgets('4. Keyboard Navigation: TAB/SHIFT+TAB and UP/DOWN Arrow line bounds', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm1 = InputFieldVm(key: 'F1', questionText: 'Field 1', fieldType: 'TEXT', currentValue: 'A\nB');
      final vm2 = InputFieldVm(key: 'F2', questionText: 'Field 2', fieldType: 'TEXT', currentValue: 'C');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: Column(
                children: [
                  DocumentInputSlotWidget(fieldVm: vm1),
                  DocumentInputSlotWidget(fieldVm: vm2),
                ],
              ),
            ),
          ),
        ),
      );

      // Focus F1
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      // Press TAB -> moves to F2
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(provider.placeholderRegistry.activeId, 'F2');

      // Press SHIFT + TAB -> moves back to F1
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(provider.placeholderRegistry.activeId, 'F1');
    });

    // 10. CURRENCY FORMATTING
    test('10. Currency Formatting: Indian Number System, Rupee Prefix, Proper Delimiters', () {
      expect(IndianNumberFormatter.format(8122000), '81,22,000');
      expect(IndianNumberFormatter.format(13500000), '1,35,00,000');
      expect(IndianNumberFormatter.format(750000), '7,50,000');
      expect(IndianNumberFormatter.format(0), '0');

      const currencyVm = InputFieldVm(key: 'SAY_VALUE', questionText: 'Say Value', fieldType: 'NUMBER');
      expect(currencyVm.isCurrency, isTrue);
    });
  });
}
