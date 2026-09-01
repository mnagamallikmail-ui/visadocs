import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../services/web_file_picker.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_components.dart';
import '../../services/api_service.dart';
import '../document_studio/document_studio_screen.dart';
import 'placeholder_catalog_screen.dart';
import '../../utils/indian_number_formatter.dart';

// ─── Shared helpers ───────────────────────────────────────────

Widget _sectionHeader(String title, String subtitle, {Widget? action}) =>
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
                Text(
                  title,
                  style: AppTypography.heading3().copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                ),
              ],
            ),
          ),
          if (action != null) action,
        ],
      ),
    );

Widget _statCard(String label, String value, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(24),
      decoration: AppComponents.cardBase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.sidebarSelected,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandBlue, size: 18),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.bodySm().copyWith(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );

Widget _placeholderSection(String icon, String title, String msg) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.heading4().copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              msg,
              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

// ─── OVERVIEW ─────────────────────────────────────────────────

class AdminOverviewSection extends StatefulWidget {
  const AdminOverviewSection({super.key});
  @override
  State<AdminOverviewSection> createState() => _AdminOverviewSectionState();
}

class _AdminOverviewSectionState extends State<AdminOverviewSection> {
  final _api = ApiService();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _diag;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await _api.dio.get('/api/v1/admin/overview');
      Map<String, dynamic>? diagData;
      try {
        final r2 = await _api.dio.get('/api/v1/admin/diagnostics');
        if (r2.data is Map<String, dynamic>) {
          diagData = r2.data as Map<String, dynamic>;
        }
      } catch (_) {}

      setState(() {
        _data = r1.data is Map<String, dynamic> ? (r1.data as Map<String, dynamic>) : null;
        _diag = diagData;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cpu = (_diag?['cpuUsagePercent'] as num?)?.toDouble() ?? 0.0;
    final int memFree = (_diag?['freeMemoryMb'] as num?)?.toInt() ?? 0;
    final int memTotal = (_diag?['totalMemoryMb'] as num?)?.toInt() ?? 0;
    final int diskFree = (_diag?['freeDiskGb'] as num?)?.toInt() ?? 0;
    final int diskTotal = (_diag?['totalDiskGb'] as num?)?.toInt() ?? 0;
    final bool dbOk = _diag?['databaseConnected'] == true;
    final int activeJobs = (_diag?['activeTemplateProcessingJobs'] as num?)?.toInt() ?? 0;

    return Column(
      children: [
        _sectionHeader(
          'Overview',
          'System health, key performance metrics, and VPS infrastructure diagnostics',
          action: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: AppComponents.secondaryButtonStyle().copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 1400 ? 4 : (MediaQuery.of(context).size.width > 900 ? 3 : 2),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: MediaQuery.of(context).size.width > 1400 ? 2.1 : 1.8,
                    children: [
                      _statCard('Total Active Users', '${_data?['totalUsers'] ?? '0'}', Icons.people_outline, AppColors.primary),
                      _statCard('Total Orders', '${_data?['totalOrders'] ?? '0'}', Icons.folder_outlined, AppColors.brandBlue),
                      _statCard('Open Orders', '${_data?['openOrders'] ?? '0'}', Icons.hourglass_empty, AppColors.warning),
                      _statCard('SPA Gate Orders', '${_data?['spaGateOrders'] ?? '0'}', Icons.supervisor_account_outlined, AppColors.brandBlue),
                      _statCard('Final Delivery', '${_data?['finalDeliveryOrders'] ?? '0'}', Icons.check_circle_outline, AppColors.success),
                      _statCard('Active Templates', '${_data?['activeTemplates'] ?? '0'}', Icons.description_outlined, AppColors.successAccent),
                    ],
                  ),
                  const SizedBox(height: 28),
                  
                  // 0.14: VPS Diagnostics & Health Monitoring Card
                  Text('VPS INFRASTRUCTURE & BACKEND DIAGNOSTICS', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.brXl,
                      border: Border.all(color: AppColors.hairlineSoft),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: dbOk ? AppColors.success : AppColors.brandRedDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Database Connectivity: ${dbOk ? "ONLINE (PostgreSQL)" : "OFFLINE"}',
                              style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold, color: dbOk ? AppColors.success : AppColors.brandRedDark),
                            ),
                            const Spacer(),
                            if (activeJobs > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                                    const SizedBox(width: 6),
                                    Text('$activeJobs DOCX processing job${activeJobs > 1 ? "s" : ""} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
                                  ],
                                ),
                              )
                            else
                              Text('Processing Queue: Idle', style: AppTypography.caption(color: AppColors.slate)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _diagMetric('CPU Load', '${cpu.toStringAsFixed(1)}%', cpu > 80 ? AppColors.brandRedDark : (cpu > 50 ? AppColors.yellowDark : AppColors.brandBlue)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _diagMetric('JVM Memory', '${memTotal - memFree} MB / $memTotal MB', AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _diagMetric('Disk Storage', '$diskFree GB Free / $diskTotal GB', diskFree < 5 ? AppColors.brandRedDark : AppColors.success),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _diagMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption(color: AppColors.slate)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── QUEUE MANAGEMENT ─────────────────────────────────────────

class AdminQueueSection extends StatefulWidget {
  const AdminQueueSection({super.key});
  @override
  State<AdminQueueSection> createState() => _AdminQueueSectionState();
}

class _AdminQueueSectionState extends State<AdminQueueSection> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/orders');
      setState(() {
        _orders = r.data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _forceRelease(dynamic order) async {
    try {
      await _api.dio.post('/api/v1/admin/orders/${order['id']}/force-release');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Order force-released to FINAL_DELIVERY.'),
        ));
      }
    } catch (_) {}
  }

  Future<void> _waivePayment(dynamic order) async {
    try {
      await _api.dio.post('/api/v1/admin/orders/${order['id']}/waive-payment');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Payment waived successfully.'),
        ));
      }
    } catch (_) {}
  }

  Future<void> _deleteOrder(dynamic order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Order to Trash?'),
        content: Text('Are you sure you want to soft-delete order #${order['id']}? It can be restored from the Trash Bin.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/v1/admin/orders/${order['id']}');
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Order moved to Trash Bin.'),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.brandRedDark,
          content: Text('Failed to delete order: ${ApiService.getErrorMessage(e)}'),
        ));
      }
    }
  }

  Future<void> _showCreateOrderDialog() async {
    final categoryCtrl = TextEditingController();
    final purposeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final templateIdCtrl = TextEditingController();
    final clientIdCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add_shopping_cart, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Create New Order', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Property Category',
                  hintText: 'VALUATION / NETWORTH / CHARTERED_ENGINEER',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeCtrl,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Estimated Value',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: templateIdCtrl,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Template ID (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientIdCtrl,
                style: AppTypography.bodySm().copyWith(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Client ID (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final double? estVal = double.tryParse(valueCtrl.text);
                final int? tId = int.tryParse(templateIdCtrl.text);
                final int? cId = int.tryParse(clientIdCtrl.text);

                await _api.dio.post('/api/v1/admin/orders', data: {
                  'propertyCategory': categoryCtrl.text.trim().isEmpty ? 'VALUATION' : categoryCtrl.text.trim().toUpperCase(),
                  'purpose': purposeCtrl.text.trim(),
                  'estimatedValue': estVal,
                  'templateId': tId,
                  'clientId': cId,
                });
                _load();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Order created successfully!'),
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: AppColors.brandRedDark,
                    content: Text('Failed to create order.'),
                  ));
                }
              }
            },
            style: AppComponents.primaryButtonStyle(),
            child: Text('Create', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Queue Management',
          'All orders across the pipeline',
          action: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateOrderDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Order'),
                style: AppComponents.primaryButtonStyle().copyWith(
                  backgroundColor: WidgetStateProperty.all(AppColors.primary),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: AppComponents.secondaryButtonStyle().copyWith(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
            ],
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_orders.isEmpty)
          Expanded(child: _placeholderSection('📦', 'No Orders Found', 'There are no active orders in the system queue.'))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('ID', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Status', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text('Purpose', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                        ),
                        SizedBox(
                          width: 220,
                          child: Text('Actions', style: AppTypography.captionBold().copyWith(color: AppColors.slate), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  ..._orders.map((o) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: AppColors.hairlineSoft),
                            left: BorderSide(color: AppColors.hairlineSoft),
                            right: BorderSide(color: AppColors.hairlineSoft),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '#${o['id']}',
                                style: AppTypography.bodySm().copyWith(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${o['status']}'.replaceAll('_', ' '),
                                      style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${o['purpose'] ?? '—'}',
                                style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 300,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _queueBtn('Release', Icons.send_outlined, AppColors.primary, () => _forceRelease(o)),
                                  const SizedBox(width: 6),
                                  _queueBtn('Waive', Icons.money_off_outlined, AppColors.success, () => _waivePayment(o)),
                                  const SizedBox(width: 6),
                                  _queueBtn('Delete', Icons.delete_outline_rounded, AppColors.brandRedDark, () => _deleteOrder(o)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _queueBtn(String label, IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.04),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.heading5().copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}

// ─── SLA DASHBOARD ────────────────────────────────────────────

class AdminSlaSection extends StatefulWidget {
  const AdminSlaSection({super.key});
  @override
  State<AdminSlaSection> createState() => _AdminSlaSectionState();
}

class _AdminSlaSectionState extends State<AdminSlaSection> {
  final _api = ApiService();
  List<dynamic> _sla = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/sla-status');
      setState(() {
        _sla = r.data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Sla Dashboard',
          'Real-time SLA health across active pipeline',
          action: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: AppComponents.secondaryButtonStyle().copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_sla.isEmpty)
          Expanded(child: _placeholderSection('⏰', 'No Active SLAs', 'All active orders are currently complying with SLAs.'))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _sla.length,
              itemBuilder: (context, idx) {
                final s = _sla[idx];
                final health = s['slaHealth'] ?? 'OK';
                final Color hColor = health == 'CRITICAL'
                    ? AppColors.brandRedDark
                    : health == 'WARNING'
                        ? AppColors.yellowDark
                        : AppColors.success;
                final Color hColorBg = health == 'CRITICAL'
                    ? AppColors.errorBg
                    : health == 'WARNING'
                        ? AppColors.yellowLight
                        : AppColors.successBg;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: hColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${s['orderId']}',
                              style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s['status']}'.replaceAll('_', ' '),
                              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${s['purpose'] ?? '—'}',
                          style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: hColorBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          health,
                          style: AppTypography.bodySm().copyWith(color: hColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '${s['remainingHours'] ?? '—'} hours left',
                        style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── PRICING CONTROL ──────────────────────────────────────────

class AdminPricingSection extends StatefulWidget {
  const AdminPricingSection({super.key});
  @override
  State<AdminPricingSection> createState() => _AdminPricingSectionState();
}

class _AdminPricingSectionState extends State<AdminPricingSection> {
  final _api = ApiService();
  List<dynamic> _configs = [];
  bool _loading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/pricing');
      final list = r.data as List<dynamic>;
      for (final c in list) {
        _controllers[c['configKey']] ??= TextEditingController(text: '${c['value']}');
      }
      setState(() {
        _configs = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save(String key) async {
    try {
      await _api.dio.put('/api/v1/admin/pricing/$key', data: {'value': double.tryParse(_controllers[key]?.text ?? '0') ?? 0});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Pricing updated successfully.'),
        ));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader('Pricing Control', 'Edit live pricing configuration values'),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _configs.length,
              itemBuilder: (_, i) {
                final c = _configs[i];
                final key = c['configKey'] as String;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key.replaceAll('_', ' ').toUpperCase(),
                              style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c['description'] ?? ''}',
                              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 140,
                        height: 40,
                        child: TextField(
                          controller: _controllers[key],
                          style: AppTypography.bodySm().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _save(key),
                        style: AppComponents.primaryButtonStyle().copyWith(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                        child: Text('Save', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── T&C MANAGEMENT ───────────────────────────────────────────

class AdminTcSection extends StatefulWidget {
  const AdminTcSection({super.key});
  @override
  State<AdminTcSection> createState() => _AdminTcSectionState();
}

class _AdminTcSectionState extends State<AdminTcSection> {
  final _api = ApiService();
  Map<String, dynamic>? _tc;
  List<dynamic> _log = [];
  bool _loading = true;
  final _versionCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _versionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await _api.dio.get('/api/v1/admin/tc');
      final r2 = await _api.dio.get('/api/v1/admin/tc/log');
      setState(() {
        _tc = r1.data as Map<String, dynamic>;
        _versionCtrl.text = _tc?['currentVersion'] ?? '';
        _log = r2.data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateVersion() async {
    try {
      await _api.dio.put('/api/v1/admin/tc', data: {'version': _versionCtrl.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('T&C version updated. All clients must re-accept.'),
        ));
      }
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader('T&C Management', 'Terms & Conditions version control and compliance tracking'),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version editor card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Agreement Version', style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _versionCtrl,
                                  style: AppTypography.bodySm().copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _updateVersion,
                              style: AppComponents.primaryButtonStyle().copyWith(
                                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                              ),
                              child: Text('Publish Version', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _tcStat('Accepted clients', '${_tc?['acceptedCount'] ?? 0}', AppColors.success),
                            const SizedBox(width: 12),
                            _tcStat('Pending consent', '${_tc?['pendingCount'] ?? 0}', AppColors.yellowDark),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('ACCEPTANCE COMPLIANCE LOG', style: AppTypography.captionBold().copyWith(color: AppColors.slate)),
                  const SizedBox(height: 12),
                  ..._log.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                        child: Row(
                          children: [
                            Icon(
                              e['compliant'] == true ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                              color: e['compliant'] == true ? AppColors.success : AppColors.yellowDark,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${e['email']}',
                                style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${e['role']}',
                                style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Version Accepted: v${e['acceptedVersion'] ?? '—'}',
                              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tcStat(String label, String val, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(val, style: AppTypography.bodySm().copyWith(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(label, style: AppTypography.bodySm().copyWith(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

// ─── TEMPLATE MANAGER ─────────────────────────────────────────

class AdminTemplateSection extends StatefulWidget {
  const AdminTemplateSection({super.key});
  @override
  State<AdminTemplateSection> createState() => _AdminTemplateSectionState();
}

class _AdminTemplateSectionState extends State<AdminTemplateSection> {
  final _api = ApiService();
  List<dynamic> _templates = [];
  bool _loading = true;
  Timer? _pollingTimer;
  dynamic _lastUploadedTemplateId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // 0.2 Safe template list loading with defensive error handling
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/templates');
      if (mounted) {
        setState(() {
          if (r.data is List) {
            _templates = r.data as List<dynamic>;
          } else {
            _templates = [];
          }
        });
        _checkAndStartPolling();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.brandRedDark,
          content: Text(ApiService.getErrorMessage(e)),
        ));
      }
    } finally {
      // 0.1 Defensive loading state reset
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // 0.8 Background silent polling every 3 seconds for async jobs
  void _checkAndStartPolling() {
    final hasActiveJobs = _templates.any((t) => t['status'] == 'PENDING' || t['status'] == 'PARSING');
    if (hasActiveJobs) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollingTimer != null && _pollingTimer!.isActive) return;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final r = await _api.dio.get('/api/v1/templates');
        if (!mounted) return;
        if (r.data is List) {
          final List<dynamic> updatedList = r.data as List<dynamic>;
          
          // Check if previously uploaded template finished parsing
          if (_lastUploadedTemplateId != null) {
            final match = updatedList.firstWhere(
              (t) => t['id'] == _lastUploadedTemplateId,
              orElse: () => null,
            );
            if (match != null && match['status'] == 'PARSED') {
              final id = _lastUploadedTemplateId;
              _lastUploadedTemplateId = null;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: AppColors.success,
                content: Text('Template "${match['name']}" parsed successfully! Ready for finalization.'),
              ));
              // Fetch detail and prompt finalization preview
              _fetchAndOpenPreview(id);
            }
          }

          setState(() {
            _templates = updatedList;
          });

          final stillActive = updatedList.any((t) => t['status'] == 'PENDING' || t['status'] == 'PARSING');
          if (!stillActive) {
            _stopPolling();
          }
        }
      } catch (_) {}
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchAndOpenPreview(dynamic templateId) async {
    try {
      final r = await _api.dio.get('/api/v1/templates/$templateId');
      if (mounted && r.data is Map<String, dynamic>) {
        _showTemplatePreviewDialog(r.data);
      }
    } catch (_) {}
  }

  Future<void> _deleteTemplate(dynamic t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${t['name']}"? All versions will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: AppComponents.dangerButton,
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/v1/templates/${t['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Template deleted successfully.'),
        ));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.brandRedDark,
          content: Text(ApiService.getErrorMessage(e)),
        ));
      }
    }
  }

  // Purge All Templates
  Future<void> _purgeAllTemplates() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge All Templates?'),
        content: const Text('Are you sure you want to permanently delete ALL templates and their versions? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PURGE ALL TEMPLATES', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/v1/admin/templates/purge-all');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('All templates permanently purged.'),
        ));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.brandRedDark,
          content: Text(ApiService.getErrorMessage(e)),
        ));
      }
    }
  }

  // 0.6 Async DOCX Upload
  Future<void> _uploadTemplate() async {
    try {
      final List<int>? fileBytes;
      final String fileName;

      if (kIsWeb) {
        final result = await WebFilePicker.pickFile(accept: '.docx');
        if (result == null) return;
        fileBytes = result.bytes;
        fileName = result.name;
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['docx'],
        );
        if (result == null || result.files.isEmpty) return;
        fileBytes = result.files.single.bytes;
        fileName = result.files.single.name;
      }

      if (fileBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: AppColors.brandRedDark,
            content: Text('Failed to read file bytes.'),
          ));
        }
        return;
      }

      final nameCtrl = TextEditingController(text: fileName.replaceAll('.docx', ''));

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Name your Template', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
          content: TextField(
            controller: nameCtrl,
            style: AppTypography.bodySm().copyWith(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Template Name',
              hintText: 'e.g. Standard Commercial Valuation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _loading = true);
                try {
                  final formData = FormData.fromMap({
                    'file': MultipartFile.fromBytes(fileBytes!, filename: fileName),
                    'name': nameCtrl.text.trim().isEmpty ? fileName : nameCtrl.text.trim(),
                  });

                  // 0.6: Upload returns 202 Accepted immediately
                  final r = await _api.dio.post('/api/v1/templates/upload', data: formData);

                  if (mounted) {
                    final newTemplateId = r.data is Map ? r.data['id'] : null;
                    if (newTemplateId != null) {
                      _lastUploadedTemplateId = newTemplateId;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: AppColors.tealDark,
                      content: Text('DOCX uploaded! Parsing document structure and DOM in background...'),
                    ));
                  }
                  _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: AppColors.brandRedDark,
                      content: Text(ApiService.getErrorMessage(e)),
                    ));
                  }
                } finally {
                  // 0.1 Defensive loading reset
                  if (mounted) {
                    setState(() => _loading = false);
                  }
                }
              },
              style: AppComponents.primaryButtonStyle(),
              child: Text('Upload', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: AppColors.brandRedDark,
          content: Text('File selection failed.'),
        ));
      }
    }
  }

  Future<void> _showTemplatePreviewDialog(dynamic template) async {
    Map<String, dynamic> parsedSchema = {};
    if (template['fieldMapping'] is String) {
      try {
        parsedSchema = jsonDecode(template['fieldMapping'] as String);
      } catch (_) {}
    } else if (template['fieldMapping'] is Map) {
      parsedSchema = Map<String, dynamic>.from(template['fieldMapping'] as Map);
    }

    final List<dynamic> fields = parsedSchema['fields'] ?? [];
    final List<TextEditingController> questionControllers = fields.map((f) => TextEditingController(text: f['question'] ?? '')).toList();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final Map<int, List<MapEntry<int, dynamic>>> groupedNonImages = {};
            final List<MapEntry<int, dynamic>> imageFields = [];

            for (int i = 0; i < fields.length; i++) {
              final f = fields[i];
              final type = f['type'] ?? 'TEXT';
              if (type == 'IMAGE') {
                imageFields.add(MapEntry(i, f));
              } else {
                final lineId = f['lineGroupId'] ?? 0;
                groupedNonImages.putIfAbsent(lineId, () => []).add(MapEntry(i, f));
              }
            }

            final sortedLineGroupIds = groupedNonImages.keys.toList()..sort();

            Widget buildFieldItem(MapEntry<int, dynamic> entry) {
              final idx = entry.key;
              final f = entry.value;
              final key = f['key'] ?? '';
              final type = f['type'] ?? 'TEXT';
              final lineGroupId = f['lineGroupId'] ?? 0;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.hairlineSoft),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            key,
                            style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['TEXT', 'DATE', 'IMAGE', 'NUMBER'].contains(type) ? type : 'TEXT',
                              style: AppTypography.bodySm().copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                              isDense: true,
                              dropdownColor: Colors.white,
                              items: <String>['TEXT', 'DATE', 'IMAGE', 'NUMBER'].map((String val) {
                                return DropdownMenuItem<String>(
                                  value: val,
                                  child: Text(val, style: const TextStyle(fontSize: 10)),
                                );
                              }).toList(),
                              onChanged: (String? newVal) {
                                if (newVal != null) {
                                  setStateDialog(() {
                                    f['type'] = newVal;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'L: $lineGroupId',
                          style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: questionControllers[idx],
                      style: AppTypography.bodySm().copyWith(fontSize: 12),
                      decoration: const InputDecoration(
                        labelText: 'Input Prompt / Question',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              );
            }

            final List<Widget> itemsList = [];

            for (final lineId in sortedLineGroupIds) {
              final entries = groupedNonImages[lineId]!;
              if (entries.length == 1) {
                itemsList.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: buildFieldItem(entries[0]),
                  ),
                );
              } else {
                final children = entries
                    .map((e) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: buildFieldItem(e),
                          ),
                        ))
                    .toList();
                itemsList.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                );
              }
            }

            if (imageFields.isNotEmpty) {
              itemsList.add(
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const SizedBox(height: 6),
                      Text(
                        'IMAGE PLACEHOLDERS',
                        style: AppTypography.bodySm().copyWith(color: AppColors.brandBlue, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );

              for (final e in imageFields) {
                itemsList.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: buildFieldItem(e),
                  ),
                );
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              title: Text('Template Finalization Preview: ${template['name']}', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify and customize prompt text for extracted placeholders before activation:', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: itemsList,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _load();
                  },
                  child: Text('Close (Keep Draft)', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    for (int i = 0; i < fields.length; i++) {
                      fields[i]['question'] = questionControllers[i].text.trim();
                    }
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    try {
                      final updatedFieldMapping = jsonEncode(parsedSchema);
                      await _api.dio.post('/api/v1/templates/${template['id']}/confirm', data: updatedFieldMapping);
                      messenger.showSnackBar(const SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text('Template finalized, activated, and versioned successfully!'),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: AppColors.brandRedDark,
                        content: Text('Failed to finalize: ${ApiService.getErrorMessage(e)}'),
                      ));
                    } finally {
                      _load();
                    }
                  },
                  style: AppComponents.primaryButtonStyle(),
                  child: Text('Confirm & Activate', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 0.9 Processing Error Inspector
  void _showErrorDialog(dynamic template) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.brandRedDark),
            const SizedBox(width: 8),
            Text('Processing Error: ${template['name']}', style: AppTypography.heading4().copyWith(color: AppColors.brandRedDark)),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('The background DOCX parser encountered an issue:', style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.hairlineSoft)),
                child: SelectableText(
                  template['processingError'] ?? 'Unknown parsing exception.',
                  style: GoogleFonts.firaCode(fontSize: 12, color: AppColors.ink),
                ),
              ),
              const SizedBox(height: 16),
              Text('Troubleshooting Tips:', style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('• Verify the DOCX is not password-protected or corrupted.\n• Ensure placeholders use <<PLACEHOLDER_NAME>> syntax.\n• Re-saving the file in Microsoft Word or LibreOffice can resolve XML run fragmentation.', style: AppTypography.caption(color: AppColors.slate)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss')),
        ],
      ),
    );
  }

  // 0.15 Version History & Rollback Modal
  Future<void> _showVersionHistoryDialog(dynamic template) async {
    final templateId = template['id'];
    List<dynamic> versions = [];
    bool loadingVersions = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (loadingVersions) {
            _api.dio.get('/api/v1/templates/$templateId/versions').then((r) {
              if (r.data is List) {
                setDialogState(() {
                  versions = r.data as List<dynamic>;
                  loadingVersions = false;
                });
              } else {
                setDialogState(() => loadingVersions = false);
              }
            }).catchError((_) {
              setDialogState(() => loadingVersions = false);
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Version History: ${template['name']}', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
              ],
            ),
            content: SizedBox(
              width: 550,
              height: 380,
              child: loadingVersions
                  ? const Center(child: CircularProgressIndicator())
                  : versions.isEmpty
                      ? const Center(child: Text('No previous versions recorded.'))
                      : ListView.separated(
                          itemCount: versions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final v = versions[idx];
                            final isCurrent = v['version'] == template['version'];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppColors.tealLight : AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('v${v['version']}', style: TextStyle(fontWeight: FontWeight.bold, color: isCurrent ? AppColors.deepTeal : AppColors.slate)),
                              ),
                              title: Text(v['changeSummary'] ?? 'Version Snapshot', style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text('Created: ${v['createdAt'] ?? '—'}', style: AppTypography.caption(color: AppColors.slate)),
                              trailing: isCurrent
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('CURRENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                                    )
                                  : OutlinedButton(
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(context);
                                        Navigator.pop(ctx);
                                        setState(() => _loading = true);
                                        try {
                                          await _api.dio.post('/api/v1/templates/$templateId/rollback/${v['version']}');
                                          messenger.showSnackBar(SnackBar(
                                            backgroundColor: AppColors.success,
                                            content: Text('Rolled back to v${v['version']} successfully.'),
                                          ));
                                        } catch (e) {
                                          messenger.showSnackBar(SnackBar(
                                            backgroundColor: AppColors.brandRedDark,
                                            content: Text('Rollback failed: ${ApiService.getErrorMessage(e)}'),
                                          ));
                                        } finally {
                                          _load();
                                        }
                                      },
                                      child: const Text('Rollback'),
                                    ),
                            );
                          },
                        ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(dynamic t) {
    final status = (t['status'] ?? 'PENDING').toString().toUpperCase();
    final isActive = t['isActive'] == 'Y';

    if (status == 'PENDING' || status == 'PARSING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 6),
            Text(status == 'PARSING' ? 'PARSING DOM...' : 'PENDING...', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.deepTeal)),
          ],
        ),
      );
    } else if (status == 'FAILED') {
      return InkWell(
        onTap: () => _showErrorDialog(t),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: AppColors.errorBg, borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 12, color: AppColors.brandRedDark),
              SizedBox(width: 4),
              Text('FAILED (VIEW)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandRedDark)),
            ],
          ),
        ),
      );
    } else if (status == 'PARSED') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppColors.yellowLight, borderRadius: BorderRadius.circular(12)),
        child: const Text('PARSED (DRAFT)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.yellowDark)),
      );
    } else {
      return AppComponents.statusBadge(isActive ? 'Active' : 'Inactive');
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeTemplates = _templates.where((t) => t['isActive'] == 'Y').length;
    int inactiveTemplates = _templates.length - activeTemplates;

    return Column(
      children: [
        _sectionHeader(
          'Template Manager',
          'Manage document generation templates, placeholder schemas, and version rollback history',
          action: Row(
            children: [
              OutlinedButton.icon(
                label: const Text('Placeholder Catalog'),
                icon: const Icon(Icons.menu_book_rounded),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaceholderCatalogScreen())),
                style: AppComponents.secondaryButton,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                label: const Text('Refresh'),
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                style: AppComponents.secondaryButton,
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                label: const Text('Delete All Templates'),
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.brandRedDark),
                onPressed: _templates.isEmpty ? null : _purgeAllTemplates,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.brandRedDark),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                label: const Text('Upload DOCX'),
                icon: const Icon(Icons.upload_file),
                onPressed: _uploadTemplate,
                style: AppComponents.primaryButton,
              ),
            ],
          ),
        ),
        
        // Top KPI Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppComponents.cardBase(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Templates', style: AppTypography.bodySmMedium(color: AppColors.slate)),
                      const SizedBox(height: 8),
                      Text('${_templates.length}', style: AppTypography.statDisplay(color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppComponents.cardBase(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active (In Use)', style: AppTypography.bodySmMedium(color: AppColors.slate)),
                      const SizedBox(height: 8),
                      Text('$activeTemplates', style: AppTypography.statDisplay(color: AppColors.brandBlue)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: AppComponents.cardBase(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Draft / Inactive', style: AppTypography.bodySmMedium(color: AppColors.slate)),
                      const SizedBox(height: 8),
                      Text('$inactiveTemplates', style: AppTypography.statDisplay(color: AppColors.warning)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_templates.isEmpty)
          Expanded(
            child: Center(
              child: AppComponents.emptyState(
                icon: Icons.description_outlined,
                title: 'No Templates Available',
                description: 'Upload your first DOCX template to start generating dynamic reports.',
                primaryButtonText: 'Upload Template',
                onPrimaryAction: _uploadTemplate,
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(28),
              itemCount: _templates.length,
              itemBuilder: (_, i) {
                final t = _templates[i];
                final status = (t['status'] ?? 'PENDING').toString();
                final version = t['version'] ?? 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: AppComponents.cardBase(),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: AppRadius.brMd,
                        ),
                        child: const Icon(Icons.file_present_rounded, color: AppColors.slate, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${t['name']}', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceSoft,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.hairlineSoft),
                                  ),
                                  child: Text('v$version', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusBadge(t),
                                const SizedBox(width: 12),
                                Text(
                                  'Updated: ${t['updatedAt'] ?? t['createdAt'] ?? '—'}',
                                  style: AppTypography.caption(color: AppColors.slate),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          if (status == 'CONFIRMED' || status == 'PARSED')
                            ElevatedButton.icon(
                              icon: const Icon(Icons.auto_stories_outlined, size: 16),
                              label: const Text('Open in Studio'),
                              onPressed: () {
                                final rawId = t['id'];
                                final int parsedId = rawId is int ? rawId : int.parse(rawId.toString());
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DocumentStudioScreen(
                                      templateId: parsedId,
                                      templateName: t['name']?.toString(),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.tealLight,
                                foregroundColor: AppColors.deepTeal,
                                elevation: 0,
                                side: BorderSide(color: AppColors.deepTeal.withValues(alpha: 0.3)),
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (status == 'PARSED') ...[
                            ElevatedButton(
                              onPressed: () => _fetchAndOpenPreview(t['id']),
                              style: AppComponents.primaryButton,
                              child: const Text('Finalize'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          OutlinedButton.icon(
                            label: const Text('History'),
                            icon: const Icon(Icons.history_rounded, size: 16),
                            onPressed: () => _showVersionHistoryDialog(t),
                            style: AppComponents.secondaryButton,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            label: const Text('Delete'),
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteTemplate(t),
                            style: AppComponents.dangerButton,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── REPORT CONTROL ───────────────────────────────────────────

class AdminReportSection extends StatefulWidget {
  const AdminReportSection({super.key});
  @override
  State<AdminReportSection> createState() => _AdminReportSectionState();
}

class _AdminReportSectionState extends State<AdminReportSection> {
  final _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/orders');
      setState(() {
        _orders = r.data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _forceStatus(dynamic o, String status) async {
    try {
      await _api.dio.post('/api/v1/admin/orders/${o['id']}/force-status', data: {'status': status, 'reason': 'Superadmin override'});
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Workflow forced to $status.'),
        ));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Report Control',
          'Stateless status overrides and workflow actions',
          action: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: AppComponents.secondaryButtonStyle().copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_orders.isEmpty)
          Expanded(child: _placeholderSection('📊', 'No Reports Found', 'Workflow queue is empty.'))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _orders.length,
              itemBuilder: (_, i) {
                final o = _orders[i];
                final hasLock = o['status'] == 'PAYMENT_LOCK';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #${o['id']}', style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Purpose: ${o['purpose'] ?? '—'}  |  Category: ${o['propertyCategory'] ?? '—'}',
                              style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Workflow Status: ', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '${o['status']}',
                                    style: AppTypography.bodySm().copyWith(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Row(
                        children: [
                          if (hasLock) ...[
                            _overrideBtn('Release Delivery', AppColors.success, () => _forceStatus(o, 'FINAL_DELIVERY')),
                            const SizedBox(width: 8),
                          ],
                          _overrideBtn('Force SPA Gate', AppColors.brandBlue, () => _forceStatus(o, 'SPA_GATE')),
                          const SizedBox(width: 8),
                          _overrideBtn('Reset Draft', AppColors.slate, () => _forceStatus(o, 'DRAFT')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _overrideBtn(String label, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(4),
            color: color.withOpacity(0.04),
          ),
          child: Text(
            label,
            style: AppTypography.heading5().copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      );
}

// ─── SIGNING MONITOR ──────────────────────────────────────────

class AdminSigningSection extends StatefulWidget {
  const AdminSigningSection({super.key});
  @override
  State<AdminSigningSection> createState() => _AdminSigningSectionState();
}

class _AdminSigningSectionState extends State<AdminSigningSection> {
  final _api = ApiService();
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/audit');
      final list = r.data as List<dynamic>;
      setState(() {
        _logs = list.where((log) {
          final action = (log['action'] ?? '').toString().toUpperCase();
          return action.contains('SIGN') || action.contains('OTP') || action.contains('LOCK');
        }).toList();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Signing Monitor',
          'Digital signature audit and security logs',
          action: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: AppComponents.secondaryButtonStyle().copyWith(
              padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ),
        ),
        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_logs.isEmpty)
          Expanded(child: _placeholderSection('✍️', 'No Signing Transactions', 'No cryptographic signature events found in audit history.'))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final log = _logs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.brXl, border: Border.all(color: AppColors.hairlineSoft)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.verified_user_outlined, color: AppColors.success, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${log['action']}', style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${log['details']}', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(
                              'Actor: ${log['actorEmail']}  |  Entity: ${log['entityType']} #${log['entityId']}',
                              style: AppTypography.bodySm().copyWith(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── DICTIONARY LOOKUP ────────────────────────────────────────

class DictionaryDialogWidget extends StatefulWidget {
  const DictionaryDialogWidget({super.key});
  @override
  State<DictionaryDialogWidget> createState() => _DictionaryDialogWidgetState();
}

class _DictionaryDialogWidgetState extends State<DictionaryDialogWidget> {
  final ApiService _api = ApiService();
  List<dynamic> _questions = [];
  List<dynamic> _filteredQuestions = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/templates/questions');
      setState(() {
        _questions = r.data as List<dynamic>;
        _filterQuestions();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _filterQuestions() {
    setState(() {
      if (_searchQuery.trim().isEmpty) {
        _filteredQuestions = List.from(_questions);
      } else {
        _filteredQuestions = _questions.where((q) {
          final key = (q['placeholderKey'] ?? '').toString().toLowerCase();
          final text = (q['questionText'] ?? '').toString().toLowerCase();
          final qry = _searchQuery.toLowerCase();
          return key.contains(qry) || text.contains(qry);
        }).toList();
      }
    });
  }

  Future<void> _editQuestion(dynamic q) async {
    final ctrl = TextEditingController(text: q['questionText']);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Edit Predefined Question', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placeholder Key: ${q['placeholderKey']}',
              style: AppTypography.bodySm().copyWith(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: AppTypography.bodySm().copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Enter question text mapping...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _api.dio.put('/api/v1/templates/questions', data: {
                  'placeholderKey': q['placeholderKey'],
                  'questionText': ctrl.text.trim(),
                });
                _loadQuestions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: AppColors.success,
                    content: Text('Predefined dictionary updated successfully!'),
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: AppColors.brandRedDark,
                    content: Text('Failed to update dictionary mapping.'),
                  ));
                }
              }
            },
            style: AppComponents.primaryButtonStyle(),
            child: Text('Save', style: AppTypography.bodySm().copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.book_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Questions Dictionary Lookup', style: AppTypography.heading4().copyWith(color: AppColors.ink)),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) {
                _searchQuery = val;
                _filterQuestions();
              },
              style: AppTypography.bodySm().copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search placeholder keys or question texts...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_filteredQuestions.isEmpty)
              Expanded(child: Center(child: Text('No dictionary mappings found.', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredQuestions.length,
                  itemBuilder: (ctx, i) {
                    final q = _filteredQuestions[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${q['placeholderKey']}', style: AppTypography.bodySm().copyWith(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('${q['questionText'] ?? '—'}', style: AppTypography.bodySm().copyWith(color: AppColors.ink, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _editQuestion(q),
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                            tooltip: 'Edit Mapping',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ─── 2. BUILDING TYPE MASTER ──────────────────────────────────

class AdminBuildingTypesSection extends StatefulWidget {
  const AdminBuildingTypesSection({super.key});

  @override
  State<AdminBuildingTypesSection> createState() => _AdminBuildingTypesSectionState();
}

class _AdminBuildingTypesSectionState extends State<AdminBuildingTypesSection> {
  final _api = ApiService();
  List<dynamic> _buildingTypes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/api/v1/admin/building-types');
      if (res.data is List) {
        setState(() => _buildingTypes = res.data as List<dynamic>);
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showAddEditDialog([dynamic existing]) {
    final nameCtrl = TextEditingController(text: existing != null ? existing['name'] : '');
    final lifeCtrl = TextEditingController(text: existing != null ? existing['defaultUsefulLife'].toString() : '60');
    bool isActive = existing != null ? (existing['active'] ?? true) : true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Building Type' : 'Add Building Type', style: AppTypography.heading4()),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Building Type Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lifeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Default Useful Life (Years)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final life = int.tryParse(lifeCtrl.text) ?? 60;
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  if (existing != null) {
                    await _api.dio.put('/api/v1/admin/building-types/${existing['id']}', data: {
                      'name': name,
                      'defaultUsefulLife': life,
                      'active': isActive,
                    });
                  } else {
                    await _api.dio.post('/api/v1/admin/building-types', data: {
                      'name': name,
                      'defaultUsefulLife': life,
                      'active': isActive,
                    });
                  }
                  _load();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: AppColors.brandRedDark,
                    content: Text('Failed to save: ${ApiService.getErrorMessage(e)}'),
                  ));
                }
              },
              style: AppComponents.primaryButtonStyle(),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Building Type Master',
          'Configure building classifications and default useful life for automatic depreciation calculations',
          action: ElevatedButton.icon(
            label: const Text('Add Building Type'),
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
            style: AppComponents.primaryButton,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(28),
                  itemCount: _buildingTypes.length,
                  itemBuilder: (context, idx) {
                    final b = _buildingTypes[idx];
                    final isActive = b['active'] == true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: AppComponents.cardBase(),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.apartment_rounded, color: AppColors.deepTeal, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['name'] ?? '', style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('Default Useful Life: ${b['defaultUsefulLife']} Years', style: AppTypography.caption(color: AppColors.slate)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.successBg : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? AppColors.success : AppColors.slate)),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                            onPressed: () => _showAddEditDialog(b),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── 1. VALUATION SETTINGS MASTER ─────────────────────────────

class AdminValuationSettingsSection extends StatefulWidget {
  const AdminValuationSettingsSection({super.key});

  @override
  State<AdminValuationSettingsSection> createState() => _AdminValuationSettingsSectionState();
}

class _AdminValuationSettingsSectionState extends State<AdminValuationSettingsSection> {
  final _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  final _realizableCtrl = TextEditingController(text: '85');
  final _distressCtrl = TextEditingController(text: '75');
  final _salvageCtrl = TextEditingController(text: '10');
  final _rccLifeCtrl = TextEditingController(text: '60');
  final _shedLifeCtrl = TextEditingController(text: '40');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/api/v1/admin/valuation-settings');
      if (res.data is Map) {
        final d = res.data as Map<String, dynamic>;
        _realizableCtrl.text = d['realizablePercentage']?.toString() ?? '85';
        _distressCtrl.text = d['distressSalePercentage']?.toString() ?? '75';
        _salvageCtrl.text = d['salvagePercentage']?.toString() ?? '10';
        _rccLifeCtrl.text = d['rccUsefulLife']?.toString() ?? '60';
        _shedLifeCtrl.text = d['shedUsefulLife']?.toString() ?? '40';
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.dio.put('/api/v1/admin/valuation-settings', data: {
        'realizablePercentage': double.tryParse(_realizableCtrl.text) ?? 85.0,
        'distressSalePercentage': double.tryParse(_distressCtrl.text) ?? 75.0,
        'salvagePercentage': double.tryParse(_salvageCtrl.text) ?? 10.0,
        'rccUsefulLife': int.tryParse(_rccLifeCtrl.text) ?? 60,
        'shedUsefulLife': int.tryParse(_shedLifeCtrl.text) ?? 40,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Valuation Master Settings saved successfully!'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Save failed: ${ApiService.getErrorMessage(e)}'),
      ));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Valuation Settings Master',
          'Configure global default percentages and parameters auto-injected into newly created valuation reports',
          action: ElevatedButton.icon(
            label: Text(_saving ? 'Saving...' : 'Save Settings'),
            icon: const Icon(Icons.save_rounded),
            onPressed: _saving ? null : _save,
            style: AppComponents.primaryButton,
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppComponents.cardBase(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Default Valuation Parameters', style: AppTypography.heading4()),
                        const SizedBox(height: 8),
                        Text('These values will automatically populate on report creation and remain editable per report.', style: AppTypography.bodySm(color: AppColors.slate)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _realizableCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Default Realizable %', suffixText: '%', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _distressCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Default Distress Sale %', suffixText: '%', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _salvageCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Default Salvage Value %', suffixText: '%', border: OutlineInputBorder()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rccLifeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'RCC Useful Life (Years)', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _shedLifeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Shed Useful Life (Years)', border: OutlineInputBorder()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── 17. TRASH BIN / DELETED REPORTS SECTION ──────────────────

class AdminTrashBinSection extends StatefulWidget {
  const AdminTrashBinSection({super.key});

  @override
  State<AdminTrashBinSection> createState() => _AdminTrashBinSectionState();
}

class _AdminTrashBinSectionState extends State<AdminTrashBinSection> {
  final _api = ApiService();
  List<dynamic> _deletedOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _api.dio.get('/api/v1/admin/orders/deleted');
      if (res.data is List) {
        setState(() => _deletedOrders = res.data as List<dynamic>);
      }
    } catch (_) {
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _restore(int id) async {
    try {
      await _api.dio.post('/api/v1/admin/orders/$id/restore');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Report restored to active status successfully!'),
      ));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Restore failed: ${ApiService.getErrorMessage(e)}'),
      ));
    }
  }

  Future<void> _purge(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Purge Report?'),
        content: const Text('Are you sure you want to permanently delete this report? This will remove all associated valuation items, snapshots, and documents.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PURGE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/v1/admin/orders/$id/purge');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('Report permanently purged from database.'),
      ));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Purge failed: ${ApiService.getErrorMessage(e)}'),
      ));
    }
  }

  Future<void> _purgeAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Purge ALL Reports & Valuation Data?'),
        content: const Text('CRITICAL: This will permanently delete ALL orders, valuation items, snapshots, documents, inputs, and revisions from the entire system. This action cannot be reversed!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('PURGE ALL REPORTS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/v1/admin/reports/purge-all');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: AppColors.success,
        content: Text('All reports and valuation data permanently purged.'),
      ));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.brandRedDark,
        content: Text('Purge all failed: ${ApiService.getErrorMessage(e)}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(
          'Deleted Reports & Trash Bin',
          'Super Admin audit and recovery console for soft-deleted valuation orders',
          action: Row(
            children: [
              OutlinedButton.icon(
                label: const Text('Refresh'),
                icon: const Icon(Icons.refresh),
                onPressed: _load,
                style: AppComponents.secondaryButton,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                label: const Text('Purge All Reports'),
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: _purgeAll,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _deletedOrders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.delete_sweep_rounded, size: 48, color: AppColors.slate),
                          const SizedBox(height: 12),
                          Text('No deleted reports in trash bin.', style: AppTypography.bodySm(color: AppColors.slate)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(28),
                      itemCount: _deletedOrders.length,
                      itemBuilder: (context, idx) {
                        final o = _deletedOrders[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: AppComponents.cardBase(),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.brandRedDark.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.delete_outline_rounded, color: AppColors.brandRedDark, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o['reportNumber'] ?? 'Order #${o['id']}', style: AppTypography.bodySm().copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 4),
                                    Text('Client: ${o['clientName'] ?? '—'} | Bank: ${o['bankName'] ?? '—'} | Deleted: ${o['deletedAt'] ?? '—'}', style: AppTypography.caption(color: AppColors.slate)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.restore_from_trash_rounded, size: 16, color: AppColors.success),
                                label: const Text('Restore', style: TextStyle(color: AppColors.success)),
                                onPressed: () => _restore(o['id'] as int),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_forever_rounded, color: AppColors.brandRedDark, size: 20),
                                tooltip: 'Permanently Purge',
                                onPressed: () => _purge(o['id'] as int),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
