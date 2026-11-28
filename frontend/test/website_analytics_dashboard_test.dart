import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provaluer_frontend/features/superadmin/admin_website_analytics_section.dart';

void main() {
  testWidgets('AdminWebsiteAnalyticsSection renders KPIs, top pages, referrers, locations, and recent visitors',
      (WidgetTester tester) async {
    final sampleData = {
      'totalVisits': 1420,
      'todayVisits': 38,
      'last7DaysVisits': 290,
      'last30DaysVisits': 1105,
      'topPages': [
        {'pagePath': '/services/property-valuation', 'visits': 520},
        {'pagePath': '/', 'visits': 410},
      ],
      'topReferrers': [
        {'referrer': 'https://www.google.com/', 'visits': 840},
        {'referrer': 'Direct', 'visits': 380},
      ],
      'locations': [
        {'country': 'India', 'state': 'Telangana', 'city': 'Hyderabad', 'visits': 610},
      ],
      'recentVisitors': [
        {
          'visitedAt': '2026-11-28T12:15:00',
          'pagePath': '/services/property-valuation',
          'country': 'India',
          'state': 'Telangana',
          'city': 'Hyderabad',
          'device': 'Desktop',
          'browser': 'Chrome',
          'referrer': 'https://www.google.com/',
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminWebsiteAnalyticsSection(initialData: sampleData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Website Analytics'), findsOneWidget);
    expect(find.text('1420'), findsOneWidget);
    expect(find.text('38'), findsOneWidget);
    expect(find.text('290'), findsOneWidget);
    expect(find.text('1105'), findsOneWidget);
    expect(find.text('Top Pages'), findsOneWidget);
    expect(find.text('Top Referrers'), findsOneWidget);
    expect(find.text('Visitor Locations'), findsOneWidget);
    expect(find.text('Recent Visitors'), findsOneWidget);
    expect(find.text('Hyderabad'), findsNWidgets(2));
    expect(find.text('Chrome'), findsOneWidget);
  });
}

