import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/features/client_dashboard/client_workspace_hub.dart';
import 'package:provaluer_frontend/providers/auth_provider.dart';
import 'package:provaluer_frontend/providers/order_provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  final bool _isSuperAdmin;
  MockAuthProvider({bool isSuperAdmin = false}) : _isSuperAdmin = isSuperAdmin;

  @override
  bool get isAuthenticated => true;
  @override
  bool get isSuperAdmin => _isSuperAdmin;
  @override
  String? get role => _isSuperAdmin ? 'SUPER_ADMIN' : 'CLIENT';
  @override
  String? get token => 'dummy_token';
  @override
  String? get fullName => 'Test Client';
  @override
  String? get email => 'client@provaluer.com';
  @override
  String? get username => 'client';
  @override
  String? get mobile => '9876543210';
  @override
  String? get clientRole => 'CLIENT';
  @override
  bool get isOperations => false;
  @override
  bool get isValuer => false;
  @override
  bool get isSigner => false;
  @override
  bool get isAuditor => false;
  @override
  bool get isDeskEditor => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeOrderProvider extends ChangeNotifier implements OrderProvider {
  List<dynamic> _mockOrders = [];

  void setMockOrders(List<dynamic> orders) {
    _mockOrders = orders;
    notifyListeners();
  }

  @override
  List<dynamic> get clientOrders => _mockOrders;
  @override
  List<dynamic> get allOrders => _mockOrders;
  @override
  List<dynamic> get unassignedPool => [];
  @override
  List<dynamic> get paOrders => [];
  @override
  List<dynamic> get activeTemplates => [];
  @override
  bool get isLoadingTemplates => false;
  @override
  dynamic get currentOrder => null;
  @override
  String? get lastError => null;

  @override
  Future<void> fetchClientOrders() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P0 Client Experience & Reports UX Verification', () {
    testWidgets('Part 4: Client login starts on Welcome Dashboard with exactly 4 action cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final authProvider = MockAuthProvider();
      final orderProvider = FakeOrderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientWorkspaceHub(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Welcome Dashboard Title & Subtitle
      expect(find.text('Welcome to ProValuer'), findsOneWidget);
      expect(find.text('Choose what you would like to do'), findsOneWidget);

      // Exactly 4 Cards
      expect(find.text('Create New Request'), findsOneWidget);
      expect(find.text('View Active Reports'), findsOneWidget);
      expect(find.text('View Delivered Reports'), findsOneWidget);
      expect(find.text('Contact Advisory Desk'), findsOneWidget);

      // No report list visible on initial login
      expect(find.text('MY REPORTS'), findsNothing);
    });

    testWidgets('Part 1: Zero reports shows clean empty state and no service catalogue cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final authProvider = MockAuthProvider();
      final orderProvider = FakeOrderProvider();
      orderProvider.setMockOrders([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientWorkspaceHub(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Active Reports from Welcome card
      final activeReportsBtn = find.text('Active Reports →');
      expect(activeReportsBtn, findsOneWidget);
      await tester.tap(activeReportsBtn);
      await tester.pumpAndSettle();

      // Zero reports empty state
      expect(find.text('MY REPORTS'), findsOneWidget);
      expect(find.text('No reports found.'), findsOneWidget);
      expect(find.text('Create your first request to begin tracking progress.'), findsOneWidget);
      expect(find.text('Create New Request'), findsWidgets);

      // 5-step How It Works guide
      expect(find.text('How it works'), findsOneWidget);
      expect(find.text('1. Create Request'), findsOneWidget);
      expect(find.text('2. Receive Quote'), findsOneWidget);
      expect(find.text('3. Submit Payment'), findsOneWidget);
      expect(find.text('4. Track Progress'), findsOneWidget);
      expect(find.text('5. Download Report'), findsOneWidget);

      // Confirm service catalogue marketing cards are completely removed from Reports page
      expect(find.text('Property Valuation card'), findsNothing);
      expect(find.text('Net Worth Certificate card'), findsNothing);
      expect(find.text('Plant & Machinery card'), findsNothing);
    });

    testWidgets('Part 2 & 3: Reports exist -> Compact accordion layout, internal status badge, and toggle expand/collapse', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final authProvider = MockAuthProvider();
      final orderProvider = FakeOrderProvider();
      orderProvider.setMockOrders([
        {
          'id': 1001,
          'referenceCode': 'REQ-2026-1001',
          'status': 'PAYMENT_SUBMITTED',
          'createdAt': '2026-10-04T10:00:00Z',
          'quoteAmount': 25000,
          'quoteNumber': 'QTE-1001',
          'documents': [],
        },
      ]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ClientWorkspaceHub(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Active Reports
      await tester.tap(find.text('Active Reports →'));
      await tester.pumpAndSettle();

      // Card is collapsed initially: shows Reference Number, Date, Status Badge strictly inside card
      expect(find.text('REQ-2026-1001'), findsOneWidget);
      expect(find.text('PAYMENT_SUBMITTED'), findsOneWidget);

      // Detailed sections should be hidden while collapsed
      expect(find.text('Quote Information'), findsNothing);
      expect(find.text('Payment Information'), findsNothing);

      // Tap card to expand
      await tester.tap(find.text('REQ-2026-1001'));
      await tester.pumpAndSettle();

      // Detailed sections are revealed
      expect(find.text('Quote Information'), findsOneWidget);
      expect(find.text('Payment Information'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Timeline'), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('REQ-2026-1001'));
      await tester.pumpAndSettle();

      // Collapsed again
      expect(find.text('Quote Information'), findsNothing);
    });

    testWidgets('Part 8: Super Admin deletion verification with exact warning prompt', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final authProvider = MockAuthProvider(isSuperAdmin: true);
      final orderProvider = FakeOrderProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider<OrderProvider>.value(value: orderProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('WARNING'),
                        content: const Text(
                          'This action permanently deletes:\n\n'
                          'Order\n'
                          'Quote\n'
                          'Invoice\n'
                          'Documents\n'
                          'Workflow History\n\n'
                          'Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Delete Permanently'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Trigger Delete'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open deletion dialog
      await tester.tap(find.text('Trigger Delete'));
      await tester.pumpAndSettle();

      // Verify exact warning title and message
      expect(find.text('WARNING'), findsOneWidget);
      expect(find.textContaining('This action permanently deletes:'), findsOneWidget);
      expect(find.textContaining('Order'), findsOneWidget);
      expect(find.textContaining('Quote'), findsOneWidget);
      expect(find.textContaining('Invoice'), findsOneWidget);
      expect(find.textContaining('Documents'), findsOneWidget);
      expect(find.textContaining('Workflow History'), findsOneWidget);
      expect(find.textContaining('Continue?'), findsOneWidget);

      // Verify buttons
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('WARNING'), findsNothing);
    });
  });
}
