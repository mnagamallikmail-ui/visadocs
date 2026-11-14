import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../services/token_storage.dart';
import '../screens/app_info_screen.dart';

class AppDrawer extends StatelessWidget {
  final String activeRoute;
  final VoidCallback? onRefresh;

  const AppDrawer({
    super.key,
    required this.activeRoute,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 290,
      backgroundColor: Colors.white,
      child: FutureBuilder<Map<String, String?>>(
        future: _getUserDetails(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};
          final email = data['email'] ?? 'appraiser@provaluer.in';
          final name = data['name'] ?? 'ProValuer Appraiser';
          final role = data['role'] ?? 'VALUER';

          return Column(
            children: [
              // User Profile Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF3B82F6),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Menu Navigation List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.dashboard_rounded,
                      title: 'Field Hub & Portal',
                      route: '/portal',
                      isSelected: activeRoute == '/portal' || activeRoute.startsWith('/portal'),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.assignment_outlined,
                      title: 'Valuation Dossiers',
                      route: '/admin',
                      isSelected: activeRoute == '/admin',
                    ),
                    if (role.contains('ADMIN') || role.contains('SUPER')) ...[
                      _buildNavItem(
                        context: context,
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Super Admin Hub',
                        route: '/superadmin',
                        isSelected: activeRoute == '/superadmin',
                      ),
                      _buildNavItem(
                        context: context,
                        icon: Icons.people_alt_outlined,
                        title: 'User Roster',
                        route: '/superadmin?tab=users',
                        isSelected: false,
                      ),
                    ],
                    _buildNavItem(
                      context: context,
                      icon: Icons.business_center_outlined,
                      title: 'Client Workspace',
                      route: '/client-hub',
                      isSelected: activeRoute == '/client-hub',
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                    _buildNavItem(
                      context: context,
                      icon: Icons.info_outline_rounded,
                      title: 'App Information',
                      route: 'custom_app_info',
                      isSelected: false,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AppInfoScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Sign Out & Version Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: const Color(0xFFFEF2F2),
                      leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () => _confirmSignOut(context),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Pro Valuer v1.0.0 (Build 101)',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF1E293B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap ??
            () {
              Navigator.pop(context);
              if (route.isNotEmpty && route != activeRoute) {
                context.go(route);
              }
            },
      ),
    );
  }

  Future<Map<String, String?>> _getUserDetails() async {
    final session = TokenStorage.loadSession();
    final token = session['token']?.toString() ?? TokenStorage.getToken();
    final email = session['email']?.toString();
    final role = session['role']?.toString();
    return {
      'token': token,
      'email': email ?? 'appraiser@provaluer.in',
      'name': (email != null && email.contains('@')) ? email.split('@').first.replaceAll('.', ' ') : 'Appraiser',
      'role': role ?? 'VALUER',
    };
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of Pro Valuer? Any unsaved offline forms are safely kept locally.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              TokenStorage.clearSession();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

