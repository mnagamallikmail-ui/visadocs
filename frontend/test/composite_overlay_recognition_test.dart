import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_overlay_input_widget.dart';

void main() {
  group('Overlay Mode Composite Table Recognition Verification', () {
    testWidgets('InlineOverlayInputWidget renders COMPOSITE_TABLE badge and never TextFormField', (tester) async {
      final placeholder = VisualPlaceholderModel(
        key: 'COMPOSITE_PROPERTY_TABLE',
        rawText: '<<COMPOSITE_PROPERTY_TABLE>>',
        occurrenceIndex: 0,
        rectangles: [
          const NormalizedRectModel(x: 0.1, y: 0.2, w: 0.4, h: 0.05),
        ],
      );

      final provider = DocumentWorkspaceProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
              value: provider,
              child: Stack(
                children: [
                  InlineOverlayInputWidget(
                    placeholder: placeholder,
                    rect: placeholder.rectangles.first,
                    containerWidth: 800,
                    containerHeight: 1000,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert badge text is rendered
      expect(find.text('Composite Property Table'), findsOneWidget);
      expect(find.byIcon(Icons.apartment_rounded), findsOneWidget);

      // Assert NO TextFormField exists
      expect(find.byType(TextFormField), findsNothing);

      // Tap on the widget
      await tester.tap(find.text('Composite Property Table'));
      await tester.pumpAndSettle();

      // Verify that tapping switched viewMode to tableEdit (which hosts DocumentTableWorkspaceWidget)
      expect(provider.viewMode, equals(WorkspaceViewMode.tableEdit));

      // Assert still NO TextFormField was mounted as an overlay
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('InlineOverlayInputWidget also supports DYNAMIC_COMPOSITE_PROPERTY_TABLE and COMPOSITE_TABLE', (tester) async {
      for (final key in ['DYNAMIC_COMPOSITE_PROPERTY_TABLE', 'COMPOSITE_TABLE', '<<COMPOSITE_PROPERTY_TABLE>>']) {
        final placeholder = VisualPlaceholderModel(
          key: key,
          rawText: key,
          occurrenceIndex: 0,
          rectangles: [
            const NormalizedRectModel(x: 0.1, y: 0.2, w: 0.4, h: 0.05),
          ],
        );

        final provider = DocumentWorkspaceProvider();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                value: provider,
                child: Stack(
                  children: [
                    InlineOverlayInputWidget(
                      placeholder: placeholder,
                      rect: placeholder.rectangles.first,
                      containerWidth: 800,
                      containerHeight: 1000,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Composite Property Table'), findsOneWidget);
        expect(find.byType(TextFormField), findsNothing);
      }
    });
  });
}
