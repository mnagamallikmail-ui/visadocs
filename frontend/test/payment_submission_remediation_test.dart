import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:provaluer_frontend/providers/order_provider.dart';
import 'package:provaluer_frontend/features/quotations/client_payment_submission_modal.dart';

class FakeOrderProvider extends ChangeNotifier implements OrderProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Map<String, dynamic>?> fetchPaymentDetails(int? orderId) async {
    return {
      'orderId': 99,
      'referenceCode': 'PV-99',
      'quoteNumber': 'QTE-2026-9163',
      'quoteAmount': 10000.0,
      'quoteTax': 1800.0,
      'quoteTotal': 11800.0,
      'status': 'QUOTE_PROVIDED',
      'bankDetails': {
        'beneficiaryName': 'ProValuer Valuation & Advisory Services Pvt Ltd',
        'bankName': 'HDFC Bank Ltd',
        'accountNumber': '50200088912345',
        'ifsc': 'HDFC0001234',
        'upiId': 'provaluer.commercial@hdfcbank',
      },
    };
  }

  Map<String, dynamic>? mockSubmitResult;
  bool submitCalled = false;

  @override
  Future<Map<String, dynamic>?> submitPaymentProof({
    required int orderId,
    required String utrNumber,
    required String paymentMethod,
    required String paymentDate,
    required double amountPaid,
    String? notes,
    required List<int> fileBytes,
    required String filename,
  }) async {
    submitCalled = true;
    return mockSubmitResult;
  }
}

void main() {
  group('P0 Payment Submission Failure Remediation Tests', () {
    late FakeOrderProvider fakeOrderProvider;

    setUp(() {
      fakeOrderProvider = FakeOrderProvider();
    });

    testWidgets('Scenario A: No file selected blocks submission and displays error', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: fakeOrderProvider,
            child: const Scaffold(
              body: ClientPaymentSubmissionModal(orderId: 99),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter UTR
      await tester.enterText(find.byType(TextFormField).at(0), 'UTR1791248001');
      await tester.pumpAndSettle();

      // Submit without picking a file
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Payment Proof'));
      await tester.pumpAndSettle();

      // API must NOT be called
      expect(fakeOrderProvider.submitCalled, isFalse);

      // Validation error must be visible
      expect(find.text('Payment proof document (PDF/Image) is required.'), findsOneWidget);
    });

    testWidgets('Scenario B: API failure (400) displays error and does NOT show false success', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeOrderProvider.mockSubmitResult = {
        'error': 'File signature mismatch: Content does not match declared extension: .png'
      };

      final validPng = PlatformFile(
        name: 'receipt.png',
        size: 1024,
        bytes: Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: fakeOrderProvider,
            child: Scaffold(
              body: ClientPaymentSubmissionModal(
                orderId: 99,
                initialFileForTesting: validPng,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter UTR
      await tester.enterText(find.byType(TextFormField).at(0), 'UTR1791248001');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Payment Proof'));
      await tester.pumpAndSettle();

      expect(fakeOrderProvider.submitCalled, isTrue);

      // Must show failure error message
      expect(find.textContaining('Payment submission failed.'), findsOneWidget);
      expect(find.textContaining('File signature mismatch'), findsOneWidget);

      // Must NOT show false success snackbar
      expect(find.textContaining('Payment submitted successfully'), findsNothing);
    });

    testWidgets('Scenario C: Successful submit (HTTP 200 + saved payment) transitions state', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      fakeOrderProvider.mockSubmitResult = {
        'id': 101,
        'orderId': 99,
        'status': 'SUBMITTED',
        'utrNumber': 'UTR1791248001',
      };

      bool successCallbackCalled = false;

      final validPdf = PlatformFile(
        name: 'bank_receipt.pdf',
        size: 2048,
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<OrderProvider>.value(
            value: fakeOrderProvider,
            child: Scaffold(
              body: ClientPaymentSubmissionModal(
                orderId: 99,
                initialFileForTesting: validPdf,
                onSuccess: () => successCallbackCalled = true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter UTR
      await tester.enterText(find.byType(TextFormField).at(0), 'UTR1791248001');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.widgetWithText(ElevatedButton, 'Submit Payment Proof'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeOrderProvider.submitCalled, isTrue);
      expect(successCallbackCalled, isTrue);

      // True success notification verified
      expect(find.textContaining('Payment submitted successfully'), findsOneWidget);
    });
  });
}
