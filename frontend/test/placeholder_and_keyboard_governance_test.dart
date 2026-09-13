import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/placeholder_registry.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AUDIT 1: TEXT PLACEHOLDER GOVERNANCE', () {
    test('Every text placeholder is classified as multiline with no clipping/scrollbars', () {
      final textKeys = [
        'TEXT',
        'TO_ADDRESS',
        'OWNER_ADDRESS',
        'BANK_ADDRESS',
        'PROPERTY_ADDRESS',
        'DESCRIPTION',
        'OBSERVATIONS',
        'REMARKS',
        'BOUNDARIES',
        'MARKET_COMMENT',
        'PRICE_TREND',
        'LOCATION_DESCRIPTION',
      ];

      for (final key in textKeys) {
        final vm = InputFieldVm(
          key: key,
          questionText: DocumentWorkspaceVm.toHumanizedLabel(key),
          fieldType: 'TEXT',
          currentValue: '',
        );

        expect(vm.isMultiline, isTrue, reason: '$key must be multiline');
        expect(vm.isImage, isFalse, reason: '$key must never be an image');
        expect(vm.isNumber, isFalse, reason: '$key must not be classified as number');
      }
    });

    testWidgets('Text placeholder renders blank when empty (no hints, no placeholder labels)', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm = InputFieldVm(
        key: 'PROPERTY_DESCRIPTION',
        questionText: 'Property Description',
        fieldType: 'TEXT',
        currentValue: '',
      );

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

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.decoration?.hintText, isNull, reason: 'Text placeholders must not show hints');
      expect(textField.minLines, 3);
      expect(textField.maxLines, isNull, reason: 'Must have unlimited vertical growth (maxLines: null)');
      expect(textField.scrollPhysics, isA<NeverScrollableScrollPhysics>(), reason: 'Must never have internal scrollbars');
    });

    testWidgets('ENTER and ALT+ENTER insert newline into multiline text placeholder', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm = InputFieldVm(
        key: 'REMARKS',
        questionText: 'Valuer Remarks',
        fieldType: 'TEXT',
        currentValue: 'Line 1',
      );

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

      // Focus text field
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Press Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(provider.getValue('REMARKS').contains('\n'), isTrue, reason: 'ENTER must insert newline');

      // Press Alt + Enter key
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();

      final val = provider.getValue('REMARKS');
      final newlines = '\n'.allMatches(val).length;
      expect(newlines, greaterThanOrEqualTo(2), reason: 'ALT+ENTER must insert additional newline');
    });
  });

  group('AUDIT 2: IMAGE PLACEHOLDER GOVERNANCE', () {
    test('Image placeholders always classified as image and never multiline', () {
      final imageKeys = [
        'IMG_PIC1',
        'IMG_PIC2',
        'COVER_IMAGE',
        'PROPERTY_PHOTO',
        'SITE_IMAGE',
        'MAP_IMAGE',
        'OWNER_SIGNATURE',
        'VALUER_SELFIE',
      ];

      for (final key in imageKeys) {
        final vm = InputFieldVm(
          key: key,
          questionText: DocumentWorkspaceVm.toHumanizedLabel(key),
          fieldType: 'IMAGE',
          currentValue: '',
        );

        expect(vm.isImage, isTrue, reason: '$key must be an image');
        expect(vm.isMultiline, isFalse, reason: '$key must not be multiline text');
      }
    });

    test('Text placeholders with image keywords in description are NEVER classified as image', () {
      final trickyTextKeys = [
        'IMAGE_DESCRIPTION',
        'PHOTO_REMARKS',
        'PICTURE_CAPTION',
        'IMAGE_NOTE',
      ];

      for (final key in trickyTextKeys) {
        final vm = InputFieldVm(
          key: key,
          questionText: DocumentWorkspaceVm.toHumanizedLabel(key),
          fieldType: 'TEXT',
          currentValue: '',
        );

        expect(vm.isImage, isFalse, reason: '$key contains description/remarks and must be TEXT');
        expect(vm.isMultiline, isTrue, reason: '$key must be multiline text');
      }
    });

    testWidgets('IMAGE placeholder displays image picker controls with upload button', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm = InputFieldVm(
        key: 'IMG_PIC1',
        questionText: 'Property Front Photograph',
        fieldType: 'IMAGE',
        currentValue: '',
      );

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
      expect(find.byType(TextField), findsNothing, reason: 'Image placeholder must never render text input field');
    });
  });

  group('AUDIT 3: KEYBOARD NAVIGATION GOVERNANCE', () {
    testWidgets('TAB moves focus to next placeholder and SHIFT+TAB moves to previous', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm1 = InputFieldVm(
        key: 'FIELD_A',
        questionText: 'Field A',
        fieldType: 'TEXT',
        currentValue: 'Text A',
      );
      final vm2 = InputFieldVm(
        key: 'FIELD_B',
        questionText: 'Field B',
        fieldType: 'TEXT',
        currentValue: 'Text B',
      );

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

      // Tap on Field A to focus
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      // Press TAB -> moves to Field B
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, 'FIELD_B', reason: 'TAB must navigate to next placeholder (FIELD_B)');

      // Press SHIFT + TAB -> moves back to Field A
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, 'FIELD_A', reason: 'SHIFT+TAB must navigate to previous placeholder (FIELD_A)');
    });

    testWidgets('UP/DOWN Arrow respects multiline text bounds and navigates at top/bottom edges', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final vm1 = InputFieldVm(
        key: 'FIELD_1',
        questionText: 'Field 1',
        fieldType: 'TEXT',
        currentValue: 'Header\nBody\nFooter',
      );
      final vm2 = InputFieldVm(
        key: 'FIELD_2',
        questionText: 'Field 2',
        fieldType: 'TEXT',
        currentValue: 'Target',
      );

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

      // Focus Field 1
      await tester.tap(find.byType(TextField).first);
      await tester.pumpAndSettle();

      // When cursor is at the very end of 'Footer' (last line), pressing DOWN arrow moves to next placeholder (FIELD_2)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, 'FIELD_2', reason: 'DOWN arrow on last line navigates to next placeholder');

      // Now on FIELD_2 (single line 'Target'). Pressing UP arrow moves back to previous placeholder (FIELD_1)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, 'FIELD_1', reason: 'UP arrow on first line navigates to previous placeholder');
    });
  });
}
