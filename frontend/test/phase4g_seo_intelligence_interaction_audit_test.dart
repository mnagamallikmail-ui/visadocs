import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_seo_intelligence_section.dart';

void main() {
  final fullTelemetryPayload = {
    'ga4Connected': true,
    'ga4MeasurementId': 'G-94DDGM6XDW',
    'gscConnected': true,
    'gscStatus': 'VERIFIED LIVE',
    'gscPropertyId': 'sc-domain:provaluer.in',
    'gscTotalImpressions': 2075,
    'gscTotalClicks': 178,
    'gscAverageCtr': 0.0858,
    'gscAveragePosition': 4.43,
    'gscIndexedPages': 6,
    'gscTotalQueries': 7,
    'clarityConnected': true,
    'clarityProjectId': 'CLARITY-992',
    'pagespeedConnected': true,
    'totalLeads': 20,
    'newLeads': 5,
    'qualifiedLeads': 12,
    'urgentLeads': 3,
    'totalQuotes': 8,
    'totalQuotedAmount': 280000.0,
    'acceptedQuotes': 5,
    'totalOrders': 6,
    'completedOrders': 4,
    'realizedRevenue': 165000.0,
    'leadsByService': {
      'Rule 11UA / DCF Valuation': 6,
      'Land & Commercial Building': 5,
      'Plant & Machinery Appraisal': 3,
      'Visa & Immigration Net Worth': 2,
      'Bank Collateral Valuation': 2,
      'Angel Tax Section 56(2)(viib)': 2,
    },
    'leadsByLocation': {
      'Delhi NCR': 8,
      'Mumbai MMR': 5,
      'Bengaluru': 3,
      'Hyderabad': 2,
      'Pune': 2,
    },
    'leadsByStatus': {
      'NEW': 5,
      'QUALIFIED': 12,
      'URGENT': 3,
    },
    'gscQueries': [
      {'query': 'government approved valuer near me', 'impressions': 165, 'clicks': 18, 'ctr': 0.109, 'avgPosition': 2.8, 'country': 'IND', 'device': 'MOBILE'},
      {'query': 'section 34ab wealth tax act approved valuer', 'impressions': 110, 'clicks': 12, 'ctr': 0.109, 'avgPosition': 1.4, 'country': 'IND', 'device': 'DESKTOP'},
    ],
    'gscPages': [
      {'url': 'https://www.provaluer.in/knowledge/government-approved-valuers-complete-guide', 'title': 'Government Approved Valuers Complete Guide', 'slug': 'government-approved-valuers-complete-guide', 'indexed': true},
    ],
  };

  testWidgets('Phase 4G: Forensic Audit - All 10 SEO Intelligence Cards are Interactive and Render Full Reports', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminSeoIntelligenceSection(
            initialTelemetryData: fullTelemetryPayload,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 10 cards exist
    final cardTitles = [
      '1. Website Visitors',
      '2. Visitor Locations',
      '3. Popular Services',
      '4. Google Search Terms',
      '5. Lead Sources',
      '6. Page Performance',
      '7. Visitor Journey',
      '8. User Clicks & Heatmaps',
      '9. Website Health',
      '10. Business Impact',
    ];

    for (final title in cardTitles) {
      expect(find.text(title), findsOneWidget);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 1: Website Visitors
    // ─────────────────────────────────────────────────────────────────────────
    final card1 = find.text('1. Website Visitors');
    await tester.ensureVisible(card1);
    await tester.tap(card1);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 1: WEBSITE VISITORS'), findsOneWidget);
    // Live Data
    expect(find.text('Total Sessions'), findsOneWidget);
    expect(find.text('1,482'), findsOneWidget);
    // Charts
    expect(find.textContaining('7-Day Traffic Pacing'), findsWidgets);
    // Tables
    expect(find.text('Daily Telemetry Breakdown (Table)'), findsOneWidget);
    expect(find.text('Thursday (Peak)'), findsOneWidget);
    // AI Summary
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    // Recommended actions
    expect(find.textContaining('Recommended Growth Actions'), findsOneWidget);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 2: Visitor Locations (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill2 = find.text('2. Locations');
    await tester.ensureVisible(pill2);
    await tester.tap(pill2);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 2: VISITOR LOCATIONS'), findsOneWidget);
    // Live data
    expect(find.text('Verified Inquiry Cities'), findsOneWidget);
    // Chart
    expect(find.textContaining('Inquiries by Regional Economic Cluster'), findsOneWidget);
    // Table
    expect(find.text('Regional Inquiries Breakdown (Table)'), findsOneWidget);
    expect(find.textContaining('Delhi NCR'), findsWidgets);
    // AI Summary
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    // Recommended actions
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 3: Popular Services (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill3 = find.text('3. Services');
    await tester.ensureVisible(pill3);
    await tester.tap(pill3);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 3: POPULAR SERVICES'), findsOneWidget);
    // Live data
    expect(find.text('Leading Practice'), findsOneWidget);
    // Chart
    expect(find.textContaining('Inquiry Volume Across Valuation Disciplines'), findsOneWidget);
    // Table
    expect(find.text('Service Line Commercial Telemetry (Table)'), findsOneWidget);
    expect(find.textContaining('Rule 11UA / DCF Merchant Banker'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 4: Google Search Terms (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill4 = find.text('4. Search Terms');
    await tester.ensureVisible(pill4);
    await tester.tap(pill4);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 4: GOOGLE SEARCH TERMS'), findsOneWidget);
    // Live data
    expect(find.text('Total Impressions'), findsOneWidget);
    expect(find.text('2075'), findsWidgets);
    // Chart
    expect(find.textContaining('Impression Volume by Google Ranking Position Tiers'), findsOneWidget);
    // Table
    expect(find.textContaining('government approved valuer near me'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Synthesis'), findsOneWidget);
    expect(find.textContaining('Recommended Search Growth Actions'), findsOneWidget);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 5: Lead Sources (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill5 = find.text('5. Lead Sources');
    await tester.ensureVisible(pill5);
    await tester.tap(pill5);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 5: LEAD SOURCES'), findsOneWidget);
    // Live data
    expect(find.text('Total Verified Inquiries'), findsOneWidget);
    // Chart
    expect(find.textContaining('Lead Ingestion Volume by Source Channel'), findsOneWidget);
    // Table
    expect(find.text('Channel Quality & Realization Metrics (Table)'), findsOneWidget);
    expect(find.textContaining('Organic Google Search (SEO)'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 6: Page Performance (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill6 = find.text('6. Pages');
    await tester.ensureVisible(pill6);
    await tester.tap(pill6);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 6: PAGE PERFORMANCE'), findsOneWidget);
    // Live data
    expect(find.text('Monitored URLs'), findsOneWidget);
    // Chart
    expect(find.textContaining('Monthly Pageview Volume by URL'), findsOneWidget);
    // Table
    expect(find.text('Top Page Engagement & Velocity (Table)'), findsOneWidget);
    expect(find.textContaining('/knowledge/rule-11ua-complete-guide'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 7: Visitor Journey (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill7 = find.text('7. Journey');
    await tester.ensureVisible(pill7);
    await tester.tap(pill7);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 7: VISITOR JOURNEY'), findsOneWidget);
    // Live data
    expect(find.text('Total Funnel Entrants'), findsOneWidget);
    // Chart
    expect(find.textContaining('User Conversion Progression & Retention Rate'), findsOneWidget);
    // Table
    expect(find.text('Funnel Stage Velocity & Friction Matrix (Table)'), findsOneWidget);
    expect(find.textContaining('1. Website Arrival'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 8: User Clicks & Heatmaps (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill8 = find.text('8. Heatmaps');
    await tester.ensureVisible(pill8);
    await tester.tap(pill8);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 8: USER CLICKS & HEATMAPS'), findsOneWidget);
    // Live data
    expect(find.text('Total Clicks Tracked'), findsOneWidget);
    expect(find.text('3,420'), findsOneWidget);
    // Chart
    expect(find.textContaining('Click Distribution on Key Interactive UI Elements'), findsOneWidget);
    // Table
    expect(find.text('High-Intent Interactive Elements Telemetry (Table)'), findsOneWidget);
    expect(find.textContaining('Request Valuation Primary CTA'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 9: Website Health (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill9 = find.text('9. Health');
    await tester.ensureVisible(pill9);
    await tester.tap(pill9);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 9: WEBSITE HEALTH'), findsOneWidget);
    // Live data
    expect(find.text('Performance Score'), findsOneWidget);
    expect(find.text('98 / 100'), findsOneWidget);
    // Chart
    expect(find.textContaining('Lighthouse Performance & Compliance Scores'), findsOneWidget);
    // Table
    expect(find.text('Core Diagnostics & Speed Metrics (Table)'), findsOneWidget);
    expect(find.textContaining('Largest Contentful Paint (LCP)'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Strategic Summary'), findsWidgets);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // ─────────────────────────────────────────────────────────────────────────
    // CARD 10: Business Impact (Test Switcher Pill)
    // ─────────────────────────────────────────────────────────────────────────
    final pill10 = find.text('10. Business Impact');
    await tester.ensureVisible(pill10);
    await tester.tap(pill10);
    await tester.pumpAndSettle();
    expect(find.text('REPORT 10: BUSINESS IMPACT'), findsOneWidget);
    // Live data
    expect(find.text('Total Inquiries'), findsOneWidget);
    expect(find.text('Formal Quotes Sent'), findsOneWidget);
    expect(find.text('Total Quoted Value'), findsOneWidget);
    expect(find.text('Realized Revenue'), findsOneWidget);
    // Chart
    expect(find.textContaining('Revenue Realization & Commercial Pipeline'), findsOneWidget);
    // Table
    expect(find.text('Commercial Mandate Realization Telemetry (Table)'), findsOneWidget);
    expect(find.textContaining('Realized Billings'), findsWidgets);
    // AI Summary & Actions
    expect(find.textContaining('AI Summary (Verified Real Data)'), findsOneWidget);
    expect(find.textContaining('Recommended Actions'), findsWidgets);

    // Verify modal dialog pop-out
    await tester.tap(find.text('Pop-out Modal'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('REPORT 10: BUSINESS IMPACT'), findsWidgets);
    // Close modal dialog
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);

    // Return to overview
    final backBtn = find.text('Back to Overview');
    await tester.ensureVisible(backBtn);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();
    expect(find.text('SEO Intelligence & Revenue Telemetry'), findsOneWidget);
  });
}
