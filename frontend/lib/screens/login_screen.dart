import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  // ── Controllers (unchanged business logic) ────────────────────────────────
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _mobileCtrl   = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();

  bool _isLogin   = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  // ── Submit Handler — Username Based ────────────────────────────────────
  Future<void> _handleSubmit() async {
    setState(() { _isLoading = true; _error = null; });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool success;

    if (_isLogin) {
      success = await auth.login(
        _usernameCtrl.text.trim(), _passwordCtrl.text.trim());
    } else {
      success = await auth.register(
        _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : "${_usernameCtrl.text.trim()}@provaluer.com",
        _passwordCtrl.text.trim(),
        'CLIENT',
        _mobileCtrl.text.trim(),
        _nameCtrl.text.trim(),
      );
      if (success) {
        setState(() => _isLogin = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppComponents.successSnack('Account created. Please sign in with your username.'));
        }
      }
    }

    setState(() => _isLoading = false);

    if (success && _isLogin) {
      final role = auth.role;
      if (!mounted) return;
      if (role == 'CLIENT') {
        context.go('/client');
      } else if (role == 'PA') {
        context.go('/pa');
      } else if (role == 'SPA') {
        context.go('/spa');
      } else if (role == 'SUPER_ADMIN' || role == 'ADMIN') {
        context.go('/admin');
      }
    } else if (!success) {
      setState(() => _error = 'Invalid credentials. Please verify username and password.');
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose(); _passwordCtrl.dispose();
    _mobileCtrl.dispose(); _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ── Left editorial panel (desktop only) ───────────────────────
          if (isDesktop)
            Expanded(
              flex: 11,
              child: _LeftPanel(),
            ),

          // ── Right form panel ─────────────────────────────────────────
          Expanded(
            flex: 10,
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isDesktop) ...[
                          AppComponents.logo(fontSize: 18),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],

                        // Heading
                        Text(
                          _isLogin ? 'Welcome Back' : 'Create Account',
                          style: AppTypography.sectionHeading(color: const Color(0xFF0F172A)),
                        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          _isLogin
                              ? 'Enter your username and password to sign in.'
                              : 'Register for valuation services.',
                          style: AppTypography.bodyMd(color: const Color(0xFF64748B)),
                        ).animate(delay: 100.ms).fadeIn(duration: 400.ms),

                        const SizedBox(height: AppSpacing.xxl),

                        // Error message
                        if (_error != null) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.brandRed,
                              borderRadius: AppRadius.brMd,
                              border: Border.all(
                                  color: AppColors.brandRedDark.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.brandRedDark, size: 16),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(_error!,
                                      style: AppTypography.caption(
                                          color: AppColors.brandRedDark)),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Form fields
                        _formField(
                          controller: _usernameCtrl,
                          label: 'Username',
                          icon: Icons.person_outline_rounded,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _passwordField(),

                        if (!_isLogin) ...[
                          const SizedBox(height: AppSpacing.md),
                          _formField(
                            controller: _nameCtrl,
                            label: 'Full Name',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formField(
                            controller: _mobileCtrl,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _formField(
                            controller: _emailCtrl,
                            label: 'Contact Email (Optional)',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              if (!_isLoading) {
                                _handleSubmit();
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xxl),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF14B8A6), // Primary brand teal
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.hairlineStrong,
                              disabledForegroundColor: AppColors.slate,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: AppSpacing.buttonPadding,
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
                              textStyle: AppTypography.buttonMd(color: Colors.white),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Create Account',
                                    style: AppTypography.buttonMd(
                                        color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Toggle
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            }),
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Text(
                                _isLogin
                                    ? "Don't have an account?  Sign Up"
                                    : 'Already have an account?  Sign In',
                                style: AppTypography.bodySmMedium(
                                    color: const Color(0xFF0F766E)), // Secondary brand teal
                              ),
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

  Widget _passwordField() => TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        textInputAction: _isLogin ? TextInputAction.done : TextInputAction.next,
        onSubmitted: (_) {
          if (!_isLoading) {
            _handleSubmit();
          }
        },
        style: AppTypography.bodyMd(color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 16, color: Color(0xFF0F766E)),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 16,
              color: const Color(0xFF64748B),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyMd(color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF0F766E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ── Left Editorial Panel ───────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F766E), // Secondary brand teal
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // #0F766E
            Color(0xFF115E59), // Deep rich teal
          ],
        ),
      ),
      padding: const EdgeInsets.all(72),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          AppComponents.logo(fontSize: 18, darkMode: true),

          // Central editorial content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: AppRadius.brFull,
                  border: Border.all(color: const Color(0xFF14B8A6).withValues(alpha: 0.5)),
                ),
                child: Text('ENTERPRISE PLATFORM',
                    style: AppTypography.microUppercase(
                        color: Colors.white)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Enterprise\nValuation &\nProperty\nIntelligence',
                style: AppTypography.displayHeroMd(color: Colors.white)
                    .copyWith(height: 1.05),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Automated SLA monitoring, value-based balance gates, '
                'DOCX template token normalization, and Class 3 HSM digital '
                'signatures for regulatory compliance.',
                style: AppTypography.bodyMd(color: Colors.white.withValues(alpha: 0.88)),
              ).animate(delay: 200.ms).fadeIn(duration: 600.ms),

              const SizedBox(height: AppSpacing.xxxl),

              // Feature highlights with crisp contrast
              ...[
                'IBBI Registered Valuers',
                'Empanelled Banks',
                'Hyderabad & Secunderabad',
                'Regulatory Grade Reports',
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF14B8A6), // Primary teal accent
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(item,
                            style: AppTypography.bodySmMedium(
                                color: Colors.white.withValues(alpha: 0.95))),
                      ],
                    ),
                  )),
            ],
          ),

          // Bottom tagline
          Text(
            'Accurate Valuations.\nProfessional Insights.\nTrusted Decisions.',
            style: AppTypography.micro(color: Colors.white.withValues(alpha: 0.65)),
          ),
        ],
      ),
    );
  }
}

// ── Role Hint Tabs (visual only — server assigns roles) ───────────────────────

class _RoleHintTabs extends StatefulWidget {
  @override
  State<_RoleHintTabs> createState() => _RoleHintTabsState();
}

class _RoleHintTabsState extends State<_RoleHintTabs> {
  int _selected = 0;
  final _roles = ['Client', 'Analyst', 'Admin'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: List.generate(
          _roles.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _selected == i ? const Color(0xFF0F766E) : Colors.transparent,
                  borderRadius: AppRadius.brFull,
                ),
                alignment: Alignment.center,
                child: Text(
                  _roles[i],
                  style: AppTypography.buttonMd(
                    color: _selected == i
                        ? Colors.white
                        : const Color(0xFF64748B),
                  ).copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
