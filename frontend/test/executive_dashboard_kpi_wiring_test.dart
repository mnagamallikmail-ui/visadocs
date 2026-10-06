import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/superadmin/admin_sections.dart';
import 'package:provaluer_frontend/features/quotations/admin_release_queue_section.dart';
import 'package:provaluer_frontend/providers/auth_provider.dart';
import 'package:provaluer_frontend/providers/order_provider.dart';
import 'package:provaluer_frontend/services/api_service.dart';

class MockAuthProvider extends AuthProvider {
  @override
  bool get isSuperAdmin => true;
  @override
  String? get role => 'SUPER_ADMIN';
  @override
  int? get userId => 1;
}

class MockOrderProvider extends OrderProvider {
  @override
  Future<void> fetchPaymentReviewQueue() async {}
  @override
  Future<void> fetchReleaseQueue() async {}
}

void main() {
  setUp(() {
    final dio = ApiService().dio;
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/overview')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'totalUsers': 12,
                'totalOrders': 25,
                'finalDeliveryOrders': 8,
              },
            ));
          }
          if (options.path.contains('/orders')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {
                  'id': 101,
                  'reportNumber': 'PV-101',
                  'referenceCode': 'REQ-101',
                  'clientName': 'Acme Corp',
                  'quoteNumber': 'QTE-101',
                  'status': 'PAYMENT_VERIFIED',
                  'createdAt': DateTime.now().toIso8601String(),
                  'quoteAmount': 25000.0,
                  'quoteTotal': 29500.0,
                },
                {
                  'id': 102,
                  'reportNumber': 'PV-102',
                  'referenceCode': 'REQ-102',
                  'clientName': 'Global Logistics',
                  'quoteNumber': 'QTE-102',
                  'status': 'QUOTE_PROVIDED',
                  'createdAt': DateTime.now().toIso8601String(),
                  'quoteAmount': 18000.0,
                  'quoteTotal': 21240.0,
                },
                {
                  'id': 103,
                  'reportNumber': 'PV-103',
                  'referenceCode': 'REQ-103',
                  'clientName': 'Prime Towers',
                  'status': 'FINAL_DELIVERY',
                  'createdAt': DateTime.now().toIso8601String(),
                  'quoteAmount': 45000.0,
                  'quoteTotal': 53100.0,
                },
              ],
            ));
          }
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: {},
          ));
        },
      ),
    );
  });

  group('P0 Executive Dashboard KPI Wiring Verification', () {
    testWidgets('All 9 Executive Dashboard KPI Cards are clickable and trigger correct navigation/filters', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1600));

      String? targetMenu;
      Map<String, dynamic>? targetParams;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => MockOrderProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AdminOverviewSection(
                onNavigate: (menuKey, [params]) {
                  targetMenu = menuKey;
                  targetParams = params;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 9 cards are rendered
      expect(find.text('Orders Today'), findsOneWidget);
      expect(find.text('Quotes Issued'), findsOneWidget);
      expect(find.text('Payments Verified'), findsOneWidget);
      expect(find.text('Orders Released'), findsOneWidget);
      expect(find.text('Reports Delivered'), findsOneWidget);
      expect(find.text('Revenue Today'), findsOneWidget);
      expect(find.text('Revenue MTD'), findsOneWidget);
      expect(find.text('Revenue YTD'), findsOneWidget);
      expect(find.text('Average TAT'), findsOneWidget);

      // CARD 1: Orders Today -> Queue Management -> Today's Orders
      await tester.tap(find.text('Orders Today'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('queue'));
      expect(targetParams?['quickFilter'], equals('TODAY'));

      // CARD 2: Quotes Issued -> Queue Management -> QUOTE_PROVIDED / QUOTE_PENDING
      await tester.tap(find.text('Quotes Issued'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('queue'));
      expect(targetParams?['quickFilter'], equals('QUOTES_ISSUED'));

      // CARD 3: Payments Verified -> Queue Management -> PAYMENT_VERIFIED
      await tester.tap(find.text('Payments Verified'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('queue'));
      expect(targetParams?['quickFilter'], equals('PAYMENT_VERIFIED'));

      // CARD 4: Orders Released -> Intake Clearance -> Tab 1 (Released Orders)
      await tester.tap(find.text('Orders Released'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('intake_clearance'));
      expect(targetParams?['tab'], equals(1));

      // CARD 5: Reports Delivered -> Report Control -> FINAL_DELIVERY / CLIENT_DOWNLOADED
      await tester.ensureVisible(find.text('Reports Delivered'));
      await tester.tap(find.text('Reports Delivered'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('reports'));
      expect(targetParams?['filter'], equals('DELIVERED'));

      // CARD 6: Revenue Today -> Report Control -> Today's completed commercial reports
      await tester.ensureVisible(find.text('Revenue Today'));
      await tester.tap(find.text('Revenue Today'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('reports'));
      expect(targetParams?['filter'], equals('REVENUE_TODAY'));

      // CARD 7: Revenue MTD -> Report Control -> Current month
      await tester.ensureVisible(find.text('Revenue MTD'));
      await tester.tap(find.text('Revenue MTD'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('reports'));
      expect(targetParams?['filter'], equals('REVENUE_MTD'));

      // CARD 8: Revenue YTD -> Report Control -> Current financial year
      await tester.ensureVisible(find.text('Revenue YTD'));
      await tester.tap(find.text('Revenue YTD'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('reports'));
      expect(targetParams?['filter'], equals('REVENUE_YTD'));

      // CARD 9: Average TAT -> Opens TAT Breakdown Modal
      await tester.ensureVisible(find.text('Average TAT'));
      await tester.tap(find.text('Average TAT'));
      await tester.pumpAndSettle();
      expect(find.text('Executive Turnaround Time (TAT) Telemetry'), findsOneWidget);
      expect(find.text('STAGE-BY-STAGE VELOCITY'), findsOneWidget);
      expect(find.text('Open SLA Dashboard'), findsOneWidget);

      // Verify SLA Dashboard button navigates to 'sla'
      await tester.tap(find.text('Open SLA Dashboard'));
      await tester.pumpAndSettle();
      expect(targetMenu, equals('sla'));
    });

    testWidgets('AdminQueueSection auto-filters with initialQuickFilter TODAY and QUOTES_ISSUED', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1200));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => MockOrderProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdminQueueSection(initialQuickFilter: 'TODAY'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text("Today's Orders"), findsOneWidget);
      expect(find.text('PV-101'), findsOneWidget);
    });

    testWidgets('AdminReportSection auto-filters with initialFilter DELIVERED and shows filtered reports', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1920, 1200));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => MockOrderProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdminReportSection(initialFilter: 'DELIVERED'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('PV-103'), findsOneWidget);
    });

    testWidgets('AdminReleaseQueueSection correctly initializes with initialTab 1', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>(create: (_) => MockOrderProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AdminReleaseQueueSection(initialTab: 1),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Ready for Pool Release'), findsOneWidget);
    });
  });
}
