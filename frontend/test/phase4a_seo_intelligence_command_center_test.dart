import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_seo_intelligence_section.dart';

void main() {
  testWidgets('Phase 4C: Real Analytics Integration & Zero Mock Data Verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSeoIntelligenceSection(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Header & Phase 4C Real Telemetry Subtitle
    expect(find.text('SEO Intelligence & Revenue Telemetry'), findsOneWidget);
    expect(find.textContaining('Real telemetry only. Zero mock, zero estimated'), findsOneWidget);

    // 2. Verify Data Source Verification Matrix
    expect(find.text('Data Source Verification Matrix'), findsOneWidget);
    expect(find.text('Google Analytics 4'), findsOneWidget);
    expect(find.text('Microsoft Clarity'), findsOneWidget);
    expect(find.text('Google Search Console'), findsOneWidget);
    expect(find.text('PostgreSQL CRM Tables'), findsOneWidget);

    // 3. Verify All 10 Navigation Cards Exist
    expect(find.text('1. Website Visitors'), findsOneWidget);
    expect(find.text('2. Visitor Locations'), findsOneWidget);
    expect(find.text('3. Popular Services'), findsOneWidget);
    expect(find.text('4. Google Search Terms'), findsOneWidget);
    expect(find.text('5. Lead Sources'), findsOneWidget);
    expect(find.text('6. Page Performance'), findsOneWidget);
    expect(find.text('7. Visitor Journey'), findsOneWidget);
    expect(find.text('8. User Clicks & Heatmaps'), findsOneWidget);
    expect(find.text('9. Website Health'), findsOneWidget);
    expect(find.text('10. Business Impact'), findsOneWidget);

    // 4. Test clicking an unconnected data source: 1. Website Visitors (Requires GA4)
    final btn1 = find.text('1. Website Visitors');
    await tester.ensureVisible(btn1);
    await tester.tap(btn1);
    await tester.pumpAndSettle();

    // Verify "Data Source Not Connected" is strictly displayed (No mock numbers)
    expect(find.text('REPORT 1: WEBSITE VISITORS'), findsOneWidget);
    expect(find.text('Data Source Not Connected'), findsOneWidget);
    expect(find.textContaining('This report requires a verified connection to Google Analytics 4'), findsOneWidget);
    expect(find.textContaining('estimated, random, placeholder, or generated values are prohibited'), findsOneWidget);
    expect(find.text('Configure Google Analytics 4 Connection'), findsOneWidget);

    // Verify Metric Metadata Header (Source, Last Updated, Verification Status)
    expect(find.text('Source: '), findsWidgets);
    expect(find.text('Google Analytics 4'), findsWidgets);
    expect(find.text('Last Updated: '), findsWidgets);
    expect(find.text('Verification Status: '), findsWidgets);
    expect(find.text('NOT CONNECTED'), findsWidgets);

    // 5. Test Back Button
    final backBtn = find.text('Back to Overview');
    await tester.ensureVisible(backBtn);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // 6. Test clicking another unconnected source: 8. User Clicks & Heatmaps (Requires Clarity)
    final btn8 = find.text('8. User Clicks & Heatmaps');
    await tester.ensureVisible(btn8);
    await tester.tap(btn8);
    await tester.pumpAndSettle();

    expect(find.text('REPORT 8: USER CLICKS & HEATMAPS'), findsOneWidget);
    expect(find.text('Data Source Not Connected'), findsOneWidget);
    expect(find.textContaining('This report requires a verified connection to Microsoft Clarity'), findsOneWidget);
    expect(find.text('Configure Microsoft Clarity Connection'), findsOneWidget);

    // Return to overview
    await tester.tap(find.text('Back to Overview'));
    await tester.pumpAndSettle();

    // 7. Test clicking connected report: 10. Business Impact (PostgreSQL CRM)
    final btn10 = find.text('10. Business Impact');
    await tester.ensureVisible(btn10);
    await tester.tap(btn10);
    await tester.pumpAndSettle();

    expect(find.text('REPORT 10: BUSINESS IMPACT'), findsOneWidget);
    expect(find.text('Data Source Not Connected'), findsOneWidget);
    expect(find.text('PostgreSQL (orders, lead_quotations)'), findsWidgets);
    expect(find.textContaining('This report requires a verified connection to PostgreSQL (orders, lead_quotations)'), findsOneWidget);
    expect(find.text('Source: '), findsWidgets);
    expect(find.text('Last Updated: '), findsWidgets);
    expect(find.text('Verification Status: '), findsWidgets);
  });
}
