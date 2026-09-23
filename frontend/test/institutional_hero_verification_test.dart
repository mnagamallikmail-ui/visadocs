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

      // 2. Verify Top Trust Ribbon (All 4 proof points)
      expect(find.text('₹15,000+ Cr Valued'), findsOneWidget);
      expect(find.text('IBBI Registered Valuers'), findsOneWidget);
      expect(find.text('PAN India Coverage'), findsOneWidget);

      // 3. Verify Non-Duplicative Lower Regulatory Compliance Badges
      expect(find.text('Companies Act Sec 247 & IBBI'), findsOneWidget);
      expect(find.text('Rule 11UA / Income Tax'), findsOneWidget);
      expect(find.text('Empanelled with PSU & Private Banks'), findsOneWidget);

      // 4. Verify Single-Line Valuation Expertise Header Tile
      expect(find.text('VALUATION EXPERTISE'), findsOneWidget);

      // Pump forward to allow the cascading deck cards to drop and settle
      await tester.pump(const Duration(milliseconds: 3000));

      // 5. Verify Plant & Machinery Valuations & Lenders' Independent Engineer Services
      expect(find.text('Plant & Machinery Valuations'), findsOneWidget);
      expect(find.text("Lenders' Independent Engineer Services"), findsOneWidget);
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
        expect(find.text('IBBI Registered Valuers'), findsOneWidget);
        expect(find.text('PAN India Coverage'), findsOneWidget);

        // Verify Lower Regulatory Badges
        expect(find.text('Companies Act Sec 247 & IBBI'), findsOneWidget);
        expect(find.text('Rule 11UA / Income Tax'), findsOneWidget);
        // On mobile, compact PSU badge is rendered
        expect(find.text('PSU & Private Banks'), findsNWidgets(2)); // Once in ribbon, once in lower badge

        // Verify CTAs are rendered
        expect(find.text('Request Consultation'), findsOneWidget);
        expect(find.text('+91 85000 19091'), findsOneWidget);
      });
    }
  });
}
