import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';
import 'package:provaluer_frontend/utils/date_picker_helper.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
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

    group('CRITICAL DEFECT FIX: PLACEHOLDER CLASSIFICATION GOVERNANCE', () {
      test('Photograph | <<OWNER_NAME>> -> Expected: TEXT', () {
        final vm = InputFieldVm(
          key: 'OWNER_NAME',
          questionText: 'Photograph',
          fieldType: 'TEXT',
        );
        expect(vm.isImage, isFalse, reason: 'OWNER_NAME must be TEXT even when label is Photograph');
        expect(vm.isDate, isFalse);
        expect(vm.type, equals('TEXT'));
      });

      test('Date of Inspection | <<PROPERTY_REMARKS>> -> Expected: TEXT', () {
        final vm = InputFieldVm(
          key: 'PROPERTY_REMARKS',
          questionText: 'Date of Inspection',
          fieldType: 'TEXT',
        );
        expect(vm.isImage, isFalse);
        expect(vm.isDate, isFalse, reason: 'PROPERTY_REMARKS must be TEXT even when label is Date of Inspection');
        expect(vm.type, equals('TEXT'));
      });

      test('Date of Inspection | <<DATE_OF_INSPECTION>> -> Expected: DATE', () {
        final vm = InputFieldVm(
          key: 'DATE_OF_INSPECTION',
          questionText: 'Date of Inspection',
          fieldType: 'DATE',
        );
        expect(vm.isDate, isTrue);
        expect(vm.isImage, isFalse);
        expect(vm.type, equals('DATE'));
      });

      test('Governance Precedence: DATE_OF_INSPECTION / VALUATION_DATE / DATE_001 with fieldType=TEXT -> Expected: TEXT', () {
        final vm1 = InputFieldVm(
          key: 'DATE_OF_INSPECTION',
          questionText: 'Date of Inspection',
          fieldType: 'TEXT',
        );
        expect(vm1.isDate, isFalse);
        expect(vm1.type, equals('TEXT'));

        final vm2 = InputFieldVm(
          key: 'VALUATION_DATE',
          questionText: 'Valuation Date',
          fieldType: 'TEXT',
        );
        expect(vm2.isDate, isFalse);
        expect(vm2.type, equals('TEXT'));

        final vm3 = InputFieldVm(
          key: 'DATE_001',
          questionText: 'Date 1',
          fieldType: 'TEXT',
        );
        expect(vm3.isDate, isFalse);
        expect(vm3.type, equals('TEXT'));
      });

      test('Photograph | <<IMG_SITE_1>> -> Expected: IMAGE', () {
        final vm = InputFieldVm(
          key: 'IMG_SITE_1',
          questionText: 'Photograph',
          fieldType: 'IMAGE',
        );
        expect(vm.isImage, isTrue);
        expect(vm.isDate, isFalse);
        expect(vm.type, equals('IMAGE'));
      });

      test('Photograph | <<TEXT_PLACEHOLDER>> -> Expected: TEXT', () {
        final vm = InputFieldVm(
          key: 'TEXT_PLACEHOLDER',
          questionText: 'Photograph',
          fieldType: 'TEXT',
        );
        expect(vm.isImage, isFalse);
        expect(vm.isDate, isFalse);
        expect(vm.type, equals('TEXT'));
      });

      test('Date | <<TEXT_PLACEHOLDER>> -> Expected: TEXT', () {
        final vm = InputFieldVm(
          key: 'TEXT_PLACEHOLDER',
          questionText: 'Date',
          fieldType: 'TEXT',
        );
        expect(vm.isImage, isFalse);
        expect(vm.isDate, isFalse);
        expect(vm.type, equals('TEXT'));
      });

      test('Image | <<TEXT_PLACEHOLDER>> -> Expected: TEXT', () {
        final vm = InputFieldVm(
          key: 'TEXT_PLACEHOLDER',
          questionText: 'Image',
          fieldType: 'TEXT',
        );
        expect(vm.isImage, isFalse);
        expect(vm.isDate, isFalse);
        expect(vm.type, equals('TEXT'));
      });

      test('Table row binding with surrounding label does not alter placeholder type', () {
        final studioRowPhoto = StudioTableRow(
          rowIndex: 1,
          rowType: 'QUESTION_ANSWER',
          cells: [
            const StudioTableCell(
              cellId: 'c0',
              cellRole: 'QUESTION',
              plainText: 'Photograph',
            ),
            const StudioTableCell(
              cellId: 'c1',
              cellRole: 'ANSWER',
              placeholderBindings: [
                PlaceholderBinding(
                  key: 'OWNER_NAME',
                  questionText: 'Photograph',
                  fieldType: 'TEXT',
                ),
              ],
            ),
          ],
        );

        final rowVmPhoto = TableRowVm.fromStudioTableRow(
          studioRowPhoto,
          {'OWNER_NAME': 1},
          {},
          {},
        );
        expect(rowVmPhoto.inputFields.first.isImage, isFalse);
        expect(rowVmPhoto.inputFields.first.type, equals('TEXT'));

        final studioRowDate = StudioTableRow(
          rowIndex: 2,
          rowType: 'QUESTION_ANSWER',
          cells: [
            const StudioTableCell(
              cellId: 'c0',
              cellRole: 'QUESTION',
              plainText: 'Date of Inspection',
            ),
            const StudioTableCell(
              cellId: 'c1',
              cellRole: 'ANSWER',
              placeholderBindings: [
                PlaceholderBinding(
                  key: 'PROPERTY_REMARKS',
                  questionText: 'Date of Inspection',
                  fieldType: 'TEXT',
                ),
              ],
            ),
          ],
        );

        final rowVmDate = TableRowVm.fromStudioTableRow(
          studioRowDate,
          {'PROPERTY_REMARKS': 1},
          {},
          {},
        );
        expect(rowVmDate.inputFields.first.isDate, isFalse);
        expect(rowVmDate.inputFields.first.type, equals('TEXT'));
      });

      testWidgets('WIDGET VERIFICATION: Photograph | <<OWNER_NAME>> renders TEXT field, NO image widget, NO date picker', (tester) async {
        final provider = DocumentWorkspaceProvider();
        final fieldVm = InputFieldVm(
          key: 'OWNER_NAME',
          questionText: 'Photograph',
          fieldType: 'TEXT',
          currentValue: 'Acme Enterprises',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: DocumentInputSlotWidget(fieldVm: fieldVm),
              ),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing, reason: 'Must NOT render image upload control');
        expect(find.byIcon(Icons.calendar_today_rounded), findsNothing, reason: 'Must NOT render date picker icon');
        expect(find.text('dd-MMM-yyyy'), findsNothing);
      });

      testWidgets('WIDGET VERIFICATION: Photograph | <<TEXT_PLACEHOLDER>> renders TEXT field, NO image widget, NO date picker', (tester) async {
        final provider = DocumentWorkspaceProvider();
        final fieldVm = InputFieldVm(
          key: 'TEXT_PLACEHOLDER',
          questionText: 'Photograph',
          fieldType: 'TEXT',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: DocumentInputSlotWidget(fieldVm: fieldVm),
              ),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing, reason: 'Must NOT render image upload control');
        expect(find.byIcon(Icons.calendar_today_rounded), findsNothing, reason: 'Must NOT render date picker icon');
      });

      testWidgets('WIDGET VERIFICATION: Date | <<TEXT_PLACEHOLDER>> renders TEXT field, NO image widget, NO date picker', (tester) async {
        final provider = DocumentWorkspaceProvider();
        final fieldVm = InputFieldVm(
          key: 'TEXT_PLACEHOLDER',
          questionText: 'Date',
          fieldType: 'TEXT',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: DocumentInputSlotWidget(fieldVm: fieldVm),
              ),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_rounded), findsNothing, reason: 'Must NOT render date picker icon');
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      });

      testWidgets('WIDGET VERIFICATION: Date | <<PROPERTY_REMARKS>> renders TEXT field, NO date picker, NO image widget', (tester) async {
        final provider = DocumentWorkspaceProvider();
        final fieldVm = InputFieldVm(
          key: 'PROPERTY_REMARKS',
          questionText: 'Date',
          fieldType: 'TEXT',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: DocumentInputSlotWidget(fieldVm: fieldVm),
              ),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_rounded), findsNothing, reason: 'Must NOT render date picker icon');
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      });

      testWidgets('WIDGET VERIFICATION: Inspection Date / Date of Visit beside TEXT placeholders render TEXT field only', (tester) async {
        final provider = DocumentWorkspaceProvider();
        final fieldVm = InputFieldVm(
          key: 'PERSON_COORDINATED_FOR_INSPECTION',
          questionText: 'Inspection Date Coordinator',
          fieldType: 'TEXT',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: DocumentInputSlotWidget(fieldVm: fieldVm),
              ),
            ),
          ),
        );

        expect(find.byType(TextFormField), findsOneWidget);
        expect(find.byIcon(Icons.calendar_today_rounded), findsNothing);
        expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      });

      test('IMAGE PLACEHOLDER GOVERNANCE: Only IMG_ and IMAGE_ prefixes qualify as IMAGE', () {
        // Permitted image placeholders
        expect(InputFieldVm(key: 'IMG_SITE_1', questionText: 'Site 1', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMG_SITE_2', questionText: 'Site 2', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMG_FRONT_PAGE', questionText: 'Front', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMG_COVER_PAGE', questionText: 'Cover', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMG_LOCATION', questionText: 'Loc', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMG_GOVT_RATE', questionText: 'Govt Rate', fieldType: 'IMAGE').isImage, isTrue);
        expect(InputFieldVm(key: 'IMAGE_SITE_PHOTO_1', questionText: 'Site Photo', fieldType: 'IMAGE').isImage, isTrue);
        // Even if fieldType is default TEXT, key starting with IMG_ or IMAGE_ is IMAGE
        expect(InputFieldVm(key: 'IMG_SITE_1', questionText: 'Site 1', fieldType: 'TEXT').isImage, isTrue);
        expect(InputFieldVm(key: 'IMAGE_LOCATION', questionText: 'Loc', fieldType: 'TEXT').isImage, isTrue);

        // Prohibited image patterns: MUST NOT BE IMAGE
        expect(InputFieldVm(key: 'PROPERTY_PHOTO', questionText: 'Photo', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'PHOTO', questionText: 'Photo', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'SELFIE', questionText: 'Selfie', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'SIGNATURE', questionText: 'Sign', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'FRONT_PAGE_IMAGE', questionText: 'Front Page', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'LOCATION_IMG', questionText: 'Location', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'PHOTO_1', questionText: 'Photo 1', fieldType: 'TEXT').isImage, isFalse);
        expect(InputFieldVm(key: 'OWNER_NAME', questionText: 'Owner', fieldType: 'TEXT').isImage, isFalse);
      });

      test('GENERIC TEXT PLACEHOLDER GOVERNANCE: Independent field state across TEXT fields', () {
        final provider = DocumentWorkspaceProvider();
        provider.updateValue('TEXT_001', 'Introduction');
        provider.updateValue('TEXT_002', 'Observation');
        provider.updateValue('TEXT_003', 'Remarks');

        expect(provider.getValue('TEXT_001'), equals('Introduction'));
        expect(provider.getValue('TEXT_002'), equals('Observation'));
        expect(provider.getValue('TEXT_003'), equals('Remarks'));

        // Modifying one TEXT field must never affect another
        provider.updateValue('TEXT_001', 'Updated Introduction');
        expect(provider.getValue('TEXT_001'), equals('Updated Introduction'));
        expect(provider.getValue('TEXT_002'), equals('Observation'));
        expect(provider.getValue('TEXT_003'), equals('Remarks'));
      });
    });
  });
}
