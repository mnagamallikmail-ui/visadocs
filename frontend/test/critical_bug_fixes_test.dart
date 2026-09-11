import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';

void main() {
  group('Critical Bug Fixes Verification', () {
    test('Issue 1: Incorrect Image Placeholder Detection', () {
      // 1. Text placeholders must NEVER be rendered as images, even if question is "Building plan"
      const buildingPlanField = InputFieldVm(
        key: 'BUILDING_PLAN',
        questionText: 'Building plan',
        fieldType: 'TEXT',
      );
      expect(buildingPlanField.isImage, isFalse,
          reason: 'BUILDING_PLAN text placeholder must not be detected as image');

      const floorPlanField = InputFieldVm(
        key: 'FLOOR_PLAN',
        questionText: 'Floor plan',
        fieldType: 'TEXT',
      );
      expect(floorPlanField.isImage, isFalse,
          reason: 'FLOOR_PLAN text placeholder must not be detected as image');

      const remarksField = InputFieldVm(
        key: 'REMARKS',
        questionText: 'Property Photo Remarks',
        fieldType: 'MULTILINE',
      );
      expect(remarksField.isImage, isFalse,
          reason: 'REMARKS with photo in questionText must not be detected as image');

      const descriptionField = InputFieldVm(
        key: 'DESCRIPTION',
        questionText: 'Description',
        fieldType: 'TEXT',
      );
      expect(descriptionField.isImage, isFalse);

      const commentsField = InputFieldVm(
        key: 'COMMENTS',
        questionText: 'Valuer Comments',
        fieldType: 'TEXT',
      );
      expect(commentsField.isImage, isFalse);

      // 2. True image placeholders MUST be detected as images
      const propertyPhotoField = InputFieldVm(
        key: 'PROPERTY_PHOTO',
        questionText: 'Property Photo',
        fieldType: 'TEXT',
      );
      expect(propertyPhotoField.isImage, isTrue,
          reason: 'PROPERTY_PHOTO key must be detected as image');

      const valuerSelfieField = InputFieldVm(
        key: 'VALUER_SELFIE',
        questionText: 'Valuer Selfie',
        fieldType: 'TEXT',
      );
      expect(valuerSelfieField.isImage, isTrue,
          reason: 'VALUER_SELFIE key must be detected as image');

      const explicitImageField = InputFieldVm(
        key: 'CUSTOM_KEY',
        questionText: 'Any image label',
        fieldType: 'IMAGE',
      );
      expect(explicitImageField.isImage, isTrue,
          reason: 'Explicit fieldType=IMAGE must be detected as image');
    });

    test('Issue 2: Section Headers Detected and Left Aligned', () {
      const summaryRow = TableRowVm(
        rowIndex: 10,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Summary of Valuation',
        serialNo: '10',
        inputFields: [],
        rawCells: [],
      );
      expect(summaryRow.isSectionHeadingRow, isTrue,
          reason: 'Summary of Valuation with no inputFields is a section heading row');

      const guidelineRow = TableRowVm(
        rowIndex: 15,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Guideline Value',
        inputFields: [],
        rawCells: [],
      );
      expect(guidelineRow.isSectionHeadingRow, isTrue,
          reason: 'Guideline Value with no inputFields is a section heading row');

      const valuationRow = TableRowVm(
        rowIndex: 20,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Valuation',
        inputFields: [],
        rawCells: [],
      );
      expect(valuationRow.isSectionHeadingRow, isTrue,
          reason: 'Valuation with no inputFields is a section heading row');
    });

    test('Issue 3: Fixed Grid Structure in TableRowVm', () {
      // 3-column row: has serialNo and inputFields
      const threeColRow = TableRowVm(
        rowIndex: 9,
        rowType: 'QUESTION_ANSWER',
        serialNo: '9',
        questionText: 'Mention value...',
        inputFields: [
          InputFieldVm(key: 'VALUE_1', questionText: 'Mention value...', fieldType: 'TEXT'),
        ],
        rawCells: [],
      );
      expect(threeColRow.is3Column, isTrue);
      expect(threeColRow.is2Column, isFalse);

      // 2-column row: no serialNo, has questionText and inputFields
      const twoColRow = TableRowVm(
        rowIndex: 11,
        rowType: 'QUESTION_ANSWER',
        serialNo: null,
        questionText: 'Land',
        inputFields: [
          InputFieldVm(key: 'LAND_VAL', questionText: 'Land', fieldType: 'TEXT'),
        ],
        rawCells: [],
      );
      expect(twoColRow.is2Column, isTrue);
      expect(twoColRow.is3Column, isFalse);

      // Section header row: no input fields
      const sectionHeaderRow = TableRowVm(
        rowIndex: 10,
        rowType: 'QUESTION_ANSWER',
        serialNo: '10',
        questionText: 'Summary of Valuation',
        inputFields: [],
        rawCells: [],
      );
      expect(sectionHeaderRow.isSectionHeadingRow, isTrue);
    });

    test('New Issue: Explicit <<COMPOSITE_PROPERTY_TABLE>> Detection and Classification', () {
      // 1. Explicit key detection with angle brackets
      const bracketField = InputFieldVm(
        key: '<<COMPOSITE_PROPERTY_TABLE>>',
        questionText: 'Assessment of Property Value',
        fieldType: 'TEXT',
      );
      expect(bracketField.isCompositeTable, isTrue);
      expect(bracketField.isImage, isFalse, reason: 'Must NOT be classified as Image');
      expect(bracketField.isDate, isFalse, reason: 'Must NOT be classified as Date');
      expect(bracketField.isMultiline, isFalse, reason: 'Must NOT be classified as Multiline');
      expect(bracketField.isNumber, isFalse, reason: 'Must NOT be classified as Number');

      // 2. Explicit key detection without angle brackets
      const cleanField = InputFieldVm(
        key: 'COMPOSITE_PROPERTY_TABLE',
        questionText: 'Valuation Details',
        fieldType: 'TEXT',
      );
      expect(cleanField.isCompositeTable, isTrue);
      expect(cleanField.isImage, isFalse);

      // 3. Explicit fieldType detection (DYNAMIC_COMPOSITE_PROPERTY_TABLE)
      const typedField = InputFieldVm(
        key: 'CUSTOM_TABLE_REF',
        questionText: 'Property Table',
        fieldType: 'DYNAMIC_COMPOSITE_PROPERTY_TABLE',
      );
      expect(typedField.isCompositeTable, isTrue);
      expect(typedField.isImage, isFalse);

      // 4. Must NOT be inferred from questionText/label
      const falseField = InputFieldVm(
        key: 'SOME_TEXT_FIELD',
        questionText: 'Composite Property Table Remarks',
        fieldType: 'TEXT',
      );
      expect(falseField.isCompositeTable, isFalse,
          reason: 'Must NOT infer composite table from questionText');

      // 5. TableRowVm detects hasCompositeTable
      const compositeRow = TableRowVm(
        rowIndex: 5,
        rowType: 'QUESTION_ANSWER',
        questionText: 'Valuation Assessment',
        inputFields: [cleanField],
      );
      expect(compositeRow.hasCompositeTable, isTrue);

      // 6. DOM parsing routes StudioTable with COMPOSITE_PROPERTY_TABLE to ValuationCompositeBlockVm
      final domWithTable = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION SUMMARY',
            elements: [
              StudioTable(
                id: 'table_composite',
                rowCount: 1,
                columnCount: 1,
                rows: [
                  StudioTableRow(
                    rowIndex: 0,
                    cells: [
                      StudioTableCell(
                        cellId: 'c0',
                        plainText: '<<COMPOSITE_PROPERTY_TABLE>>',
                        placeholderBindings: [
                          PlaceholderBinding(
                            key: 'COMPOSITE_PROPERTY_TABLE',
                            fieldType: 'DYNAMIC_COMPOSITE_PROPERTY_TABLE',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(
            key: 'COMPOSITE_PROPERTY_TABLE',
            label: 'Composite Table',
            occurrences: 1,
            type: 'DYNAMIC_COMPOSITE_PROPERTY_TABLE',
          ),
        ],
      );

      final vm = DocumentWorkspaceVm.fromDocumentDom(domWithTable, {});
      expect(vm.sections.first.orderedBlocks.any((b) => b is ValuationCompositeBlockVm), isTrue,
          reason: 'StudioTable containing <<COMPOSITE_PROPERTY_TABLE>> must emit ValuationCompositeBlockVm');

      // 7. Regression check: standard placeholders remain completely unaffected
      const propPhoto = InputFieldVm(key: 'PROPERTY_PHOTO', questionText: 'Photo', fieldType: 'TEXT');
      const valuerSelfie = InputFieldVm(key: 'VALUER_SELFIE', questionText: 'Selfie', fieldType: 'TEXT');
      const bldgPlan = InputFieldVm(key: 'BUILDING_PLAN', questionText: 'Building plan', fieldType: 'TEXT');
      const floorPlan = InputFieldVm(key: 'FLOOR_PLAN', questionText: 'Floor plan', fieldType: 'TEXT');
      const remarks = InputFieldVm(key: 'REMARKS', questionText: 'Remarks', fieldType: 'MULTILINE');
      const desc = InputFieldVm(key: 'DESCRIPTION', questionText: 'Description', fieldType: 'TEXT');
      const comments = InputFieldVm(key: 'COMMENTS', questionText: 'Comments', fieldType: 'TEXT');

      expect(propPhoto.isImage, isTrue);
      expect(propPhoto.isCompositeTable, isFalse);

      expect(valuerSelfie.isImage, isTrue);
      expect(valuerSelfie.isCompositeTable, isFalse);

      expect(bldgPlan.isImage, isFalse);
      expect(bldgPlan.isCompositeTable, isFalse);

      expect(floorPlan.isImage, isFalse);
      expect(floorPlan.isCompositeTable, isFalse);

      expect(remarks.isImage, isFalse);
      expect(remarks.isCompositeTable, isFalse);

      expect(desc.isImage, isFalse);
      expect(desc.isCompositeTable, isFalse);

      expect(comments.isImage, isFalse);
      expect(comments.isCompositeTable, isFalse);
    });
  });
}
