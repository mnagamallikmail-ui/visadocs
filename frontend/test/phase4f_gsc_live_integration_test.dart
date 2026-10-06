import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_seo_intelligence_section.dart';

void main() {
  testWidgets('Phase 4F: Google Search Console VERIFIED LIVE and Report Verification', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final verifiedTelemetryPayload = {
      'gscConnected': true,
      'gscStatus': 'VERIFIED LIVE',
      'gscPropertyId': 'sc-domain:provaluer.in',
      'gscTotalImpressions': 2075,
      'gscTotalClicks': 178,
      'gscAverageCtr': 0.0858,
      'gscAveragePosition': 4.43,
      'gscIndexedPages': 6,
      'gscTotalQueries': 10,
      'totalLeads': 4,
      'newLeads': 2,
      'qualifiedLeads': 2,
      'urgentLeads': 0,
      'totalQuotes': 2,
      'totalQuotedAmount': 23600.0,
      'acceptedQuotes': 1,
      'totalOrders': 3,
      'completedOrders': 1,
      'realizedRevenue': 11800.0,
      'ga4Connected': true,
      'ga4MeasurementId': 'G-94DDGM6XDW',
      'clarityConnected': false,
      'gscQueries': [
        {'query': 'government approved valuer near me', 'impressions': 165, 'clicks': 18, 'ctr': 0.109, 'avgPosition': 2.8, 'country': 'IND', 'device': 'MOBILE'},
        {'query': 'section 34ab wealth tax act approved valuer', 'impressions': 110, 'clicks': 12, 'ctr': 0.109, 'avgPosition': 1.4, 'country': 'IND', 'device': 'DESKTOP'},
        {'query': 'rule 11ua dcf valuation merchant banker', 'impressions': 135, 'clicks': 15, 'ctr': 0.111, 'avgPosition': 2.1, 'country': 'IND', 'device': 'DESKTOP'},
        {'query': 'section 56 2 viib angel tax abolition finance act 2024', 'impressions': 180, 'clicks': 22, 'ctr': 0.122, 'avgPosition': 1.8, 'country': 'IND', 'device': 'DESKTOP'},
        {'query': 'property valuation for us visa f1', 'impressions': 145, 'clicks': 16, 'ctr': 0.110, 'avgPosition': 2.4, 'country': 'IND', 'device': 'MOBILE'},
        {'query': 'depreciated replacement cost plant and machinery', 'impressions': 88, 'clicks': 7, 'ctr': 0.079, 'avgPosition': 4.3, 'country': 'IND', 'device': 'DESKTOP'},
        {'query': 'section 50c circle rate rebuttal valuer report', 'impressions': 120, 'clicks': 11, 'ctr': 0.092, 'avgPosition': 3.5, 'country': 'IND', 'device': 'DESKTOP'},
      ],
      'gscPages': [
        {'url': 'https://www.provaluer.in/knowledge/government-approved-valuers-complete-guide', 'title': 'Government Approved Valuers Complete Guide', 'slug': 'government-approved-valuers-complete-guide', 'indexed': true},
        {'url': 'https://www.provaluer.in/knowledge/rule-11ua-complete-guide', 'title': 'Rule 11UA Complete Guide: DCF & NAV Math', 'slug': 'rule-11ua-complete-guide', 'indexed': true},
        {'url': 'https://www.provaluer.in/knowledge/property-valuation-methods-complete-guide', 'title': 'Property Valuation Methods Complete Guide', 'slug': 'property-valuation-methods-complete-guide', 'indexed': true},
        {'url': 'https://www.provaluer.in/knowledge/plant-and-machinery-valuation-complete-guide', 'title': 'Plant & Machinery Valuation Complete Guide', 'slug': 'plant-and-machinery-valuation-complete-guide', 'indexed': true},
        {'url': 'https://www.provaluer.in/knowledge/angel-tax-complete-guide', 'title': 'Angel Tax Complete Guide: Section 56(2)(viib)', 'slug': 'angel-tax-complete-guide', 'indexed': true},
        {'url': 'https://www.provaluer.in/knowledge/visa-and-immigration-valuation-complete-guide', 'title': 'Visa & Immigration Valuation Complete Guide', 'slug': 'visa-and-immigration-valuation-complete-guide', 'indexed': true},
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminSeoIntelligenceSection(
            initialTelemetryData: verifiedTelemetryPayload,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Google Search Console tile shows VERIFIED LIVE status
    expect(find.text('Google Search Console'), findsOneWidget);
    expect(find.text('✅ GOOGLE SEARCH CONSOLE VERIFIED LIVE'), findsOneWidget);
    expect(find.text('sc-domain:provaluer.in'), findsWidgets);

    // 2. Verify Card 4 "4. Google Search Terms" exists
    final searchTermsBtn = find.text('4. Google Search Terms');
    expect(searchTermsBtn, findsOneWidget);

    // 3. Click Card 4 to view Report 4
    await tester.ensureVisible(searchTermsBtn);
    await tester.tap(searchTermsBtn);
    await tester.pumpAndSettle();

    // 4. Verify Report 4 Header & Live GSC Telemetry
    expect(find.text('REPORT 4: GOOGLE SEARCH TERMS'), findsOneWidget);
    expect(find.text('GOOGLE SEARCH CONSOLE VERIFIED LIVE'), findsWidgets);
    expect(find.textContaining('sc-domain:provaluer.in'), findsWidgets);
    expect(find.text('Status: SITE_OWNER Verified'), findsOneWidget);

    // 5. Verify Metric blocks: Impressions, Clicks, CTR, Position, Indexed Pages
    expect(find.text('Total Impressions'), findsOneWidget);
    expect(find.text('2075'), findsWidgets);
    expect(find.text('Total Clicks'), findsOneWidget);
    expect(find.text('178'), findsWidgets);
    expect(find.text('Average CTR'), findsOneWidget);
    expect(find.text('8.58%'), findsWidgets);
    expect(find.text('Average Position'), findsOneWidget);
    expect(find.text('4.43'), findsWidgets);
    expect(find.text('Indexed Pages'), findsOneWidget);
    expect(find.text('6 / 6 (100%)'), findsWidgets);

    // 6. Verify Top Institutional Queries
    expect(find.text('government approved valuer near me'), findsWidgets);
    expect(find.text('section 34ab wealth tax act approved valuer'), findsWidgets);
    expect(find.text('rule 11ua dcf valuation merchant banker'), findsWidgets);
    expect(find.text('section 56 2 viib angel tax abolition finance act 2024'), findsWidgets);

    // 7. Verify Indexed Canonical Guides
    expect(find.text('Government Approved Valuers Complete Guide'), findsWidgets);
    expect(find.text('Rule 11UA Complete Guide: DCF & NAV Math'), findsWidgets);
    expect(find.text('INDEXED'), findsWidgets);

    // 8. Test Back Button returns to overview
    final backBtn = find.text('Back to Overview');
    await tester.ensureVisible(backBtn);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('SEO Intelligence & Revenue Telemetry'), findsOneWidget);
    expect(find.text('✅ GOOGLE SEARCH CONSOLE VERIFIED LIVE'), findsOneWidget);
  });
}
