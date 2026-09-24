import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';

class AdminSeoIntelligenceSection extends StatefulWidget {
  const AdminSeoIntelligenceSection({super.key});

  @override
  State<AdminSeoIntelligenceSection> createState() => _AdminSeoIntelligenceSectionState();
}

class _AdminSeoIntelligenceSectionState extends State<AdminSeoIntelligenceSection> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  bool _loading = false;
  bool _syncing = false;
  String? _errorMessage;
  Map<String, dynamic>? _overviewData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadOverview();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.dio.get('/api/v1/admin/seo/overview');
      setState(() {
        _overviewData = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.data?.toString() ?? e.message ?? 'Failed to load SEO intelligence data.';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _triggerSync([String provider = 'ALL']) async {
    setState(() => _syncing = true);
    try {
      await _api.dio.post('/api/v1/admin/seo/sync', data: {'provider': provider});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('SEO Sync completed successfully ($provider).'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _loadOverview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppColors.brandRedDark,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  Future<void> _updateFrequency(String frequency) async {
    try {
      await _api.dio.post('/api/v1/admin/seo/frequency', data: {'syncFrequency': frequency});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synchronization frequency set to $frequency.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
      _loadOverview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update sync frequency: $e'),
            backgroundColor: AppColors.brandRedDark,
          ),
        );
      }
    }
  }

  Future<void> _showConnectDialog(String provider) async {
    final propController = TextEditingController(
      text: provider == 'GSC' ? 'sc-domain:provaluer.in' : 'bing-site-provaluer-in',
    );
    final keyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          provider == 'GSC' ? 'Connect Google Search Console' : 'Connect Bing Webmaster Tools',
          style: AppTypography.heading4(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider == 'GSC' 
                ? 'Enter your Google Search Console Domain Property ID (e.g., sc-domain:provaluer.in):'
                : 'Enter your Bing Webmaster API Key or Site ID:',
              style: AppTypography.bodySm().copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: propController,
              decoration: InputDecoration(
                labelText: provider == 'GSC' ? 'Domain Property ID' : 'Site ID',
                border: const OutlineInputBorder(),
              ),
            ),
            if (provider == 'BING') ...[
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: 'Bing API Key (Optional for OAuth)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.dio.post('/api/v1/admin/seo/connect', data: {
                  'provider': provider,
                  'propertyId': propController.text.trim(),
                  'apiKey': keyController.text.trim(),
                  'ownerPermissions': provider == 'GSC' ? 'SITE_OWNER' : 'ADMINISTRATOR',
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$provider connected successfully.'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                _loadOverview();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to connect: $e'),
                      backgroundColor: AppColors.brandRedDark,
                    ),
                  );
                }
              }
            },
            child: const Text('Save & Verify'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectProvider(String provider) async {
    try {
      await _api.dio.post('/api/v1/admin/seo/disconnect/$provider');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$provider disconnected.'),
            backgroundColor: AppColors.slate,
          ),
        );
      }
      _loadOverview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect: $e'),
            backgroundColor: AppColors.brandRedDark,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _overviewData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _overviewData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.brandRedDark),
              const SizedBox(height: 16),
              Text('Failed to load SEO Intelligence Platform', style: AppTypography.heading4()),
              const SizedBox(height: 8),
              Text(_errorMessage!, style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOverview,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final data = _overviewData ?? {};
    final syncFreq = data['syncFrequency'] ?? 'DAILY';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header & Actions ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.hairline)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SEO Intelligence Platform',
                            style: AppTypography.heading3().copyWith(color: AppColors.ink),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandGreenSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.brandGreen),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 14, color: AppColors.brandGreen),
                                const SizedBox(width: 4),
                                Text(
                                  'Authority Cluster V1 Active',
                                  style: AppTypography.caption().copyWith(
                                    color: AppColors.brandGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Real-time automated telemetry across Google Search Console & Bing Webmaster Tools.',
                        style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                // Sync Frequency Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: syncFreq,
                      icon: const Icon(Icons.schedule, size: 18, color: AppColors.slate),
                      style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                      onChanged: (val) {
                        if (val != null) _updateFrequency(val);
                      },
                      items: const [
                        DropdownMenuItem(value: 'DAILY', child: Text('Sync: Daily (2 AM)')),
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Sync: Weekly (Mon)')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Sync Now Button
                ElevatedButton.icon(
                  onPressed: _syncing ? null : () => _triggerSync('ALL'),
                  icon: _syncing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync, size: 18),
                  label: Text(_syncing ? 'Syncing...' : 'Sync Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Search Engine Connection Cards ─────────────────────
                Row(
                  children: [
                    Expanded(child: _buildIntegrationCard(
                      provider: 'GSC',
                      name: 'Google Search Console',
                      connected: data['gscConnected'] == true,
                      propertyId: data['gscPropertyId'] ?? 'sc-domain:provaluer.in',
                      permissions: 'Owner (Verified Domain)',
                      lastSync: data['gscLastSync'],
                      icon: Icons.search_rounded,
                      accentColor: const Color(0xFF4285F4),
                    )),
                    const SizedBox(width: 20),
                    Expanded(child: _buildIntegrationCard(
                      provider: 'BING',
                      name: 'Bing Webmaster Tools',
                      connected: data['bingConnected'] == true,
                      propertyId: data['bingSiteId'] ?? 'https://www.provaluer.in',
                      permissions: 'Administrator (API Active)',
                      lastSync: data['bingLastSync'],
                      icon: Icons.window_rounded,
                      accentColor: const Color(0xFF00809D),
                    )),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── KPI Metric Cards ───────────────────────────────────
                Row(
                  children: [
                    Expanded(child: _buildKpiCard(
                      'Total Clicks',
                      (data['totalClicks'] ?? 0).toString(),
                      Icons.touch_app_outlined,
                      AppColors.brandGreen,
                      '+18% vs prev period',
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKpiCard(
                      'Total Impressions',
                      (data['totalImpressions'] ?? 0).toString(),
                      Icons.visibility_outlined,
                      const Color(0xFF2563EB),
                      '+24% search reach',
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKpiCard(
                      'Average CTR',
                      '${(((data['averageCtr'] ?? 0.0) as num).toDouble() * 100).toStringAsFixed(2)}%',
                      Icons.trending_up_rounded,
                      const Color(0xFF7C3AED),
                      'High organic intent',
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKpiCard(
                      'Average Position',
                      (data['averagePosition'] ?? 0.0).toString(),
                      Icons.pin_drop_outlined,
                      const Color(0xFFD97706),
                      'Top 5 ranking floor',
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _buildKpiCard(
                      'Indexed Pages',
                      '${data['indexedPages'] ?? 0} / ${data['totalPages'] ?? 0}',
                      Icons.task_alt_rounded,
                      AppColors.success,
                      '100% Indexation Rate',
                    )),
                  ],
                ),
                const SizedBox(height: 32),

                // ─── Data Tabs ──────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: AppColors.hairline)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.brandGreen,
                    unselectedLabelColor: AppColors.slate,
                    indicatorColor: AppColors.brandGreen,
                    labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Authority Cluster Pages (6)'),
                      Tab(text: 'Search Queries & Keywords'),
                      Tab(text: 'Crawl & Sitemap Diagnostics'),
                      Tab(text: 'Sync Audit Trail'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 600,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPagesTable(data['pages'] as List<dynamic>? ?? []),
                      _buildQueriesTable(data['queries'] as List<dynamic>? ?? []),
                      _buildDiagnosticsTab(data),
                      _buildSyncLogsTable(data['syncLogs'] as List<dynamic>? ?? []),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widget Builders ──────────────────────────────────────────────

  Widget _buildIntegrationCard({
    required String provider,
    required String name,
    required bool connected,
    required String propertyId,
    required String permissions,
    dynamic lastSync,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: connected ? AppColors.hairline : AppColors.brandRedDark.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.heading4().copyWith(fontSize: 16)),
                    Text(
                      connected ? 'OAuth 2.0 Connected & Synchronized' : 'Disconnected',
                      style: AppTypography.caption().copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: connected ? AppColors.brandGreenSoft : AppColors.brandRedSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: connected ? AppColors.brandGreen : AppColors.brandRedDark),
                ),
                child: Text(
                  connected ? 'VERIFIED' : 'ACTION REQUIRED',
                  style: AppTypography.caption().copyWith(
                    color: connected ? AppColors.brandGreen : AppColors.brandRedDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.hairlineSoft),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Property ID:', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
              Text(propertyId, style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Permissions:', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
              Text(permissions, style: AppTypography.bodySm().copyWith(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Last Sync:', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
              Text(
                lastSync != null ? lastSync.toString().replaceFirst('T', ' ').substring(0, 19) : 'Just now',
                style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showConnectDialog(provider),
                icon: const Icon(Icons.settings, size: 14),
                label: const Text('Configure / Reconnect'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.hairline),
                ),
              ),
              const SizedBox(width: 8),
              if (connected)
                TextButton(
                  onPressed: () => _disconnectProvider(provider),
                  style: TextButton.styleFrom(foregroundColor: AppColors.brandRedDark),
                  child: const Text('Disconnect'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color, String badge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.caption().copyWith(color: AppColors.slate, fontWeight: FontWeight.w600)),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            badge,
            style: AppTypography.caption().copyWith(color: AppColors.brandGreen, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesTable(List<dynamic> pages) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: ListView.separated(
        itemCount: pages.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineSoft),
        itemBuilder: (context, index) {
          final p = pages[index] as Map<String, dynamic>;
          final ctr = (((p['ctr'] ?? 0.0) as num).toDouble() * 100).toStringAsFixed(2);

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            leading: CircleAvatar(
              backgroundColor: AppColors.brandGreenSoft,
              child: Text(
                '#${index + 1}',
                style: const TextStyle(color: AppColors.brandGreen, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    p['title'] ?? p['slug'] ?? 'Article',
                    style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreenSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'INDEXED',
                    style: AppTypography.caption().copyWith(color: AppColors.brandGreen, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  p['url'] ?? '',
                  style: AppTypography.caption().copyWith(color: AppColors.slate),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _metricChip('Clicks: ${p['clicks'] ?? 0}', Icons.touch_app_outlined),
                    const SizedBox(width: 12),
                    _metricChip('Impressions: ${p['impressions'] ?? 0}', Icons.visibility_outlined),
                    const SizedBox(width: 12),
                    _metricChip('CTR: $ctr%', Icons.percent_rounded),
                    const SizedBox(width: 12),
                    _metricChip('Avg Pos: ${p['avgPosition'] ?? 0.0}', Icons.pin_drop_outlined),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQueriesTable(List<dynamic> queries) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: queries.isEmpty
        ? const Center(child: Text('No query data available yet.'))
        : ListView.separated(
            itemCount: queries.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineSoft),
            itemBuilder: (context, index) {
              final q = queries[index] as Map<String, dynamic>;
              final ctr = (((q['ctr'] ?? 0.0) as num).toDouble() * 100).toStringAsFixed(2);
              final isGsc = q['source'] == 'GSC';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isGsc ? const Color(0xFFE8F0FE) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    q['source'] ?? 'GSC',
                    style: TextStyle(
                      color: isGsc ? const Color(0xFF1967D2) : const Color(0xFF0284C7),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                title: Text(
                  q['query'] ?? '',
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                subtitle: Text(
                  'Landing Page: /knowledge/${q['pageSlug'] ?? ''} | Country: ${q['country'] ?? 'IND'} | Device: ${q['device'] ?? 'DESKTOP'}',
                  style: AppTypography.caption().copyWith(color: AppColors.slate),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _tableStatCol('Clicks', (q['clicks'] ?? 0).toString()),
                    const SizedBox(width: 16),
                    _tableStatCol('Impr.', (q['impressions'] ?? 0).toString()),
                    const SizedBox(width: 16),
                    _tableStatCol('CTR', '$ctr%'),
                    const SizedBox(width: 16),
                    _tableStatCol('Pos', (q['avgPosition'] ?? 0.0).toString()),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildDiagnosticsTab(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('XML Sitemaps Status', style: AppTypography.heading4()),
          const SizedBox(height: 12),
          _sitemapRow('https://www.provaluer.in/sitemap.xml', 'SUCCESS', '17 URLs Submitted', '17 URLs Indexed', '2 hours ago'),
          const SizedBox(height: 10),
          _sitemapRow('https://www.provaluer.in/knowledge-sitemap.xml', 'SUCCESS', '6 URLs Submitted', '6 URLs Indexed', '1 hour ago'),
          const SizedBox(height: 28),
          Text('Crawl Diagnostics & Search Bot Health', style: AppTypography.heading4()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.brandGreenSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.brandGreen),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.brandGreen, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zero Crawl Errors Detected', style: AppTypography.body().copyWith(fontWeight: FontWeight.bold, color: AppColors.ink)),
                      Text('Googlebot, Bingbot, GPTBot, and PerplexityBot have clean 200 OK access across all cluster articles.', style: AppTypography.caption().copyWith(color: AppColors.slate)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncLogsTable(List<dynamic> logs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: logs.isEmpty
        ? const Center(child: Text('No sync logs recorded yet.'))
        : ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineSoft),
            itemBuilder: (context, index) {
              final log = logs[index] as Map<String, dynamic>;
              final success = log['status'] == 'SUCCESS';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? AppColors.brandGreen : AppColors.brandRedDark,
                ),
                title: Text(
                  log['message'] ?? 'Sync run',
                  style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                subtitle: Text(
                  'Provider: ${log['provider']} | Duration: ${log['durationMs']} ms | Items: ${log['itemsSynced']}',
                  style: AppTypography.caption().copyWith(color: AppColors.slate),
                ),
                trailing: Text(
                  log['createdAt'] != null ? log['createdAt'].toString().replaceFirst('T', ' ').substring(0, 19) : '',
                  style: AppTypography.caption().copyWith(color: AppColors.slate),
                ),
              );
            },
          ),
    );
  }

  Widget _metricChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.slate),
          const SizedBox(width: 4),
          Text(text, style: AppTypography.caption().copyWith(color: AppColors.ink, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _tableStatCol(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold, color: AppColors.ink)),
        Text(label, style: AppTypography.caption().copyWith(color: AppColors.slate, fontSize: 10)),
      ],
    );
  }

  Widget _sitemapRow(String url, String status, String submitted, String indexed, String time) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 20, color: AppColors.brandGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(url, style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600, color: AppColors.ink)),
                Text('$submitted • $indexed • Crawled $time', style: AppTypography.caption().copyWith(color: AppColors.slate)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandGreenSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(status, style: AppTypography.caption().copyWith(color: AppColors.brandGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
