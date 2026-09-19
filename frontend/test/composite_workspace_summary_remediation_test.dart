import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Composite Workspace Summary Remediation Verification', () {
    testWidgets('TEST 1: Composite Template renders 2-column summary and suppresses Land/Building columns', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final provider = DocumentWorkspaceProvider();

      // Configure composite order workspace
      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION SECTION',
            elements: [
              StudioParagraph(
                id: 'p_composite',
                runs: [
                  StudioRun(
                    text: '<<COMPOSITE_PROPERTY_TABLE>>',
                    isPlaceholder: true,
                    placeholderKey: 'COMPOSITE_PROPERTY_TABLE',
                  ),
                ],
              ),
              StudioParagraph(
                id: 'p_summary',
                runs: [
                  StudioRun(
                    text: '<<VALUATION_SUMMARY_TABLE>>',
                    isPlaceholder: true,
                    placeholderKey: 'VALUATION_SUMMARY_TABLE',
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
          PlaceholderSummaryItem(
            key: 'VALUATION_SUMMARY_TABLE',
            label: 'Summary Table',
            occurrences: 1,
            type: 'DYNAMIC_VALUATION_SUMMARY_TABLE',
          ),
        ],
      );

      final model = DocumentWorkspaceModel(
        orderId: 101,
        status: 'ASSIGNED',
        reportNumber: 'PV-COMP-101',
        values: {
          'VALUATION_METHODOLOGY': 'COMPOSITE',
          'PROPERTY_CATEGORY': 'Flat / Apartment',
          'SALEABLE_AREA': '1200',
          'SALEABLE_RATE': '7150',
          'REALIZABLE_PERCENTAGE': '85.0',
          'DISTRESS_SALE_PERCENTAGE': '75.0',
        },
        readOnly: false,
        documentDom: dom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      provider.setWorkspaceModelForTest(model);
      expect(provider.isCompositeProperty, isTrue);

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

      // 1. Single composite summary appears at <<VALUATION_SUMMARY_TABLE>>
      expect(find.text('<<VALUATION_SUMMARY_TABLE>>'), findsOneWidget);
      expect(find.text('VALUATION PARAMETERS SUMMARY'), findsOneWidget);

      // 2. 2-Column header is rendered (VALUATION PARAMETER in summary; AMOUNT (₹) in both composite table and summary card)
      expect(find.text('VALUATION PARAMETER'), findsOneWidget);
      expect(find.text('AMOUNT (₹)'), findsNWidgets(2));

      // 3. No LAND / BUILDING / TOTAL 4-column headers
      expect(find.text('LAND (₹)'), findsNothing);
      expect(find.text('BUILDING (₹)'), findsNothing);
      expect(find.text('TOTAL (₹)'), findsNothing);

      // 4. No separate Land + Building rows
      expect(find.text('Fair Market Value (Say Land + Say Bldg)'), findsNothing);
      expect(find.textContaining('85% Land, 85% Bldg'), findsNothing);
      expect(find.textContaining('75% Land, 75% Bldg'), findsNothing);

      // 5. Composite rows are displayed
      expect(find.text('Fair Value'), findsOneWidget);
      expect(find.textContaining('Realizable Value'), findsOneWidget);
      expect(find.textContaining('Distress Sale Value'), findsOneWidget);
      expect(find.textContaining('Government Value'), findsOneWidget);
      expect(find.textContaining('Insurable Value'), findsOneWidget);
    });

    testWidgets('TEST 2: Land and Building Template retains 4-column summary', (tester) async {
      final provider = DocumentWorkspaceProvider();

      final dom = StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'VALUATION SECTION',
            elements: [
              StudioParagraph(
                id: 'p_land',
                runs: [
                  StudioRun(
                    text: '<<LAND_TABLE>>',
                    isPlaceholder: true,
                    placeholderKey: 'LAND_TABLE',
                  ),
                ],
              ),
              StudioParagraph(
                id: 'p_bldg',
                runs: [
                  StudioRun(
                    text: '<<BUILDING_TABLE>>',
                    isPlaceholder: true,
                    placeholderKey: 'BUILDING_TABLE',
                  ),
                ],
              ),
              StudioParagraph(
                id: 'p_summary',
                runs: [
                  StudioRun(
                    text: '<<VALUATION_SUMMARY_TABLE>>',
                    isPlaceholder: true,
                    placeholderKey: 'VALUATION_SUMMARY_TABLE',
                  ),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(
            key: 'LAND_TABLE',
            label: 'Land Table',
            occurrences: 1,
            type: 'DYNAMIC_LAND_TABLE',
          ),
          PlaceholderSummaryItem(
            key: 'BUILDING_TABLE',
            label: 'Building Table',
            occurrences: 1,
            type: 'DYNAMIC_BUILDING_TABLE',
          ),
          PlaceholderSummaryItem(
            key: 'VALUATION_SUMMARY_TABLE',
            label: 'Summary Table',
            occurrences: 1,
            type: 'DYNAMIC_VALUATION_SUMMARY_TABLE',
          ),
        ],
      );

      final model = DocumentWorkspaceModel(
        orderId: 102,
        status: 'ASSIGNED',
        reportNumber: 'PV-LB-102',
        values: {
          'VALUATION_METHODOLOGY': 'LAND_BUILDING',
          'PROPERTY_CATEGORY': 'Independent House',
          'LAND_AREA': '2400',
          'LAND_RATE': '5000',
        },
        readOnly: false,
        documentDom: dom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 1,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      provider.setWorkspaceModelForTest(model);
      expect(provider.isCompositeProperty, isFalse);

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

      // Land & Building 4-column headers MUST be visible
      expect(find.text('LAND (₹)'), findsWidgets);
      expect(find.text('BUILDING (₹)'), findsWidgets);
      expect(find.text('TOTAL (₹)'), findsWidgets);
      expect(find.text('SUMMARY OF VALUATION'), findsOneWidget);
    });
  });
}
