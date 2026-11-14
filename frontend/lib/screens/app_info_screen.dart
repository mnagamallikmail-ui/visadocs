import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auto_update_service.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  String _lastSyncDisplay = 'Never synchronized';
  bool _isCheckingUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSyncTimestamp();
  }

  Future<void> _loadSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTime = prefs.getString('last_offline_sync_time') ?? prefs.getString('last_update_check_time');
    if (savedTime != null) {
      final dt = DateTime.tryParse(savedTime);
      if (dt != null) {
        setState(() {
          _lastSyncDisplay = DateFormat('dd-MMM-yyyy hh:mm a').format(dt.toLocal());
        });
      }
    }
  }

  Future<void> _triggerCheckForUpdates() async {
    setState(() => _isCheckingUpdates = true);
    await AutoUpdateService.instance.checkForUpdate(context: context, showToastIfLatest: true);
    if (mounted) {
      await _loadSyncTimestamp();
      setState(() => _isCheckingUpdates = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('App Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Branding Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'PV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pro Valuer',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Commercial Property & Collateral Valuation Suite',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metadata Info Tile Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildMetaTile(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    value: AutoUpdateService.currentAppVersion,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMetaTile(
                    icon: Icons.numbers_rounded,
                    label: 'Build Number',
                    value: AutoUpdateService.currentVersionCode.toString(),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMetaTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Release Date',
                    value: AutoUpdateService.currentReleaseDate,
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMetaTile(
                    icon: Icons.alt_route_rounded,
                    label: 'Branch',
                    value: AutoUpdateService.currentBranch,
                    badgeColor: const Color(0xFFEFF6FF),
                    badgeTextColor: const Color(0xFF1E40AF),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMetaTile(
                    icon: Icons.sync_rounded,
                    label: 'Last Sync Time',
                    value: _lastSyncDisplay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Check for updates CTA button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isCheckingUpdates ? null : _triggerCheckForUpdates,
                icon: _isCheckingUpdates
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  _isCheckingUpdates ? 'Checking for updates...' : 'Check For Updates',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Running on dedicated Android runtime. Web presentation unaffected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTile({
    required IconData icon,
    required String label,
    required String value,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF475569)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
            ),
          ),
          if (badgeColor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badgeTextColor ?? const Color(0xFF1E293B),
                ),
              ),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
        ],
      ),
    );
  }
}

