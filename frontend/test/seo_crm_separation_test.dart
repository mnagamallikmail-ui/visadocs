import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_seo_intelligence_section.dart';

void main() {
  group('SEO Intelligence & CRM Revenue Telemetry Separation Tests', () {
    testWidgets('1. Disconnected State: Displays distinct CRM and SEO sections and shows "SEO Data Unavailable - External SEO Sources Not Connected"', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Disconnected external SEO sources
      final disconnectedTelemetry = {
        'crmConnected': true,
        'totalLeads': 24,
        'newLeads': 8,
        'qualifiedLeads': 12,
        'totalQuotes': 18,
        'totalQuotedAmount': 450000.0,
        'totalOrders': 10,
        'realizedRevenue': 285000.0,
        'ga4Connected': false,
        'clarityConnected': false,
        'gscConnected': false,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSeoIntelligenceSection(
              initialTelemetryData: disconnectedTelemetry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Distinct Section 1: CRM Revenue Telemetry
      expect(find.text('1. CRM Revenue Telemetry'), findsOneWidget);
      expect(find.textContaining('Notice: CRM Revenue Telemetry accurately reports valuation intake'), findsOneWidget);
      expect(find.text('2. Visitor Locations'), findsOneWidget);
      expect(find.text('3. Popular Services'), findsOneWidget);
      expect(find.text('5. Lead Sources'), findsOneWidget);
      expect(find.text('10. Business Impact'), findsOneWidget);

      // Verify Distinct Section 2: SEO Intelligence
      expect(find.text('2. SEO Intelligence'), findsOneWidget);
      expect(find.text('SEO Data Unavailable - External SEO Sources Not Connected'), findsWidgets);
      expect(find.textContaining('Actual SEO telemetry is unavailable because external search sources are currently disconnected'), findsOneWidget);
      expect(find.text('1. Website Visitors'), findsOneWidget);
      expect(find.text('4. Google Search Terms'), findsOneWidget);
      expect(find.text('6. Page Performance'), findsOneWidget);
      expect(find.text('7. Visitor Journey'), findsOneWidget);
      expect(find.text('8. User Clicks & Heatmaps'), findsOneWidget);
      expect(find.text('9. Website Health'), findsOneWidget);

      // Verify that active search KPI blocks are NOT displayed when GSC is disconnected
      expect(find.text('Live Search-Related KPIs (Sourced from Connected Google Search Console & GA4)'), findsNothing);
    });

    testWidgets('2. Connected State: Displays live search KPIs only when sourced from connected GSC or GA4 APIs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Connected GSC
      final connectedTelemetry = {
        'crmConnected': true,
        'totalLeads': 24,
        'totalQuotes': 18,
        'totalOrders': 10,
        'realizedRevenue': 285000.0,
        'ga4Connected': false,
        'clarityConnected': false,
        'gscConnected': true,
        'gscPropertyId': 'sc-domain:provaluer.in',
        'gscTotalImpressions': 4520,
        'gscTotalClicks': 312,
        'gscAverageCtr': 0.069,
        'gscAveragePosition': 3.2,
        'gscIndexedPages': 6,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSeoIntelligenceSection(
              initialTelemetryData: connectedTelemetry,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Live Search KPIs are displayed from connected GSC
      expect(find.text('Live Search-Related KPIs (Sourced from Connected Google Search Console & GA4)'), findsOneWidget);
      expect(find.text('4520'), findsOneWidget);
      expect(find.text('312'), findsOneWidget);
      expect(find.text('6.90%'), findsOneWidget);
      expect(find.text('3.20'), findsOneWidget);
      expect(find.text('6 / 6'), findsOneWidget);
    });
  });
}
