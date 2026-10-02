import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/request_intake/client_request_intake_modal.dart';

/// Full-screen route wrapper for /request-valuation
class RequestIntakeScreen extends StatefulWidget {
  const RequestIntakeScreen({super.key});

  @override
  State<RequestIntakeScreen> createState() => _RequestIntakeScreenState();
}

class _RequestIntakeScreenState extends State<RequestIntakeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ClientRequestIntakeModal.show(context);
      if (mounted) {
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
              const SizedBox(height: 16),
              Text(
                "Launching Valuation Request Intake...",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
