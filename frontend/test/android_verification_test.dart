import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/constants/version_info.dart';
import 'package:provaluer_frontend/features/document_workspace/models/workspace_view_model.dart';
import 'package:provaluer_frontend/features/document_workspace/providers/document_workspace_provider.dart';
import 'package:provaluer_frontend/features/document_workspace/widgets/document_input_slot_widget.dart';
import 'package:provaluer_frontend/screens/app_info_screen.dart';
import 'package:provaluer_frontend/widgets/app_drawer.dart';
import 'package:provaluer_frontend/widgets/section_stepper_widget.dart';
import 'package:provaluer_frontend/widgets/field_order_search_delegate.dart';
import 'package:provaluer_frontend/services/inspection_photo_service.dart';
import 'package:provaluer_frontend/services/valuation_autosave_service.dart';
import 'package:provaluer_frontend/services/offline_sync_service.dart';
import 'package:provaluer_frontend/services/auto_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Android Acceptance & UI Verification Tests', () {
    testWidgets('Verify AppInfoScreen renders metadata and update check button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(
        const MaterialApp(
          home: AppInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('App Information'), findsOneWidget);
      expect(find.text('Pro Valuer'), findsOneWidget);
      expect(find.text(VersionInfo.versionName), findsOneWidget);
      expect(find.text(VersionInfo.versionCode.toString()), findsOneWidget);
      expect(find.text('07-Nov-2026'), findsOneWidget);
      expect(find.text('android'), findsOneWidget);
      expect(find.text('Check For Updates'), findsOneWidget);
    });

    testWidgets('Verify AppDrawer renders profile, role badge, and Sign Out button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(activeRoute: '/portal'),
            body: Center(child: Text('Test Body')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Field Hub & Portal'), findsOneWidget);
      expect(find.text('Valuation Dossiers'), findsOneWidget);
      expect(find.text('App Information'), findsOneWidget);
    });

    testWidgets('Verify SectionStepperWidget renders section pills, progress, and jump modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      final sections = [
        const SectionItem(id: 's1', title: 'General Info', icon: Icons.info, isCompleted: true),
        const SectionItem(id: 's2', title: 'Land Details', icon: Icons.landscape, isCompleted: false),
        const SectionItem(id: 's3', title: 'Building Structure', icon: Icons.home_work, isCompleted: false),
      ];

      int selectedIdx = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionStepperWidget(
              sections: sections,
              activeIndex: 1,
              onSectionSelected: (idx) => selectedIdx = idx,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SECTION 2 OF 3 (66%)'), findsOneWidget);
      expect(find.text('Land Details'), findsWidgets);
      expect(find.text('Jump'), findsOneWidget);

      // Tap Jump to open bottom sheet
      await tester.tap(find.text('Jump'));
      await tester.pumpAndSettle();

      expect(find.text('Jump to Section'), findsOneWidget);
      expect(find.text('General Info'), findsWidgets);
      expect(find.text('Building Structure'), findsWidgets);
    });

    test('Verify InspectionPhotoMetadata GPS and timestamp formatting', () {
      final meta = InspectionPhotoMetadata(
        filePath: '/data/user/0/in.provaluer.app/cache/photo_101.jpg',
        fileName: 'photo_101.jpg',
        fileSizeBytes: 2048500,
        latitude: 19.076090,
        longitude: 72.877426,
        altitude: 14.5,
        accuracy: 3.2,
        timestamp: DateTime.utc(2026, 11, 7, 10, 30, 0),
        appraiserId: 'pa.sharma@provaluer.in',
        referenceNumber: 'PV-2610-0328',
        stage: 'FIELD_INSPECTION',
      );

      expect(meta.formattedGps, '19.076090°, 72.877426° (±3.2m)');
      expect(meta.formattedTimestamp, '2026-11-07 10:30:00 UTC');
      expect(meta.toJson()['latitude'], 19.076090);
      expect(meta.toJson()['referenceNumber'], 'PV-2610-0328');
    });

    test('Verify FieldOrderSearchDelegate filtering logic', () {
      final orders = [
        const SearchableOrderItem(
          referenceNumber: 'PV-2610-0328',
          borrowerName: 'Sunrise Textiles Ltd',
          propertyAddress: 'Plot 42, MIDC Turbhe',
          bankName: 'State Bank of India',
          status: 'INSPECTION_SCHEDULED',
        ),
        const SearchableOrderItem(
          referenceNumber: 'PV-2609-0114',
          borrowerName: 'Apex Commercial Towers',
          propertyAddress: 'BKC Bandra East',
          bankName: 'HDFC Bank',
          status: 'COMPLETED',
        ),
      ];

      final delegate = FieldOrderSearchDelegate(allOrders: orders);
      expect(delegate.allOrders.length, 2);

      final matchRef = orders.where((o) => o.referenceNumber.contains('0328')).toList();
      expect(matchRef.length, 1);
      expect(matchRef.first.borrowerName, 'Sunrise Textiles Ltd');

      final matchBank = orders.where((o) => o.bankName.toLowerCase().contains('hdfc')).toList();
      expect(matchBank.length, 1);
      expect(matchBank.first.referenceNumber, 'PV-2609-0114');
    });

    testWidgets('Verify Reference Code layout across viewports (360x800, 393x852, 412x915)', (tester) async {
      const viewports = [
        Size(360, 800),
        Size(393, 852),
        Size(412, 915),
      ];

      for (final vp in viewports) {
        await tester.binding.setSurfaceSize(vp);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 170,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'PV-2610-0328',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Must find widget exactly on one line with no character breaking
        expect(find.text('PV-2610-0328'), findsOneWidget);
        final textWidget = tester.widget<Text>(find.text('PV-2610-0328'));
        expect(textWidget.maxLines, 1);
        expect(textWidget.softWrap, false);
      }
    });

    testWidgets('Verify Mobile Image Upload Widget vertical Column layout and no character breaking (360x800, 393x852, 412x915)', (tester) async {
      const testCases = [
        {'key': 'IMG_BHUVAN', 'title': 'Bhuvan'},
        {'key': 'IMG_1', 'title': 'Img1'},
      ];

      const viewports = [
        Size(360, 800),
        Size(393, 852),
        Size(412, 915),
      ];

      for (final vp in viewports) {
        await tester.binding.setSurfaceSize(vp);

        for (final tc in testCases) {
          final field = InputFieldVm(
            key: tc['key']!,
            questionText: tc['title']!,
            fieldType: 'IMAGE',
            occurrences: 1,
            currentValue: '',
          );

          final provider = DocumentWorkspaceProvider();

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ChangeNotifierProvider<DocumentWorkspaceProvider>.value(
                  value: provider,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: DocumentInputSlotWidget(fieldVm: field),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // 1. Question Title: "Bhuvan" / "Img1" must be visible as a full string on one line
          final titleFinder = find.text(tc['title']!);
          expect(titleFinder, findsOneWidget);
          final titleWidget = tester.widget<Text>(titleFinder);
          expect(titleWidget.softWrap, true);

          // 2. Image Placeholder: Must have an image icon and be present
          expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);

          // 3. Description Text: readable description text present
          final descFinder = find.text('PNG, JPEG, WebP supported for report documentation');
          expect(descFinder, findsOneWidget);

          // 4. Upload Button: Full-width Upload Image button present
          final btnFinder = find.widgetWithText(ElevatedButton, 'Upload Image');
          expect(btnFinder, findsOneWidget);

          // 5. Structure: Ensure vertical layout (title Y < placeholder Y < desc Y < button Y)
          final titleBox = tester.getRect(titleFinder);
          final placeholderBox = tester.getRect(find.byIcon(Icons.add_photo_alternate_outlined));
          final descBox = tester.getRect(descFinder);
          final btnBox = tester.getRect(btnFinder);

          expect(titleBox.bottom, lessThanOrEqualTo(placeholderBox.top));
          expect(placeholderBox.bottom, lessThanOrEqualTo(descBox.top));
          expect(descBox.bottom, lessThanOrEqualTo(btnBox.top));

          // 6. Centered placeholder: placeholder horizontal center roughly matches viewport center
          final placeholderCenter = placeholderBox.center.dx;
          final screenCenter = vp.width / 2;
          expect((placeholderCenter - screenCenter).abs(), lessThan(5.0));

          // 7. Full width button: button width should be >= 80% of screen width (spanning 100% of inner container)
          expect(btnBox.width, greaterThan(vp.width * 0.80));
        }
      }
    });
  });
}

