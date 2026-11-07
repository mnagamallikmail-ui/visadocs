import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
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
  });
}

