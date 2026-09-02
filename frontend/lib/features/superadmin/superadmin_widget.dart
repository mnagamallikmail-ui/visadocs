import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_components.dart';
import '../../services/api_service.dart';
import '../valuation_portal/valuation_portal_widget.dart';
import 'admin_sections.dart';

class SuperAdminWidget extends StatefulWidget {
  final String role;
  final String email;
  final String fullName;
  final VoidCallback onLogout;

  const SuperAdminWidget({
    super.key,
    required this.role,
    required this.email,
    required this.fullName,
    required this.onLogout,
  });

  @override
  State<SuperAdminWidget> createState() => _SuperAdminWidgetState();
}

class _SuperAdminWidgetState extends State<SuperAdminWidget> {
  String _selectedMenu = 'overview';
  bool _showValuationPortal = false;
  final ApiService _api = ApiService();

  // User Management state
  bool _loadingUsers = false;
  String? _usersError;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final res = await _api.dio.get('/api/v1/admin/users');
      setState(() {
        _users = res.data as List<dynamic>;
        _loadingUsers = false;
      });
    } on DioException catch (e) {
      setState(() {
        _usersError = e.response?.data?.toString() ?? e.message;
        _loadingUsers = false;
      });
    }
  }

  Future<void> _softDelete(dynamic user) async {
    try {
      await _api.dio.delete('/api/v1/admin/users/${user['id']}');
      _showSnack('User archived successfully.', AppColors.success);
      _loadUsers();
    } catch (_) {
      _showSnack('Action failed.', AppColors.brandRedDark);
    }
  }

  Future<void> _hardDelete(dynamic user) async {
    try {
      await _api.dio.delete('/api/v1/admin/users/${user['id']}/hard');
      _showSnack('User permanently purged.', AppColors.success);
      _loadUsers();
    } catch (_) {
      _showSnack('Hard delete failed.', AppColors.brandRedDark);
    }
  }

  Future<void> _toggleLock(dynamic user) async {
    final isLocked = user['locked'] == true;
    try {
      await _api.dio.post('/api/v1/admin/users/${user['id']}/${isLocked ? 'unlock' : 'lock'}');
      _showSnack('Account ${isLocked ? 'unlocked' : 'locked'}.', AppColors.success);
      _loadUsers();
    } catch (_) {}
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      content: Text(
        msg,
        style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ));
  }

  void _showSoftDeleteDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairlineSoft),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.archive_outlined, color: AppColors.slate, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Confirm Archive',
                style: AppTypography.heading4().copyWith(color: AppColors.ink),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to archive this record? This will hide the item from all active directories, but it can still be recovered by the system administrator for compliance auditing.',
          style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13).copyWith(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _softDelete(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellowDark,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Archive',
              style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showHardDeleteDialog(dynamic user) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_forever_outlined, color: AppColors.brandRedDark, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permanent Deletion',
                  style: AppTypography.heading4().copyWith(color: AppColors.brandRedDark),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action is completely irreversible. Hard deleting this record will permanently erase it along with all its linked logs, historical data, and file references from the database. Type \'DELETE\' to confirm.',
                style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13).copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                autofocus: true,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                onChanged: (_) => ss(() {}),
                decoration: InputDecoration(
                  hintText: 'Type DELETE here...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ctrl.dispose();
              },
              child: Text(
                'Cancel',
                style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: ctrl.text.trim() == 'DELETE'
                  ? () {
                      Navigator.pop(ctx);
                      ctrl.dispose();
                      _hardDelete(user);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRedDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.hairlineSoft,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text(
                'Erase Data',
                style: AppTypography.bodySm().copyWith(
                  color: ctrl.text.trim() == 'DELETE' ? Colors.white : Colors.black26,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog() {
    final usernameCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: 'password');
    final mobileCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'PA';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Create New User', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Username *', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. mallik, poojitha, ravi',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Full Name *', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Full display name',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Role *', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PA', child: Text('PA — Property Analyst')),
                      DropdownMenuItem(value: 'SPA', child: Text('SPA — Senior Property Analyst')),
                      DropdownMenuItem(value: 'CLIENT', child: Text('CLIENT — Standard Client')),
                      DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('ADMIN — Administrator')),
                    ],
                    onChanged: (v) {
                      if (v != null) ss(() => selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Password *', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: passwordCtrl,
                    decoration: InputDecoration(
                      hintText: 'Initial password',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Mobile Number', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: mobileCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. 9876543210',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Contact Email (Optional)', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. name@domain.com',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final uname = usernameCtrl.text.trim();
                final fname = nameCtrl.text.trim();
                final pass = passwordCtrl.text.trim();
                if (uname.isEmpty || fname.isEmpty || pass.isEmpty) {
                  _showSnack('Username, Full Name and Password are required.', AppColors.brandRedDark);
                  return;
                }
                Navigator.pop(ctx);
                try {
                  await _api.dio.post('/api/v1/admin/users', data: {
                    'username': uname,
                    'fullName': fname,
                    'password': pass,
                    'role': selectedRole,
                    'mobileNumber': mobileCtrl.text.trim().isNotEmpty ? mobileCtrl.text.trim() : null,
                    'email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                  });
                  _showSnack('User @$uname created successfully.', AppColors.success);
                  _loadUsers();
                } catch (e) {
                  _showSnack('Failed to create user. Verify uniqueness.', AppColors.brandRedDark);
                }
              },
              style: AppComponents.primaryButtonStyle(),
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(dynamic user) {
    final nameCtrl = TextEditingController(text: user['fullName'] ?? '');
    final mobileCtrl = TextEditingController(text: user['mobileNumber'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    String selectedRole = user['role'] ?? 'CLIENT';
    final isMasterAdmin = user['username'] == 'admin';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Edit User: @${user['username'] ?? user['email']}', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Role', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'PA', child: Text('PA — Property Analyst')),
                      DropdownMenuItem(value: 'SPA', child: Text('SPA — Senior Property Analyst')),
                      DropdownMenuItem(value: 'CLIENT', child: Text('CLIENT — Standard Client')),
                      DropdownMenuItem(value: 'SUPER_ADMIN', child: Text('ADMIN — Administrator')),
                    ],
                    onChanged: isMasterAdmin ? null : (v) {
                      if (v != null) ss(() => selectedRole = v);
                    },
                  ),
                  if (isMasterAdmin) ...[
                    const SizedBox(height: 4),
                    Text('Master admin role is permanent and cannot be changed.', style: AppTypography.caption(color: AppColors.muted)),
                  ],
                  const SizedBox(height: 12),
                  Text('Mobile Number', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: mobileCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Contact Email (Optional)', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.dio.put('/api/v1/admin/users/${user['id']}', data: {
                    'fullName': nameCtrl.text.trim(),
                    'mobileNumber': mobileCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                  });
                  if (!isMasterAdmin && selectedRole != user['role']) {
                    await _api.dio.put('/api/v1/admin/users/${user['id']}/role', data: {
                      'role': selectedRole,
                    });
                  }
                  _showSnack('User profile updated.', AppColors.success);
                  _loadUsers();
                } catch (e) {
                  _showSnack('Failed to update user.', AppColors.brandRedDark);
                }
              },
              style: AppComponents.primaryButtonStyle(),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(dynamic user) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairlineSoft),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Reset Password: @${user['username'] ?? user['email']}', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a new password for this user (minimum 4 characters):', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: passCtrl,
              autofocus: true,
              obscureText: false,
              decoration: InputDecoration(
                hintText: 'New password...',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = passCtrl.text.trim();
              if (newPass.length < 4) {
                _showSnack('Password must be at least 4 characters.', AppColors.brandRedDark);
                return;
              }
              Navigator.pop(ctx);
              try {
                await _api.dio.post('/api/v1/admin/users/${user['id']}/reset-password', data: {
                  'newPassword': newPass,
                });
                _showSnack('Password successfully reset for @${user['username'] ?? user['email']}.', AppColors.success);
              } catch (e) {
                _showSnack('Failed to reset password.', AppColors.brandRedDark);
              }
            },
            style: AppComponents.primaryButtonStyle(),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar ─────────────────────────────────────────────
  static const _menuItems = [
    {'key': 'overview', 'label': 'Overview', 'icon': Icons.dashboard_outlined},
    {'key': 'valuation_portal', 'label': 'Valuation Portal', 'icon': Icons.swap_horiz_outlined},
    {'key': 'users', 'label': 'User Management', 'icon': Icons.manage_accounts_outlined},
    {'key': 'queue', 'label': 'Queue Management', 'icon': Icons.queue_play_next_outlined},
    {'key': 'sla', 'label': 'SLA Dashboard', 'icon': Icons.timer_outlined},
    {'key': 'pricing', 'label': 'Pricing Control', 'icon': Icons.price_change_outlined},
    {'key': 'tc', 'label': 'T&C Management', 'icon': Icons.gavel_outlined},
    {'key': 'templates', 'label': 'Template Manager', 'icon': Icons.description_outlined},
    {'key': 'building_types', 'label': 'Building Types', 'icon': Icons.apartment_rounded},
    {'key': 'val_settings', 'label': 'Valuation Settings', 'icon': Icons.tune_rounded},
    {'key': 'reports', 'label': 'Report Control', 'icon': Icons.summarize_outlined},
    {'key': 'trash', 'label': 'Trash Bin', 'icon': Icons.delete_outline_rounded},
    {'key': 'signing', 'label': 'Signing Monitor', 'icon': Icons.draw_outlined},
  ];

  List<Map<String, dynamic>> _getFilteredMenuItems() {
    final isSuper = widget.role == 'SUPER_ADMIN';
    return _menuItems.where((m) {
      final key = m['key'] as String;
      if (isSuper) return true;
      return key == 'overview' || key == 'templates' || key == 'signing' || key == 'valuation_portal';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_showValuationPortal) {
      return ValuationPortalWidget(
        role: widget.role,
        email: widget.email,
        fullName: widget.fullName,
        onLogout: widget.onLogout,
        onBackToAdmin: () {
          setState(() {
            _showValuationPortal = false;
          });
        },
      );
    }
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          _buildSidebar(),
          Container(width: 1, color: AppColors.hairline),
          Expanded(child: _buildCanvas()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.sidebarBg, // warm cream sidebar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo area
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppComponents.logo(fontSize: 17),
                const SizedBox(height: 3),
                Text(
                  'Admin Console',
                  style: AppTypography.bodySm().copyWith(
                    color: AppColors.sidebarMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Divider
          Container(height: 1, color: AppColors.hairline, margin: const EdgeInsets.symmetric(horizontal: 20)),
          const SizedBox(height: 12),
          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _getFilteredMenuItems().map((m) => _sidebarItem(
                m['key'] as String,
                m['label'] as String,
                m['icon'] as IconData,
              )).toList(),
            ),
          ),
          // Profile footer
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.deepTeal.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : 'A',
                          style: AppTypography.bodySm().copyWith(
                            color: AppColors.deepTeal,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fullName,
                            style: AppTypography.bodySm().copyWith(
                              color: AppColors.sidebarText,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            widget.role.replaceAll('_', ' '),
                            style: AppTypography.bodySm().copyWith(
                              color: AppColors.sidebarMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: AppTypography.bodySm().copyWith(
                    color: AppColors.sidebarMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  height: 1,
                  color: AppColors.hairline,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onLogout,
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: AppColors.brandRedDark,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sign Out',
                          style: AppTypography.bodySm().copyWith(
                            color: AppColors.brandRedDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(String key, String label, IconData icon) {
    final isSel = _selectedMenu == key;
    return _HoverableSidebarItem(
      key: ValueKey(key),
      label: label,
      icon: icon,
      isSelected: isSel,
      onTap: () {
        if (key == 'valuation_portal') {
          setState(() => _showValuationPortal = true);
        } else {
          setState(() {
            _selectedMenu = key;
            if (key == 'users') _loadUsers();
          });
        }
      },
    );
  }

  // ─── Canvas Router ────────────────────────────────────────
  Widget _buildCanvas() {
    final isSuper = widget.role == 'SUPER_ADMIN';
    final menu = _selectedMenu;
    if (!isSuper && menu != 'overview' && menu != 'templates' && menu != 'signing') {
      return const AdminOverviewSection();
    }
    switch (menu) {
      case 'overview':
        return const AdminOverviewSection();
      case 'users':
        return _buildUserManagement();
      case 'queue':
        return const AdminQueueSection();
      case 'sla':
        return const AdminSlaSection();
      case 'pricing':
        return const AdminPricingSection();
      case 'tc':
        return const AdminTcSection();
      case 'templates':
        return const AdminTemplateSection();
      case 'building_types':
        return const AdminBuildingTypesSection();
      case 'val_settings':
        return const AdminValuationSettingsSection();
      case 'reports':
        return const AdminReportSection();
      case 'trash':
        return const AdminTrashBinSection();
      case 'signing':
        return const AdminSigningSection();
      default:
        return const AdminOverviewSection();
    }
  }

  // ─── User Management (inline) ────────────────────────────
  Widget _buildUserManagement() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.hairlineSoft)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Management',
                      style: AppTypography.heading3().copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage all portal user accounts — lock, archive, or permanently erase.',
                      style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Add User'),
                style: AppComponents.primaryButtonStyle(),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: AppComponents.secondaryButtonStyle().copyWith(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
            ],
          ),
        ),
        if (_loadingUsers)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_usersError != null)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.brandRedDark, size: 40),
                  const SizedBox(height: 12),
                  Text(_usersError!, style: AppTypography.bodySm().copyWith(color: AppColors.brandRedDark, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Retry'),
                    style: AppComponents.primaryButtonStyle(),
                  ),
                ],
              ),
            ),
          )
        else if (_users.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline, color: AppColors.muted, size: 48),
                  const SizedBox(height: 12),
                  Text('No Users Found', style: AppTypography.heading4().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 4),
                  Text('Accounts created on the platform will appear here.', style: AppTypography.bodySm().copyWith(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Modern Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'ID',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'User (Username / Name)',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Contact (Mobile / Email)',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Role',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Status',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: 290,
                          child: Text(
                            'Actions',
                            style: AppTypography.captionBold().copyWith(color: AppColors.slate),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._users.map((u) => _userRow(u)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _userRow(dynamic u) {
    final isLocked = u['locked'] == true;
    final isMasterAdmin = u['username'] == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.hairlineSoft),
          left: BorderSide(color: AppColors.hairlineSoft),
          right: BorderSide(color: AppColors.hairlineSoft),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '#${u['id']}',
              style: AppTypography.bodySm().copyWith(color: AppColors.muted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '@${u['username'] ?? u['email']}',
                      style: AppTypography.bodySm().copyWith(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isMasterAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('MASTER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${u['fullName'] ?? '—'}',
                  style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${u['mobileNumber'] ?? '—'}',
                  style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${u['email'] ?? 'No contact email'}',
                  style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${u['role']}'.replaceAll('_', ' '),
                  style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isLocked ? AppColors.errorBg : AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isLocked ? 'Locked' : 'Active',
                  style: AppTypography.bodySm().copyWith(
                    color: isLocked ? AppColors.brandRedDark : AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 290,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _actionBtn(
                  'Edit',
                  Icons.edit_outlined,
                  AppColors.primary,
                  () => _showEditUserDialog(u),
                  true,
                ),
                const SizedBox(width: 4),
                _actionBtn(
                  'Reset',
                  Icons.vpn_key_outlined,
                  AppColors.slate,
                  () => _showResetPasswordDialog(u),
                  true,
                ),
                const SizedBox(width: 4),
                if (isMasterAdmin)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: AppColors.slate),
                        SizedBox(width: 4),
                        Text('Protected', style: TextStyle(fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )
                else ...[
                  _actionBtn(
                    isLocked ? 'Unlock' : 'Lock',
                    isLocked ? Icons.lock_open_outlined : Icons.lock_outline,
                    AppColors.primary,
                    () => _toggleLock(u),
                    true,
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(
                    'Archive',
                    Icons.archive_outlined,
                    AppColors.yellowDark,
                    () => _showSoftDeleteDialog(u),
                    true,
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(
                    'Erase',
                    Icons.delete_forever_outlined,
                    AppColors.brandRedDark,
                    () => _showHardDeleteDialog(u),
                    false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap, bool outlined) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withOpacity(0.08),
            border: Border.all(color: outlined ? AppColors.hairlineSoft : color.withOpacity(0.3), width: 1.0),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.bodySm().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Hoverable Sidebar Item ──────────────────────────────────────────────────

class _HoverableSidebarItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _HoverableSidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_HoverableSidebarItem> createState() => _HoverableSidebarItemState();
}

class _HoverableSidebarItemState extends State<_HoverableSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.sidebarSelected      // Blue 50 tint
                : (_hovered ? AppColors.sidebarHover : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isActive
                    ? AppColors.sidebarAccent
                    : (_hovered ? AppColors.sidebarText : AppColors.sidebarMuted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTypography.bodySm().copyWith(
                    color: isActive
                        ? AppColors.sidebarAccent
                        : (_hovered ? AppColors.sidebarText : AppColors.sidebarMuted),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




