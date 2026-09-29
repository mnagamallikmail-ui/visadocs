import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_seo_intelligence_section.dart';

void main() {
  testWidgets('Phase 4A: SEO Intelligence Command Center Executive Business UI Verification', (WidgetTester tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(1920, 1080);
    tester.binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSeoIntelligenceSection(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Header & Business-Oriented Subtitle
    expect(find.text('SEO Intelligence Command Center'), findsOneWidget);
    expect(find.text('Business Telemetry Active'), findsOneWidget);
    expect(find.textContaining('Summarized in plain English'), findsOneWidget);

    // 2. Verify Global AI Executive Summary
    expect(find.text('SEO Executive Summary'), findsOneWidget);
    expect(find.textContaining('This month your website received 3,416 visitors'), findsOneWidget);
    expect(find.textContaining('Most visitors came from Hyderabad'), findsOneWidget);
    expect(find.textContaining('Share Valuation is the most viewed service'), findsOneWidget);
    expect(find.textContaining('Google Search generated 62% of website traffic'), findsOneWidget);
    expect(find.textContaining('9 corporate projects converted into revenue'), findsOneWidget);

    // 3. Verify All 10 Navigation Buttons Exist on Dashboard
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

    // 4. Test Follow-Up Command Chip: "Which city gives most leads?"
    final cityChip = find.text('Which city gives most leads?');
    await tester.ensureVisible(cityChip);
    await tester.tap(cityChip);
    await tester.pumpAndSettle();

    // Verify AI Plain-English Answer appears
    expect(find.textContaining('AI Response to: "Which city gives most leads?"'), findsOneWidget);
    expect(find.textContaining('Most of your visitors come from Hyderabad (48%) and Mumbai (24%)'), findsOneWidget);

    // 5. Click "Open Full Report (Visitor Locations)"
    final openReportBtn = find.textContaining('Open Full Report (Visitor Locations)');
    await tester.ensureVisible(openReportBtn);
    await tester.tap(openReportBtn);
    await tester.pumpAndSettle();

    // Verify Report 2 is Open with all 4 required sections
    expect(find.text('REPORT 2: VISITOR LOCATIONS'), findsOneWidget);
    expect(find.text('Data & Performance Metrics'), findsOneWidget);
    expect(find.text('AI Summary (Plain English)'), findsOneWidget);
    expect(find.text('Strategic Insights'), findsOneWidget);
    expect(find.text('Recommended Actions'), findsOneWidget);
    expect(find.textContaining('Most visitors are coming from Hyderabad and Mumbai'), findsOneWidget);

    // 6. Test Back Button
    final backBtn = find.text('Back to Command Center');
    await tester.ensureVisible(backBtn);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verify returned to Command Center Dashboard
    expect(find.text('SEO Executive Summary'), findsOneWidget);
    expect(find.text('1. Website Visitors'), findsOneWidget);

    // 7. Click Button 1: Website Visitors
    final btn1 = find.text('1. Website Visitors');
    await tester.ensureVisible(btn1);
    await tester.tap(btn1);
    await tester.pumpAndSettle();

    // Verify Report 1 has Today, This Week, This Month, Growth % and 4 sections
    expect(find.text('REPORT 1: WEBSITE VISITORS'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Growth %'), findsOneWidget);
    expect(find.text('Data & Performance Metrics'), findsOneWidget);
    expect(find.text('AI Summary (Plain English)'), findsOneWidget);
    expect(find.text('Strategic Insights'), findsOneWidget);
    expect(find.text('Recommended Actions'), findsOneWidget);
  });
}
