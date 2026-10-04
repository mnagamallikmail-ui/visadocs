import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/request_intake/client_request_intake_modal.dart';

void main() {
  group('Client Request Intake Modal - End-to-End Navigation Branching', () {
    testWidgets('Selecting Asset Valuation navigates to 5 Asset Valuation submenus and isolates them', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientRequestIntakeModal(initialStep: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 3: Service Selection
      expect(find.text('1. Asset Valuation'), findsOneWidget);
      expect(find.text('2. Net Worth Certification'), findsOneWidget);
      expect(find.text('3. Technical Assessment'), findsOneWidget);

      final nextBtn = find.text('Continue to Asset Category');
      expect(nextBtn, findsOneWidget);
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();

      // Screen 4: Should display 5 Asset Valuation Submenus
      expect(find.text('Real Estate Valuation'), findsOneWidget);
      expect(find.text('Plant & Machinery'), findsOneWidget);
      expect(find.text('Securities & Financial Assets'), findsOneWidget);
      expect(find.text('Business Valuation'), findsOneWidget);
      expect(find.text('Inventory & Current Assets'), findsOneWidget);

      // Must NOT show Net Worth or Technical Assessment options
      expect(find.text('Individual'), findsNothing);
      expect(find.text('Director & Promoter'), findsNothing);
      expect(find.text('Business Entity'), findsNothing);
      expect(find.text('Property Inspection'), findsNothing);
      expect(find.text('Construction Monitoring'), findsNothing);
      expect(find.text('Engineering Assessment'), findsNothing);
      expect(find.text('Insurance & Risk'), findsNothing);
    });

    testWidgets('Selecting Net Worth Certification branches to Applicant Types and isolates other services', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientRequestIntakeModal(initialStep: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 3: Select Net Worth Certification
      final netWorthCard = find.text('2. Net Worth Certification');
      expect(netWorthCard, findsOneWidget);
      await tester.tap(netWorthCard);
      await tester.pumpAndSettle();

      // Verify button dynamically changes to "Continue to Applicant Type"
      final continueBtn = find.text('Continue to Applicant Type');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Screen 4: Must show Net Worth Submenus
      expect(find.text('Individual'), findsOneWidget);
      expect(find.text('Director & Promoter'), findsOneWidget);
      expect(find.text('Business Entity'), findsOneWidget);

      // Must NOT show Land & Building, Plant & Machinery, Securities
      expect(find.text('Land & Building'), findsNothing);
      expect(find.text('Plant & Machinery'), findsNothing);
      expect(find.text('Securities'), findsNothing);
      expect(find.text('Securities & Financial Assets'), findsNothing);
      expect(find.text('Real Estate Valuation'), findsNothing);
      expect(find.text('Property Inspection'), findsNothing);
      expect(find.text('Construction Monitoring'), findsNothing);
    });

    testWidgets('Selecting Technical Assessment branches to Assessment Types and isolates other services', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ClientRequestIntakeModal(initialStep: 3),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen 3: Select Technical Assessment
      final techCard = find.text('3. Technical Assessment');
      expect(techCard, findsOneWidget);
      await tester.tap(techCard);
      await tester.pumpAndSettle();

      // Verify button dynamically changes to "Continue to Assessment Type"
      final continueBtn = find.text('Continue to Assessment Type');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Screen 4: Must show Technical Assessment Submenus
      expect(find.text('Property Inspection'), findsOneWidget);
      expect(find.text('Construction Monitoring'), findsOneWidget);
      expect(find.text('Engineering Assessment'), findsOneWidget);
      expect(find.text('Insurance & Risk'), findsOneWidget);

      // Must NOT show Net Worth or Asset Valuation options
      expect(find.text('Real Estate Valuation'), findsNothing);
      expect(find.text('Plant & Machinery'), findsNothing);
      expect(find.text('Securities & Financial Assets'), findsNothing);
      expect(find.text('Individual'), findsNothing);
      expect(find.text('Director & Promoter'), findsNothing);
      expect(find.text('Business Entity'), findsNothing);
    });
  });
}
