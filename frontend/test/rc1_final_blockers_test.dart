import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';

void main() {
  testWidgets('BLOCKER 1: Date picker instant selection without OK confirmation button', (tester) async {
    final provider = DocumentWorkspaceProvider();
    final dateField = InputFieldVm(
      key: 'VALUATION_DATE',
      questionText: 'Date of Valuation Inspection',
      fieldType: 'DATE',
      occurrences: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
            value: provider,
            child: DocumentInputSlotWidget(fieldVm: dateField),
          ),
        ),
      ),
    );

    // Initial state: date field with calendar icon
    expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);

    // Tap on calendar icon
    await tester.tap(find.byIcon(Icons.calendar_today_rounded));
    await tester.pumpAndSettle();

    // Verify CalendarDatePicker dialog is shown with title
    expect(find.text('Date of Valuation Inspection'), findsOneWidget);
    expect(find.byType(CalendarDatePicker), findsOneWidget);
    // Verify NO OK or Apply button exists in the dialog
    expect(find.text('OK'), findsNothing);
    expect(find.text('APPLY'), findsNothing);
    expect(find.text('SUBMIT'), findsNothing);

    // Tap on day '15' in CalendarDatePicker
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    // Verify dialog has automatically closed immediately upon date selection
    expect(find.byType(CalendarDatePicker), findsNothing);

    // Verify formatted date in dd-MMM-yyyy format
    final val = provider.getValue('VALUATION_DATE');
    expect(val, isNotNull);
    expect(val, contains('15-'));
    expect(val, matches(RegExp(r'^\d{2}-[A-Za-z]{3}-\d{4}$')));
  });

  testWidgets('BLOCKER 3: Render Image Upload Controls and dropzone for IMAGE fieldType', (tester) async {
    final provider = DocumentWorkspaceProvider();
    final imageField = InputFieldVm(
      key: 'IMG_FRONT_PAGE',
      questionText: 'Upload Property Front Elevation Photograph',
      fieldType: 'IMAGE',
      occurrences: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
            value: provider,
            child: DocumentInputSlotWidget(fieldVm: imageField),
          ),
        ),
      ),
    );

    // Verify Image Upload UI controls are rendered
    expect(find.text('Upload Property Front Elevation Photograph'), findsOneWidget);
    expect(find.text('Upload Image'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });
}
