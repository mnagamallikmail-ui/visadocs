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
import 'theme/app_theme.dart';

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

class ProValuerApp extends StatelessWidget {
  const ProValuerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final GoRouter router = GoRouter(
      initialLocation: '/',
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
            loc.startsWith('/services/') ||
            loc == '/government-approved-valuers';

        if (!loggedIn && !isPublic) {
          return '/login';
        }
        if (loggedIn && loc == '/login') {
          final role = auth.role;
          if (role == 'CLIENT') return '/client';
          if (role == 'PA') return '/pa';
          if (role == 'SPA') return '/spa';
          if (role == 'SUPER_ADMIN' || role == 'ADMIN') return '/admin';
        }
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
