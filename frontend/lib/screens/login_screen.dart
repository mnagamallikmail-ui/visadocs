import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../theme/app_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl   = TextEditingController();
  final _nameCtrl     = TextEditingController();

  bool _isLogin     = true;
  bool _isLoading   = false;
  String? _error;

  Future<void> _handleSubmit() async {
    setState(() { _isLoading = true; _error = null; });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await auth.login(
        _emailCtrl.text.trim(), _passwordCtrl.text.trim());
    } else {
      success = await auth.register(
        _emailCtrl.text.trim(), _passwordCtrl.text.trim(),
        'CLIENT', _mobileCtrl.text.trim(), _nameCtrl.text.trim());
      if (success) {
        setState(() => _isLogin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppComponents.successSnack('Account created. Please sign in.'));
        }
      }
    }

    setState(() => _isLoading = false);

    if (success && _isLogin) {
      final role = auth.role;
      if (!mounted) return;
      if (role == 'CLIENT')                              context.go('/client');
      else if (role == 'PA')                             context.go('/pa');
      else if (role == 'SPA')                            context.go('/spa');
      else if (role == 'SUPER_ADMIN' || role == 'ADMIN') context.go('/admin');
    } else if (!success) {
      setState(() => _error = 'Action failed. Please verify credentials.');
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose();
    _mobileCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          // ── Left dark editorial panel (desktop only) ──────────────────
          if (isDesktop)
            Expanded(
              flex: 11,
              child: Container(
                color: AppColors.primary,
                padding: const EdgeInsets.all(72),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppComponents.logo(fontSize: 18, darkMode: true),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Yellow promo-style badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: AppRadius.brFull,
                          ),
                          child: Text('ENTERPRISE PLATFORM',
                              style: AppTypography.captionBold(color: AppColors.primary)),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Enterprise\nValuation &\nProperty\nIntelligence',
                          style: AppTypography.heading1(color: AppColors.onDark)
                              .copyWith(fontSize: 52, letterSpacing: -2.5, height: 1.05),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'Automated SLA monitoring, value-based balance gates, DOCX template token normalization, and Class 3 HSM digital signatures for regulatory compliance.',
                          style: AppTypography.bodyMd(color: AppColors.onDarkMuted),
                        ),
                      ],
                    ),
                    // Trust marks
                    Wrap(
                      spacing: AppSpacing.xl,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _trustMark('IBBI Registered Valuers'),
                        _trustMark('Empanelled Banks'),
                        _trustMark('Hyderabad & Secunderabad'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Right form panel ─────────────────────────────────────────
          Expanded(
            flex: 10,
            child: Container(
              color: AppColors.canvas,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isDesktop) ...[
                          AppComponents.logo(fontSize: 18),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],
                        Text(
                          _isLogin ? 'Sign In' : 'Create Account',
                          style: AppTypography.heading3(color: AppColors.ink),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _isLogin
                              ? 'Access your commercial valuation portal.'
                              : 'Register for valuation services.',
                          style: AppTypography.bodySm(color: AppColors.slate),
                        ),
                        const SizedBox(height: AppSpacing.xxl),

                        // Error message
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: AppSpacing.sm),
                            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.brandRed,
                              borderRadius: AppRadius.brMd,
                              border: Border.all(
                                  color: AppColors.brandRedDark.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.brandRedDark, size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(_error!,
                                      style: AppTypography.caption(
                                          color: AppColors.brandRedDark)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        _formField(
                          controller: _emailCtrl,
                          label: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _formField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          obscureText: true,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: AppSpacing.md),
                          _formField(
                            controller: _mobileCtrl,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            icon: Icons.person_outline,
                            keyboardType: TextInputType.name,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),

                        // Submit — full-width pill button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: AppComponents.primaryButtonStyle(),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: AppColors.onPrimary, strokeWidth: 2),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: AppTypography.buttonMd(
                                        color: AppColors.onPrimary),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Toggle
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = !_isLogin;
                              _error   = null;
                            }),
                            child: Text(
                              _isLogin
                                  ? "Don't have an account?  Sign Up"
                                  : 'Already have an account?  Sign In',
                              style: AppTypography.bodySmMedium(
                                  color: AppColors.brandBlue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustMark(String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
                color: AppColors.onDarkMuted, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(text, style: AppTypography.micro(color: AppColors.onDarkMuted)),
        ],
      );

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTypography.bodyMd(color: AppColors.ink),
        decoration: AppComponents.textInput(
          label: label,
          prefixIcon: Icon(icon, size: 16, color: AppColors.steel),
        ),
      );
}
