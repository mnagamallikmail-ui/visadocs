import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/web_file_picker.dart';
import '../../theme/app_colors.dart';

class PrivacyGovernanceDashboard extends StatefulWidget {
  const PrivacyGovernanceDashboard({super.key});

  @override
  State<PrivacyGovernanceDashboard> createState() => _PrivacyGovernanceDashboardState();
}

class _PrivacyGovernanceDashboardState extends State<PrivacyGovernanceDashboard> {
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _governanceSummary;
  List<dynamic> _correctionRequests = [];
  List<dynamic> _erasureRequests = [];
  List<dynamic> _grievanceCases = [];
  List<dynamic> _breachIncidents = [];
  List<dynamic> _retentionPolicies = [];

  int _selectedTab = 0;
  final List<String> _tabs = [
    'Overview & Metrics',
    'Correction Requests',
    'Erasure Requests & Holds',
    'Grievance Redressal',
    'Data Breach Incidents',
    'Retention Policies & Runs',
  ];

  @override
  void initState() {
    super.initState();
    _loadGovernanceData();
  }

  Future<void> _loadGovernanceData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiService().dio;

      // 1. Summary
      final summaryRes = await dio.get('/api/v1/admin/privacy/governance-summary');
      if (summaryRes.statusCode == 200 && summaryRes.data != null) {
        _governanceSummary = Map<String, dynamic>.from(summaryRes.data);
      }

      // 2. Correction
      final corrRes = await dio.get('/api/v1/admin/privacy/corrections');
      if (corrRes.statusCode == 200 && corrRes.data is List) {
        _correctionRequests = List<dynamic>.from(corrRes.data);
      }

      // 3. Erasure
      final erasureRes = await dio.get('/api/v1/admin/privacy/erasures');
      if (erasureRes.statusCode == 200 && erasureRes.data is List) {
        _erasureRequests = List<dynamic>.from(erasureRes.data);
      }

      // 4. Grievance
      final grievRes = await dio.get('/api/v1/admin/privacy/grievances');
      if (grievRes.statusCode == 200 && grievRes.data is List) {
        _grievanceCases = List<dynamic>.from(grievRes.data);
      }

      // 5. Breaches
      final breachRes = await dio.get('/api/v1/admin/privacy/breaches');
      if (breachRes.statusCode == 200 && breachRes.data is List) {
        _breachIncidents = List<dynamic>.from(breachRes.data);
      }

      // 6. Retention Policies
      final retRes = await dio.get('/api/v1/admin/privacy/retention-policies');
      if (retRes.statusCode == 200 && retRes.data is List) {
        _retentionPolicies = List<dynamic>.from(retRes.data);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load privacy governance data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBanner(),
          const SizedBox(height: 16),
          _buildNavTabs(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF99F6E4)),
            ),
            child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF005C5C), size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Privacy Governance Command Center',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Text(
                        'DPDP Health Score: ${_governanceSummary?['complianceHealthScore'] ?? '98%'}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.successAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Statutory oversight of Data Principal Rights, Retention Policies, Incident Response & Board Reporting.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _triggerRetentionExecution,
                icon: const Icon(Icons.cleaning_services_outlined, size: 16),
                label: const Text('Run Retention Engine'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF005C5C),
                  side: const BorderSide(color: Color(0xFF005C5C)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showLogBreachDialog,
                icon: const Icon(Icons.warning_amber_rounded, size: 16),
                label: const Text('Log Breach Incident'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandRedDark,
                  foregroundColor: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadGovernanceData,
                tooltip: 'Refresh Telemetry',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSel = _selectedTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = i),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF005C5C) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSel ? const Color(0xFF005C5C) : AppColors.hairline),
                ),
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                    color: isSel ? Colors.white : AppColors.slate,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.brandRedDark),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.brandRedDark)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadGovernanceData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewMetricsTab();
      case 1:
        return _buildCorrectionManagementTab();
      case 2:
        return _buildErasureManagementTab();
      case 3:
        return _buildGrievanceManagementTab();
      case 4:
        return _buildBreachManagementTab();
      case 5:
        return _buildRetentionManagementTab();
      default:
        return _buildOverviewMetricsTab();
    }
  }

  // ─── TAB 0: OVERVIEW & METRICS ──────────────────────────────────────────────
  Widget _buildOverviewMetricsTab() {
    final s = _governanceSummary ?? {};

    return ListView(
      children: [
        // KPI Cards Row
        Row(
          children: [
            _buildKpiCard('Open Privacy Requests', '${s['openPrivacyRequests'] ?? 0}', Icons.inbox_outlined, const Color(0xFF0284C7)),
            const SizedBox(width: 14),
            _buildKpiCard('Pending Corrections', '${s['pendingCorrections'] ?? 0}', Icons.edit_note_outlined, const Color(0xFFF59E0B)),
            const SizedBox(width: 14),
            _buildKpiCard('Active Erasure Requests', '${s['activeErasureRequests'] ?? 0}', Icons.delete_sweep_outlined, AppColors.brandRedDark),
            const SizedBox(width: 14),
            _buildKpiCard('Open Grievances', '${s['openGrievances'] ?? 0}', Icons.support_agent_outlined, const Color(0xFF7C3AED)),
            const SizedBox(width: 14),
            _buildKpiCard('Active Consents', '${s['activeConsents'] ?? 0}', Icons.verified_user_outlined, const Color(0xFF047857)),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildPanel(
                title: 'Data Governance Safeguards Status',
                child: Column(
                  children: [
                    _buildRow('Statutory Law', s['statutoryAct']?.toString() ?? 'DPDP Act 2023 (India)'),
                    _buildRow('Encryption Standard', s['encryptionStatus']?.toString() ?? 'ACTIVE (AES-256-GCM)'),
                    _buildRow('Total Breaches Recorded', '${s['totalBreaches'] ?? 0} incidents'),
                    _buildRow('Active Breach Investigations', '${s['openBreaches'] ?? 0} incidents'),
                    _buildRow('Statutory DPO Notice', s['activeNoticeVersion']?.toString() ?? 'DPDP-NOTICE-V1.0'),
                    _buildRow('Compliance Health Score', s['complianceHealthScore']?.toString() ?? '98%'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _buildPanel(
                title: 'Statutory DPDP Officers',
                child: Column(
                  children: [
                    _buildRow('Data Protection Officer', s['dpoName']?.toString() ?? 'Compliance Cell'),
                    _buildRow('DPO Email', s['dpoEmail']?.toString() ?? 'dpo@provaluer.com'),
                    _buildRow('Grievance Officer', s['grievanceOfficer']?.toString() ?? 'Grievance Officer'),
                    _buildRow('Grievance Email', s['grievanceEmail']?.toString() ?? 'grievance@provaluer.com'),
                    _buildRow('Grievance SLA Standard', '7 Working Days'),
                    _buildRow('Supervisory Authority', s['dpbiSupervisoryAuthority']?.toString() ?? 'Data Protection Board of India'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── TAB 1: CORRECTION MANAGEMENT ───────────────────────────────────────────
  Widget _buildCorrectionManagementTab() {
    return ListView(
      children: [
        if (_correctionRequests.isEmpty)
          _buildEmpty('No correction requests pending.')
        else
          ..._correctionRequests.map((c) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Req #${c['id']} — Field: ${c['fieldName']}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(width: 10),
                            _buildBadge(c['status']?.toString() ?? 'SUBMITTED'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('User ID: ${c['userId']} • Existing: ${c['existingValue'] ?? '—'} ➔ Requested: ${c['requestedValue'] ?? '—'}',
                            style: GoogleFonts.inter(fontSize: 12)),
                        Text('Reason: ${c['reason'] ?? '—'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  if (c['status'] == 'SUBMITTED' || c['status'] == 'UNDER_REVIEW') ...[
                    TextButton(
                      onPressed: () => _updateCorrectionStatus(c['id'], 'APPROVED'),
                      child: const Text('Approve', style: TextStyle(color: AppColors.successAccent)),
                    ),
                    TextButton(
                      onPressed: () => _updateCorrectionStatus(c['id'], 'REJECTED'),
                      child: const Text('Reject', style: TextStyle(color: AppColors.brandRedDark)),
                    ),
                  ],
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 2: ERASURE MANAGEMENT ──────────────────────────────────────────────
  Widget _buildErasureManagementTab() {
    return ListView(
      children: [
        if (_erasureRequests.isEmpty)
          _buildEmpty('No erasure requests filed.')
        else
          ..._erasureRequests.map((e) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Erasure #${e['id']} — User #${e['userId']}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                            const SizedBox(width: 10),
                            _buildBadge(e['status']?.toString() ?? 'SUBMITTED'),
                            if (e['legalHoldFlag'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.brandRed, borderRadius: BorderRadius.circular(4)),
                                child: Text('LEGAL HOLD', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.brandRedDark)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('Reason: ${e['reason'] ?? '—'}', style: GoogleFonts.inter(fontSize: 12)),
                        Text('Submitted: ${e['createdAt'] ?? '—'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.steel)),
                      ],
                    ),
                  ),
                  if (e['status'] == 'SUBMITTED' || e['status'] == 'LEGAL_REVIEW') ...[
                    ElevatedButton(
                      onPressed: () => _executeSecureErasure(e['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
                      child: const Text('Approve & Shred Data'),
                    ),
                  ],
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 3: GRIEVANCE MANAGEMENT ────────────────────────────────────────────
  Widget _buildGrievanceManagementTab() {
    return ListView(
      children: [
        if (_grievanceCases.isEmpty)
          _buildEmpty('No grievance tickets.')
        else
          ..._grievanceCases.map((g) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ticket: ${g['ticketNumber']} — Category: ${g['category']}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      _buildBadge(g['status']?.toString() ?? 'SUBMITTED'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Description: ${g['description']}', style: GoogleFonts.inter(fontSize: 12)),
                  Text('Officer: ${g['assignedOfficer'] ?? 'Unassigned'} • Due: ${g['slaDueDate'] ?? '—'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                  const SizedBox(height: 10),
                  if (g['status'] != 'RESOLVED' && g['status'] != 'CLOSED')
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _resolveGrievanceDialog(g['id']),
                          child: const Text('Resolve Ticket'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 4: BREACH MANAGEMENT ───────────────────────────────────────────────
  Widget _buildBreachManagementTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data Breach Incident Registry (DPDP Sec 8(6))',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('Statutory 72-hour notification pipeline to Data Protection Board of India and affected Principals.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showLogBreachDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Log New Incident'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_breachIncidents.isEmpty)
          _buildEmpty('No breach incidents registered.')
        else
          ..._breachIncidents.map((b) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Incident #${b['incidentId']} — Severity: ${b['severity']}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      _buildBadge(b['status']?.toString() ?? 'OPEN'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Root Cause: ${b['rootCause'] ?? '—'}', style: GoogleFonts.inter(fontSize: 12)),
                  Text('Impact: ${b['impactAssessment'] ?? '—'} • Affected Principals: ${b['numberAffected'] ?? 0}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                  Text('Containment: ${b['containmentStatus'] ?? 'PENDING'}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                  const SizedBox(height: 10),
                  if (b['status'] != 'CLOSED')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _dispatchDpbiNotification(b['id']),
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: const Text('Dispatch Statutory DPBI & Principal Notice'),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005C5C), foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 5: RETENTION MANAGEMENT ────────────────────────────────────────────
  Widget _buildRetentionManagementTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statutory Retention Policy Engine (DPDP Sec 8(7))',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('Configurable retention schedules with automatic archiving and cryptographic shredding.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _triggerRetentionExecution,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Execute Retention Job Now'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF005C5C), foregroundColor: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_retentionPolicies.isEmpty)
          _buildEmpty('No retention policies loaded.')
        else
          ..._retentionPolicies.map((p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.hairline),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entity: ${p['entityType']}',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text('Retention Period: ${p['retentionPeriodDays']} Days (${(p['retentionPeriodDays'] / 365).toStringAsFixed(1)} Years)',
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF005C5C), fontWeight: FontWeight.w600)),
                        Text('Legal Basis: ${p['legalBasis']}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                        Text('Archive: ${p['archiveStrategy']} • Purge: ${p['purgeStrategy']}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.steel)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (p['active'] == true) ? AppColors.successBg : AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text((p['active'] == true) ? 'ACTIVE' : 'DISABLED',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: (p['active'] == true) ? AppColors.successAccent : AppColors.steel)),
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── HELPERS ────────────────────────────────────────────────────────────────

  Widget _buildKpiCard(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w500)),
                Icon(icon, size: 18, color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(val, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String status) {
    Color bg = AppColors.surfaceSoft;
    Color fg = AppColors.slate;

    switch (status) {
      case 'APPROVED':
      case 'RESOLVED':
      case 'CLOSED':
      case 'CONTAINED':
        bg = AppColors.successBg;
        fg = AppColors.successAccent;
        break;
      case 'REJECTED':
      case 'CRITICAL':
        bg = AppColors.brandRed;
        fg = AppColors.brandRedDark;
        break;
      case 'UNDER_REVIEW':
      case 'LEGAL_REVIEW':
      case 'HIGH':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'SUBMITTED':
      case 'OPEN':
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(status, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildEmpty(String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.steel)),
    );
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _updateCorrectionStatus(dynamic id, String status) async {
    try {
      await ApiService().dio.post('/api/v1/admin/privacy/corrections/$id/review', data: {
        'status': status,
        'remarks': 'Reviewed by Compliance Officer',
      });
      _loadGovernanceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _executeSecureErasure(dynamic id) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Validating legal holds & executing erasure...')));
      final res = await ApiService().dio.post('/api/v1/admin/privacy/erasures/$id/approve-and-execute');
      if (res.data != null && res.data['certificateNumber'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erasure completed. Certificate: ${res.data['certificateNumber']}')),
        );
      }
      _loadGovernanceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _resolveGrievanceDialog(dynamic id) {
    final remarksCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Grievance Ticket'),
        content: TextField(
          controller: remarksCtrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Resolution Findings & Actions', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().dio.post('/api/v1/admin/privacy/grievances/$id/resolve', data: {
                  'findings': remarksCtrl.text.trim(),
                });
                _loadGovernanceData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );
  }

  void _showLogBreachDialog() {
    String severity = 'HIGH';
    final causeCtrl = TextEditingController();
    final impactCtrl = TextEditingController();
    final affectedCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Log Data Breach Incident (DPDP Sec 8(6))'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(labelText: 'Severity Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('LOW — Minimal internal exposure')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM — Moderate exposure, contained')),
                    DropdownMenuItem(value: 'HIGH', child: Text('HIGH — Personal identifiers exposed')),
                    DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL — Sensitive credentials / financial data')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => severity = val);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: causeCtrl, decoration: const InputDecoration(labelText: 'Root Cause', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: impactCtrl, decoration: const InputDecoration(labelText: 'Impact Assessment', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: affectedCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Estimated Principals Affected', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await ApiService().dio.post('/api/v1/admin/privacy/breaches', data: {
                    'severity': severity,
                    'rootCause': causeCtrl.text.trim(),
                    'impactAssessment': impactCtrl.text.trim(),
                    'numberAffected': int.tryParse(affectedCtrl.text.trim()) ?? 1,
                  });
                  _loadGovernanceData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
              child: const Text('Register Incident'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dispatchDpbiNotification(dynamic id) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispatching statutory DPBI & principal notices...')));
      await ApiService().dio.post('/api/v1/admin/privacy/breaches/$id/notify-dpbi');
      _loadGovernanceData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notices dispatched. Status updated to NOTIFIED.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _triggerRetentionExecution() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Triggering automated data retention engine...')));
      final res = await ApiService().dio.post('/api/v1/admin/privacy/trigger-retention');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Retention cycle executed. Records purged: ${res.data['purgedCount'] ?? 0}')),
      );
      _loadGovernanceData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
