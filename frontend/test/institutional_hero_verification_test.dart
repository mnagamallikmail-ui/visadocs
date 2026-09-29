import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/landing/landing_sections.dart';

void main() {
  group('Institutional Hero Section Authority & Trust Suite', () {
    testWidgets('Desktop Viewport (1920x1080): Verifies Eyebrow badge, Trust Ribbon, Regulatory Badges, and Deck', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HeroSection(
                isDesktop: true,
                launchWhatsApp: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify Masthead Eyebrow Badge
      expect(
        find.text('REGISTERED VALUERS (GOVT APPROVED) • IBBI • INCOME TAX • ASSET INTELLIGENCE'),
        findsOneWidget,
      );

      // 2. Verify Top Trust Ribbon (All 4 institutional proof points)
      expect(find.text('₹15,000+ Cr Valued'), findsOneWidget);
      expect(find.text('PSU & Private Banks'), findsWidgets);
      expect(find.text('IBBI Registered Valuers'), findsOneWidget);
      expect(find.text('PAN India Coverage'), findsOneWidget);

      // 3. Verify Non-Duplicative Lower Regulatory Compliance Badges
      expect(find.text('Government Approved Valuers'), findsOneWidget);
      expect(find.text('IBBI Registered · Sec 247'), findsOneWidget);
      expect(find.text('Rule 11UA / Income Tax'), findsOneWidget);

      // 4. Verify Single-Line Valuation Expertise Header Tile & Executive Card
      expect(find.text('VALUATION EXPERTISE'), findsOneWidget);
      expect(find.text('01 / 04'), findsOneWidget);
      expect(find.text('BANKING'), findsOneWidget);
      expect(find.text('Collateral & Security Valuation'), findsOneWidget);
      expect(find.text('For PSU & Private Banks'), findsOneWidget);

      // 5. Verify CTAs & Rotating Headline
      expect(find.text('Request Valuation Report'), findsOneWidget);
      expect(find.text('Banking Collaterals'), findsOneWidget);
    });

    final mobileWidths = [320.0, 360.0, 375.0, 390.0, 412.0, 430.0];

    for (final width in mobileWidths) {
      testWidgets('Mobile Viewport (${width.toInt()}x844): Verifies balanced 2-line ribbon, compact badges, and 0 overflow', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HeroSection(
                  isDesktop: false,
                  launchWhatsApp: (_) async {},
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        // Verify balanced 2-line ribbon items are rendered
        expect(find.text('₹15,000+ Cr Valued'), findsOneWidget);
        expect(find.text('PSU & Private Banks'), findsWidgets);
        expect(find.text('IBBI Registered Valuers'), findsOneWidget);
        expect(find.text('PAN India Coverage'), findsOneWidget);

        // Verify Lower Regulatory Badges
        expect(find.text('Government Approved Valuers'), findsOneWidget);
        expect(find.text('IBBI Registered · Sec 247'), findsOneWidget);
        expect(find.text('Rule 11UA / Income Tax'), findsOneWidget);

        // Verify CTAs are rendered
        expect(find.text('Request Valuation Report'), findsOneWidget);
      });
    }
  });
}
