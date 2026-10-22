import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../services/web_file_picker.dart';
import '../../theme/app_colors.dart';

class PrivacyDashboardWidget extends StatefulWidget {
  const PrivacyDashboardWidget({super.key});

  @override
  State<PrivacyDashboardWidget> createState() => _PrivacyDashboardWidgetState();
}

class _PrivacyDashboardWidgetState extends State<PrivacyDashboardWidget> {
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Data cache
  Map<String, dynamic>? _profileSummary;
  List<dynamic> _consentHistory = [];
  List<dynamic> _correctionRequests = [];
  List<dynamic> _erasureRequests = [];
  List<dynamic> _nominees = [];
  List<dynamic> _grievances = [];

  final List<String> _tabs = [
    'Personal Data Summary',
    'My Consents',
    'Download My Data',
    'Correction Requests',
    'Erasure Requests',
    'Nominee Management',
    'Privacy Complaints',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrivacyData();
  }

  Future<void> _loadPrivacyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiService().dio;

      // 1. Profile Summary
      final summaryRes = await dio.get('/api/v1/privacy/profile-summary');
      if (summaryRes.statusCode == 200 && summaryRes.data != null) {
        _profileSummary = Map<String, dynamic>.from(summaryRes.data);
      }

      // 2. Consent History
      final consentRes = await dio.get('/api/v1/privacy/consent-history');
      if (consentRes.statusCode == 200 && consentRes.data is List) {
        _consentHistory = List<dynamic>.from(consentRes.data);
      }

      // 3. Correction Requests
      final corrRes = await dio.get('/api/v1/privacy/correction-requests');
      if (corrRes.statusCode == 200 && corrRes.data is List) {
        _correctionRequests = List<dynamic>.from(corrRes.data);
      }

      // 4. Erasure Requests
      final erasureRes = await dio.get('/api/v1/privacy/erasure-requests');
      if (erasureRes.statusCode == 200 && erasureRes.data is List) {
        _erasureRequests = List<dynamic>.from(erasureRes.data);
      }

      // 5. Nominees
      final nomineeRes = await dio.get('/api/v1/privacy/nominees');
      if (nomineeRes.statusCode == 200 && nomineeRes.data is List) {
        _nominees = List<dynamic>.from(nomineeRes.data);
      }

      // 6. Grievances
      final grievanceRes = await dio.get('/api/v1/privacy/grievances');
      if (grievanceRes.statusCode == 200 && grievanceRes.data is List) {
        _grievances = List<dynamic>.from(grievanceRes.data);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load privacy details. Please check connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildTabBar(),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState()
                    : _buildActiveTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
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
            child: const Icon(Icons.shield_outlined, color: Color(0xFF005C5C), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Privacy & My Data',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: Text(
                        'DPDP Act 2023 Compliant',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.successAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Exercise your statutory rights under Digital Personal Data Protection Act, 2023 (Sections 11, 12, 13 & 14).',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _loadPrivacyData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.slate,
              side: const BorderSide(color: AppColors.hairlineStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedTabIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF005C5C) : AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF005C5C) : AppColors.hairline,
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.slate,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.brandRedDark),
          const SizedBox(height: 12),
          Text(_errorMessage!, style: GoogleFonts.inter(color: AppColors.brandRedDark)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPrivacyData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildProfileSummaryTab();
      case 1:
        return _buildConsentHistoryTab();
      case 2:
        return _buildDownloadMyDataTab();
      case 3:
        return _buildCorrectionRequestsTab();
      case 4:
        return _buildErasureRequestsTab();
      case 5:
        return _buildNomineeManagementTab();
      case 6:
        return _buildPrivacyComplaintsTab();
      default:
        return _buildProfileSummaryTab();
    }
  }

  // ─── TAB 1: PERSONAL DATA SUMMARY ───────────────────────────────────────────
  Widget _buildProfileSummaryTab() {
    final s = _profileSummary ?? {};
    final processingPurposes = s['processingPurposes'] as List<dynamic>? ?? [];
    final thirdPartyAccess = s['thirdPartiesWithAccess'] as List<dynamic>? ?? [];

    return ListView(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: _buildCard(
                title: 'Personal Identifiers Collected',
                icon: Icons.person_outline,
                child: Column(
                  children: [
                    _buildDataRow('Full Name', s['name']?.toString() ?? '—'),
                    _buildDataRow('Primary Email', s['email']?.toString() ?? '—'),
                    _buildDataRow('Mobile Number', s['mobile']?.toString() ?? '—'),
                    _buildDataRow('Registered Address', s['address']?.toString() ?? 'Not recorded'),
                    _buildDataRow('Age Classification', s['ageClassification']?.toString() ?? 'ADULT_18_PLUS'),
                    _buildDataRow('Active Valuation Orders', '${s['activeOrdersCount'] ?? 0} orders'),
                    _buildDataRow('Archived Orders', '${s['archivedOrdersCount'] ?? 0} orders'),
                    _buildDataRow('Uploaded Documents', '${s['uploadedDocumentsCount'] ?? 0} files'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 4,
              child: _buildCard(
                title: 'Data Retention & Safeguards',
                icon: Icons.access_time_rounded,
                child: Column(
                  children: [
                    _buildDataRow('Retention Category', s['dataRetentionStatus']?.toString() ?? 'ACTIVE_VALUATION_HOLD'),
                    _buildDataRow('Retention Obligation', '8 Years (Tax/IT Act & Valuation Standard)'),
                    _buildDataRow('Encryption Standard', 'AES-256-GCM (At Rest) • TLS 1.3 (Transit)'),
                    _buildDataRow('Statutory Notice', s['activeNoticeVersion']?.toString() ?? 'DPDP-NOTICE-V1.0'),
                    _buildDataRow('Consent Given', (s['consentStatus'] == true) ? 'YES (Valid)' : 'NOT GIVEN'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DPDP Sec 11 Right to Information: Data is retained strictly during the currency of your valuation mandate and statutory archive duration.',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCard(
          title: 'Purpose of Processing & Disclosures',
          icon: Icons.policy_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Specified Legal Purposes for Processing:',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: processingPurposes.map((p) => Chip(
                  label: Text(p.toString(), style: GoogleFonts.inter(fontSize: 11)),
                  backgroundColor: AppColors.surfaceSoft,
                  side: const BorderSide(color: AppColors.hairline),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Authorized Third Parties with Access (DPDP Sec 8(2)):',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: thirdPartyAccess.map((t) => Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF005C5C)),
                  label: Text(t.toString(), style: GoogleFonts.inter(fontSize: 11)),
                  backgroundColor: const Color(0xFFF0FDFA),
                  side: const BorderSide(color: Color(0xFF99F6E4)),
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TAB 2: MY CONSENTS ─────────────────────────────────────────────────────
  Widget _buildConsentHistoryTab() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              const Icon(Icons.history_edu_outlined, color: Color(0xFF005C5C), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statutory Consent Ledger (DPDP Sec 6)',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
                    ),
                    Text(
                      'Immutable audit trail of your affirmative declarations and withdrawal requests.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_consentHistory.isEmpty)
          _buildEmptyState('No consent ledger records found.')
        else
          ..._consentHistory.map((c) {
            final isWithdrawn = c['withdrawn'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isWithdrawn ? AppColors.errorBorder : AppColors.hairline),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isWithdrawn ? AppColors.brandRed : AppColors.successBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isWithdrawn ? 'WITHDRAWN' : 'ACTIVE CONSENT',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isWithdrawn ? AppColors.brandRedDark : AppColors.successAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              c['consentType']?.toString() ?? 'GENERAL',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                            ),
                          ],
                        ),
                        if (!isWithdrawn)
                          TextButton.icon(
                            onPressed: () => _showWithdrawConsentDialog(c['consentType']?.toString() ?? ''),
                            icon: const Icon(Icons.remove_circle_outline, size: 14, color: AppColors.brandRedDark),
                            label: Text(
                              'Withdraw Consent',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandRedDark),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildMetaText('Notice Version', c['noticeVersion']?.toString() ?? '—')),
                        Expanded(child: _buildMetaText('Terms Version', c['termsVersion']?.toString() ?? '—')),
                        Expanded(child: _buildMetaText('Timestamp', c['createdAt']?.toString() ?? '—')),
                        Expanded(child: _buildMetaText('IP Address', c['ipAddress']?.toString() ?? '—')),
                      ],
                    ),
                    if (isWithdrawn && c['withdrawnAt'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Withdrawn on: ${c['withdrawnAt']} • Reason: ${c['withdrawalReason'] ?? 'Voluntary'}',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.brandRedDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ─── TAB 3: DOWNLOAD MY DATA ────────────────────────────────────────────────
  Widget _buildDownloadMyDataTab() {
    return ListView(
      children: [
        _buildCard(
          title: 'Section 11(1) — Data Portability & Archive Export',
          icon: Icons.download_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Generate an authenticated, cryptographically signed export of all personal data held under your account.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The generated package (privacy_export.zip) includes:',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildCheckItem('privacy_export.json — Structured profile, order history, leads & consents'),
                    _buildCheckItem('SHA-256 Digital Verification Signature for tamper evidence'),
                    _buildCheckItem('Uploaded files metadata & download history'),
                    _buildCheckItem('Data Principal Rights statement and legal retention schedule'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _downloadMyDataPackage,
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Download My Data (ZIP Package)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005C5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── TAB 4: CORRECTION REQUESTS ─────────────────────────────────────────────
  Widget _buildCorrectionRequestsTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Correction & Rectification Requests',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('DPDP Act Section 12 — Right to correction and updating of inaccurate personal data.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showNewCorrectionDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Correction Request'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_correctionRequests.isEmpty)
          _buildEmptyState('No correction requests submitted yet.')
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Field: ${c['fieldName']}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                      _buildStatusBadge(c['status']?.toString() ?? 'SUBMITTED'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Existing Value: ${c['existingValue'] ?? '—'}', style: GoogleFonts.inter(fontSize: 12)),
                  Text('Requested Value: ${c['requestedValue'] ?? '—'}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF005C5C))),
                  Text('Reason: ${c['reason'] ?? '—'}', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                  const SizedBox(height: 6),
                  Text('Submitted: ${c['createdAt'] ?? '—'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.steel)),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 5: ERASURE REQUESTS ────────────────────────────────────────────────
  Widget _buildErasureRequestsTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Erasure Requests (Right to be Forgotten)',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('DPDP Act Section 12 — Statutory deletion and secure erasure of personal data.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showNewErasureDialog,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Request Erasure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandRedDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Statutory Notice: Completed valuation orders, registered valuation reports, and tax invoices are subject to mandatory legal hold under the Companies Act and IT Act (8-year retention). Erasure requests will delete all eligible personal identifiers while retaining statutory records.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF78350F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_erasureRequests.isEmpty)
          _buildEmptyState('No erasure requests filed.')
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Request #${e['id']}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                      _buildStatusBadge(e['status']?.toString() ?? 'SUBMITTED'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Reason: ${e['reason'] ?? 'Voluntary deletion request'}', style: GoogleFonts.inter(fontSize: 12)),
                  Text('Legal Hold Status: ${(e['legalHoldFlag'] == true) ? 'ACTIVE LEGAL HOLD ENFORCED' : 'NO HOLD'}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: (e['legalHoldFlag'] == true) ? AppColors.brandRedDark : AppColors.successAccent)),
                  const SizedBox(height: 6),
                  Text('Submitted: ${e['createdAt'] ?? '—'}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.steel)),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 6: NOMINEE MANAGEMENT ──────────────────────────────────────────────
  Widget _buildNomineeManagementTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Manage Nominees (DPDP Act Section 14)',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('Nominate a trusted individual to exercise your privacy rights in the event of death or incapacity.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddNomineeDialog,
              icon: const Icon(Icons.person_add_alt, size: 16),
              label: const Text('Add Nominee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_nominees.isEmpty)
          _buildEmptyState('No nominees nominated yet. Under DPDP Sec 14, you may designate a nominee at any time.')
        else
          ..._nominees.map((n) => Card(
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF005C5C)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['nomineeName']?.toString() ?? '—',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                        Text('Relationship: ${n['relationship'] ?? '—'} • Mobile: ${n['mobile'] ?? '—'}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                        Text('Email: ${n['email'] ?? '—'} • Address: ${n['address'] ?? '—'}',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.brandRedDark),
                    onPressed: () => _deleteNominee(n['id']),
                    tooltip: 'Revoke Nomination',
                  ),
                ],
              ),
            ),
          )),
      ],
    );
  }

  // ─── TAB 7: PRIVACY COMPLAINTS & GRIEVANCE ──────────────────────────────────
  Widget _buildPrivacyComplaintsTab() {
    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy Complaints & Grievance Redressal',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text('DPDP Act Section 13 — Statutory Grievance Redressal with 7-Day Resolution SLA.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showNewGrievanceDialog,
              icon: const Icon(Icons.campaign_outlined, size: 16),
              label: const Text('Lodge Complaint'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_grievances.isEmpty)
          _buildEmptyState('No complaints lodged.')
        else
          ..._grievances.map((g) => Card(
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
                      Text('Ticket: ${g['ticketNumber']}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                      _buildStatusBadge(g['status']?.toString() ?? 'SUBMITTED'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Category: ${g['category']}',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF005C5C))),
                  Text('Description: ${g['description']}', style: GoogleFonts.inter(fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('SLA Due: ${g['slaDueDate'] ?? '7 Days'}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
                      if (g['status'] != 'RESOLVED' && g['status'] != 'CLOSED')
                        TextButton(
                          onPressed: () => _escalateGrievance(g['id']),
                          child: const Text('Escalate Ticket'),
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

  // ─── HELPERS & DIALOGS ──────────────────────────────────────────────────────

  Widget _buildCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x040F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF005C5C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
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

  Widget _buildMetaText(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.steel)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
      ],
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF005C5C)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.ink))),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.surfaceSoft;
    Color fg = AppColors.slate;

    switch (status) {
      case 'APPROVED':
      case 'RESOLVED':
      case 'COMPLETED':
        bg = AppColors.successBg;
        fg = AppColors.successAccent;
        break;
      case 'REJECTED':
      case 'CLOSED':
        bg = AppColors.brandRed;
        fg = AppColors.brandRedDark;
        break;
      case 'UNDER_REVIEW':
      case 'LEGAL_REVIEW':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
        break;
      case 'SUBMITTED':
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

  Widget _buildEmptyState(String text) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(text, style: GoogleFonts.inter(fontSize: 13, color: AppColors.steel)),
    );
  }

  // ─── ACTION IMPLEMENTATIONS ─────────────────────────────────────────────────

  Future<void> _downloadMyDataPackage() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing authenticated ZIP export package...')),
      );

      final dio = ApiService().dio;
      final res = await dio.get<List<int>>(
        '/api/v1/privacy/export',
        options: Options(responseType: ResponseType.bytes),
      );

      if (res.data != null) {
        triggerBrowserDownload(res.data!, 'privacy_export.zip', 'application/zip');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data package downloaded successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  void _showWithdrawConsentDialog(String consentType) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Withdraw Consent ($consentType)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Under DPDP Act Sec 6(4), you may withdraw statutory consent at any time. Processing carried out prior to withdrawal remains lawful.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason for Withdrawal (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().dio.post('/api/v1/privacy/withdraw-consent', data: {
                  'consentType': consentType,
                  'reason': reasonCtrl.text.trim(),
                });
                _loadPrivacyData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
            child: const Text('Confirm Withdrawal'),
          ),
        ],
      ),
    );
  }

  void _showNewCorrectionDialog() {
    final fieldCtrl = TextEditingController();
    final existingCtrl = TextEditingController();
    final requestedCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Correction Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fieldCtrl,
                decoration: const InputDecoration(labelText: 'Field to Correct (e.g. Email, Mobile, Address)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: existingCtrl,
                decoration: const InputDecoration(labelText: 'Existing Value', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: requestedCtrl,
                decoration: const InputDecoration(labelText: 'Requested Value', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: 'Reason / Documentation', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (fieldCtrl.text.trim().isEmpty || requestedCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService().dio.post('/api/v1/privacy/correction-request', data: {
                  'fieldName': fieldCtrl.text.trim(),
                  'existingValue': existingCtrl.text.trim(),
                  'requestedValue': requestedCtrl.text.trim(),
                  'reason': reasonCtrl.text.trim(),
                });
                _loadPrivacyData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  void _showNewErasureDialog() {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Erasure Request (Sec 12)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Request permanent erasure of your personal data. Eligible records will be securely purged subject to mandatory statutory tax and valuation retention hold periods.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Reason for Erasure', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService().dio.post('/api/v1/privacy/erasure-request', data: {
                  'reason': reasonCtrl.text.trim(),
                });
                _loadPrivacyData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandRedDark, foregroundColor: Colors.white),
            child: const Text('Submit Erasure Request'),
          ),
        ],
      ),
    );
  }

  void _showAddNomineeDialog() {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final mobCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Designate Nominee (DPDP Sec 14)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nominee Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship (Spouse, Child, Parent, Legal Representative)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: mobCtrl, decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ApiService().dio.post('/api/v1/privacy/nominees', data: {
                  'nomineeName': nameCtrl.text.trim(),
                  'relationship': relCtrl.text.trim(),
                  'mobile': mobCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                });
                _loadPrivacyData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Save Nominee'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNominee(dynamic id) async {
    try {
      await ApiService().dio.delete('/api/v1/privacy/nominees/$id');
      _loadPrivacyData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showNewGrievanceDialog() {
    String category = 'CONSENT_VIOLATION';
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Lodge Privacy Grievance (Sec 13)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: category,
                decoration: const InputDecoration(labelText: 'Complaint Category', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'CONSENT_VIOLATION', child: Text('Consent Violation')),
                  DropdownMenuItem(value: 'DATA_ACCESS', child: Text('Data Access Denial')),
                  DropdownMenuItem(value: 'UNAUTHORIZED_PROCESSING', child: Text('Unauthorized Processing')),
                  DropdownMenuItem(value: 'CORRECTION_DELAY', child: Text('Correction Delay')),
                  DropdownMenuItem(value: 'RETENTION_BREACH', child: Text('Retention Breach')),
                  DropdownMenuItem(value: 'SECURITY_CONCERN', child: Text('Data Security / Breach Concern')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Detailed Description of Grievance', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (descCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService().dio.post('/api/v1/privacy/grievances', data: {
                    'category': category,
                    'description': descCtrl.text.trim(),
                  });
                  _loadPrivacyData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Submit Complaint'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _escalateGrievance(dynamic id) async {
    try {
      await ApiService().dio.post('/api/v1/privacy/grievances/$id/escalate');
      _loadPrivacyData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket escalated to Senior Grievance Officer.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}
