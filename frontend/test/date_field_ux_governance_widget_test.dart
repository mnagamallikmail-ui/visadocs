import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';
import 'package:provaluer_frontend/utils/date_picker_helper.dart';

void main() {
  group('Date Field UX Governance Widget Tests', () {
    testWidgets('1. Click date field in DocumentInputSlotWidget opens Calendar immediately', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'VALUATION_DATE',
        questionText: 'Valuation Date',
        fieldType: 'DATE',
        currentValue: '15-Jan-2027',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Field should show formatted date
      expect(find.text('15-Jan-2027'), findsOneWidget);

      // 1. Click field
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();

      // Calendar must open immediately
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      expect(find.text('Valuation Date'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Clear'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);
    });

    testWidgets('2 & 3. Enter and Space keys on focused DocumentInputSlotWidget open Calendar immediately', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'INSPECTION_DATE',
        questionText: 'Inspection Date',
        fieldType: 'DATE',
        currentValue: '03-Sep-2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Activate registry (simulating Tab/Shift+Tab navigation)
      provider.placeholderRegistry.next('NON_EXISTENT');
      await tester.pumpAndSettle();

      // Send Enter key
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Send Space key
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('4. Single-click date selection auto-closes and populates dd-MMM-yyyy', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'REPORT_DATE',
        questionText: 'Report Date',
        fieldType: 'DATE',
        currentValue: '10-Sep-2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open calendar
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Click day 20 in the calendar grid
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      // Calendar must close automatically
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Date field must be populated with selected date in dd-MMM-yyyy format
      expect(find.text('20-Sep-2026'), findsOneWidget);
      expect(provider.getValue('REPORT_DATE'), '20-Sep-2026');
    });

    testWidgets('5. Click Today button populates current date and auto-closes', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'LEGAL_DATE',
        questionText: 'Legal Date',
        fieldType: 'DATE',
        currentValue: '01-Jan-2020',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open calendar
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Click Today button
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      // Calendar closes automatically
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Value matches today's date formatted
      final expectedToday = DatePickerHelper.formatDate(DateTime.now());
      expect(find.text(expectedToday), findsOneWidget);
      expect(provider.getValue('LEGAL_DATE'), expectedToday);
    });

    testWidgets('6. Click Clear button empties the date field and auto-closes', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'APPLICATION_DATE',
        questionText: 'Application Date',
        fieldType: 'DATE',
        currentValue: '15-Aug-2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const DocumentInputSlotWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15-Aug-2026'), findsOneWidget);

      // Open calendar
      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Click Clear button
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Calendar closes automatically
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Value is now empty
      expect(provider.getValue('APPLICATION_DATE'), '');
    });

    testWidgets('InlineEditablePlaceholderWidget: Click and Calendar Icon open picker immediately without text edit mode', (tester) async {
      final provider = DocumentWorkspaceProvider();
      const fieldVm = InputFieldVm(
        key: 'VISIT_DATE',
        questionText: 'Visit Date',
        fieldType: 'DATE',
        currentValue: '12-May-2026',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: const InlineEditablePlaceholderWidget(fieldVm: fieldVm),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT render a TextFormField in read mode
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text('12-May-2026'), findsOneWidget);

      // Click the inline placeholder badge
      await tester.tap(find.text('12-May-2026'));
      await tester.pumpAndSettle();

      // Calendar opens immediately!
      expect(find.byType(CalendarDatePicker), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);

      // Still in read mode - never switched to manual text edit
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
