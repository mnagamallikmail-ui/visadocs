import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../features/superadmin/superadmin_widget.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SuperAdminWidget(
      role: authProvider.role ?? 'ADMIN',
      email: authProvider.email ?? 'admin@provaluer.com',
      fullName: authProvider.fullName ?? 'System Administrator',
      onLogout: () {
        authProvider.logout();
        context.go('/login');
      },
    );
  }
}
