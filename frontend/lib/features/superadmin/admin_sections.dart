import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../../services/web_file_picker.dart';
import '../../theme/design_system.dart';
import '../../services/api_service.dart';

// ─── Shared helpers ───────────────────────────────────────────

Widget _sectionHeader(String title, String subtitle, {Widget? action}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: const BoxDecoration(
        color: DesignSystem.white,
        border: Border(bottom: BorderSide(color: DesignSystem.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DesignSystem.h2(color: DesignSystem.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13),
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
      decoration: BoxDecoration(
        color: DesignSystem.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignSystem.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DesignSystem.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignSystem.textSecondary, size: 18),
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: DesignSystem.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
              ),
            ],
          ),
        ],
      ),
    );

Widget _placeholderSection(String icon, String title, String msg) =>
    Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignSystem.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(icon, style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: 20),
            Text(title, style: DesignSystem.h3(color: DesignSystem.textPrimary)),
            const SizedBox(height: 8),
            Text(
              msg,
              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 14),
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/admin/overview');
      setState(() {
        _data = r.data as Map<String, dynamic>;
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
          'Overview',
          'System health and key performance metrics',
          action: ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: DesignSystem.outlinedButton.copyWith(
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
                children: [
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 3 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                    children: [
                      _statCard('Total Active Users', '${_data?['totalUsers'] ?? '0'}', Icons.people_outline, DesignSystem.primary),
                      _statCard('Total Orders', '${_data?['totalOrders'] ?? '0'}', Icons.folder_outlined, DesignSystem.secondary),
                      _statCard('Open Orders', '${_data?['openOrders'] ?? '0'}', Icons.hourglass_empty, const Color(0xFFD97706)),
                      _statCard('SPA Gate Orders', '${_data?['spaGateOrders'] ?? '0'}', Icons.supervisor_account_outlined, const Color(0xFF8B5CF6)),
                      _statCard('Final Delivery', '${_data?['finalDeliveryOrders'] ?? '0'}', Icons.check_circle_outline, DesignSystem.success),
                      _statCard('Active Templates', '${_data?['activeTemplates'] ?? '0'}', Icons.description_outlined, const Color(0xFF0891B2)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
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
          backgroundColor: DesignSystem.success,
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
          backgroundColor: DesignSystem.success,
          content: Text('Payment waived successfully.'),
        ));
      }
    } catch (_) {}
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
              decoration: BoxDecoration(color: DesignSystem.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add_shopping_cart, color: DesignSystem.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('Create New Order', style: DesignSystem.h3(color: DesignSystem.textPrimary)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtrl,
                style: DesignSystem.body(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Property Category',
                  hintText: 'VALUATION / NETWORTH / CHARTERED_ENGINEER',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purposeCtrl,
                style: DesignSystem.body(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                style: DesignSystem.body(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Estimated Value',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: templateIdCtrl,
                style: DesignSystem.body(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Template ID (Optional)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientIdCtrl,
                style: DesignSystem.body(fontSize: 13),
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
            child: Text('Cancel', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    backgroundColor: DesignSystem.success,
                    content: Text('Order created successfully!'),
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: DesignSystem.error,
                    content: Text('Failed to create order.'),
                  ));
                }
              }
            },
            style: DesignSystem.primaryButton,
            child: Text('Create', style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
                style: DesignSystem.primaryButton.copyWith(
                  backgroundColor: WidgetStateProperty.all(DesignSystem.primary),
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: DesignSystem.outlinedButton.copyWith(
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
                      color: DesignSystem.structural,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('ID', style: DesignSystem.label(color: DesignSystem.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Status', style: DesignSystem.label(color: DesignSystem.textSecondary)),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text('Purpose', style: DesignSystem.label(color: DesignSystem.textSecondary)),
                        ),
                        SizedBox(
                          width: 220,
                          child: Text('Actions', style: DesignSystem.label(color: DesignSystem.textSecondary), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  ..._orders.map((o) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: DesignSystem.border),
                            left: BorderSide(color: DesignSystem.border),
                            right: BorderSide(color: DesignSystem.border),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '#${o['id']}',
                                style: DesignSystem.body(color: DesignSystem.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: DesignSystem.structural,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${o['status']}'.replaceAll('_', ' '),
                                      style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                '${o['purpose'] ?? '—'}',
                                style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(
                              width: 220,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  _queueBtn('Release', Icons.send_outlined, DesignSystem.primary, () => _forceRelease(o)),
                                  const SizedBox(width: 8),
                                  _queueBtn('Waive Payment', Icons.money_off_outlined, DesignSystem.success, () => _waivePayment(o)),
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
                style: GoogleFonts.montserrat(
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
            style: DesignSystem.outlinedButton.copyWith(
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
                    ? DesignSystem.error
                    : health == 'WARNING'
                        ? DesignSystem.warning
                        : DesignSystem.success;
                final Color hColorBg = health == 'CRITICAL'
                    ? DesignSystem.errorBg
                    : health == 'WARNING'
                        ? DesignSystem.warningBg
                        : DesignSystem.successBg;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: DesignSystem.cardDecoration,
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
                              style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${s['status']}'.replaceAll('_', ' '),
                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          '${s['purpose'] ?? '—'}',
                          style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
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
                          style: DesignSystem.body(color: hColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '${s['remainingHours'] ?? '—'} hours left',
                        style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
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
          backgroundColor: DesignSystem.success,
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
                  decoration: DesignSystem.cardDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              key.replaceAll('_', ' ').toUpperCase(),
                              style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c['description'] ?? ''}',
                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12),
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
                          style: DesignSystem.body(fontSize: 13, fontWeight: FontWeight.bold),
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
                        style: DesignSystem.primaryButton.copyWith(
                          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                        ),
                        child: Text('Save', style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
          backgroundColor: DesignSystem.success,
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
                    decoration: DesignSystem.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Agreement Version', style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: _versionCtrl,
                                  style: DesignSystem.body(fontSize: 13, fontWeight: FontWeight.bold),
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
                              style: DesignSystem.primaryButton.copyWith(
                                padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                              ),
                              child: Text('Publish Version', style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _tcStat('Accepted clients', '${_tc?['acceptedCount'] ?? 0}', DesignSystem.success),
                            const SizedBox(width: 12),
                            _tcStat('Pending consent', '${_tc?['pendingCount'] ?? 0}', DesignSystem.warning),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text('ACCEPTANCE COMPLIANCE LOG', style: DesignSystem.label(color: DesignSystem.textSecondary)),
                  const SizedBox(height: 12),
                  ..._log.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: DesignSystem.cardDecoration,
                        child: Row(
                          children: [
                            Icon(
                              e['compliant'] == true ? Icons.check_circle_outline : Icons.pending_actions_outlined,
                              color: e['compliant'] == true ? DesignSystem.success : DesignSystem.warning,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${e['email']}',
                                style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: DesignSystem.structural, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${e['role']}',
                                style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Version Accepted: v${e['acceptedVersion'] ?? '—'}',
                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
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
            Text(val, style: DesignSystem.body(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(label, style: DesignSystem.body(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _api.dio.get('/api/v1/templates');
      setState(() {
        _templates = r.data as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteTemplate(dynamic t) async {
    try {
      await _api.dio.delete('/api/v1/templates/${t['id']}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: DesignSystem.success,
          content: Text('Template deleted successfully.'),
        ));
      }
      _load();
    } catch (_) {}
  }

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
            backgroundColor: DesignSystem.error,
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
          title: Text('Name your Template', style: DesignSystem.h3(color: DesignSystem.textPrimary)),
          content: TextField(
            controller: nameCtrl,
            style: DesignSystem.body(fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'Template Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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

                  final r = await _api.dio.post('/api/v1/templates/upload', data: formData);

                  if (mounted) {
                    _showTemplatePreviewDialog(r.data);
                  }
                } catch (e) {
                  setState(() => _loading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      backgroundColor: DesignSystem.error,
                      content: Text('Failed to upload template.'),
                    ));
                  }
                }
              },
              style: DesignSystem.primaryButton,
              child: Text('Upload', style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: DesignSystem.error,
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
                  color: DesignSystem.structural,
                  border: Border.all(color: DesignSystem.border),
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
                            style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignSystem.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: ['TEXT', 'DATE', 'IMAGE', 'NUMBER'].contains(type) ? type : 'TEXT',
                              style: DesignSystem.body(color: DesignSystem.primary, fontSize: 10, fontWeight: FontWeight.bold),
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
                          style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: questionControllers[idx],
                      style: DesignSystem.body(fontSize: 12),
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
                        style: DesignSystem.body(color: DesignSystem.secondary, fontSize: 11, fontWeight: FontWeight.bold),
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
              title: Text('Template Parsing Preview: ${template['name']}', style: DesignSystem.h3(color: DesignSystem.textPrimary)),
              content: SizedBox(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verify and customize the prompt text for each extracted placeholder:', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13)),
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
                  child: Text('Cancel', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    for (int i = 0; i < fields.length; i++) {
                      fields[i]['question'] = questionControllers[i].text.trim();
                    }
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    try {
                      final updatedFieldMapping = jsonEncode(parsedSchema);
                      await _api.dio.post('/api/v1/templates/${template['id']}/confirm', data: updatedFieldMapping);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: DesignSystem.success,
                          content: Text('Template finalized and activated successfully!'),
                        ));
                      }
                    } catch (_) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          backgroundColor: DesignSystem.error,
                          content: Text('Failed to finalize template.'),
                        ));
                      }
                    }
                    _load();
                  },
                  style: DesignSystem.primaryButton,
                  child: Text('Confirm & Finalize', style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int activeTemplates = _templates.where((t) => t['isActive'] == 'Y').length;
    int inactiveTemplates = _templates.length - activeTemplates;

    return Column(
      children: [
        _sectionHeader(
          'Template Manager',
          'Manage document generation templates',
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
                final isActive = t['isActive'] == 'Y';
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
                        child: Icon(Icons.file_present_rounded, color: AppColors.slate, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t['name']}', style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                AppComponents.statusBadge(isActive ? 'Active' : 'Inactive'),
                                const SizedBox(width: 12),
                                Text(
                                  'Status: ${t['status']}',
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
                          if (!isActive) ...[
                            ElevatedButton(
                              onPressed: () => _showTemplatePreviewDialog(t),
                              style: AppComponents.primaryButton,
                              child: const Text('Finalize'),
                            ),
                            const SizedBox(width: 8),
                          ],
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
          backgroundColor: DesignSystem.success,
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
            style: DesignSystem.outlinedButton.copyWith(
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
                  decoration: DesignSystem.cardDecoration,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #${o['id']}', style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              'Purpose: ${o['purpose'] ?? '—'}  |  Category: ${o['propertyCategory'] ?? '—'}',
                              style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Workflow Status: ', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: DesignSystem.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                    '${o['status']}',
                                    style: DesignSystem.body(color: DesignSystem.primary, fontSize: 10, fontWeight: FontWeight.bold),
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
                            _overrideBtn('Release Delivery', DesignSystem.success, () => _forceStatus(o, 'FINAL_DELIVERY')),
                            const SizedBox(width: 8),
                          ],
                          _overrideBtn('Force SPA Gate', const Color(0xFF8B5CF6), () => _forceStatus(o, 'SPA_GATE')),
                          const SizedBox(width: 8),
                          _overrideBtn('Reset Draft', const Color(0xFF64748B), () => _forceStatus(o, 'DRAFT')),
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
            style: GoogleFonts.montserrat(
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
            style: DesignSystem.outlinedButton.copyWith(
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
                  decoration: DesignSystem.cardDecoration,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: DesignSystem.successBg, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.verified_user_outlined, color: DesignSystem.success, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${log['action']}', style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${log['details']}', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 12)),
                            const SizedBox(height: 6),
                            Text(
                              'Actor: ${log['actorEmail']}  |  Entity: ${log['entityType']} #${log['entityId']}',
                              style: DesignSystem.body(color: DesignSystem.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
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
        title: Text('Edit Predefined Question', style: DesignSystem.h3(color: DesignSystem.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Placeholder Key: ${q['placeholderKey']}',
              style: DesignSystem.body(color: DesignSystem.primary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              style: DesignSystem.body(fontSize: 13),
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
            child: Text('Cancel', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                    backgroundColor: DesignSystem.success,
                    content: Text('Predefined dictionary updated successfully!'),
                  ));
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    backgroundColor: DesignSystem.error,
                    content: Text('Failed to update dictionary mapping.'),
                  ));
                }
              }
            },
            style: DesignSystem.primaryButton,
            child: Text('Save', style: DesignSystem.body(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
            decoration: BoxDecoration(color: DesignSystem.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.book_outlined, color: DesignSystem.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text('Questions Dictionary Lookup', style: DesignSystem.h3(color: DesignSystem.textPrimary)),
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
              style: DesignSystem.body(fontSize: 13),
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
              Expanded(child: Center(child: Text('No dictionary mappings found.', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13))))
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
                        border: Border.all(color: DesignSystem.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${q['placeholderKey']}', style: DesignSystem.body(color: DesignSystem.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('${q['questionText'] ?? '—'}', style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _editQuestion(q),
                            icon: const Icon(Icons.edit_outlined, size: 18, color: DesignSystem.primary),
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
          child: Text('Close', style: DesignSystem.body(color: DesignSystem.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
