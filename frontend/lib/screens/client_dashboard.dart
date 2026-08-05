import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_components.dart';
import '../features/valuation_portal/valuation_portal_widget.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({super.key});

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // T&C interceptor — Miro-inspired modal overlay
    if (authProvider.tcRequired) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.xl),
              padding: const EdgeInsets.all(AppSpacing.section),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadius.brXxl,
                border: Border.all(color: AppColors.hairline),
                boxShadow: AppShadows.modal,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Deep teal icon badge
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.tealLight,
                      borderRadius: AppRadius.brFull,
                    ),
                    child: const Icon(Icons.gavel_outlined,
                        color: AppColors.deepTeal, size: 32),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Agreement Update Required',
                      style: AppTypography.sectionTitle(color: AppColors.ink),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'To continue utilizing ProValuer Commercial Valuation Services, '
                    'you must read and accept our updated T&C guidelines version '
                    '(v${authProvider.activeTcVersion}).',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMd(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () =>
                                authProvider.acceptTc(authProvider.activeTcVersion),
                            style: AppComponents.primaryButtonStyle(),
                            child: Text('I Agree & Accept',
                                style: AppTypography.buttonMd(
                                    color: AppColors.onPrimary)),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => authProvider.logout(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.brandRedDark,
                            side: const BorderSide(color: AppColors.hairline),
                            shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.brMd),
                          ),
                          child: Text('Logout',
                              style: AppTypography.buttonMd(
                                  color: AppColors.brandRedDark)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return ValuationPortalWidget(
      role: authProvider.role ?? 'CLIENT',
      email: authProvider.email ?? 'client@provaluer.com',
      fullName: authProvider.fullName ?? 'Client User',
      onLogout: () {
        authProvider.logout();
        context.go('/login');
      },
    );
  }
}
