import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/privacy/privacy_dashboard_widget.dart';
import 'package:provaluer_frontend/features/privacy/privacy_governance_dashboard.dart';
import 'package:provaluer_frontend/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final dio = ApiService().dio;
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/api/v1/privacy/profile-summary')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'name': 'Aditi Sharma',
                'email': 'aditi@example.com',
                'mobile': '+91 98765 43210',
                'address': 'HITEC City, Hyderabad',
                'ageClassification': 'ADULT_18_PLUS',
                'activeOrdersCount': 2,
                'archivedOrdersCount': 5,
                'uploadedDocumentsCount': 8,
                'dataRetentionStatus': 'ACTIVE_VALUATION_HOLD',
                'activeNoticeVersion': 'DPDP-NOTICE-V1.0',
                'consentStatus': true,
                'processingPurposes': ['Property Valuation', 'Audit Mandate'],
                'thirdPartiesWithAccess': ['Designated Lending Banks', 'Ministry of Corporate Affairs'],
              },
            ));
          }
          if (options.path.contains('/api/v1/admin/privacy/governance-summary')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'openPrivacyRequests': 3,
                'pendingCorrections': 1,
                'activeErasureRequests': 0,
                'openGrievances': 2,
                'activeConsents': 150,
                'complianceHealthScore': '98%',
                'encryptionStatus': 'ACTIVE (AES-256-GCM)',
                'statutoryAct': 'DPDP Act 2023 (India)',
                'dpoName': 'Corporate Compliance Cell',
                'dpoEmail': 'dpo@provaluer.com',
                'grievanceOfficer': 'Grievance Redressal Officer',
                'grievanceEmail': 'grievance@provaluer.com',
                'dpbiSupervisoryAuthority': 'Data Protection Board of India',
              },
            ));
          }
          // Default empty list for arrays
          return handler.resolve(Response(
            requestOptions: options,
            statusCode: 200,
            data: [],
          ));
        },
      ),
    );
  });

  group('DPDP Act 2023 - Batch 3 Frontend Privacy Widgets Test Suite', () {
    testWidgets('1. PrivacyDashboardWidget renders initial state with statutory header', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyDashboardWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Title & Compliance Badge
      expect(find.text('Privacy & My Data'), findsOneWidget);
      expect(find.text('DPDP Act 2023 Compliant'), findsOneWidget);

      // Verify all 7 core statutory tabs
      expect(find.text('Personal Data Summary'), findsOneWidget);
      expect(find.text('My Consents'), findsOneWidget);
      expect(find.text('Download My Data'), findsOneWidget);
      expect(find.text('Correction Requests'), findsOneWidget);
      expect(find.text('Erasure Requests'), findsOneWidget);
      expect(find.text('Nominee Management'), findsOneWidget);
      expect(find.text('Privacy Complaints'), findsOneWidget);

      // Verify Profile Summary data points loaded from mock
      expect(find.text('Aditi Sharma'), findsOneWidget);
      expect(find.text('aditi@example.com'), findsOneWidget);
    });

    testWidgets('2. PrivacyGovernanceDashboard renders Command Center for Super Admin', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyGovernanceDashboard(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Command Center Title
      expect(find.text('Privacy Governance Command Center'), findsOneWidget);
      expect(find.textContaining('DPDP Health Score: 98%'), findsOneWidget);

      // Verify admin quick actions
      expect(find.text('Run Retention Engine'), findsOneWidget);
      expect(find.text('Log Breach Incident'), findsOneWidget);

      // Verify admin tabs
      expect(find.text('Overview & Metrics'), findsOneWidget);
      expect(find.text('Correction Requests'), findsOneWidget);
      expect(find.text('Erasure Requests & Holds'), findsOneWidget);
      expect(find.text('Grievance Redressal'), findsOneWidget);
      expect(find.text('Data Breach Incidents'), findsOneWidget);
      expect(find.text('Retention Policies & Runs'), findsOneWidget);
    });

    testWidgets('3. Tab switching works smoothly in PrivacyDashboardWidget', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PrivacyDashboardWidget(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Download My Data tab
      await tester.tap(find.text('Download My Data'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Section 11(1) — Data Portability & Archive Export'), findsOneWidget);

      // Tap on Nominee Management tab
      await tester.tap(find.text('Nominee Management'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Manage Nominees (DPDP Act Section 14)'), findsOneWidget);

      // Tap on Privacy Complaints tab
      await tester.tap(find.text('Privacy Complaints'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Privacy Complaints & Grievance Redressal'), findsOneWidget);
    });
  });
}
