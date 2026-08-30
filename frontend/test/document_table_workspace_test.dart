import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';

void main() {
  group('Document Table Workspace ViewModel Tests', () {
    test('3-Column and 2-Column Table Parsing into Structured ViewModel', () {
      final sampleDomJson = {
        'sections': [
          {
            'sectionIndex': 0,
            'title': '3. Details of Property',
            'elements': [
              {
                'type': 'TABLE',
                'id': 'tbl_2',
                'rowCount': 3,
                'columnCount': 3,
                'rows': [
                  {
                    'rowIndex': 0,
                    'rowType': 'TABLE_HEADER',
                    'cells': [
                      {'cellId': 'tbl_2_r0_c0', 'plainText': 'S.No', 'cellRole': 'HEADER'},
                      {'cellId': 'tbl_2_r0_c1', 'plainText': 'Particulars', 'cellRole': 'HEADER'},
                      {'cellId': 'tbl_2_r0_c2', 'plainText': 'Observed Details', 'cellRole': 'HEADER'},
                    ]
                  },
                  {
                    'rowIndex': 1,
                    'rowType': 'QUESTION_ANSWER',
                    'cells': [
                      {'cellId': 'tbl_2_r1_c0', 'plainText': '1', 'cellRole': 'INDEX'},
                      {'cellId': 'tbl_2_r1_c1', 'plainText': 'Name of owner(s) and address', 'cellRole': 'QUESTION'},
                      {
                        'cellId': 'tbl_2_r1_c2',
                        'plainText': '',
                        'cellRole': 'ANSWER',
                        'placeholderBindings': [
                          {
                            'key': 'CLIENT_NAME',
                            'serialNo': '1',
                            'questionText': 'Name of owner(s) and address',
                            'fieldType': 'TEXT'
                          }
                        ]
                      }
                    ]
                  },
                  {
                    'rowIndex': 2,
                    'rowType': 'QUESTION_ANSWER',
                    'cells': [
                      {'cellId': 'tbl_2_r2_c0', 'plainText': '2', 'cellRole': 'INDEX'},
                      {'cellId': 'tbl_2_r2_c1', 'plainText': 'Postal address of property', 'cellRole': 'QUESTION'},
                      {
                        'cellId': 'tbl_2_r2_c2',
                        'plainText': '',
                        'cellRole': 'ANSWER',
                        'placeholderBindings': [
                          {
                            'key': 'PROPERTY_ADDRESS',
                            'serialNo': '2',
                            'questionText': 'Postal address of property',
                            'fieldType': 'TEXT'
                          }
                        ]
                      }
                    ]
                  }
                ]
              }
            ]
          }
        ],
        'placeholdersSummary': [
          {
            'key': 'CLIENT_NAME',
            'label': 'Client Name',
            'questionText': 'Name of owner(s) and address',
            'serialNo': '1',
            'occurrences': 2,
            'type': 'TEXT'
          },
          {
            'key': 'PROPERTY_ADDRESS',
            'label': 'Property Address',
            'questionText': 'Postal address of property',
            'serialNo': '2',
            'occurrences': 3,
            'type': 'TEXT'
          }
        ]
      };

      final dom = StudioDocumentModel.fromJson(sampleDomJson);
      final initialValues = {'CLIENT_NAME': 'Acme Real Estate'};

      final vm = DocumentWorkspaceVm.fromDocumentDom(dom, initialValues);

      expect(vm.sections.length, 1);
      final section = vm.sections.first;
      expect(section.title, '3. Details of Property');
      expect(section.tables.length, 1);

      final table = section.tables.first;
      expect(table.rows.length, 3);

      // Header row
      expect(table.rows[0].isTableHeader, true);
      expect(table.rows[0].rawCells.length, 3);

      // Row 1 (3-column Question-Answer)
      final row1 = table.rows[1];
      expect(row1.is3Column, true);
      expect(row1.serialNo, '1');
      expect(row1.questionText, 'Name of owner(s) and address');
      expect(row1.inputFields.length, 1);
      expect(row1.inputFields.first.key, 'CLIENT_NAME');
      expect(row1.inputFields.first.currentValue, 'Acme Real Estate');
      expect(row1.inputFields.first.isRepeated, true);
      expect(row1.inputFields.first.occurrences, 2);

      // Row 2 (3-column Question-Answer)
      final row2 = table.rows[2];
      expect(row2.is3Column, true);
      expect(row2.serialNo, '2');
      expect(row2.questionText, 'Postal address of property');
      expect(row2.inputFields.length, 1);
      expect(row2.inputFields.first.key, 'PROPERTY_ADDRESS');
      expect(row2.inputFields.first.currentValue, '');
      expect(row2.inputFields.first.occurrences, 3);

      // Progress computation
      expect(vm.totalFields, 2);
      expect(vm.getCompletedFieldsCount(initialValues), 1);
      expect(vm.getCompletionProgress(initialValues), 0.5);
    });
  });
}
