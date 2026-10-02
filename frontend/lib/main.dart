import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/client_dashboard.dart';
import 'screens/pa_dashboard.dart';
import 'screens/spa_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'screens/landing_page.dart';
import 'screens/services/bank_collateral_valuation_screen.dart';
import 'screens/services/nclt_ibc_valuation_screen.dart';
import 'screens/services/government_approved_valuers_screen.dart';
import 'screens/services/visa_immigration_valuation_screen.dart';
import 'screens/services/property_valuation_screen.dart';
import 'screens/services/divorce_matrimonial_valuation_screen.dart';
import 'screens/services/probate_inheritance_valuation_screen.dart';
import 'screens/services/share_valuation_screen.dart';
import 'screens/services/plant_machinery_valuation_screen.dart';
import 'screens/request_intake_screen.dart';
import 'theme/app_theme.dart';
import 'services/analytics_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const ProValuerApp(),
    ),
  );
}

class Ga4RouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final routeName = route.settings.name;
    if (routeName != null && routeName.isNotEmpty) {
      AnalyticsService.trackPageView(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    final routeName = newRoute?.settings.name;
    if (routeName != null && routeName.isNotEmpty) {
      AnalyticsService.trackPageView(routeName);
    }
  }
}

class ProValuerApp extends StatelessWidget {
  const ProValuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final GoRouter router = GoRouter(
      initialLocation: '/',
      observers: [Ga4RouteObserver()],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LandingPage(),
        ),
        GoRoute(
          path: '/government-approved-valuers',
          builder: (context, state) => const GovernmentApprovedValuersScreen(),
        ),
        GoRoute(
          path: '/services/property-valuation',
          builder: (context, state) => const PropertyValuationScreen(),
        ),
        GoRoute(
          path: '/services/bank-collateral-valuation',
          builder: (context, state) => const BankCollateralValuationScreen(),
        ),
        GoRoute(
          path: '/services/nclt-ibc-valuation',
          builder: (context, state) => const NcltIbcValuationScreen(),
        ),
        GoRoute(
          path: '/services/visa-and-immigration-valuations',
          builder: (context, state) => const VisaImmigrationValuationScreen(),
        ),
        GoRoute(
          path: '/services/divorce-matrimonial-valuation',
          builder: (context, state) => const DivorceMatrimonialValuationScreen(),
        ),
        GoRoute(
          path: '/services/probate-inheritance-valuation',
          builder: (context, state) => const ProbateInheritanceValuationScreen(),
        ),
        GoRoute(
          path: '/services/share-valuation',
          builder: (context, state) => const ShareValuationScreen(),
        ),
        GoRoute(
          path: '/services/plant-and-machinery-valuation',
          builder: (context, state) => const PlantMachineryValuationScreen(),
        ),
        GoRoute(
          path: '/request-valuation',
          builder: (context, state) => const RequestIntakeScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/client',
          builder: (context, state) => const ClientDashboard(),
        ),
        GoRoute(
          path: '/pa',
          builder: (context, state) => const PaDashboard(),
        ),
        GoRoute(
          path: '/spa',
          builder: (context, state) => const SpaDashboard(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboard(),
        ),
      ],
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final loc = state.matchedLocation;
        final isPublic = loc == '/' ||
            loc == '/login' ||
            loc == '/request-valuation' ||
            loc.startsWith('/services/') ||
            loc == '/government-approved-valuers';

        if (!loggedIn && !isPublic) {
          AnalyticsService.trackPageView('/login', 'Account Sign In | ProValuer');
          return '/login';
        }
        if (loggedIn && loc == '/login') {
          final role = auth.role;
          if (role == 'CLIENT') {
            AnalyticsService.trackPageView('/client', 'Client Mandate Dashboard | ProValuer');
            return '/client';
          }
          if (role == 'PA') {
            AnalyticsService.trackPageView('/pa', 'Partner Appraiser Dashboard | ProValuer');
            return '/pa';
          }
          if (role == 'SPA') {
            AnalyticsService.trackPageView('/spa', 'Senior Partner Review Dashboard | ProValuer');
            return '/spa';
          }
          if (role == 'SUPER_ADMIN' || role == 'ADMIN') {
            AnalyticsService.trackPageView('/admin', 'Super Admin Governance Console | ProValuer');
            return '/admin';
          }
        }
        AnalyticsService.trackPageView(loc);
        return null;
      },
    );

    return MaterialApp.router(
      title: 'ProValuer Commercial',
      debugShowCheckedModeBanner: false,
      // All design tokens applied via AppTheme — single source of truth
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
