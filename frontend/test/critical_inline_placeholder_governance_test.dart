import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';
import 'package:provaluer_frontend/utils/date_picker_helper.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CRITICAL INLINE PLACEHOLDER GOVERNANCE - TESTS A TO H', () {
    test('TEST A: Column 2: PHOTO, Column 3: <<TEXT>> -> Single-line textbox only, No image picker', () {
      // Key is TEXT or TEXT_001, questionText from Column 2 is PHOTO
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
      expect(vm1.isMultiline, isFalse, reason: 'TEXT must be single-line');
      expect(vm1.isBlockNarrative, isFalse);

      expect(vm2.isImage, isFalse, reason: 'TEXT_001 must never be classified as IMAGE even if question is PHOTO');
      expect(vm2.isDate, isFalse);
      expect(vm2.isMultiline, isFalse, reason: 'TEXT_001 must be single-line');
      expect(vm2.isBlockNarrative, isFalse);
    });

    test('TEST B: Column 2: DATE OF PHOTO, Column 3: <<TEXT>> -> Single-line textbox only, No calendar picker', () {
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
      expect(vm1.isMultiline, isFalse, reason: 'TEXT must be single-line');
      expect(vm1.isBlockNarrative, isFalse);

      expect(vm2.isDate, isFalse, reason: 'TEXT_002 must never be classified as DATE even if question mentions DATE');
      expect(vm2.isImage, isFalse);
      expect(vm2.isMultiline, isFalse, reason: 'TEXT_002 must be single-line');
      expect(vm2.isBlockNarrative, isFalse);

      // DatePickerHelper verification
      expect(DatePickerHelper.isDateKey('TEXT', 'TEXT'), isFalse);
      expect(DatePickerHelper.isDateKey('TEXT_002', 'TEXT'), isFalse);
      expect(DatePickerHelper.isDateKey('TXT_001', 'TEXT'), isFalse);
    });

    test('TEST C: Column 2: ANY DESCRIPTION, Column 3: <<TEXT>> -> Single-line textbox only', () {
      final vm = InputFieldVm(
        key: 'TEXT_003',
        questionText: 'ANY DESCRIPTION',
        fieldType: 'TEXT',
      );

      expect(vm.isMultiline, isFalse, reason: 'Generic TEXT must remain single-line');
      expect(vm.isBlockNarrative, isFalse);
      expect(vm.isImage, isFalse);
      expect(vm.isDate, isFalse);
    });

    test('TEST D: Inline sentence placeholder classification', () {
      final inlineTextVm = InputFieldVm(
        key: 'TEXT_004',
        questionText: 'Property Address',
        fieldType: 'TEXT',
      );
      final inlineOwnerVm = InputFieldVm(
        key: 'OWNER_NAME',
        questionText: 'Owner Name',
        fieldType: 'TEXT',
      );

      expect(inlineTextVm.isBlockNarrative, isFalse, reason: 'Inline placeholder must NOT be block narrative');
      expect(inlineTextVm.isMultiline, isFalse, reason: 'Inline placeholder must be single line');
      expect(inlineOwnerVm.isBlockNarrative, isFalse, reason: 'OWNER_NAME must NOT be block narrative');
      expect(inlineOwnerVm.isMultiline, isFalse, reason: 'OWNER_NAME must be single line');
    });

    test('TEST E: OBSERVATIONS -> Still multiline block narrative, No regression', () {
      final vm = InputFieldVm(
        key: 'OBSERVATIONS',
        questionText: 'Site Observations',
        fieldType: 'MULTILINE',
      );
      final vm2 = InputFieldVm(
        key: 'OBSERVATION_1',
        questionText: 'Observation 1',
        fieldType: 'TEXT',
      );

      expect(vm.isBlockNarrative, isTrue);
      expect(vm.isMultiline, isTrue, reason: 'OBSERVATIONS must remain multiline');
      expect(vm2.isBlockNarrative, isTrue);
      expect(vm2.isMultiline, isTrue, reason: 'OBSERVATION_1 must remain multiline');
    });

    test('TEST F: REMARKS -> Still multiline block narrative, No regression', () {
      final vm1 = InputFieldVm(
        key: 'REMARKS',
        questionText: 'General Remarks',
        fieldType: 'TEXT',
      );
      final vm2 = InputFieldVm(
        key: 'VALUATION_REMARKS',
        questionText: 'Valuation Remarks',
        fieldType: 'MULTILINE',
      );

      expect(vm1.isBlockNarrative, isTrue);
      expect(vm1.isMultiline, isTrue, reason: 'REMARKS must remain multiline');
      expect(vm2.isBlockNarrative, isTrue);
      expect(vm2.isMultiline, isTrue, reason: 'VALUATION_REMARKS must remain multiline');
    });

    test('TEST G: DOCUMENTS_PERUSED -> Still multiline block narrative, No regression', () {
      final vm = InputFieldVm(
        key: 'DOCUMENTS_PERUSED',
        questionText: 'Documents Perused',
        fieldType: 'TEXT',
      );

      expect(vm.isBlockNarrative, isTrue);
      expect(vm.isMultiline, isTrue, reason: 'DOCUMENTS_PERUSED must remain multiline');
    });

    test('TEST H: LOCATION_DESCRIPTION -> Still multiline block narrative, No regression', () {
      final vm = InputFieldVm(
        key: 'LOCATION_DESCRIPTION',
        questionText: 'Location Description',
        fieldType: 'TEXT',
      );
      final vmBoundaries = InputFieldVm(
        key: 'BOUNDARIES',
        questionText: 'Boundaries of Property',
        fieldType: 'TEXT',
      );

      expect(vm.isBlockNarrative, isTrue);
      expect(vm.isMultiline, isTrue, reason: 'LOCATION_DESCRIPTION must remain multiline');
      expect(vmBoundaries.isBlockNarrative, isTrue);
      expect(vmBoundaries.isMultiline, isTrue, reason: 'BOUNDARIES must remain multiline');
    });
  });

  group('INLINE EDITABLE WIDGET SINGLE-LINE GOVERNANCE', () {
    testWidgets('InlineEditablePlaceholderWidget renders in single line and enters edit mode', (tester) async {
      final provider = DocumentWorkspaceProvider();
      final fieldVm = InputFieldVm(
        key: 'TEXT_001',
        questionText: 'Owner',
        fieldType: 'TEXT',
        currentValue: 'John Doe',
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

      // Read mode shows text 'John Doe'
      expect(find.text('John Doe'), findsOneWidget);

      // Click to enter edit mode
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // In edit mode, TextField is rendered with maxLines = 1, minLines = 1
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, equals(1), reason: 'Inline placeholder must have maxLines = 1');
      expect(textField.minLines, equals(1), reason: 'Inline placeholder must have minLines = 1');
    });
  });
}
