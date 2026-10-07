import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provaluer_frontend/constants/order_status.dart';
import 'package:provaluer_frontend/theme/app_components.dart';
import 'package:provaluer_frontend/utils/report_list_helper.dart';
import 'package:provaluer_frontend/providers/auth_provider.dart';

class MockAuthProvider extends AuthProvider {
  final int? _mockUserId;
  final String _mockRole;

  MockAuthProvider({required int? userId, required String role})
      : _mockUserId = userId,
        _mockRole = role;

  @override
  int? get userId => _mockUserId;

  @override
  String? get role => _mockRole;

  @override
  bool get isSuperAdmin => _mockRole == 'SUPER_ADMIN';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('P0 Client Download Parity & Status Governance Tests', () {

    test('Canonical OrderStatus registry includes all required statuses and predicates', () {
      expect(OrderStatus.finalDelivery, 'FINAL_DELIVERY');
      expect(OrderStatus.clientDownloaded, 'CLIENT_DOWNLOADED');
      expect(OrderStatus.closed, 'CLOSED');
      expect(OrderStatus.deliveryReady, 'DELIVERY_READY');
      expect(OrderStatus.onHoldPaymentPending, 'ON_HOLD_PAYMENT_PENDING');
      expect(OrderStatus.deliveryDisputed, 'DELIVERY_DISPUTED');
      expect(OrderStatus.workspaceReady, 'WORKSPACE_READY');
      expect(OrderStatus.drafting, 'DRAFTING');
      expect(OrderStatus.actionNeeded, 'ACTION_NEEDED');

      // Delivery predicates
      expect(OrderStatus.isDelivered('FINAL_DELIVERY'), isTrue);
      expect(OrderStatus.isDelivered('CLIENT_DOWNLOADED'), isTrue);
      expect(OrderStatus.isDelivered('CLOSED'), isTrue);
      expect(OrderStatus.isDelivered('DRAFTING'), isFalse);
      expect(OrderStatus.isDelivered('SPA_GATE'), isFalse);

      // Open KPI predicates
      expect(OrderStatus.isOpen('PAYMENT_REJECTED'), isTrue);
      expect(OrderStatus.isOpen('ACTION_NEEDED'), isTrue);
      expect(OrderStatus.isOpen('SPA_CONFIRMED'), isTrue);
      expect(OrderStatus.isOpen('ON_HOLD_PAYMENT_PENDING'), isTrue);
      expect(OrderStatus.isOpen('DELIVERY_READY'), isTrue);
      expect(OrderStatus.isOpen('CLOSED'), isFalse);
    });

    test('Scenario A & C: Completed Reports Filter includes FINAL_DELIVERY, CLIENT_DOWNLOADED, and CLOSED', () {
      final orders = [
        {'id': 1, 'orderNumber': 'PV-001', 'status': 'FINAL_DELIVERY'},
        {'id': 2, 'orderNumber': 'PV-002', 'status': 'CLIENT_DOWNLOADED'},
        {'id': 3, 'orderNumber': 'PV-003', 'status': 'CLOSED'},
        {'id': 4, 'orderNumber': 'PV-004', 'status': 'DRAFTING'},
        {'id': 5, 'orderNumber': 'PV-005', 'status': 'SPA_GATE'},
      ];

      // Completed filter
      final completedOrders = orders.where((o) => OrderStatus.isDelivered(o['status'] as String)).toList();
      expect(completedOrders.length, 3);
      expect(completedOrders.map((o) => o['status']), containsAll(['FINAL_DELIVERY', 'CLIENT_DOWNLOADED', 'CLOSED']));

      // In-progress filter must NOT leak delivery states
      final inProgressOrders = orders.where((o) => !OrderStatus.isDelivered(o['status'] as String)).toList();
      expect(inProgressOrders.length, 2);
      expect(inProgressOrders.map((o) => o['status']), containsAll(['DRAFTING', 'SPA_GATE']));
      expect(inProgressOrders.any((o) => o['status'] == 'CLIENT_DOWNLOADED'), isFalse);
    });

    test('Scenario B: Multiple re-downloads (10 times) maintain client access parity', () {
      String currentStatus = OrderStatus.finalDelivery;

      // First download occurs
      expect(OrderStatus.isDelivered(currentStatus), isTrue);
      currentStatus = OrderStatus.clientDownloaded;

      // 10 subsequent downloads simulated
      for (int i = 1; i <= 10; i++) {
        expect(
          OrderStatus.isDelivered(currentStatus),
          isTrue,
          reason: 'Download #$i must be permitted under CLIENT_DOWNLOADED status',
        );
      }
    });

    test('Scenario D: Search and filtering works across all delivery states', () {
      final orders = [
        {'id': 101, 'clientName': 'Marine Drive Client', 'status': 'FINAL_DELIVERY'},
        {'id': 102, 'clientName': 'Bandra West Client', 'status': 'CLIENT_DOWNLOADED'},
        {'id': 103, 'clientName': 'Worli Sea Face Client', 'status': 'CLOSED'},
      ];

      final marineDrive = ReportListHelper.filterAndSortReports(orders, 'Marine Drive', 'DATE_DESC');
      expect(marineDrive.length, 1);
      expect(marineDrive.first['status'], 'FINAL_DELIVERY');

      final bandra = ReportListHelper.filterAndSortReports(orders, 'Bandra', 'DATE_DESC');
      expect(bandra.length, 1);
      expect(bandra.first['status'], 'CLIENT_DOWNLOADED');

      final worli = ReportListHelper.filterAndSortReports(orders, 'Worli', 'DATE_DESC');
      expect(worli.length, 1);
      expect(worli.first['status'], 'CLOSED');
    });

    testWidgets('Fix 4: Status badge renders dedicated visual support without error', (tester) async {
      final statuses = [
        'CLIENT_DOWNLOADED',
        'DELIVERY_READY',
        'ON_HOLD_PAYMENT_PENDING',
        'DELIVERY_DISPUTED',
        'CLOSED',
        'FINAL_DELIVERY',
        'SPA_CONFIRMED',
      ];

      for (final st in statuses) {
        final badge = AppComponents.statusBadge(st);
        expect(badge, isNotNull);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: badge)));
        expect(find.byWidget(badge), findsOneWidget);
      }
    });

    test('Fix 6: ReportListHelper isFinalized recognizes CLIENT_DOWNLOADED and CLOSED', () {
      final clientDownloadedOrder = {'status': 'CLIENT_DOWNLOADED', 'adminCreated': false, 'clientId': 10};
      final closedOrder = {'status': 'CLOSED', 'adminCreated': false, 'clientId': 10};

      // Mock user context
      final clientAuth = MockAuthProvider(role: 'CLIENT', userId: 10);
      final adminAuth = MockAuthProvider(role: 'SUPER_ADMIN', userId: 1);

      // Super admin can manage finalized, client cannot delete finalized
      expect(ReportListHelper.canDeleteReport(clientDownloadedOrder, clientAuth), isFalse);
      expect(ReportListHelper.canDeleteReport(clientDownloadedOrder, adminAuth), isTrue);

      expect(ReportListHelper.canDeleteReport(closedOrder, clientAuth), isFalse);
      expect(ReportListHelper.canDeleteReport(closedOrder, adminAuth), isTrue);
    });
  });
}
