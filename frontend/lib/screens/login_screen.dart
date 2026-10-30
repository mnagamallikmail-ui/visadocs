import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isSubmitting = false;

  void _navigateByRole(String? role) {
    if (role == 'CLIENT') {
      context.go('/client');
    } else if (role == 'PA') {
      context.go('/pa');
    } else if (role == 'SPA') {
      context.go('/spa');
    } else if (role == 'SUPER_ADMIN' || role == 'ADMIN') {
      context.go('/admin');
    } else {
      context.go('/');
    }
  }

  // ── Submit Handler — Username Based with MFA Detection ────────────────────
  Future<void> _handleSubmit() async {
    if (_isSubmitting || _isLoading) return; // Prevent double submission
    _isSubmitting = true;
    setState(() { _isLoading = true; _error = null; });

    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_isLogin) {
      final result = await auth.login(
        _usernameCtrl.text.trim(), _passwordCtrl.text.trim());
      _isSubmitting = false;
      setState(() => _isLoading = false);

      if (result.success && mounted) {
        _navigateByRole(auth.role);
      } else if (result.mfaSetupRequired && mounted) {
        _showMfaSetupModal(result);
      } else if (result.mfaRequired && mounted) {
        _showMfaVerifyModal(result);
      } else {
        setState(() => _error = result.errorMessage ?? 'Invalid credentials. Please verify username and password.');
      }
    } else {
      final email = _emailCtrl.text.trim().isNotEmpty
          ? _emailCtrl.text.trim()
          : (_usernameCtrl.text.trim().contains('@')
              ? _usernameCtrl.text.trim()
              : "${_usernameCtrl.text.trim()}@provaluer.com");
      final pass = _passwordCtrl.text.trim();
      final usernameOrEmail = _usernameCtrl.text.trim().isNotEmpty ? _usernameCtrl.text.trim() : email;
      final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : usernameOrEmail;
      final mobile = _mobileCtrl.text.trim().isNotEmpty ? _mobileCtrl.text.trim() : "9999999999";

      final success = await auth.register(
        email,
        pass,
        'CLIENT',
        mobile,
        name,
      );

      if (success) {
        final result = await auth.login(usernameOrEmail, pass);
        _isSubmitting = false;
        if (mounted) {
          setState(() => _isLoading = false);
          if (result.success) {
            _navigateByRole(auth.role);
            return;
          } else if (result.mfaSetupRequired) {
            _showMfaSetupModal(result);
            return;
          } else if (result.mfaRequired) {
            _showMfaVerifyModal(result);
            return;
          }
        }
      }

      _isSubmitting = false;
      setState(() {
        _isLoading = false;
        _error = 'Registration failed. Email or username may already be in use.';
      });
    }
  }

  // ── MFA Setup Modal (Privileged Role Initial Enrollment) ─────────────────
  void _showMfaSetupModal(LoginResult result) {
    final codeCtrl = TextEditingController();
    String? modalError;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: 520,
            constraints: const BoxConstraints(maxHeight: 640),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.security_rounded, color: Color(0xFF0F766E), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Multi-Factor Authentication Setup',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'DPDP Act Section 8(5) Mandatory Privilege Security',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF15803D)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Scan the QR code with Google Authenticator, Microsoft Authenticator, or Authy to configure your account.',
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 170,
                      height: 170,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Image.network(
                        'https://api.qrserver.com/v1/create-qr-code/?size=170x170&data=${Uri.encodeComponent(result.otpAuthUri ?? '')}',
                        loadingBuilder: (_, child, p) => p == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.qr_code_2, size: 64, color: Color(0xFF94A3B8))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Secret Key Fallback:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            result.secretKey ?? '',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Color(0xFF0F172A)),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: result.secretKey ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Secret key copied!'), duration: Duration(seconds: 2)));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0F766E)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Recovery Codes (Keep safe offline):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: result.recoveryCodes.map((code) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Text(code, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                    )).toList(),
                  ),
                  const SizedBox(height: 18),
                  const Text('Enter 6-Digit TOTP Code from App:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: codeCtrl,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '000000',
                      hintStyle: TextStyle(fontSize: 22, letterSpacing: 8, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2)),
                    ),
                  ),
                  if (modalError != null) ...[
                    const SizedBox(height: 8),
                    Text(modalError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isVerifying ? null : () => Navigator.pop(dlgCtx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isVerifying ? null : () async {
                            final code = codeCtrl.text.trim();
                            if (code.length != 6) {
                              setDlgState(() => modalError = 'Please enter a 6-digit verification code.');
                              return;
                            }
                            setDlgState(() { isVerifying = true; modalError = null; });
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            final confirmed = await auth.confirmMfaSetup(
                              setupToken: result.setupToken ?? '',
                              secretKey: result.secretKey ?? '',
                              verificationCode: code,
                              recoveryCodes: result.recoveryCodes,
                            );
                            if (confirmed && dlgCtx.mounted && mounted) {
                              Navigator.pop(dlgCtx);
                              _navigateByRole(auth.role);
                            } else {
                              setDlgState(() {
                                isVerifying = false;
                                modalError = 'Invalid code. Check your authenticator time or enter again.';
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF14B8A6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isVerifying
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Confirm Setup'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── MFA Verification Modal (Standard TOTP / Recovery Code Login) ──────────
  void _showMfaVerifyModal(LoginResult result) {
    final codeCtrl = TextEditingController();
    String? modalError;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF0F766E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Two-Factor Authentication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          SizedBox(height: 2),
                          Text('Enter code to verify your identity', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Enter 6-digit TOTP or Recovery Code:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                TextField(
                  controller: codeCtrl,
                  maxLength: 9,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. 123456',
                    hintStyle: TextStyle(fontSize: 16, letterSpacing: 2, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 2)),
                  ),
                ),
                if (modalError != null) ...[
                  const SizedBox(height: 8),
                  Text(modalError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isVerifying ? null : () => Navigator.pop(dlgCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isVerifying ? null : () async {
                          final code = codeCtrl.text.trim();
                          if (code.isEmpty) {
                            setDlgState(() => modalError = 'Please enter your code.');
                            return;
                          }
                          setDlgState(() { isVerifying = true; modalError = null; });
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final verified = await auth.verifyMfa(
                            mfaToken: result.mfaToken ?? '',
                            code: code,
                          );
                          if (verified && dlgCtx.mounted && mounted) {
                            Navigator.pop(dlgCtx);
                            _navigateByRole(auth.role);
                          } else {
                            setDlgState(() {
                              isVerifying = false;
                              modalError = 'Invalid TOTP code or recovery code. Please try again.';
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: isVerifying
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify & Sign In'),
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
                        // Back to Home action
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              InkWell(
                                onTap: () => context.go('/'),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFF64748B)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Back to Home',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isDesktop)
                                GestureDetector(
                                  onTap: () => context.go('/'),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: AppComponents.logo(fontSize: 18),
                                  ),
                                ),
                            ],
                          ),
                        ),

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
                            onPressed: (_isLoading || _isSubmitting) ? null : _handleSubmit,
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
          // Clickable Logo to return home
          GestureDetector(
            onTap: () => context.go('/'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: AppComponents.logo(fontSize: 18, darkMode: true),
            ),
          ),

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
