import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/token_storage.dart';
import '../theme/app_colors.dart';

/// SPRINT 6 EMERGENCY HOTFIX: In-Line Session Recovery Modal
/// Guarantees that users can re-authenticate without losing uncommitted workspace inputs.
class InLineReauthDialog extends StatefulWidget {
  final Future<void> Function()? onAuthenticatedAndSync;

  const InLineReauthDialog({
    super.key,
    this.onAuthenticatedAndSync,
  });

  static Future<bool?> show(
    BuildContext context, {
    Future<void> Function()? onAuthenticatedAndSync,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InLineReauthDialog(
        onAuthenticatedAndSync: onAuthenticatedAndSync,
      ),
    );
  }

  @override
  State<InLineReauthDialog> createState() => _InLineReauthDialogState();
}

class _InLineReauthDialogState extends State<InLineReauthDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final session = TokenStorage.loadSession();
    final email = session['email'] as String?;
    final username = session['username'] as String?;
    _usernameController.text = (email != null && email.isNotEmpty)
        ? email
        : (username ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleReauth() async {
    final identifier = _usernameController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your password to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.dio.post(
        '/api/v1/auth/login',
        data: {
          'username': identifier,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data =
            response.data is Map<String, dynamic> ? response.data : {};
        final newToken = data['token'] as String?;

        if (newToken != null && newToken.isNotEmpty) {
          // Update credentials seamlessly without reloading or clearing workspace
          api.token = newToken;
          TokenStorage.saveSession(
            token: newToken,
            username: data['username'] as String?,
            email: data['email'] as String?,
            role: data['role'] as String?,
            fullName: data['fullName'] as String?,
            mobile: data['mobile'] as String?,
            userId: data['id'] is int ? data['id'] : null,
          );

          // Retry synchronization if callback provided
          if (widget.onAuthenticatedAndSync != null) {
            await widget.onAuthenticatedAndSync!();
          }

          if (mounted) {
            Navigator.of(context).pop(true);
          }
          return;
        }
      }

      setState(() {
        _errorMessage = 'Authentication response invalid. Please try again.';
      });
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
          _errorMessage = 'Invalid username or password. Please re-enter.';
        } else {
          _errorMessage = 'Connection error (${e.response?.statusCode ?? 'network'}). Edits remain safe.';
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.errorBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lock_clock_rounded, color: AppColors.workspaceErrorText, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Session Expired',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.charcoal),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_rounded, color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All unsaved changes have been safely preserved in local storage.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF15803D), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Your authentication session has expired. Please re-authenticate to synchronize your work directly to the database.',
              style: TextStyle(fontSize: 13.5, color: AppColors.charcoal, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username / Email',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _handleReauth(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.workspaceErrorText, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.workspaceErrorText, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Log Out', style: TextStyle(color: AppColors.steel)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleReauth,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.workspaceCorporateNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Re-Authenticate & Sync', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
