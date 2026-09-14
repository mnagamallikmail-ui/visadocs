import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';

void main() {
  group('CRITICAL WORKSPACE PERFORMANCE, COMPOSITE TABLE & REAL-TIME SYNC TESTS', () {
    late DocumentWorkspaceProvider provider;

    setUp(() {
      provider = DocumentWorkspaceProvider();
    });

    test('TEST A: Input 1425 sft immediately updates Composite Property Table Quantity to 1425', () {
      final model = DocumentWorkspaceModel(
        orderId: 101,
        reportNumber: 'ORD-101',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat/Unit',
          'VALUATION_METHODOLOGY': 'COMPOSITE',
          'SALEABLE_AREA': '1000',
        },
      );
      provider.setWorkspaceModelForTest(model);

      // Verify initial main unit exists
      provider.ensureCompositeMainUnit();
      expect(provider.compositeItems.isNotEmpty, isTrue);

      // User enters: "1425 sft"
      provider.updateValue('SALEABLE_AREA', '1425 sft');

      // Check Composite Property Table quantity
      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnit.quantity, equals(1425.0), reason: 'Composite Property Table Quantity must be exactly 1425');
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1425'), reason: 'Only numeric value carried forward');
      expect(provider.getValue('SALEABLE_AREA_UNIT').toUpperCase(), equals('SQFT'));
    });

    test('TEST B: Input 1425 sqft immediately updates Composite Property Table Quantity to 1425', () {
      final model = DocumentWorkspaceModel(
        orderId: 102,
        reportNumber: 'ORD-102',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat/Unit',
          'VALUATION_METHODOLOGY': 'COMPOSITE',
        },
      );
      provider.setWorkspaceModelForTest(model);

      // User enters: "1425 sqft"
      provider.updateValue('SALEABLE_AREA', '1425 sqft');

      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnit.quantity, equals(1425.0), reason: 'Composite Property Table Quantity must be exactly 1425');
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1425'));
    });

    test('TEST C: Persistence - Reopen preserves 1425 in Composite Property Table without fallback to zero', () {
      // Simulate reload with database persisted values
      final reopenedModel = DocumentWorkspaceModel(
        orderId: 103,
        reportNumber: 'ORD-103',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat/Unit',
          'VALUATION_METHODOLOGY': 'COMPOSITE',
          'SALEABLE_AREA': '1425 sq ft',
          'SALEABLE_AREA_NUMERIC': '1425',
          'SALEABLE_AREA_STANDARD_SQFT': '1425',
          'RAW_COMPOSITE_ITEMS_JSON': '[{"itemCategory":"MAIN_UNIT","description":"Commercial Unit","enteredUnit":"Sq.Ft","quantity":1425.0,"rate":5000.0,"amount":7125000.0,"depreciationAmount":0.0,"fairValue":7125000.0}]',
        },
      );

      final reopenedProvider = DocumentWorkspaceProvider();
      reopenedProvider.setWorkspaceModelForTest(reopenedModel);

      final rehydratedMainUnit = reopenedProvider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(rehydratedMainUnit.quantity, equals(1425.0), reason: 'Reopened table must still show 1425 without fallback to 0');
    });

    test('TEST I: Fast continuous typing into text inputs does not rebuild entire DOM or freeze workspace', () {
      final docDom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Section 1',
            elements: [
              StudioParagraph(
                id: 'p_1',
                runs: [
                  const StudioRun(text: 'Client Name: '),
                  const StudioRun(text: '<<CLIENT_NAME>>', isPlaceholder: true, placeholderKey: 'CLIENT_NAME'),
                ],
              ),
            ],
          )
        ],
        placeholdersSummary: [
          const PlaceholderSummaryItem(key: 'CLIENT_NAME', label: 'Client Name', occurrences: 1, type: 'TEXT', questionText: 'Client Name'),
        ],
      );

      final model = DocumentWorkspaceModel(
        orderId: 104,
        reportNumber: 'ORD-104',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        documentDom: docDom,
        values: {'CLIENT_NAME': 'Initial'},
      );
      provider.setWorkspaceModelForTest(model);

      final initialVm = provider.workspaceVm;
      expect(initialVm, isNotNull);

      int listenerNotificationCount = 0;
      provider.addListener(() {
        listenerNotificationCount++;
      });

      // Type 10 characters with notify: false (continuous typing in text input)
      final characters = ' ABCDEFGHIJ';
      for (int i = 0; i < characters.length; i++) {
        provider.updateValue('CLIENT_NAME', 'Initial${characters.substring(0, i + 1)}', notify: false);
      }

      // Assert: provider listeners were NOT inundated with notifications on every single key
      expect(listenerNotificationCount, equals(0), reason: 'Continuous plain text typing must not flood listeners');

      // Assert: DocumentWorkspaceVm was NOT destructively reconstructed
      expect(identical(provider.workspaceVm, initialVm), isTrue, reason: 'DocumentWorkspaceVm must NOT be re-parsed on keystrokes');

      // Focus lost / blur notification
      provider.notifyChanges();
      expect(listenerNotificationCount, equals(1));
    });

    test('TEST J: Modify Saleable Area updates Composite Property Table in real-time without save or reload', () {
      final model = DocumentWorkspaceModel(
        orderId: 105,
        reportNumber: 'ORD-105',
        status: 'PA_ASSIGNED',
        visualPreview: VisualPreviewModel.fromJson({}),
        values: {
          'PROPERTY_CATEGORY': 'Commercial Flat/Unit',
          'VALUATION_METHODOLOGY': 'COMPOSITE',
          'SALEABLE_AREA': '1000',
          'MARKET_RATE_FLAT': '5000',
        },
      );
      provider.setWorkspaceModelForTest(model);

      final mainUnit = provider.compositeItems.firstWhere((i) => i.itemCategory == 'MAIN_UNIT');
      expect(mainUnit.quantity, equals(1000.0));

      // Modify Saleable Area
      provider.updateValue('SALEABLE_AREA', '1850.5 sft');

      // Immediate real-time update in memory
      expect(mainUnit.quantity, equals(1850.5));
      expect(provider.getValue('SALEABLE_AREA_NUMERIC'), equals('1850.5'));
    });
  });
}
