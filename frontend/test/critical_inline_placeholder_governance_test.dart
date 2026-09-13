import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';
import 'package:provaluer_frontend/utils/date_picker_helper.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CRITICAL TEXT INPUT PLACEHOLDER GOVERNANCE - TESTS A TO J', () {
    test('TEST A: Column 2: PHOTO, Column 3: <<TEXT>> -> Text input only, No image picker', () {
      final vm1 = InputFieldVm(
        key: 'TEXT',
        questionText: 'PHOTO',
        fieldType: 'TEXT',
      );
      final vm2 = InputFieldVm(
        key: 'TEXT_001',
        questionText: 'PHOTO',
        fieldType: 'TEXT',
      );

      expect(vm1.isImage, isFalse, reason: 'TEXT must never be classified as IMAGE even if question is PHOTO');
      expect(vm1.isDate, isFalse);
      expect(vm2.isImage, isFalse, reason: 'TEXT_001 must never be classified as IMAGE even if question is PHOTO');
      expect(vm2.isDate, isFalse);
    });

    test('TEST B: Column 2: DATE OF PHOTO, Column 3: <<TEXT>> -> Text input only, No calendar picker', () {
      final vm1 = InputFieldVm(
        key: 'TEXT',
        questionText: 'DATE OF PHOTO',
        fieldType: 'TEXT',
      );
      final vm2 = InputFieldVm(
        key: 'TEXT_002',
        questionText: 'DATE OF PHOTO',
        fieldType: 'TEXT',
      );

      expect(vm1.isDate, isFalse, reason: 'TEXT must never be classified as DATE even if question mentions DATE');
      expect(vm1.isImage, isFalse);
      expect(vm2.isDate, isFalse, reason: 'TEXT_002 must never be classified as DATE even if question mentions DATE');
      expect(vm2.isImage, isFalse);

      expect(DatePickerHelper.isDateKey('TEXT', 'TEXT'), isFalse);
      expect(DatePickerHelper.isDateKey('TEXT_002', 'TEXT'), isFalse);
      expect(DatePickerHelper.isDateKey('TXT_001', 'TEXT'), isFalse);
    });

    testWidgets('TEST C & D: Inline placeholder starts single-line, ALT+ENTER inserts newline and expands', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final fieldVm = InputFieldVm(
        key: 'TEXT_001',
        questionText: 'Property Address',
        fieldType: 'TEXT',
        currentValue: 'Line 1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: InlineEditablePlaceholderWidget(
                fieldVm: fieldVm,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);

      // Tap to enter edit mode
      await tester.tap(find.text('Line 1'));
      await tester.pumpAndSettle();

      // Verify starts as single-line (minLines: 1, maxLines: null for dynamic growth)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, equals(1), reason: 'Starts single-line');
      expect(textField.maxLines, isNull, reason: 'Allows dynamic vertical expansion');

      // Send ALT + ENTER key event
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      // Verify newline was inserted in provider
      expect(provider.getValue('TEXT_001'), equals('Line 1\n'));

      // Enter Line 2
      await tester.enterText(find.byType(TextField), 'Line 1\nLine 2');
      await tester.pumpAndSettle();
      expect(provider.getValue('TEXT_001'), equals('Line 1\nLine 2'));

      // Send ALT + ENTER again (TEST D: repeated ALT+ENTER -> Line 3)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Line 1\nLine 2\nLine 3');
      await tester.pumpAndSettle();
      expect(provider.getValue('TEXT_001'), equals('Line 1\nLine 2\nLine 3'));

      // Normal ENTER commits edit mode without adding another newline
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // Read mode displays all 3 lines preserved
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });

    test('TEST E: Save and Reopen preserves multi-line content exactly', () {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('TEXT_001', 'Line 1\nLine 2\nLine 3');

      final savedMap = Map<String, String>.from(provider.activeValues);
      expect(savedMap['TEXT_001'], equals('Line 1\nLine 2\nLine 3'));

      // Simulate reopen
      final reopenedProvider = DocumentWorkspaceProvider();
      reopenedProvider.updateValue('TEXT_001', savedMap['TEXT_001']!);
      expect(reopenedProvider.getValue('TEXT_001'), equals('Line 1\nLine 2\nLine 3'));
    });

    testWidgets('TEST H: Inline paragraph placeholder keeps entire sentence visible', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final fieldVm = InputFieldVm(
        key: 'TEXT_005',
        questionText: 'Location',
        fieldType: 'TEXT',
        currentValue: 'Main Road',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'The property situated at '),
                    WidgetSpan(
                      child: InlineEditablePlaceholderWidget(
                        fieldVm: fieldVm,
                      ),
                    ),
                    const TextSpan(text: ' is bounded by a public road.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Context words before and after must both be visible
      expect(find.textContaining('The property situated at', findRichText: true), findsOneWidget);
      expect(find.textContaining('is bounded by a public road.', findRichText: true), findsOneWidget);
      expect(find.text('Main Road'), findsOneWidget);

      // Tap placeholder to edit
      await tester.tap(find.text('Main Road'));
      await tester.pumpAndSettle();

      // Sentence context remains visible during editing
      expect(find.textContaining('The property situated at', findRichText: true), findsOneWidget);
      expect(find.textContaining('is bounded by a public road.', findRichText: true), findsOneWidget);
    });

    testWidgets('TEST I: OBSERVATIONS starts single-line and expands with ALT+ENTER', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final fieldVm = InputFieldVm(
        key: 'OBSERVATIONS',
        questionText: 'Site Observations',
        fieldType: 'TEXT',
        currentValue: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: DocumentInputSlotWidget(
                fieldVm: fieldVm,
              ),
            ),
          ),
        ),
      );

      // Verify starts as single-line (minLines: 1)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, equals(1), reason: 'OBSERVATIONS must start single-line');
      expect(textField.maxLines, isNull, reason: 'OBSERVATIONS must auto-expand dynamically');
    });

    testWidgets('TEST J: REMARKS starts single-line and expands with ALT+ENTER', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final fieldVm = InputFieldVm(
        key: 'REMARKS',
        questionText: 'General Remarks',
        fieldType: 'TEXT',
        currentValue: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: DocumentInputSlotWidget(
                fieldVm: fieldVm,
              ),
            ),
          ),
        ),
      );

      // Verify starts as single-line (minLines: 1)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, equals(1), reason: 'REMARKS must start single-line');
      expect(textField.maxLines, isNull, reason: 'REMARKS must auto-expand dynamically');
    });
  });
}
