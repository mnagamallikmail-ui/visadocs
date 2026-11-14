import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SessionChallengeDialog extends StatefulWidget {
  final String deviceName;
  final String platform;
  final String approximateLocation;
  final int timeoutSeconds;
  final VoidCallback onKeepSession;
  final VoidCallback onAllowSession;

  const SessionChallengeDialog({
    super.key,
    required this.deviceName,
    required this.platform,
    required this.approximateLocation,
    required this.timeoutSeconds,
    required this.onKeepSession,
    required this.onAllowSession,
  });

  static Future<void> show(
    BuildContext context, {
    required String deviceName,
    required String platform,
    required String approximateLocation,
    required int timeoutSeconds,
    required VoidCallback onKeepSession,
    required VoidCallback onAllowSession,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SessionChallengeDialog(
        deviceName: deviceName,
        platform: platform,
        approximateLocation: approximateLocation,
        timeoutSeconds: timeoutSeconds,
        onKeepSession: onKeepSession,
        onAllowSession: onAllowSession,
      ),
    );
  }

  @override
  State<SessionChallengeDialog> createState() => _SessionChallengeDialogState();
}

class _SessionChallengeDialogState extends State<SessionChallengeDialog> {
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.timeoutSeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }
      } else {
        timer.cancel();
        // Defaults to KEEP SESSION if timeout expires to safeguard active user
        if (mounted) {
          Navigator.of(context).pop();
          widget.onKeepSession();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security_update_warning_rounded, color: Colors.red),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Another Login Detected',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Someone is attempting to log in to your ProValuer account from another device or browser session.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow('Device Name:', widget.deviceName),
                const SizedBox(height: 6),
                _buildRow('Platform:', widget.platform),
                const SizedBox(height: 6),
                _buildRow('Approximate Location:', widget.approximateLocation),
                const SizedBox(height: 6),
                _buildRow('Action Required In:', '$_remainingSeconds second(s)'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: widget.timeoutSeconds > 0 ? (_remainingSeconds / widget.timeoutSeconds) : 0,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _remainingSeconds > 10 ? AppColors.primary : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'If you select "Allow Session", your current session will be terminated immediately. If you select "Keep Session", the new login attempt will be denied.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      actions: [
        OutlinedButton(
          onPressed: () {
            _countdownTimer?.cancel();
            Navigator.of(context).pop();
            widget.onAllowSession();
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade800,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: const Text('Allow Session'),
        ),
        FilledButton.icon(
          onPressed: () {
            _countdownTimer?.cancel();
            Navigator.of(context).pop();
            widget.onKeepSession();
          },
          icon: const Icon(Icons.shield_outlined, size: 18),
          label: Text('Keep Session ($_remainingSeconds s)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }
}
