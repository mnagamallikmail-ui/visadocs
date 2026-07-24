import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/valuation_portal/valuation_portal_widget.dart';

class SpaDashboard extends StatefulWidget {
  const SpaDashboard({super.key});

  @override
  State<SpaDashboard> createState() => _SpaDashboardState();
}

class _SpaDashboardState extends State<SpaDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return ValuationPortalWidget(
      role: authProvider.role ?? 'SPA',
      email: authProvider.email ?? 'spa@provaluer.com',
      fullName: authProvider.fullName ?? 'Senior Property Analyst',
      onLogout: () {
        authProvider.logout();
        context.go('/login');
      },
    );
  }
}
