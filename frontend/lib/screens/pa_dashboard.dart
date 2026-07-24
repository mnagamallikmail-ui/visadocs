import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../features/valuation_portal/valuation_portal_widget.dart';

class PaDashboard extends StatefulWidget {
  const PaDashboard({super.key});

  @override
  State<PaDashboard> createState() => _PaDashboardState();
}

class _PaDashboardState extends State<PaDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return ValuationPortalWidget(
      role: authProvider.role ?? 'PA',
      email: authProvider.email ?? 'pa@provaluer.com',
      fullName: authProvider.fullName ?? 'Property Analyst',
      onLogout: () {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.stopHeartbeat();
        authProvider.logout();
        context.go('/login');
      },
    );
  }
}
