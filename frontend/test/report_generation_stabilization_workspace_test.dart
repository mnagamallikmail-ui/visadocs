import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';

void main() {
  group('Report Generation Stabilization Program - Workspace Zero Phantom Parity Tests', () {
    test('Template Directives are Authoritative: No Synthetic Dynamic Placeholders Injected', () {
      final sampleDomJson = {
        'sections': [
          {
            'title': 'VALUATION OF PROPERTY',
            'pageNumber': 1,
            'elements': [
              {
                'id': 'p_land',
                'type': 'paragraph',
                'runs': [
                  {'text': '<<LAND_TABLE>>', 'isPlaceholder': true, 'placeholderKey': 'LAND_TABLE'}
                ]
              },
              {
                'id': 'p_bldg',
                'type': 'paragraph',
                'runs': [
                  {'text': '<<BUILDING_TABLE>>', 'isPlaceholder': true, 'placeholderKey': 'BUILDING_TABLE'}
                ]
              },
              {
                'id': 'p_summary',
                'type': 'paragraph',
                'runs': [
                  {'text': '<<VALUATION_SUMMARY_TABLE>>', 'isPlaceholder': true, 'placeholderKey': 'VALUATION_SUMMARY_TABLE'}
                ]
              }
            ]
          }
        ],
        'placeholdersSummary': [
          {'key': 'LAND_TABLE', 'type': 'DYNAMIC_TABLE', 'occurrences': 1, 'questionText': 'Land Table'},
          {'key': 'BUILDING_TABLE', 'type': 'DYNAMIC_TABLE', 'occurrences': 1, 'questionText': 'Building Table'},
          {'key': 'VALUATION_SUMMARY_TABLE', 'type': 'DYNAMIC_TABLE', 'occurrences': 1, 'questionText': 'Valuation Summary Table'},
        ]
      };

      final dom = StudioDocumentModel.fromJson(sampleDomJson);

      // Order values with Composite property type
      final initialValues = {
        'PROPERTY_TYPE': 'Flat / Unit (Composite)',
        'RAW_LAND_ITEMS_JSON': '[]',
        'RAW_BUILDING_ITEMS_JSON': '[]',
      };

      final vm = DocumentWorkspaceVm.fromDocumentDom(dom, initialValues);

      expect(vm.sections.length, 1);
      final section = vm.sections.first;

      // Extract all ordered blocks
      final blocks = section.orderedBlocks;
      expect(blocks.length, 3, reason: 'Workspace block count must equal template directive count');

      // Verify physical directives are strictly preserved
      expect(blocks[0], isA<ValuationLandBlockVm>());
      expect(blocks[1], isA<ValuationBuildingBlockVm>());
      expect(blocks[2], isA<ValuationSummaryBlockVm>());

      // Verify ZERO synthetic/phantom placeholders exist in workspace
      expect(blocks.any((b) => b is ValuationCompositeBlockVm), isFalse,
          reason: 'COMPOSITE_PROPERTY_TABLE must not be synthetically injected when not in template');
      expect(blocks.any((b) => b is ValuationPropertyBlockVm), isFalse,
          reason: 'PROPERTY_VALUE_TABLE must not be synthetically injected');
      expect(blocks.any((b) => b is ValuationComparableBlockVm), isFalse,
          reason: 'COMPARABLES_TABLE must not be synthetically injected');

      print('-> Workspace successfully matches Template XML with 100% parity and 0 synthetic placeholders.');
    });
  });
}
