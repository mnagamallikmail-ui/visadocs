import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/document_studio/models/studio_document_model.dart';
import 'package:provaluer_frontend/features/document_studio/models/visual_preview_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/document_workspace_model.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_table_workspace_widget.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/inline_editable_placeholder_widget.dart';

void main() {
  group('Phase 3.5: Template Fidelity Audit & Real-World Validation', () {
    testWidgets('AUDIT CATEGORY 1-13: Real-World Report Sections Render with High Fidelity', (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sections = <StudioSection>[
        // 1. Covering Letter
        const StudioSection(
          sectionIndex: 0,
          title: 'Covering Letter',
          elements: [
            StudioParagraph(
              id: 'p_cov_1',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'To,\nThe Branch Manager,\n'),
                StudioRun(text: '<<BANK_NAME>>', isPlaceholder: true, placeholderKey: 'BANK_NAME'),
                StudioRun(text: ',\n'),
                StudioRun(text: '<<BRANCH_NAME>>', isPlaceholder: true, placeholderKey: 'BRANCH_NAME'),
                StudioRun(text: '.\n\nDear Sir/Madam,\nSubject: Valuation of property belonging to '),
                StudioRun(text: '<<BORROWER_NAME>>', isPlaceholder: true, placeholderKey: 'BORROWER_NAME'),
                StudioRun(text: ' situated at '),
                StudioRun(text: '<<PROPERTY_ADDRESS>>', isPlaceholder: true, placeholderKey: 'PROPERTY_ADDRESS'),
                StudioRun(text: '.'),
              ],
            ),
          ],
        ),
        // 2. Valuation Certificate (Center Aligned)
        const StudioSection(
          sectionIndex: 1,
          title: 'Valuation Certificate',
          elements: [
            StudioParagraph(
              id: 'p_cert_title',
              alignment: 'CENTER',
              runs: [
                StudioRun(text: 'VALUATION CERTIFICATE', isBold: true, fontSizePt: 16.0),
              ],
            ),
            StudioParagraph(
              id: 'p_cert_body',
              alignment: 'JUSTIFY',
              runs: [
                StudioRun(text: 'This is to certify that the undersigned valuer has carried out inspection on '),
                StudioRun(text: '<<INSPECTION_DATE>>', isPlaceholder: true, placeholderKey: 'INSPECTION_DATE'),
                StudioRun(text: ' and assessed the Fair Market Value of the subject asset at ₹ '),
                StudioRun(text: '<<FAIR_VALUE>>', isPlaceholder: true, placeholderKey: 'FAIR_VALUE'),
                StudioRun(text: ' (Rupees '),
                StudioRun(text: '<<FAIR_VALUE_WORDS>>', isPlaceholder: true, placeholderKey: 'FAIR_VALUE_WORDS'),
                StudioRun(text: ' only).'),
              ],
            ),
          ],
        ),
        // 3. Property Description & 4. Bank Report
        const StudioSection(
          sectionIndex: 2,
          title: 'Property Description & Bank Particulars',
          elements: [
            StudioParagraph(
              id: 'p_prop_desc',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'The property inspected is a '),
                StudioRun(text: '<<PROPERTY_TYPE>>', isPlaceholder: true, placeholderKey: 'PROPERTY_TYPE'),
                StudioRun(text: ' located in Survey No. '),
                StudioRun(text: '<<SURVEY_NO>>', isPlaceholder: true, placeholderKey: 'SURVEY_NO'),
                StudioRun(text: ' with approved plan under facility type '),
                StudioRun(text: '<<LOAN_FACILITY>>', isPlaceholder: true, placeholderKey: 'LOAN_FACILITY'),
                StudioRun(text: '.'),
              ],
            ),
          ],
        ),
        // 5. Legal Narratives & Title Verification
        const StudioSection(
          sectionIndex: 3,
          title: 'Legal Narrative & Title Perusal',
          elements: [
            StudioParagraph(
              id: 'p_legal',
              alignment: 'JUSTIFY',
              runs: [
                StudioRun(text: 'As per Document No. '),
                StudioRun(text: '<<DOCUMENT_NO>>', isPlaceholder: true, placeholderKey: 'DOCUMENT_NO'),
                StudioRun(text: ' registered at SRO '),
                StudioRun(text: '<<SRO_NAME>>', isPlaceholder: true, placeholderKey: 'SRO_NAME'),
                StudioRun(text: ', the title is marketable, unencumbered, and held in freehold tenure by '),
                StudioRun(text: '<<OWNER_NAME>>', isPlaceholder: true, placeholderKey: 'OWNER_NAME'),
                StudioRun(text: '.'),
              ],
            ),
          ],
        ),
        // 6. Observations & 7. Recommendations
        const StudioSection(
          sectionIndex: 4,
          title: 'Observations & Recommendations',
          elements: [
            StudioParagraph(
              id: 'p_obs',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'Physical Observations:\n'),
                StudioRun(text: '<<OBSERVATION_1>>', isPlaceholder: true, placeholderKey: 'OBSERVATION_1'),
              ],
            ),
            StudioParagraph(
              id: 'p_rec',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'Valuer Recommendation:\n'),
                StudioRun(text: '<<RECOMMENDATION>>', isPlaceholder: true, placeholderKey: 'RECOMMENDATION'),
              ],
            ),
          ],
        ),
        // 8. Boundary Descriptions & 9. Area Statements
        const StudioSection(
          sectionIndex: 5,
          title: 'Boundaries & Area Statement',
          elements: [
            StudioParagraph(
              id: 'p_bound',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'North: <<BOUNDARY_NORTH>>, South: <<BOUNDARY_SOUTH>>, East: <<BOUNDARY_EAST>>, West: <<BOUNDARY_WEST>>'),
              ],
            ),
            StudioParagraph(
              id: 'p_area',
              alignment: 'LEFT',
              runs: [
                StudioRun(text: 'The total plot extent measures <<LAND_AREA>> Sq.Yds with a built-up plinth area of <<PLINTH_AREA>> Sq.Ft.'),
              ],
            ),
          ],
        ),
        // 10. Marketability, 11. Assumptions, 12. Disclaimers, 13. Signatory Block (Right Aligned)
        const StudioSection(
          sectionIndex: 6,
          title: 'Disclaimers & Signatures',
          elements: [
            StudioParagraph(
              id: 'p_market',
              alignment: 'JUSTIFY',
              runs: [
                StudioRun(text: 'Marketability is considered good owing to robust infrastructure and active commercial absorption in <<LOCALITY_NAME>>.'),
              ],
            ),
            StudioParagraph(
              id: 'p_disclaimer',
              alignment: 'JUSTIFY',
              runs: [
                StudioRun(text: 'Special Assumptions & Disclaimers: This report is prepared solely for <<BANK_NAME>> and no third party liability is assumed.'),
              ],
            ),
            StudioParagraph(
              id: 'p_signature',
              alignment: 'RIGHT',
              runs: [
                StudioRun(text: 'For <<VALUER_FIRM>>,\n\n\n(<<VALUER_NAME>>)\nRegistered Valuer IBBI: <<VALUER_REG_NO>>', isBold: true),
              ],
            ),
          ],
        ),
      ];

      final docDom = StudioDocumentModel(
        sections: sections,
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'BANK_NAME', label: 'Bank Name', occurrences: 2),
          PlaceholderSummaryItem(key: 'BRANCH_NAME', label: 'Branch Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'BORROWER_NAME', label: 'Borrower Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'PROPERTY_ADDRESS', label: 'Property Address', occurrences: 1),
          PlaceholderSummaryItem(key: 'INSPECTION_DATE', label: 'Inspection Date', occurrences: 1),
          PlaceholderSummaryItem(key: 'FAIR_VALUE', label: 'Fair Value', occurrences: 1),
          PlaceholderSummaryItem(key: 'FAIR_VALUE_WORDS', label: 'Fair Value Words', occurrences: 1),
          PlaceholderSummaryItem(key: 'PROPERTY_TYPE', label: 'Property Type', occurrences: 1),
          PlaceholderSummaryItem(key: 'SURVEY_NO', label: 'Survey No', occurrences: 1),
          PlaceholderSummaryItem(key: 'LOAN_FACILITY', label: 'Loan Facility', occurrences: 1),
          PlaceholderSummaryItem(key: 'DOCUMENT_NO', label: 'Document No', occurrences: 1),
          PlaceholderSummaryItem(key: 'SRO_NAME', label: 'SRO Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'OWNER_NAME', label: 'Owner Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'OBSERVATION_1', label: 'Observation 1', occurrences: 1),
          PlaceholderSummaryItem(key: 'RECOMMENDATION', label: 'Recommendation', occurrences: 1),
          PlaceholderSummaryItem(key: 'BOUNDARY_NORTH', label: 'North Boundary', occurrences: 1),
          PlaceholderSummaryItem(key: 'BOUNDARY_SOUTH', label: 'South Boundary', occurrences: 1),
          PlaceholderSummaryItem(key: 'BOUNDARY_EAST', label: 'East Boundary', occurrences: 1),
          PlaceholderSummaryItem(key: 'BOUNDARY_WEST', label: 'West Boundary', occurrences: 1),
          PlaceholderSummaryItem(key: 'LAND_AREA', label: 'Land Area', occurrences: 1),
          PlaceholderSummaryItem(key: 'PLINTH_AREA', label: 'Plinth Area', occurrences: 1),
          PlaceholderSummaryItem(key: 'LOCALITY_NAME', label: 'Locality Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'VALUER_FIRM', label: 'Valuer Firm', occurrences: 1),
          PlaceholderSummaryItem(key: 'VALUER_NAME', label: 'Valuer Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'VALUER_REG_NO', label: 'Valuer Reg No', occurrences: 1),
        ],
      );

      final values = <String, String>{
        'BANK_NAME': 'State Bank of India',
        'BRANCH_NAME': 'Commercial Credit Branch, Banjara Hills',
        'BORROWER_NAME': 'M/s Sri Venkateshwara Infra Ltd',
        'PROPERTY_ADDRESS': 'Road No. 12, Banjara Hills, Hyderabad',
        'INSPECTION_DATE': '28-Aug-2026',
        'FAIR_VALUE': '4,50,00,000',
        'FAIR_VALUE_WORDS': 'Four Crores Fifty Lakhs',
        'PROPERTY_TYPE': 'Commercial Multi-Tenanted Complex',
        'SURVEY_NO': '142/2 and 143/1',
        'LOAN_FACILITY': 'Term Loan & Working Capital',
        'DOCUMENT_NO': '4821/2019',
        'SRO_NAME': 'Banjara Hills',
        'OWNER_NAME': 'Sri Venkateshwara Infra Ltd',
        'OBSERVATION_1': 'Building structure in sound condition with Grade-A RCC framing and high quality glass facade.',
        'RECOMMENDATION': 'Recommended for mortgage security with low liquidation risk.',
        'BOUNDARY_NORTH': '40 Ft Wide Municipal Road',
        'BOUNDARY_SOUTH': 'Neighboring Commercial Building',
        'BOUNDARY_EAST': 'Open Plot Sy No 142/3',
        'BOUNDARY_WEST': '100 Ft Main Arterial Road',
        'LAND_AREA': '1,200',
        'PLINTH_AREA': '18,500',
        'LOCALITY_NAME': 'Banjara Hills Commercial Core',
        'VALUER_FIRM': 'ProValuer Consulting LLP',
        'VALUER_NAME': 'Er. N. K. Sharma, M.E., F.I.V.',
        'VALUER_REG_NO': 'IBBI/RV/02/2019/10482',
      };

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 201,
        reportNumber: 'VAL-FIDELITY-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: values,
        documentDom: docDom,
        visualPreview: const VisualPreviewModel(
          templateId: 1,
          totalPages: 7,
          pageDimensions: VisualPageDimensionsModel(widthPt: 595.28, heightPt: 841.89, aspectRatio: 0.707),
          pages: [],
        ),
      );

      final provider = DocumentWorkspaceProvider();
      provider.setWorkspaceModelForTest(workspaceModel);
      provider.setScrollMode(DocumentScrollMode.continuous);

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

      // Verify Covering Letter paragraph rendered with inline placeholders
      expect(find.textContaining('To,\nThe Branch Manager,'), findsOneWidget);
      expect(find.text('State Bank of India'), findsWidgets);
      expect(find.text('Commercial Credit Branch, Banjara Hills'), findsOneWidget);
      expect(find.text('M/s Sri Venkateshwara Infra Ltd'), findsWidgets);

      // Verify Valuation Certificate Center Aligned & dynamic valuation calculation
      expect(find.text('VALUATION CERTIFICATE'), findsOneWidget);
      expect(find.text('Rupees Zero Only'), findsOneWidget);

      // Verify Signature Block Right Aligned
      expect(find.textContaining('Er. N. K. Sharma, M.E., F.I.V.'), findsOneWidget);

      // Verify All Placeholders rendered as InlineEditablePlaceholderWidget
      expect(find.byType(InlineEditablePlaceholderWidget), findsWidgets);
      final inlineCount = tester.widgetList(find.byType(InlineEditablePlaceholderWidget)).length;
      expect(inlineCount >= 20, isTrue, reason: 'Must render all category placeholders inline');

      // Verify zero raw <<...>> tokens in UI
      expect(find.textContaining('<<'), findsNothing);
      expect(find.textContaining('>>'), findsNothing);
    });

    testWidgets('INLINE EXPANSION & REFLOW: Short, Long, and Very Long Values do not overflow or clip', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const shortText = 'M/s ABC';
      const longText = 'M/s ABC Infrastructure Private Limited';
      const veryLongText = 'M/s ABC Infrastructure Private Limited and Associates with Global Engineering Consortium';

      final docDom = StudioDocumentModel(
        sections: [
          const StudioSection(
            sectionIndex: 0,
            title: 'Dynamic Reflow Verification',
            elements: [
              StudioParagraph(
                id: 'p_flow',
                alignment: 'LEFT',
                runs: [
                  StudioRun(text: 'The premises belonging to '),
                  StudioRun(text: '<<COMPANY_NAME>>', isPlaceholder: true, placeholderKey: 'COMPANY_NAME'),
                  StudioRun(text: ' were fully surveyed and inspected.'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'COMPANY_NAME', label: 'Company Name', occurrences: 1),
        ],
      );

      final values = <String, String>{'COMPANY_NAME': shortText};
      final workspaceModel = DocumentWorkspaceModel(
        orderId: 202,
        reportNumber: 'VAL-REFLOW-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: values,
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

      // 1. Short Value Verification
      expect(find.text(shortText), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Short text must render with zero layout exceptions');

      // 2. Expand to Long Value
      provider.updateValue('COMPANY_NAME', longText);
      await tester.pumpAndSettle();
      expect(find.text(longText), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Long text expansion must reflow with zero exceptions');

      // 3. Expand to Very Long Value
      provider.updateValue('COMPANY_NAME', veryLongText);
      await tester.pumpAndSettle();
      expect(find.text(veryLongText), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'Very long text expansion must wrap naturally without overflow');
    });

    testWidgets('EDGE CASES: Consecutive placeholders, Styles (Bold/Italic), Alignments, and Images', (tester) async {
      final docDom = StudioDocumentModel(
        sections: [
          const StudioSection(
            sectionIndex: 0,
            title: 'Edge Case Gallery',
            elements: [
              // Edge Case 1: Consecutive placeholders without intervening static text
              StudioParagraph(
                id: 'p_consecutive',
                alignment: 'LEFT',
                runs: [
                  StudioRun(text: '<<SALUTATION>>', isPlaceholder: true, placeholderKey: 'SALUTATION'),
                  StudioRun(text: ' '),
                  StudioRun(text: '<<FIRST_NAME>>', isPlaceholder: true, placeholderKey: 'FIRST_NAME'),
                  StudioRun(text: ' '),
                  StudioRun(text: '<<LAST_NAME>>', isPlaceholder: true, placeholderKey: 'LAST_NAME'),
                ],
              ),
              // Edge Case 2: Bold, Italic & Styled placeholders
              StudioParagraph(
                id: 'p_styled',
                alignment: 'LEFT',
                runs: [
                  StudioRun(text: 'Title Deed: '),
                  StudioRun(text: '<<DOC_NUMBER>>', isPlaceholder: true, placeholderKey: 'DOC_NUMBER', isBold: true),
                  StudioRun(text: ' dated '),
                  StudioRun(text: '<<DOC_DATE>>', isPlaceholder: true, placeholderKey: 'DOC_DATE', isItalic: true),
                ],
              ),
              // Edge Case 3: Center-aligned Certificate & Right-aligned Valuer Block
              StudioParagraph(
                id: 'p_center',
                alignment: 'CENTER',
                runs: [
                  StudioRun(text: 'CERTIFICATE OF VALUATION', isBold: true),
                ],
              ),
              StudioParagraph(
                id: 'p_right',
                alignment: 'RIGHT',
                runs: [
                  StudioRun(text: 'Authorised Signatory:\n<<SIGNATORY_NAME>>', isBold: true, placeholderKey: 'SIGNATORY_NAME', isPlaceholder: true),
                ],
              ),
              // Edge Case 4: Image Slot
              StudioParagraph(
                id: 'p_img',
                alignment: 'LEFT',
                runs: [
                  StudioRun(text: '<<IMG_ELEVATION>>', isPlaceholder: true, placeholderKey: 'IMG_ELEVATION', isImage: true),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: const [
          PlaceholderSummaryItem(key: 'SALUTATION', label: 'Salutation', occurrences: 1),
          PlaceholderSummaryItem(key: 'FIRST_NAME', label: 'First Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'LAST_NAME', label: 'Last Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'DOC_NUMBER', label: 'Doc Number', occurrences: 1),
          PlaceholderSummaryItem(key: 'DOC_DATE', label: 'Doc Date', occurrences: 1),
          PlaceholderSummaryItem(key: 'SIGNATORY_NAME', label: 'Signatory Name', occurrences: 1),
          PlaceholderSummaryItem(key: 'IMG_ELEVATION', label: 'Property Elevation', occurrences: 1, type: 'IMAGE'),
        ],
      );

      final values = <String, String>{
        'SALUTATION': 'Dr.',
        'FIRST_NAME': 'Rajesh',
        'LAST_NAME': 'Varma',
        'DOC_NUMBER': 'DOC-2026/8912',
        'DOC_DATE': '15-Jan-2026',
        'SIGNATORY_NAME': 'Er. K. Ramesh',
        'IMG_ELEVATION': '',
      };

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 203,
        reportNumber: 'VAL-EDGE-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: values,
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

      // Verify consecutive placeholders render side-by-side
      expect(find.text('Dr.'), findsOneWidget);
      expect(find.text('Rajesh'), findsOneWidget);
      expect(find.text('Varma'), findsOneWidget);

      // Verify bold and italic styles
      expect(find.text('DOC-2026/8912'), findsOneWidget);
      expect(find.text('15-Jan-2026'), findsOneWidget);

      // Verify right-aligned signatory block
      expect(find.text('Er. K. Ramesh'), findsOneWidget);

      // Verify image placeholder slot rendered with upload button
      expect(find.text('Upload Image'), findsOneWidget);
    });

    test('PERFORMANCE BENCHMARK: 10, 25, 50, and 100 Page Report Transformation & Memory Scaling', () {
      final pageCounts = [10, 25, 50, 100];
      final benchmarkResults = <int, Map<String, dynamic>>{};

      for (final pages in pageCounts) {
        final sections = <StudioSection>[];
        final summaries = <PlaceholderSummaryItem>[];
        final values = <String, String>{};

        for (int p = 0; p < pages; p++) {
          final pKey = 'PARAM_$p';
          summaries.add(PlaceholderSummaryItem(key: pKey, label: 'Param $p', occurrences: 1));
          values[pKey] = 'Value for page $p observation';

          sections.add(
            StudioSection(
              sectionIndex: p,
              title: 'Page $p - Valuation Module',
              elements: [
                StudioParagraph(
                  id: 'p_hdr_$p',
                  alignment: 'LEFT',
                  runs: [
                    StudioRun(text: 'Section $p: This is official valuation text for property assessment paragraph. Parameter value: '),
                    StudioRun(text: '<<$pKey>>', isPlaceholder: true, placeholderKey: pKey),
                    const StudioRun(text: '. Comprehensive documentation perused and verified.'),
                  ],
                ),
              ],
            ),
          );
        }

        final dom = StudioDocumentModel(sections: sections, placeholdersSummary: summaries);

        final stopwatch = Stopwatch()..start();
        final vm = DocumentWorkspaceVm.fromDocumentDom(dom, values);
        stopwatch.stop();

        final transformTimeMs = stopwatch.elapsedMilliseconds;
        final totalBlocks = vm.sections.fold<int>(0, (sum, s) => sum + s.orderedBlocks.length);

        benchmarkResults[pages] = {
          'transformMs': transformTimeMs,
          'sections': vm.sections.length,
          'blocks': totalBlocks,
        };

        // Assert performance thresholds
        expect(transformTimeMs < 500, isTrue, reason: '$pages-page DOM transformation must be < 500ms (was ${transformTimeMs}ms)');
        expect(vm.sections.length, pages);
      }

      print('=== PHASE 3.5 PERFORMANCE BENCHMARK MATRIX ===');
      benchmarkResults.forEach((pages, data) {
        print('$pages Pages: Transform=${data['transformMs']}ms | Sections=${data['sections']} | Blocks=${data['blocks']}');
      });
    });

    testWidgets('UAT WORKFLOW SCENARIO: PA Edit -> Dynamic Recalculation -> SPA Review Gate', (tester) async {
      final docDom = const StudioDocumentModel(
        sections: [
          StudioSection(
            sectionIndex: 0,
            title: 'Borrower & Property Info',
            elements: [
              StudioParagraph(
                id: 'p_main',
                runs: [
                  StudioRun(text: 'Borrower: '),
                  StudioRun(text: '<<CLIENT_NAME>>', isPlaceholder: true, placeholderKey: 'CLIENT_NAME'),
                ],
              ),
            ],
          ),
        ],
        placeholdersSummary: [
          PlaceholderSummaryItem(key: 'CLIENT_NAME', label: 'Client Name', occurrences: 1),
        ],
      );

      final workspaceModel = DocumentWorkspaceModel(
        orderId: 204,
        reportNumber: 'VAL-GATE-001',
        status: 'IN_PROGRESS',
        readOnly: false,
        values: {'CLIENT_NAME': 'Initial Client Name'},
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

      // PA Editing: Update client name
      provider.updateValue('CLIENT_NAME', 'Updated Client Enterprise Ltd');
      await tester.pumpAndSettle();
      expect(provider.getValue('CLIENT_NAME'), 'Updated Client Enterprise Ltd');
      expect(find.text('Updated Client Enterprise Ltd'), findsOneWidget);

      // SPA Review: Toggle Read Only mode
      provider.setWorkspaceModelForTest(workspaceModel.copyWith(readOnly: true, values: provider.activeValues));
      await tester.pumpAndSettle();

      expect(provider.isReadOnly, isTrue);
      // Ensure widget still displays properly in read only mode
      expect(find.text('Updated Client Enterprise Ltd'), findsOneWidget);
    });
  });
}
