import 'package:flutter/material.dart';

class BuildInfo {
  static const String commitHash = String.fromEnvironment('BUILD_COMMIT', defaultValue: '67fcbfd');
  static const String buildTimestamp = String.fromEnvironment('BUILD_TIMESTAMP', defaultValue: '2026-10-04 20:00 IST');
  static const String environment = String.fromEnvironment('BUILD_ENV', defaultValue: 'Production');
}

class BuildFooterWidget extends StatelessWidget {
  final bool compact;
  final Color? textColor;

  const BuildFooterWidget({super.key, this.compact = false, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? const Color(0xFF94A3B8);
    if (compact) {
      return Tooltip(
        message: 'Version: ${BuildInfo.commitHash}\nBuilt: ${BuildInfo.buildTimestamp}\nEnv: ${BuildInfo.environment}',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'v${BuildInfo.commitHash}',
            style: TextStyle(fontSize: 10, color: color, fontFamily: 'RobotoMono'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Version: ${BuildInfo.commitHash}',
            style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600, fontFamily: 'RobotoMono'),
          ),
          const SizedBox(height: 2),
          Text(
            'Built: ${BuildInfo.buildTimestamp}',
            style: TextStyle(fontSize: 9.5, color: color),
          ),
          const SizedBox(height: 1),
          Text(
            'Environment: ${BuildInfo.environment}',
            style: TextStyle(fontSize: 9.5, color: color),
          ),
        ],
      ),
    );
  }
}
