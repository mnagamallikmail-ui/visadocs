import 'package:flutter/material.dart';
import '../../features/superadmin/admin_sections.dart';
import '../../theme/app_colors.dart';

/// Standalone Template Management Screen for Admin Portal.
class TemplateManagementScreen extends StatelessWidget {
  const TemplateManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.canvas,
      body: AdminTemplateSection(),
    );
  }
}
