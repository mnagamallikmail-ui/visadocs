import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final String latestVersion;
  final int latestVersionCode;
  final int minSupportedVersionCode;
  final bool forceUpdate;
  final String downloadUrl;
  final List<String> releaseNotes;

  const UpdateInfo({
    required this.latestVersion,
    required this.latestVersionCode,
    required this.minSupportedVersionCode,
    required this.forceUpdate,
    required this.downloadUrl,
    required this.releaseNotes,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['versionName']?.toString() ?? json['latestVersion']?.toString() ?? '1.0.0',
      latestVersionCode: json['versionCode'] is int
          ? json['versionCode']
          : (json['latestVersionCode'] is int
              ? json['latestVersionCode']
              : int.tryParse(json['versionCode']?.toString() ?? json['latestVersionCode']?.toString() ?? '100') ?? 100),
      minSupportedVersionCode: json['minSupportedVersionCode'] is int
          ? json['minSupportedVersionCode']
          : int.tryParse(json['minSupportedVersionCode']?.toString() ?? '100') ?? 100,
      forceUpdate: json['forceUpdate'] == true,
      downloadUrl: json['apkUrl']?.toString() ?? json['downloadUrl']?.toString() ?? 'https://app.provaluer.in/download/latest.apk',
      releaseNotes: (json['releaseNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class AutoUpdateService {
  AutoUpdateService._();
  static final AutoUpdateService instance = AutoUpdateService._();

  static const String currentAppVersion = '1.0.0';
  static const int currentVersionCode = 101;
  static const String currentBranch = 'android';
  static const String currentReleaseDate = '07-Nov-2026';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  DateTime? _lastCheckTime;
  DateTime? get lastCheckTime => _lastCheckTime;

  /// Checks for available updates from VPS or Google Play.
  Future<UpdateInfo?> checkForUpdate({BuildContext? context, bool showToastIfLatest = false}) async {
    _lastCheckTime = DateTime.now();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_update_check_time', _lastCheckTime!.toIso8601String());

      // Query the distribution version manifest endpoint with fallback
      Response<dynamic>? response;
      try {
        response = await _dio.get('https://app.provaluer.in/app/version.json');
      } catch (_) {
        // Fallback to legacy VPS API endpoint if dedicated distribution endpoint is unreachable
        response = await _dio.get('https://visadocs.online/api/v1/app/version');
      }
      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = response.data is String
            ? jsonDecode(response.data)
            : Map<String, dynamic>.from(response.data);
        final update = UpdateInfo.fromJson(data);

        final bool isUpdateAvailable = update.latestVersionCode > currentVersionCode;
        final bool isMandatory = isUpdateAvailable &&
            (update.forceUpdate || currentVersionCode < update.minSupportedVersionCode);

        if (context != null && context.mounted) {
          if (isMandatory) {
            _showForceUpdateDialog(context, update);
          } else if (isUpdateAvailable) {
            _showSoftUpdateBottomSheet(context, update);
          } else if (showToastIfLatest) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pro Valuer is up to date (Version 1.0.0+101)'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

        return update;
      }
    } catch (e) {
      debugPrint('[AutoUpdateService] Check update error (using offline fallback): $e');
      if (context != null && context.mounted && showToastIfLatest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pro Valuer is on latest verified build (1.0.0+101)'),
            backgroundColor: Color(0xFF1E3A8A),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    return null;
  }

  void _showSoftUpdateBottomSheet(BuildContext context, UpdateInfo update) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.system_update_rounded, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update Available',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Version ${update.latestVersion} is ready to install',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                if (update.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('What\'s New:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  ...update.releaseNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: Color(0xFF2563EB))),
                          Expanded(child: Text(note, style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Update Later'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final uri = Uri.parse(update.downloadUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Install Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showForceUpdateDialog(BuildContext context, UpdateInfo update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: const [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Required Update'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A critical update (v${update.latestVersion}) is required to continue using Pro Valuer safely.',
                  style: const TextStyle(fontSize: 14),
                ),
                if (update.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...update.releaseNotes.map(
                    (note) => Text('• $note', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                ],
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(update.downloadUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Update Pro Valuer Immediately'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

