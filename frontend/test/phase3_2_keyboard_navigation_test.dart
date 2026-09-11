import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/services/placeholder_registry.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';

void main() {
  group('Phase 3.2: Keyboard-First Placeholder Navigation', () {
    test('PlaceholderRegistry Unit Test: Document Ordering, Traversal, and Uniqueness', () {
      final registry = PlaceholderRegistry();

      bool p1Active = false;
      bool p2Active = false;
      bool p3Active = false;

      registry.register(PlaceholderRegistration(
        id: 'p1_BANK_NAME',
        key: 'BANK_NAME',
        onActivate: () => p1Active = true,
        onDeactivate: () => p1Active = false,
      ));

      registry.register(PlaceholderRegistration(
        id: 'p1_OWNER_NAME',
        key: 'OWNER_NAME',
        onActivate: () => p2Active = true,
        onDeactivate: () => p2Active = false,
      ));

      registry.register(PlaceholderRegistration(
        id: 'p2_PROPERTY_ADDRESS',
        key: 'PROPERTY_ADDRESS',
        onActivate: () => p3Active = true,
        onDeactivate: () => p3Active = false,
      ));

      // 1. Verify Ordering
      expect(registry.entries.length, 3);
      expect(registry.entries[0].id, 'p1_BANK_NAME');
      expect(registry.entries[1].id, 'p1_OWNER_NAME');
      expect(registry.entries[2].id, 'p2_PROPERTY_ADDRESS');

      // 2. Set Active Uniqueness
      registry.setActive('p1_BANK_NAME');
      expect(registry.activeId, 'p1_BANK_NAME');

      // 3. Next Navigation: Bank -> Owner
      registry.next('p1_BANK_NAME');
      expect(registry.activeId, 'p1_OWNER_NAME');
      expect(p2Active, isTrue);

      // 4. Next Navigation: Owner -> Address
      registry.next('p1_OWNER_NAME');
      expect(registry.activeId, 'p2_PROPERTY_ADDRESS');
      expect(p3Active, isTrue);

      // 5. Previous Navigation: Address -> Owner
      registry.previous('p2_PROPERTY_ADDRESS');
      expect(registry.activeId, 'p1_OWNER_NAME');
      expect(p2Active, isTrue);

      // 6. Deregistration
      registry.unregister('p1_OWNER_NAME');
      expect(registry.entries.length, 2);
      expect(registry.entries.any((e) => e.id == 'p1_OWNER_NAME'), isFalse);
    });

    testWidgets('Enter Key = Commit Current + Automatically Activate Next Placeholder', (tester) async {
      final docDom = const StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Borrower & Bank Section',
            elements: [
              StudioParagraph(
                id: 'p_letter',
                runs: [
                  StudioRun(text: 'Dear '),
                  StudioRun(text: '<<BANK_NAME>>', isPlaceholder: true, placeholderKey: 'BANK_NAME'),
                  StudioRun(text: ', Property owned by '),
                  StudioRun(text: '<<OWNER_NAME>>', isPlaceholder: true, placeholderKey: 'OWNER_NAME'),
                  StudioRun(text: ' is valued.'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'BANK_NAME', label: 'Bank Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'OWNER_NAME', label: 'Owner Name', occurrences: 1),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 401,
        reportNumber: 'VAL-KEYBOARD-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: {
          'BANK_NAME': 'SBI',
          'OWNER_NAME': 'ABC Infra',
        },
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read Mode: 0 TextFields
      expect(find.byType(TextFormField), findsNothing);

      // Tap first field [ SBI ] to enter edit mode
      await tester.tap(find.text('SBI'));
      await tester.pumpAndSettle();

      // Exactly 1 active editor
      expect(find.byType(TextFormField), findsOneWidget);
      expect(provider.placeholderRegistry.activeId, contains('BANK_NAME'));

      // Edit SBI -> HDFC
      await tester.enterText(find.byType(TextFormField), 'HDFC');
      await tester.pump();

      // Press Enter Key
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // VERIFY:
      // 1. BANK_NAME committed to provider
      expect(provider.getValue('BANK_NAME'), 'HDFC');
      // 2. Next placeholder (OWNER_NAME) is now automatically active in edit mode!
      expect(find.byType(TextFormField), findsOneWidget);
      expect(provider.placeholderRegistry.activeId, contains('OWNER_NAME'));
      // 3. User can continue typing immediately without touching the mouse
      await tester.enterText(find.byType(TextFormField), 'XYZ Infrastructure Ltd');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(provider.getValue('OWNER_NAME'), 'XYZ Infrastructure Ltd');
    });

    testWidgets('Tab & Shift+Tab Navigation across Consecutive Placeholders', (tester) async {
      final docDom = const StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Continuous Form Section',
            elements: [
              StudioParagraph(
                id: 'p_flow',
                runs: [
                  StudioRun(text: 'Name: '),
                  StudioRun(text: '<<FIRST_NAME>>', isPlaceholder: true, placeholderKey: 'FIRST_NAME'),
                  StudioRun(text: ' <<LAST_NAME>>', isPlaceholder: true, placeholderKey: 'LAST_NAME'),
                  StudioRun(text: ' in <<CITY>>', isPlaceholder: true, placeholderKey: 'CITY'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'FIRST_NAME', label: 'First Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'LAST_NAME', label: 'Last Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'CITY', label: 'City', occurrences: 1),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 402,
        reportNumber: 'VAL-KEYBOARD-002',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: {
          'FIRST_NAME': 'Robert',
          'LAST_NAME': 'Langdon',
          'CITY': 'Florence',
        },
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click FIRST_NAME
      await tester.tap(find.text('Robert'));
      await tester.pumpAndSettle();
      expect(provider.placeholderRegistry.activeId, contains('FIRST_NAME'));

      // Press TAB Key -> moves to LAST_NAME
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, contains('LAST_NAME'));
      expect(find.byType(TextFormField), findsOneWidget);

      // Press TAB Key again -> moves to CITY
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, contains('CITY'));
      expect(find.byType(TextFormField), findsOneWidget);

      // Press SHIFT + TAB Key -> moves backward to LAST_NAME
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(provider.placeholderRegistry.activeId, contains('LAST_NAME'));
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('Esc Key Cancels Changes and Returns to Read Mode', (tester) async {
      final docDom = const StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Cancellation Section',
            elements: [
              StudioParagraph(
                id: 'p_cancel',
                runs: [
                  StudioRun(text: 'Valuer: '),
                  StudioRun(text: '<<VALUER_NAME>>', isPlaceholder: true, placeholderKey: 'VALUER_NAME'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'VALUER_NAME', label: 'Valuer Name', occurrences: 1),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 403,
        reportNumber: 'VAL-KEYBOARD-003',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: {'VALUER_NAME': 'Original Name'},
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentTableWorkspaceWidget(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Click to edit
      await tester.tap(find.text('Original Name'));
      await tester.pumpAndSettle();

      // Type unwanted draft changes
      await tester.enterText(find.byType(TextFormField), 'Accidental Bad Change');
      await tester.pump();

      // Press Escape Key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Edit mode closes
      expect(find.byType(TextFormField), findsNothing);
      // Reverted to original value without modifying provider
      expect(find.text('Original Name'), findsOneWidget);
      expect(provider.getValue('VALUER_NAME'), 'Original Name');
      expect(provider.placeholderRegistry.activeId, isNull);
    });
  });
}
