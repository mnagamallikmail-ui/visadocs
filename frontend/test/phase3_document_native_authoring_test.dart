import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';
import 'package:provider/provider.dart';

void main() {
  group('Phase 3 Document-Native Authoring Tests', () {
    test('Narrative Paragraph parses into DocumentRunNode preserving flow and placeholders', () {
      final sampleDomJson = {
        'sections': [
          {
            'sectionIndex': 0,
            'title': '1. Valuation Certificate',
            'elements': [
              {
                'type': 'PARAGRAPH',
                'id': 'p_cert_0',
                'alignment': 'LEFT',
                'runs': [
                  {'text': 'This is to certify that the fair value of the property of ', 'isPlaceholder': false},
                  {'text': '<<PROPERTY_DESCRIPTION>>', 'isPlaceholder': true, 'placeholderKey': 'PROPERTY_DESCRIPTION', 'isBold': true},
                  {'text': ' : ', 'isPlaceholder': false},
                  {'text': '<<PROPERTY_ADDRESS>>', 'isPlaceholder': true, 'placeholderKey': 'PROPERTY_ADDRESS'},
                  {'text': ' Owned by ', 'isPlaceholder': false},
                  {'text': '<<OWNER_NAME>>', 'isPlaceholder': true, 'placeholderKey': 'OWNER_NAME', 'isBold': true},
                  {'text': ' is ', 'isPlaceholder': false},
                  {'text': '<<FAIR_VALUE>>', 'isPlaceholder': true, 'placeholderKey': 'FAIR_VALUE', 'isBold': true},
                  {'text': ' /- as on ', 'isPlaceholder': false},
                  {'text': '<<REPORT_DATE>>', 'isPlaceholder': true, 'placeholderKey': 'REPORT_DATE'},
                  {'text': '.', 'isPlaceholder': false},
                ]
              }
            ]
          }
        ],
        'placeholdersSummary': [
          {'key': 'PROPERTY_DESCRIPTION', 'type': 'TEXT', 'occurrences': 1, 'questionText': 'Property Description'},
          {'key': 'PROPERTY_ADDRESS', 'type': 'MULTILINE', 'occurrences': 2, 'questionText': 'Property Address'},
          {'key': 'OWNER_NAME', 'type': 'TEXT', 'occurrences': 3, 'questionText': 'Owner Name'},
          {'key': 'FAIR_VALUE', 'type': 'NUMBER', 'occurrences': 2, 'questionText': 'Fair Market Value'},
          {'key': 'REPORT_DATE', 'type': 'DATE', 'occurrences': 1, 'questionText': 'Date of Report'},
        ]
      };

      final dom = StudioDocumentModel.fromJson(sampleDomJson);
      final values = {
        'PROPERTY_DESCRIPTION': 'Commercial Showroom',
        'PROPERTY_ADDRESS': 'Plot No. 42, Jubilee Hills, Hyderabad',
        'OWNER_NAME': 'M/s ABC Infrastructure',
        'FAIR_VALUE': '12500000',
        'REPORT_DATE': '27-Aug-2026',
      };

      final vm = DocumentWorkspaceVm.fromDocumentDom(dom, values);

      expect(vm.sections.length, 1);
      final section = vm.sections.first;
      expect(section.paragraphBlocks.length, 1);

      final block = section.paragraphBlocks.first;
      expect(block.hasNodes, isTrue);
      expect(block.textAlign, TextAlign.left);

      // Verify the sequence of nodes matching the prose
      expect(block.nodes.length, 11);
      expect(block.nodes[0], isA<TextRunNode>());
      expect((block.nodes[0] as TextRunNode).text, contains('This is to certify'));

      expect(block.nodes[1], isA<PlaceholderRunNode>());
      expect((block.nodes[1] as PlaceholderRunNode).key, 'PROPERTY_DESCRIPTION');
      expect((block.nodes[1] as PlaceholderRunNode).isBold, isTrue);

      expect(block.nodes[3], isA<PlaceholderRunNode>());
      expect((block.nodes[3] as PlaceholderRunNode).key, 'PROPERTY_ADDRESS');

      expect(block.nodes[5], isA<PlaceholderRunNode>());
      expect((block.nodes[5] as PlaceholderRunNode).key, 'OWNER_NAME');

      expect(block.nodes[7], isA<PlaceholderRunNode>());
      expect((block.nodes[7] as PlaceholderRunNode).key, 'FAIR_VALUE');

      expect(block.nodes[9], isA<PlaceholderRunNode>());
      expect((block.nodes[9] as PlaceholderRunNode).key, 'REPORT_DATE');

      expect(block.nodes[10], isA<TextRunNode>());
      expect((block.nodes[10] as TextRunNode).text, '.');

      // Verify inputFields collection for backward compatibility
      expect(block.inputFields.length, 5);
      expect(section.boundKeys.contains('OWNER_NAME'), isTrue);
      expect(section.boundKeys.contains('FAIR_VALUE'), isTrue);
    });

    test('Type A Safe Alignment Standard verifies conditional alignment', () {
      // Short values -> CENTER
      const numField = InputFieldVm(
        key: 'FAIR_VALUE',
        questionText: 'Fair Market Value',
        fieldType: 'NUMBER',
      );
      expect(numField.isNumber, isTrue);
      expect(numField.isCurrency, isTrue);
      expect(numField.shouldLeftAlign, isFalse);
      expect(numField.effectiveTextAlign, TextAlign.center);

      const dateField = InputFieldVm(
        key: 'REPORT_DATE',
        questionText: 'Date of Valuation',
        fieldType: 'DATE',
      );
      expect(dateField.isDate, isTrue);
      expect(dateField.shouldLeftAlign, isFalse);
      expect(dateField.effectiveTextAlign, TextAlign.center);

      const statusField = InputFieldVm(
        key: 'APPROVAL_STATUS',
        questionText: 'Approval Granted',
        fieldType: 'TEXT',
      );
      expect(statusField.shouldLeftAlign, isFalse);
      expect(statusField.effectiveTextAlign, TextAlign.center);

      // Long / narrative values -> LEFT
      const addressField = InputFieldVm(
        key: 'PROPERTY_ADDRESS',
        questionText: 'Property Address',
        fieldType: 'TEXT',
      );
      expect(addressField.shouldLeftAlign, isTrue);
      expect(addressField.effectiveTextAlign, TextAlign.left);

      const remarksField = InputFieldVm(
        key: 'VALUATION_REMARKS',
        questionText: 'Valuation Remarks',
        fieldType: 'TEXT',
      );
      expect(remarksField.shouldLeftAlign, isTrue);
      expect(remarksField.effectiveTextAlign, TextAlign.left);

      const boundaryField = InputFieldVm(
        key: 'BOUNDARY_NORTH',
        questionText: 'North Boundary Details',
        fieldType: 'TEXT',
      );
      expect(boundaryField.shouldLeftAlign, isTrue);
      expect(boundaryField.effectiveTextAlign, TextAlign.left);
    });

    test('Type B Section Header row is detected and strictly left aligned', () {
      // Subheader
      const subHeaderRow = TableRowVm(
        rowIndex: 0,
        rowType: 'SECTION_SUBHEADER',
        questionText: 'Property Details',
        rawCells: [],
      );
      expect(subHeaderRow.isSectionHeadingRow, isTrue);

      // Merged category heading with no input fields
      const categoryHeadingRow = TableRowVm(
        rowIndex: 1,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Stage of Construction',
        inputFields: [],
        rawCells: [],
      );
      expect(categoryHeadingRow.isSectionHeadingRow, isTrue);

      // Normal Question Row -> NOT a section heading
      const normalQuestionRow = TableRowVm(
        rowIndex: 2,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Name of Owner',
        serialNo: '1',
        inputFields: [
          InputFieldVm(key: 'OWNER_NAME', questionText: 'Name of Owner', fieldType: 'TEXT')
        ],
        rawCells: [],
      );
      expect(normalQuestionRow.isSectionHeadingRow, isFalse);
    });

    testWidgets('InlineEditablePlaceholderWidget renders in Read Mode by default and enters Edit Mode on tap', (tester) async {
      final provider = DocumentWorkspaceProvider();
      provider.updateValue('OWNER_NAME', 'Mr. ABC Infrastructure');

      const fieldVm = InputFieldVm(
        key: 'OWNER_NAME',
        questionText: 'Name of Owner',
        fieldType: 'TEXT',
        occurrences: 2,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const InlineEditablePlaceholderWidget(
                fieldVm: fieldVm,
              ),
            ),
          ),
        ),
      );

      // Verify Read Mode: Rendered as styled text, not an active TextFormField
      expect(find.text('Mr. ABC Infrastructure'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget); // Repeated sync icon

      // Tap on placeholder to enter Edit Mode
      await tester.tap(find.text('Mr. ABC Infrastructure'));
      await tester.pumpAndSettle();

      // Verify Edit Mode: TextFormField is now rendered and active
      expect(find.byType(TextFormField), findsOneWidget);

      // Enter new value
      await tester.enterText(find.byType(TextFormField), 'XYZ Holdings Ltd');
      expect(provider.getValue('OWNER_NAME'), 'XYZ Holdings Ltd');

      // Submit field to commit and return to Read Mode
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify returned to Read Mode with updated text
      expect(find.text('XYZ Holdings Ltd'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
