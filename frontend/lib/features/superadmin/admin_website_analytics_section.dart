import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class AdminWebsiteAnalyticsSection extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AdminWebsiteAnalyticsSection({super.key, this.initialData});

  @override
  State<AdminWebsiteAnalyticsSection> createState() =>
      _AdminWebsiteAnalyticsSectionState();
}

class _AdminWebsiteAnalyticsSectionState
    extends State<AdminWebsiteAnalyticsSection> {
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _error;

  int _totalVisits = 0;
  int _todayVisits = 0;
  int _last7DaysVisits = 0;
  int _last30DaysVisits = 0;
  List<Map<String, dynamic>> _topPages = [];
  List<Map<String, dynamic>> _topReferrers = [];
  List<Map<String, dynamic>> _locations = [];
  List<Map<String, dynamic>> _recentVisitors = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _applyData(widget.initialData!);
    } else {
      _fetchSummary();
    }
  }

  void _applyData(Map<String, dynamic> data) {
    setState(() {
      _totalVisits = (data['totalVisits'] as num?)?.toInt() ?? 0;
      _todayVisits = (data['todayVisits'] as num?)?.toInt() ?? 0;
      _last7DaysVisits = (data['last7DaysVisits'] as num?)?.toInt() ?? 0;
      _last30DaysVisits = (data['last30DaysVisits'] as num?)?.toInt() ?? 0;
      _topPages = _toMapList(data['topPages']);
      _topReferrers = _toMapList(data['topReferrers']);
      _locations = _toMapList(data['locations']);
      _recentVisitors = _toMapList(data['recentVisitors']);
      _error = null;
    });
  }

  List<Map<String, dynamic>> _toMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.dio.get('/api/v1/admin/analytics/summary');
      if (res.data is Map) {
        _applyData(Map<String, dynamic>.from(res.data as Map));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to load website analytics: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (_error != null) _buildErrorBanner(),
          _buildKpiRow(),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTopPagesCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTopReferrersCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildTopPagesCard(),
                  const SizedBox(height: 16),
                  _buildTopReferrersCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          _buildLocationsCard(),
          const SizedBox(height: 24),
          _buildRecentVisitorsCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Website Analytics',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'First-party visit counts, top pages, referrers, and visitor locations',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _loading ? null : _fetchSummary,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded, size: 18),
          label: Text(_loading ? 'Refreshing...' : 'Refresh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandNavy,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.inter(color: Colors.red.shade800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    final cards = [
      _KpiItem('Total Visits', '$_totalVisits', Icons.public_rounded, AppColors.brandNavy),
      _KpiItem("Today's Visits", '$_todayVisits', Icons.today_rounded, Colors.teal.shade700),
      _KpiItem('Last 7 Days', '$_last7DaysVisits', Icons.date_range_rounded, Colors.indigo.shade700),
      _KpiItem('Last 30 Days', '$_last30DaysVisits', Icons.calendar_month_rounded, Colors.blueGrey.shade700),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: constraints.maxWidth >= 900 ? 2.1 : 1.9,
          ),
          itemBuilder: (context, idx) {
            final c = cards[idx];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Icon(c.icon, size: 20, color: c.color),
                    ],
                  ),
                  Text(
                    c.value,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: c.color,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTopPagesCard() {
    return _SectionCard(
      title: 'Top Pages',
      icon: Icons.article_outlined,
      child: _topPages.isEmpty
          ? _emptyState('No page visits recorded yet')
          : Column(
              children: _topPages.map((p) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    p['pagePath']?.toString() ?? '/',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _countBadge('${p['visits'] ?? 0}'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTopReferrersCard() {
    return _SectionCard(
      title: 'Top Referrers',
      icon: Icons.link_rounded,
      child: _topReferrers.isEmpty
          ? _emptyState('No referrers recorded yet')
          : Column(
              children: _topReferrers.map((r) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    r['referrer']?.toString() ?? 'Direct',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _countBadge('${r['visits'] ?? 0}'),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildLocationsCard() {
    return _SectionCard(
      title: 'Visitor Locations',
      icon: Icons.location_on_outlined,
      child: _locations.isEmpty
          ? _emptyState('No location data recorded yet')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columns: const [
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('State')),
                  DataColumn(label: Text('City')),
                  DataColumn(label: Text('Visits'), numeric: true),
                ],
                rows: _locations.map((loc) {
                  return DataRow(cells: [
                    DataCell(Text(loc['country']?.toString() ?? 'Unknown')),
                    DataCell(Text(loc['state']?.toString() ?? 'Unknown')),
                    DataCell(Text(loc['city']?.toString() ?? 'Unknown')),
                    DataCell(Text('${loc['visits'] ?? 0}')),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildRecentVisitorsCard() {
    return _SectionCard(
      title: 'Recent Visitors',
      icon: Icons.people_outline_rounded,
      child: _recentVisitors.isEmpty
          ? _emptyState('No recent visitors recorded yet')
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 46,
                columns: const [
                  DataColumn(label: Text('Date/Time')),
                  DataColumn(label: Text('Page Path')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('State')),
                  DataColumn(label: Text('City')),
                  DataColumn(label: Text('Device')),
                  DataColumn(label: Text('Browser')),
                  DataColumn(label: Text('Referrer')),
                ],
                rows: _recentVisitors.map((v) {
                  return DataRow(cells: [
                    DataCell(Text(_formatTimestamp(v['visitedAt']?.toString()))),
                    DataCell(Text(v['pagePath']?.toString() ?? '/')),
                    DataCell(Text(v['country']?.toString() ?? 'Unknown')),
                    DataCell(Text(v['state']?.toString() ?? 'Unknown')),
                    DataCell(Text(v['city']?.toString() ?? 'Unknown')),
                    DataCell(Text(v['device']?.toString() ?? 'Desktop')),
                    DataCell(Text(v['browser']?.toString() ?? 'Unknown')),
                    DataCell(Text(v['referrer']?.toString() ?? 'Direct')),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    return iso.replaceFirst('T', ' ').split('.').first;
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.brandNavy,
        ),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        msg,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
      ),
    );
  }
}

class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiItem(this.label, this.value, this.icon, this.color);
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandNavy),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

