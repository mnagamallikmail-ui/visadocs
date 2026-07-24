import 'package:flutter/material.dart';
import 'valuation_form.dart';
import 'valuation_directory.dart';
import 'valuation_analytics.dart';

class ValuationWorkspaceWidget extends StatelessWidget {
  final String viewKey;
  final String userRole;
  final VoidCallback onFormSubmitted;

  const ValuationWorkspaceWidget({
    super.key,
    required this.viewKey,
    required this.userRole,
    required this.onFormSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewKey) {
      case 'start_new':
        return ValuationFormWidget(onSubmitSuccess: onFormSubmitted);
      case 'project_list':
        return ValuationDirectoryWidget(userRole: userRole);
      case 'analytics':
        return const ValuationAnalyticsWidget();
      default:
        return const Center(child: Text("Premium view not found."));
    }
  }
}
