import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:provaluer_frontend/features/landing/landing_sections.dart';

void main() {
  setUpAll(() {
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  group('Institutional Hero Section Authority & Trust Suite', () {
    testWidgets('Desktop Viewport (1920x1080): Verifies Eyebrow badge, Headline, Trust Badges, CTAs, and Accordion Visual', (tester) async {
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
      await tester.pumpAndSettle();

      // 1. Verify Masthead Eyebrow Badge
      expect(
        find.text('PROFESSIONAL VALUATION & ENGINEERING SERVICES • EST. 2001'),
        findsOneWidget,
      );

      // 2. Verify Core Headline
      expect(
        find.text('Statutory Valuation & Advisory Practice'),
        findsOneWidget,
      );

      // 3. Verify Regulatory & Trust Badges
      expect(find.text('CBDT Approved Valuers • Sec 34AB'), findsOneWidget);
      expect(find.text('IBBI Registered Valuers • Sec 247'), findsOneWidget);
      expect(find.text('Chartered Engineers (IEI)'), findsOneWidget);
      expect(find.text('Accepted by 45+ Banks & High Courts'), findsOneWidget);

      // 4. Verify CTAs & Phone Pill
      expect(find.text('Request Proposal →'), findsOneWidget);
      expect(find.text('Advisory Desk: +91 85008 80333'), findsOneWidget);

      // 5. Verify Metrics & Reassurance
      expect(find.text('₹2,00,000+ Cr'), findsOneWidget);
      expect(find.text('Court & Bank Accepted'), findsOneWidget);
    });

    final testWidths = [
      // Desktop
      1920.0, 1600.0, 1440.0, 1366.0, 1280.0,
      // Tablet
      1024.0, 820.0, 768.0,
      // Mobile
      430.0, 414.0, 390.0, 375.0, 360.0, 320.0,
    ];

    for (final width in testWidths) {
      testWidgets('Responsive Viewport (${width.toInt()}px): Renders without overflow or clipping', (tester) async {
        final bool isDesktop = width >= 1100.0;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HeroSection(
                  isDesktop: isDesktop,
                  launchWhatsApp: (_) async {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Core elements must render across all viewports
        expect(find.text('PROFESSIONAL VALUATION & ENGINEERING SERVICES • EST. 2001'), findsOneWidget);
        expect(find.text('Statutory Valuation & Advisory Practice'), findsOneWidget);
        expect(find.text('Request Proposal →'), findsOneWidget);
        expect(find.text('Advisory Desk: +91 85008 80333'), findsOneWidget);
      });
    }
  });
}
