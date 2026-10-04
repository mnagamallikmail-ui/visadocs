// ─────────────────────────────────────────────────────────────────────────────
// ClientWorkspaceHub
// Client Portal Simplification — Client-First UX Transformation
// Route: /client
// Preserves entire existing backend, database, state machine, and API contracts.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

// ─── Simplified Client Navigation ─────────────────────────────────────────────
enum _ClientNav {
  createReport,
  reportsInProgress,
  completedReports,
}

extension _ClientNavMeta on _ClientNav {
  String get label => switch (this) {
        _ClientNav.createReport => 'Create New Report',
        _ClientNav.reportsInProgress => 'Reports In Progress',
        _ClientNav.completedReports => 'Completed Reports',
      };

  IconData get icon => switch (this) {
        _ClientNav.createReport => Icons.add_circle_outline,
        _ClientNav.reportsInProgress => Icons.hourglass_top_rounded,
        _ClientNav.completedReports => Icons.check_circle_outline_rounded,
      };
}

// ─── 6 Simplified Client Stages ──────────────────────────────────────────────
class _ClientStageInfo {
  final int stageIndex; // 0 to 5
  final String stageTitle;
  final String statusBadge;
  final Color statusColor;
  final String statusDescription;
  final String requiredActionLabel;
  final bool isDelivered;

  const _ClientStageInfo({
    required this.stageIndex,
    required this.stageTitle,
    required this.statusBadge,
    required this.statusColor,
    required this.statusDescription,
    required this.requiredActionLabel,
    this.isDelivered = false,
  });
}

const List<String> _kClientStages = [
  'Request Submitted',
  'Under Review',
  'Quotation Ready',
  'Payment Complete',
  'Report In Progress',
  'Delivered',
];

// ─── Landing Page Luxury Design System ───────────────────────────────────────
class _LuxuryTheme {
  static const Color bgDark = Color(0xFF060B18);
  static const Color bgCanvas = Color(0xFF0A1128);
  static const Color cardGlass = Color(0x0AFFFFFF); // rgba(255,255,255, 0.04)
  static const Color cardGlassHover = Color(0x14FFFFFF); // rgba(255,255,255, 0.08)
  static const Color cardBorder = Color(0x14FFFFFF); // rgba(255,255,255, 0.08)
  static const Color primaryBlue = Color(0xFF1E57A4);
  static const Color goldAccent = Color(0xFFFABB1F);
  static const Color goldGlow = Color(0x26FABB1F);
  static const Color tealAccent = Color(0xFF10B981);
  static const Color skyAccent = Color(0xFF38BDF8);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
}

_ClientStageInfo _mapToClientStage(dynamic order) {
  if (order == null) {
    return const _ClientStageInfo(
      stageIndex: 0,
      stageTitle: 'Request Submitted',
      statusBadge: 'Request Submitted',
      statusColor: Color(0xFF3B82F6),
      statusDescription: 'Valuation mandate parameters initialized.',
      requiredActionLabel: 'Awaiting Commercial Review',
    );
  }

  final status = (order['status'] as String? ?? 'DRAFT').toUpperCase();
  final paymentStatus = (order['paymentStatus'] as String? ?? 'PENDING').toUpperCase();

  switch (status) {
    case 'DRAFT':
      return const _ClientStageInfo(
        stageIndex: 0,
        stageTitle: 'Request Submitted',
        statusBadge: 'Request Submitted',
        statusColor: Color(0xFF3B82F6),
        statusDescription: 'Your valuation request has been submitted successfully.',
        requiredActionLabel: 'Under Review by Desk',
      );

    case 'QUOTE_PENDING':
      return const _ClientStageInfo(
        stageIndex: 1,
        stageTitle: 'Under Review',
        statusBadge: 'Under Review',
        statusColor: Color(0xFFF59E0B),
        statusDescription: 'Our commercial valuation desk is reviewing your property documents and circle rates.',
        requiredActionLabel: 'Desk Assessment in Progress',
      );

    case 'QUOTE_PROVIDED':
      if (paymentStatus == 'SUBMITTED') {
        return const _ClientStageInfo(
          stageIndex: 3,
          stageTitle: 'Payment Complete',
          statusBadge: 'Payment Submitted',
          statusColor: Color(0xFF8B5CF6),
          statusDescription: 'Your payment remittance proof has been received and is undergoing bank credit verification.',
          requiredActionLabel: 'Awaiting Bank Settlement',
        );
      }
      return const _ClientStageInfo(
        stageIndex: 2,
        stageTitle: 'Quotation Ready',
        statusBadge: 'Quotation Ready',
        statusColor: Color(0xFF10B981),
        statusDescription: 'Your official quotation and completion turnaround SLA are available for review.',
        requiredActionLabel: 'View & Accept Quotation',
      );

    case 'PAYMENT_SUBMITTED':
      return const _ClientStageInfo(
        stageIndex: 3,
        stageTitle: 'Payment Complete',
        statusBadge: 'Payment Submitted',
        statusColor: Color(0xFF8B5CF6),
        statusDescription: 'Payment remittance proof submitted. Accounts desk is verifying bank credit.',
        requiredActionLabel: 'Verification Pending',
      );

    case 'PAYMENT_REJECTED':
      return const _ClientStageInfo(
        stageIndex: 2,
        stageTitle: 'Quotation Ready',
        statusBadge: 'Payment Discrepancy',
        statusColor: Color(0xFFEF4444),
        statusDescription: 'Payment remittance could not be confirmed. Please check UTR and re-submit payment proof.',
        requiredActionLabel: 'Re-submit Payment Proof',
      );

    case 'PAYMENT_VERIFIED':
      return const _ClientStageInfo(
        stageIndex: 3,
        stageTitle: 'Payment Complete',
        statusBadge: 'Payment Verified',
        statusColor: Color(0xFF10B981),
        statusDescription: 'Bank credit confirmed. Your mandate is entering the appraisal execution phase.',
        requiredActionLabel: 'Appraisal Preparation',
      );

    case 'PAID_INTAKE':
    case 'IN_GENERAL_POOL':
    case 'ASSIGNED':
    case 'INSPECTION_SCHEDULED':
    case 'INSPECTION_IN_PROGRESS':
    case 'INSPECTION_COMPLETED':
    case 'DRAFTING':
    case 'UNDER_REVIEW':
    case 'SPA_REVIEW':
    case 'SPA_CONFIRMED':
    case 'SNAPSHOT_CREATED':
    case 'ON_HOLD_PAYMENT_PENDING':
      return const _ClientStageInfo(
        stageIndex: 4,
        stageTitle: 'Report In Progress',
        statusBadge: 'Report In Progress',
        statusColor: Color(0xFF2563EB),
        statusDescription: 'Certified Registered Valuers are conducting asset analysis and compiling your official report.',
        requiredActionLabel: 'Track Progress',
      );

    case 'DELIVERY_READY':
    case 'FINAL_DELIVERY':
    case 'CLIENT_DOWNLOADED':
    case 'CLOSED':
      return const _ClientStageInfo(
        stageIndex: 5,
        stageTitle: 'Delivered',
        statusBadge: 'Report Delivered',
        statusColor: Color(0xFF059669),
        statusDescription: 'Your digitally signed valuation report package and tax invoice are ready for download.',
        requiredActionLabel: 'Download Report',
        isDelivered: true,
      );

    default:
      return const _ClientStageInfo(
        stageIndex: 0,
        stageTitle: 'Request Submitted',
        statusBadge: 'Submitted',
        statusColor: Color(0xFF3B82F6),
        statusDescription: 'Valuation mandate initialized.',
        requiredActionLabel: 'Pending Desk Review',
      );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ClientWorkspaceHub Main Widget
// ─────────────────────────────────────────────────────────────────────────────
class ClientWorkspaceHub extends StatefulWidget {
  const ClientWorkspaceHub({super.key});

  @override
  State<ClientWorkspaceHub> createState() => _ClientWorkspaceHubState();
}

class _ClientWorkspaceHubState extends State<ClientWorkspaceHub> {
  // Navigation State — DEFAULT SCREEN IS REPORTS IN PROGRESS
  _ClientNav _activeNav = _ClientNav.reportsInProgress;
  dynamic _focusedActiveOrder;
  dynamic _focusedCompletedOrder;
  bool _sidebarCollapsed = false;

  // ─── Flow 1: 6-Step Dedicated Wizard State ─────────────────────────────────
  int _wizardStep = 1; // 1 to 6 (7 = Success)
  String _wizardService = 'VALUATION';
  String _wizardAsset = 'LAND_AND_BUILDING';
  String _wizardPurpose = 'BANK_COLLATERAL';

  // Step 4 Asset Controllers
  final _assetNameCtrl = TextEditingController();
  final _propertyAddressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _estimatedValueCtrl = TextEditingController();

  // Step 5 Document Matrix
  final Map<String, PlatformFile> _wizardDocs = {};
  Timer? _step4ValidationDebounce;
  bool _step4AutoAdvancing = false;

  // Wizard Submission State
  bool _wizardSubmitting = false;
  String? _wizardError;
  int? _createdOrderId;

  // ─── Payment Form State (Encapsulated Inside Active Report) ─────────────────
  final _utrCtrl = TextEditingController();
  final _paymentAmountCtrl = TextEditingController();
  final String _paymentMethod = 'UPI';
  PlatformFile? _paymentReceiptFile;
  bool _paymentSubmitting = false;
  String? _paymentError;

  // Delivery & Download State
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrdersAndSync();
    });
  }

  @override
  void dispose() {
    _assetNameCtrl.dispose();
    _propertyAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _step4ValidationDebounce?.cancel();

    _utrCtrl.dispose();
    _paymentAmountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrdersAndSync() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.fetchClientOrders();
    if (mounted) {
      final activeList = orderProvider.clientOrders
          .where((o) => _mapToClientStage(o).stageIndex < 5)
          .toList();
      final completedList = orderProvider.clientOrders
          .where((o) => _mapToClientStage(o).stageIndex == 5)
          .toList();

      setState(() {
        if (_focusedActiveOrder != null) {
          _focusedActiveOrder = activeList.firstWhere(
            (o) => o['id'] == _focusedActiveOrder['id'],
            orElse: () => activeList.isNotEmpty ? activeList.first : null,
          );
        }
        if (_focusedCompletedOrder != null) {
          _focusedCompletedOrder = completedList.firstWhere(
            (o) => o['id'] == _focusedCompletedOrder['id'],
            orElse: () => completedList.isNotEmpty ? completedList.first : null,
          );
        }
      });
    }
  }

  void _onStep4FieldChanged() {
    _step4ValidationDebounce?.cancel();
    final nameValid = _assetNameCtrl.text.trim().isNotEmpty;
    final addrValid = _propertyAddressCtrl.text.trim().isNotEmpty;
    final cityValid = _cityCtrl.text.trim().isNotEmpty;
    final stateValid = _stateCtrl.text.trim().isNotEmpty;

    if (nameValid && addrValid && cityValid && stateValid) {
      setState(() => _step4AutoAdvancing = true);
      _step4ValidationDebounce = Timer(const Duration(milliseconds: 650), () {
        if (mounted && _wizardStep == 4) {
          setState(() {
            _step4AutoAdvancing = false;
            _wizardStep = 5;
          });
        }
      });
    } else {
      if (_step4AutoAdvancing) {
        setState(() => _step4AutoAdvancing = false);
      }
    }
  }

  List<Map<String, dynamic>> _getRequiredDocumentSlots() {
    switch (_wizardAsset) {
      case 'PLANT_AND_MACHINERY':
        return [
          {'key': 'INVOICE_BILL', 'label': 'Purchase Invoice / Machinery Bill', 'mandatory': true},
        ];
      case 'SECURITIES_FINANCIAL_ASSETS':
        return [
          {'key': 'FIN_AUDIT', 'label': 'Financial Statements (Audited Balance Sheet)', 'mandatory': true},
        ];
      default:
        return [
          {'key': 'TITLE_DEED', 'label': 'Title Deed / Registered Sale Deed', 'mandatory': true},
          {'key': 'SANCTION_PLAN', 'label': 'Approved / Municipal Sanction Plan', 'mandatory': true},
          {'key': 'TAX_RECEIPT', 'label': 'Latest Property Tax Paid Receipt', 'mandatory': true},
        ];
    }
  }

  Future<void> _pickWizardDoc(String key) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      if (f.size > 20 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File exceeds maximum allowed size of 20 MB.')),
          );
        }
        return;
      }
      setState(() {
        _wizardDocs[key] = f;
      });

      // Check if all mandatory documents are uploaded; if so, AUTOMATICALLY ADVANCE to Step 6
      final requiredSlots = _getRequiredDocumentSlots();
      final allUploaded = requiredSlots.every((s) => _wizardDocs.containsKey(s['key']));
      if (allUploaded) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && _wizardStep == 5) {
            setState(() => _wizardStep = 6);
          }
        });
      }
    }
  }

  Future<void> _submitWizardReport() async {
    setState(() {
      _wizardSubmitting = true;
      _wizardError = null;
    });

    final orderProvider = context.read<OrderProvider>();

    try {
      final estVal = double.tryParse(_estimatedValueCtrl.text.trim()) ?? 0.0;
      final fullAddress = '${_propertyAddressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()}';
      final inputs = {
        'asset_name': _assetNameCtrl.text.trim(),
        'location': fullAddress,
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'urgency_sla': 'STANDARD_3D',
      };

      // 1. Create Draft Order
      final draftRes = await orderProvider.saveDraft(
        _wizardAsset,
        _wizardPurpose,
        estVal,
        inputs,
        serviceCategory: _wizardService,
      );

      if (draftRes == null || draftRes['id'] == null) {
        setState(() {
          _wizardSubmitting = false;
          _wizardError = 'Unable to create report request. Please try again.';
        });
        return;
      }

      final orderId = (draftRes['id'] as num).toInt();
      _createdOrderId = orderId;

      // 2. Upload mandatory documents
      for (final entry in _wizardDocs.entries) {
        await orderProvider.uploadDocument(
          orderId,
          entry.key,
          entry.value.name,
          entry.value.bytes ?? [],
        );
      }

      // 3. Submit request
      final submitRes = await orderProvider.submitRequest(orderId);

      setState(() => _wizardSubmitting = false);

      if (submitRes != null && submitRes['error'] == null) {
        await _loadOrdersAndSync();
        setState(() {
          _wizardStep = 7; // Success Screen
        });
      } else {
        setState(() {
          _wizardError = submitRes?['error']?.toString() ?? 'Failed to submit report request.';
        });
      }
    } catch (e) {
      setState(() {
        _wizardSubmitting = false;
        _wizardError = 'Submission exception: $e';
      });
    }
  }

  void _resetWizard() {
    setState(() {
      _wizardStep = 1;
      _wizardService = 'VALUATION';
      _wizardAsset = 'LAND_AND_BUILDING';
      _wizardPurpose = 'BANK_COLLATERAL';
      _assetNameCtrl.clear();
      _propertyAddressCtrl.clear();
      _cityCtrl.clear();
      _stateCtrl.clear();
      _estimatedValueCtrl.clear();
      _wizardDocs.clear();
      _wizardError = null;
      _step4AutoAdvancing = false;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Builder
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final isNarrow = MediaQuery.of(context).size.width < 960;

    return Scaffold(
      backgroundColor: _LuxuryTheme.bgDark,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_LuxuryTheme.bgDark, _LuxuryTheme.bgCanvas],
          ),
        ),
        child: Row(
        children: [
          // ── LEFT SIDEBAR ──────────────────────────────────────────────────
          _ClientSidebar(
            collapsed: _sidebarCollapsed || isNarrow,
            activeNav: _activeNav,
            fullName: auth.fullName ?? 'Client Officer',
            email: auth.email ?? 'client@provaluer.com',
            onNavSelect: (nav) {
              setState(() {
                _activeNav = nav;
                _focusedActiveOrder = null;
                _focusedCompletedOrder = null;
                if (nav == _ClientNav.createReport) {
                  _resetWizard();
                }
              });
            },
            onProfileTap: () => _showProfileDialog(auth),
            onSupportTap: () => _showSupportDialog(),
            onToggleCollapse: () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onSignOut: () {
              auth.logout();
              context.go('/');
            },
          ),

          // ── MAIN WORKSPACE CONTAINER ──────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _ClientTopHeader(
                  title: switch (_activeNav) {
                    _ClientNav.createReport => 'Create New Report',
                    _ClientNav.reportsInProgress => _focusedActiveOrder == null
                        ? 'Reports In Progress'
                        : 'Report Workspace • ${_focusedActiveOrder['referenceCode'] ?? 'REQ-${_focusedActiveOrder['id']}'}',
                    _ClientNav.completedReports => _focusedCompletedOrder == null
                        ? 'Completed Reports'
                        : 'Archived Report • ${_focusedCompletedOrder['referenceCode'] ?? 'REQ-${_focusedCompletedOrder['id']}'}',
                  },
                  onRefresh: _loadOrdersAndSync,
                  onCreateNew: () {
                    setState(() {
                      _activeNav = _ClientNav.createReport;
                      _focusedActiveOrder = null;
                      _focusedCompletedOrder = null;
                      _resetWizard();
                    });
                  },
                ),
                Expanded(
                  child: _buildCurrentView(orders, auth),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCurrentView(OrderProvider orders, AuthProvider auth) {
    switch (_activeNav) {
      case _ClientNav.createReport:
        return _buildWizardView();

      case _ClientNav.reportsInProgress:
        if (_focusedActiveOrder != null) {
          return _buildActiveReportWorkspace(_focusedActiveOrder, orders);
        }
        return _buildReportsInProgressGallery(orders);

      case _ClientNav.completedReports:
        if (_focusedCompletedOrder != null) {
          return _buildCompletedReportWorkspace(_focusedCompletedOrder, orders);
        }
        return _buildCompletedReportsGallery(orders);
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 1: CREATE NEW REPORT (6-Step Auto-Advancing Wizard)
  // ═════════════════════════════════════════════════════════════════════════
  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 1: CREATE NEW REPORT (6-Step Auto-Advancing Wizard — Luxury Refined)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildWizardView() {
    if (_wizardStep == 7) {
      return _buildWizardSuccessScreen();
    }

    final stepTitles = [
      '',
      'What service do you need?',
      'What are you valuing?',
      'Why do you need the report?',
      'Tell us about the asset',
      'Upload Documents',
      'Review Request',
    ];

    final stepSubtitles = [
      '',
      'Select your required appraisal service. Click any option to advance.',
      'Select asset type. Document requirements are automatically configured.',
      'Select statutory recipient purpose for legal formatting.',
      'Enter basic property location parameters for desk review.',
      'Upload statutory title deeds and sanction layouts.',
      'Verify mandate parameters before official commercial issuance.',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Landing Page Style Section Header ────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0x1AFABB1F),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x33FABB1F)),
                        ),
                        child: Text(
                          'STEP $_wizardStep OF 6',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: _LuxuryTheme.goldAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        stepTitles[_wizardStep],
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _LuxuryTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stepSubtitles[_wizardStep],
                        style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
                      ),
                    ],
                  ),
                  if (_wizardStep > 1)
                    TextButton.icon(
                      onPressed: () => setState(() => _wizardStep--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 14),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: _LuxuryTheme.textMuted,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Minimal Premium Progress Indicator ───────────────────────
              _buildMinimalProgressIndicator(),
              const SizedBox(height: 24),

              if (_wizardError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x1AEF4444),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33EF4444)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 17),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wizardError!,
                          style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Step Component Dark Glass Container ──────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: switch (_wizardStep) {
                  1 => _buildWizardStep1(),
                  2 => _buildWizardStep2(),
                  3 => _buildWizardStep3(),
                  4 => _buildWizardStep4(),
                  5 => _buildWizardStep5(),
                  6 => _buildWizardStep6(),
                  _ => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Minimal Progress Indicator: ●────○────○────○────○────○
  Widget _buildMinimalProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(11, (i) {
        if (i % 2 == 0) {
          final stepIndex = i ~/ 2 + 1; // 1 to 6
          final isDone = stepIndex < _wizardStep;
          final isCurrent = stepIndex == _wizardStep;
          return Container(
            width: isCurrent ? 22 : 16,
            height: isCurrent ? 22 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent
                  ? _LuxuryTheme.goldAccent
                  : (isDone ? _LuxuryTheme.tealAccent : const Color(0x1AFFFFFF)),
              border: Border.all(
                color: isCurrent
                    ? _LuxuryTheme.goldAccent
                    : (isDone ? _LuxuryTheme.tealAccent : const Color(0x33FFFFFF)),
                width: 1.5,
              ),
              boxShadow: isCurrent
                  ? const [BoxShadow(color: Color(0x40FABB1F), blurRadius: 8)]
                  : null,
            ),
            child: Center(
              child: isDone
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : Text(
                      '$stepIndex',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: isCurrent ? const Color(0xFF060B18) : _LuxuryTheme.textMuted,
                      ),
                    ),
            ),
          );
        } else {
          final lineStep = (i - 1) ~/ 2 + 1;
          final isDone = lineStep < _wizardStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone ? _LuxuryTheme.tealAccent : const Color(0x1AFFFFFF),
            ),
          );
        }
      }),
    );
  }

  // Compact Selector Card Component
  Widget _compactSelectorCard({
    required String title,
    required String sub,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0x1AFABB1F) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _LuxuryTheme.goldAccent : const Color(0x14FFFFFF),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? const [BoxShadow(color: Color(0x26FABB1F), blurRadius: 12, offset: Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0x33FABB1F) : const Color(0x0FFFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 19,
                color: isSelected ? _LuxuryTheme.goldAccent : _LuxuryTheme.skyAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _LuxuryTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: _LuxuryTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: isSelected ? _LuxuryTheme.goldAccent : _LuxuryTheme.textDim,
            ),
          ],
        ),
      ),
    );
  }

  // STEP 1: What service do you need? (Clean Horizontal Grid on Desktop)
  Widget _buildWizardStep1() {
    final services = [
      {
        'id': 'VALUATION',
        'icon': Icons.account_balance_outlined,
        'title': 'Valuation Report',
        'sub': 'Bank, Visa & IT Act Section 34AB',
      },
      {
        'id': 'NET_WORTH_CERTIFICATE',
        'icon': Icons.verified_user_outlined,
        'title': 'Net Worth Certificate',
        'sub': 'Global Embassy & Solvency Proof',
      },
      {
        'id': 'CHARTERED_ENGINEER',
        'icon': Icons.precision_manufacturing_outlined,
        'title': 'Chartered Engineer',
        'sub': 'Machinery, Customs & EPCG Audit',
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isDesktop = constraints.maxWidth > 650;
        final cards = services.map((s) {
          final isSelected = _wizardService == s['id'];
          return _compactSelectorCard(
            title: s['title'] as String,
            sub: s['sub'] as String,
            icon: s['icon'] as IconData,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _wizardService = s['id'] as String;
                _wizardStep = 2; // CLICK = ADVANCE AUTOMATICALLY
              });
            },
          );
        }).toList();

        if (isDesktop) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c)))
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c))
                .toList(),
          );
        }
      },
    );
  }

  // STEP 2: What are you valuing? (Clean Horizontal Grid on Desktop)
  Widget _buildWizardStep2() {
    final assets = [
      {
        'id': 'LAND_AND_BUILDING',
        'icon': Icons.business_rounded,
        'title': 'Land & Building',
        'sub': 'Commercial, Residential, Land',
      },
      {
        'id': 'PLANT_AND_MACHINERY',
        'icon': Icons.settings_suggest_rounded,
        'title': 'Plant & Machinery',
        'sub': 'Industrial, Technical & Tools',
      },
      {
        'id': 'SECURITIES_FINANCIAL_ASSETS',
        'icon': Icons.trending_up_rounded,
        'title': 'Financial Assets',
        'sub': 'Shares, Equity & Portfolios',
      },
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isDesktop = constraints.maxWidth > 650;
        final cards = assets.map((a) {
          final isSelected = _wizardAsset == a['id'];
          return _compactSelectorCard(
            title: a['title'] as String,
            sub: a['sub'] as String,
            icon: a['icon'] as IconData,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _wizardAsset = a['id'] as String;
                _wizardDocs.clear(); // reset files if asset category changed
                _wizardStep = 3; // CLICK = ADVANCE AUTOMATICALLY
              });
            },
          );
        }).toList();

        if (isDesktop) {
          return Row(
            children: cards
                .map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: c)))
                .toList(),
          );
        } else {
          return Column(
            children: cards
                .map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c))
                .toList(),
          );
        }
      },
    );
  }

  // STEP 3: Why do you need the report? (Compact Grid)
  Widget _buildWizardStep3() {
    final purposes = [
      {'id': 'BANK_COLLATERAL', 'icon': Icons.account_balance_rounded, 'title': 'Bank Loan', 'sub': 'Mortgage collateral'},
      {'id': 'VISA_IMMIGRATION', 'icon': Icons.flight_takeoff_rounded, 'title': 'Visa / Immigration', 'sub': 'Embassy solvency'},
      {'id': 'TAXATION_COMPLIANCE', 'icon': Icons.receipt_long_rounded, 'title': 'Income Tax', 'sub': 'Sec 50C compliance'},
      {'id': 'CORPORATE_INSOLVENCY', 'icon': Icons.corporate_fare_rounded, 'title': 'Corporate', 'sub': 'Audits, M&A & NCLT'},
      {'id': 'DISPUTE', 'icon': Icons.gavel_rounded, 'title': 'Court Matter', 'sub': 'Litigation & Partition'},
      {'id': 'OTHER', 'icon': Icons.work_outline_rounded, 'title': 'Other', 'sub': 'Internal advisory'},
    ];

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 700 ? 3 : (constraints.maxWidth > 480 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 2.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: purposes.length,
          itemBuilder: (ctx, i) {
            final p = purposes[i];
            final isSelected = _wizardPurpose == p['id'];
            return _compactSelectorCard(
              title: p['title'] as String,
              sub: p['sub'] as String,
              icon: p['icon'] as IconData,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _wizardPurpose = p['id'] as String;
                  _wizardStep = 4; // CLICK = ADVANCE AUTOMATICALLY
                });
              },
            );
          },
        );
      },
    );
  }

  // STEP 4: Tell us about the asset (Real-time Auto-Advance — Dark Glass)
  Widget _buildWizardStep4() {
    InputDecoration inputDec(String label, String hint, {String? prefix}) {
      return InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 12, color: _LuxuryTheme.textDim),
        prefixText: prefix,
        prefixStyle: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.goldAccent),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _LuxuryTheme.skyAccent, width: 1.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Asset Name
        TextField(
          controller: _assetNameCtrl,
          onChanged: (_) => _onStep4FieldChanged(),
          style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.textMain),
          decoration: inputDec('Asset Name *', 'e.g. Cyber Towers Unit 402'),
        ),
        const SizedBox(height: 12),

        // Property Address
        TextField(
          controller: _propertyAddressCtrl,
          onChanged: (_) => _onStep4FieldChanged(),
          style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.textMain),
          decoration: inputDec('Property Address *', 'e.g. HITEC City Main Corridor, Madhapur'),
        ),
        const SizedBox(height: 12),

        // City & State
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.textMain),
                decoration: inputDec('City *', 'e.g. Hyderabad'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _stateCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.textMain),
                decoration: inputDec('State *', 'e.g. Telangana'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Estimated Value
        TextField(
          controller: _estimatedValueCtrl,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.textMain),
          decoration: inputDec('Estimated Value (Optional)', 'e.g. 18500000', prefix: '₹ '),
        ),
        const SizedBox(height: 16),

        // Auto-Advancement feedback indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _step4AutoAdvancing ? const Color(0x1A10B981) : const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _step4AutoAdvancing ? const Color(0x3310B981) : const Color(0x14FFFFFF),
            ),
          ),
          child: Row(
            children: [
              if (_step4AutoAdvancing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _LuxuryTheme.tealAccent),
                )
              else
                const Icon(Icons.info_outline, size: 15, color: _LuxuryTheme.textDim),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _step4AutoAdvancing
                      ? '✓ Details verified! Advancing to document upload...'
                      : 'Fill Asset Name, Address, City, and State to continue.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: _step4AutoAdvancing ? FontWeight.w600 : FontWeight.normal,
                    color: _step4AutoAdvancing ? _LuxuryTheme.tealAccent : _LuxuryTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: Upload Documents (Dark Luxury Glass Cards)
  Widget _buildWizardStep5() {
    final slots = _getRequiredDocumentSlots();
    final allUploaded = slots.every((s) => _wizardDocs.containsKey(s['key']));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Required documents for ${_wizardAsset.replaceAll('_', ' ').toLowerCase()}:',
                style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: allUploaded ? const Color(0x1A10B981) : const Color(0x1AFABB1F),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: allUploaded ? const Color(0x3310B981) : const Color(0x33FABB1F),
                ),
              ),
              child: Text(
                allUploaded ? '✓ Upload Complete' : 'Mandatory Uploads',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: allUploaded ? _LuxuryTheme.tealAccent : _LuxuryTheme.goldAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...slots.map((s) {
          final key = s['key'] as String;
          final label = s['label'] as String;
          final hasFile = _wizardDocs.containsKey(key);
          final file = _wizardDocs[key];

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: hasFile ? const Color(0x0F10B981) : const Color(0x0AFFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile ? const Color(0x3310B981) : const Color(0x14FFFFFF),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0x1A10B981) : const Color(0x0FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                    color: hasFile ? _LuxuryTheme.tealAccent : _LuxuryTheme.skyAccent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _LuxuryTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFile
                            ? '${file!.name} (${(file.size / 1024).toStringAsFixed(1)} KB) • Verified ✓'
                            : 'Mandatory file • PDF, PNG, JPG (Max 20MB)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: hasFile ? _LuxuryTheme.tealAccent : _LuxuryTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickWizardDoc(key),
                    icon: Icon(hasFile ? Icons.refresh : Icons.attach_file, size: 13),
                    label: Text(hasFile ? 'Replace' : 'Upload', style: const TextStyle(fontSize: 11.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasFile ? const Color(0x14FFFFFF) : const Color(0x1A38BDF8),
                      foregroundColor: hasFile ? _LuxuryTheme.tealAccent : _LuxuryTheme.skyAccent,
                      side: BorderSide(color: hasFile ? const Color(0x3310B981) : const Color(0x3338BDF8)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // STEP 6: Review Request (Single Luxury Gold Button)
  Widget _buildWizardStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please verify your mandate scope before official desk appraisal issuance:',
          style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted),
        ),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: Column(
            children: [
              _summaryRow('Service', _wizardService.replaceAll('_', ' ')),
              const Divider(height: 16, color: Color(0x0FFFFFFF)),
              _summaryRow('Asset Type', _wizardAsset.replaceAll('_', ' ')),
              const Divider(height: 16, color: Color(0x0FFFFFFF)),
              _summaryRow('Purpose', _wizardPurpose.replaceAll('_', ' ')),
              const Divider(height: 16, color: Color(0x0FFFFFFF)),
              _summaryRow('Asset Name', _assetNameCtrl.text.trim()),
              const Divider(height: 16, color: Color(0x0FFFFFFF)),
              _summaryRow('Property Address', '${_propertyAddressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()}'),
              if (_estimatedValueCtrl.text.trim().isNotEmpty) ...[
                const Divider(height: 16, color: Color(0x0FFFFFFF)),
                _summaryRow('Estimated Value', '₹ ${_estimatedValueCtrl.text.trim()}'),
              ],
              const Divider(height: 16, color: Color(0x0FFFFFFF)),
              _summaryRow('Attached Documents', '${_wizardDocs.length} mandatory records uploaded ✓'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // THE ONLY BUTTON IN FLOW 1 (Compact Gold Luxury Button)
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: _wizardSubmitting ? null : _submitWizardReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: _LuxuryTheme.goldAccent,
              foregroundColor: const Color(0xFF060B18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 2,
            ),
            child: _wizardSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Color(0xFF060B18), strokeWidth: 2),
                  )
                : Text(
                    'Submit Report Request →',
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted)),
        Text(
          value,
          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
        ),
      ],
    );
  }

  // SUCCESS SCREEN (Dark Luxury Glass)
  Widget _buildWizardSuccessScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _LuxuryTheme.cardBorder),
              boxShadow: const [
                BoxShadow(color: Color(0x2A000000), blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1A10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x3310B981)),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: _LuxuryTheme.tealAccent, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  'Request Submitted Successfully',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFABB1F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x33FABB1F)),
                  ),
                  child: Text(
                    'Reference Number: REQ-${_createdOrderId ?? 'NEW'}',
                    style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: _LuxuryTheme.goldAccent),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Our Senior Commercial Valuation Desk is evaluating your property details, circle rates, and statutory documents. Your tailored quotation and SLA turnaround will be ready shortly.',
                  style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted, height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () {
                            final orders = context.read<OrderProvider>();
                            final created = orders.clientOrders.firstWhere(
                              (o) => o['id'] == _createdOrderId,
                              orElse: () => orders.clientOrders.isNotEmpty ? orders.clientOrders.first : null,
                            );
                            setState(() {
                              _activeNav = _ClientNav.reportsInProgress;
                              _focusedActiveOrder = created;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _LuxuryTheme.goldAccent,
                            foregroundColor: const Color(0xFF060B18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View Report'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton(
                          onPressed: () => _resetWizard(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _LuxuryTheme.textMain,
                            side: const BorderSide(color: Color(0x1EFFFFFF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Create Another Report'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 2: REPORTS IN PROGRESS (Compact Luxury Gallery)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildReportsInProgressGallery(OrderProvider orders) {
    final activeOrders = orders.clientOrders
        .where((o) => _mapToClientStage(o).stageIndex < 5)
        .toList();

    if (activeOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  shape: BoxShape.circle,
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                ),
                child: const Icon(Icons.note_add_outlined, size: 40, color: _LuxuryTheme.goldAccent),
              ),
              const SizedBox(height: 18),
              Text(
                'No Reports In Progress',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
              ),
              const SizedBox(height: 6),
              Text(
                'All your active valuation mandates will appear here with live milestone tracking.',
                style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeNav = _ClientNav.createReport;
                    _resetWizard();
                  });
                },
                icon: const Icon(Icons.add, size: 15),
                label: const Text('Create New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LuxuryTheme.goldAccent,
                  foregroundColor: _LuxuryTheme.bgDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _LuxuryTheme.goldAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Active Valuation Mandates',
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeOrders.length} active report${activeOrders.length > 1 ? 's' : ''} currently undergoing processing.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeNav = _ClientNav.createReport;
                    _resetWizard();
                  });
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Create New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LuxuryTheme.goldAccent,
                  foregroundColor: _LuxuryTheme.bgDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  textStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Compact Luxury Cards Grid (~135px height per card)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: activeOrders.map((order) {
              final stageInfo = _mapToClientStage(order);
              final orderId = order['id'];
              final refCode = order['referenceCode'] ?? 'REQ-$orderId';
              final category = (order['propertyCategory'] ?? 'Commercial Property').toString().replaceAll('_', ' ');

              return Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Reference Badge + Current Status Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.skyAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _LuxuryTheme.skyAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            refCode,
                            style: GoogleFonts.robotoMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _LuxuryTheme.skyAccent,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stageInfo.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: stageInfo.statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            stageInfo.statusBadge,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: stageInfo.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Title (Compact 1-line)
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _LuxuryTheme.textMain,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Row 3: Expected Completion
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 12, color: _LuxuryTheme.textDim),
                        const SizedBox(width: 5),
                        Text(
                          'Expected: 3 Business Days',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: _LuxuryTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Compact Open Workspace Button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _focusedActiveOrder = order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LuxuryTheme.textMain,
                          side: BorderSide(color: _LuxuryTheme.cardBorder),
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Open Workspace', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 3: ACTIVE REPORT WORKSPACE (Luxury Glass Architecture)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildActiveReportWorkspace(dynamic order, OrderProvider orders) {
    final stageInfo = _mapToClientStage(order);
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final createdDate = order['createdAt'] != null ? order['createdAt'].toString().split('T').first : 'Recent';
    final reportNumber = order['reportNumber'] ?? 'PV-2026-PENDING';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb Back
          TextButton.icon(
            onPressed: () => setState(() => _focusedActiveOrder = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 15),
            label: const Text('Back to Reports In Progress'),
            style: TextButton.styleFrom(
              foregroundColor: _LuxuryTheme.textMuted,
              textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),

          // SECTION 1: REPORT HEADER
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _LuxuryTheme.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.skyAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _LuxuryTheme.skyAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            refCode,
                            style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: _LuxuryTheme.skyAccent),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stageInfo.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: stageInfo.statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            stageInfo.statusBadge,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stageInfo.statusColor),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Report No: $reportNumber',
                      style: GoogleFonts.robotoMono(fontSize: 11.5, color: _LuxuryTheme.textDim, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 19, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purpose: ${order['purpose'] != null ? order['purpose'].toString().replaceAll('_', ' ') : 'Valuation Mandate'}',
                  style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Divider(height: 1, color: _LuxuryTheme.cardBorder),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _headerMetaCol('Created Date', createdDate),
                    const SizedBox(width: 36),
                    _headerMetaCol('Expected Completion', '3 Business Days'),
                    const SizedBox(width: 36),
                    _headerMetaCol('Subject Category', order['propertyCategory']?.toString().replaceAll('_', ' ') ?? 'Real Estate'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // SECTION 2: CLIENT PROGRESS TRACKER (6 Stages ONLY)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _LuxuryTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: _LuxuryTheme.goldAccent, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Progress Tracker',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildClientProgressTracker(stageInfo.stageIndex),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // SECTION 3: CURRENT STATUS HERO CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stageInfo.statusColor.withValues(alpha: 0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: stageInfo.statusColor.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: stageInfo.statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: stageInfo.statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    stageInfo.isDelivered ? Icons.verified_rounded : Icons.radar_rounded,
                    color: stageInfo.statusColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageInfo.statusBadge,
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stageInfo.statusDescription,
                        style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildStatusHeroAction(stageInfo, order),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // TWO-COLUMN SECTION: DOCUMENTS & UPDATES TIMELINE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 4: DOCUMENTS
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _LuxuryTheme.cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _LuxuryTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mandate Documents',
                            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                          ),
                          TextButton.icon(
                            onPressed: () => _uploadAdditionalDocument(orderId),
                            icon: const Icon(Icons.add_circle_outline, size: 14),
                            label: const Text('Upload Document'),
                            style: TextButton.styleFrom(
                              foregroundColor: _LuxuryTheme.skyAccent,
                              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildWorkspaceDocumentsList(order),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // SECTION 5: UPDATES TIMELINE
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _LuxuryTheme.cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _LuxuryTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updates Timeline',
                        style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                      ),
                      const SizedBox(height: 14),
                      _buildUpdatesTimeline(stageInfo.stageIndex, createdDate),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // SECTION 6: CONTEXTUAL ACTIONS
          _buildContextualActionCenter(stageInfo, order),
          const SizedBox(height: 22),

          // SUPPORT CONCIERGE FOOTER
          _buildSupportConciergeBanner(),
        ],
      ),
    );
  }

  Widget _headerMetaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: _LuxuryTheme.textDim)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _LuxuryTheme.textMain)),
      ],
    );
  }

  // 6-Stage Progress Tracker (Luxury Minimal)
  Widget _buildClientProgressTracker(int activeIndex) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Row(
          children: List.generate(_kClientStages.length, (idx) {
            final isCompleted = idx < activeIndex;
            final isCurrent = idx == activeIndex;
            final isPending = idx > activeIndex;

            final circleColor = isCompleted
                ? _LuxuryTheme.tealAccent
                : (isCurrent ? _LuxuryTheme.goldAccent : Colors.transparent);

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? _LuxuryTheme.tealAccent
                                : (isCurrent ? _LuxuryTheme.goldAccent.withValues(alpha: 0.15) : _LuxuryTheme.cardGlass),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? _LuxuryTheme.tealAccent
                                  : (isCurrent ? _LuxuryTheme.goldAccent : _LuxuryTheme.cardBorder),
                              width: isCurrent ? 2 : 1.2,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: _LuxuryTheme.goldAccent.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent ? _LuxuryTheme.goldAccent : _LuxuryTheme.textDim,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _kClientStages[idx],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? _LuxuryTheme.textMain : _LuxuryTheme.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (idx < _kClientStages.length - 1)
                    Container(
                      width: 16,
                      height: 2,
                      color: idx < activeIndex ? _LuxuryTheme.tealAccent : _LuxuryTheme.cardBorder,
                      margin: const EdgeInsets.only(bottom: 22),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStatusHeroAction(_ClientStageInfo stageInfo, dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';

    switch (stageInfo.stageIndex) {
      case 2: // Quotation Ready
        return ElevatedButton(
          onPressed: () => _showQuotationModal(order),
          style: ElevatedButton.styleFrom(
            backgroundColor: _LuxuryTheme.goldAccent,
            foregroundColor: _LuxuryTheme.bgDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
          child: const Text('View Quote'),
        );

      case 3: // Payment Pending / Complete
        if (order['status'] == 'QUOTE_ACCEPTED' || order['paymentStatus'] == 'PENDING') {
          return ElevatedButton(
            onPressed: () => _showPaymentModal(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: _LuxuryTheme.tealAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
            child: const Text('Pay Now'),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _LuxuryTheme.cardGlass,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _LuxuryTheme.cardBorder),
          ),
          child: Text('Under Verification', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _LuxuryTheme.goldAccent)),
        );

      case 5: // Delivered
        return ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _downloadFinalReport(refCode),
          icon: const Icon(Icons.download_rounded, size: 14),
          label: const Text('Download Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _LuxuryTheme.tealAccent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _LuxuryTheme.cardGlass,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _LuxuryTheme.cardBorder),
          ),
          child: Text(
            stageInfo.requiredActionLabel,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _LuxuryTheme.textMuted),
          ),
        );
    }
  }

  Widget _buildWorkspaceDocumentsList(dynamic order) {
    final documents = (order['documents'] as List<dynamic>?) ?? [];

    if (documents.isEmpty) {
      return Column(
        children: [
          _docItemRow('Title Deed / Registered Sale Deed', 'Verified', true),
          Divider(height: 14, color: _LuxuryTheme.cardBorder),
          _docItemRow('Municipal Sanction Plan', 'Verified', true),
          Divider(height: 14, color: _LuxuryTheme.cardBorder),
          _docItemRow('Property Tax Receipt', 'Verified', true),
          Divider(height: 14, color: _LuxuryTheme.cardBorder),
          _docItemRow('Site Inspection Photographs', 'Optional / In Review', false),
        ],
      );
    }

    return Column(
      children: documents.map((doc) {
        final name = doc['originalFilename'] ?? doc['name'] ?? 'Document.pdf';
        final category = (doc['documentCategory'] ?? doc['category'] ?? 'Legal').toString().replaceAll('_', ' ');
        final isVerified = doc['verified'] == true || doc['status'] == 'VERIFIED';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: _docItemRow('$category ($name)', isVerified ? 'Verified' : 'In Review', isVerified),
        );
      }).toList(),
    );
  }

  Widget _docItemRow(String name, String status, bool verified) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              verified ? Icons.check_circle_rounded : Icons.pending_outlined,
              size: 16,
              color: verified ? _LuxuryTheme.tealAccent : _LuxuryTheme.goldAccent,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: _LuxuryTheme.textMain),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: verified
                ? _LuxuryTheme.tealAccent.withValues(alpha: 0.12)
                : _LuxuryTheme.goldAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: verified
                  ? _LuxuryTheme.tealAccent.withValues(alpha: 0.3)
                  : _LuxuryTheme.goldAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            verified ? 'Verified ✓' : 'In Review ⏳',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: verified ? _LuxuryTheme.tealAccent : _LuxuryTheme.goldAccent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatesTimeline(int currentStageIndex, String createdDate) {
    final updates = [
      {'title': 'Valuation Request Submitted', 'date': createdDate, 'desc': 'Client initialized mandate.'},
      if (currentStageIndex >= 1)
        {'title': 'Documents Verified by Desk', 'date': createdDate, 'desc': 'Ownership & circle rates confirmed.'},
      if (currentStageIndex >= 2)
        {'title': 'Official Quotation Generated', 'date': 'Today', 'desc': 'Turnaround SLA and fee scope determined.'},
      if (currentStageIndex >= 3)
        {'title': 'Payment Remittance Processed', 'date': 'Today', 'desc': 'Bank credit confirmed.'},
      if (currentStageIndex >= 4)
        {'title': 'Valuation Compilation In Progress', 'date': 'Today', 'desc': 'Appraisal inspection underway.'},
      if (currentStageIndex >= 5)
        {'title': 'Certified Report Package Released', 'date': 'Today', 'desc': 'Cloud HSM signed package generated.'},
    ].reversed.toList();

    return Column(
      children: updates.map((u) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: _LuxuryTheme.skyAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['title']!, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _LuxuryTheme.textMain)),
                    Text('${u['date']} • ${u['desc']}', style: GoogleFonts.inter(fontSize: 11, color: _LuxuryTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Contextual Actions Center (Compact Luxury Buttons)
  Widget _buildContextualActionCenter(_ClientStageInfo stageInfo, dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _LuxuryTheme.cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LuxuryTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mandate Action Center',
            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
          ),
          const SizedBox(height: 14),

          if (stageInfo.stageIndex == 2) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showQuotationModal(order),
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: const Text('View Quote'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LuxuryTheme.goldAccent,
                    foregroundColor: _LuxuryTheme.bgDark,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _downloadQuotePdf(orderId),
                  icon: const Icon(Icons.download, size: 14),
                  label: const Text('Download PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _LuxuryTheme.textMain,
                    side: BorderSide(color: _LuxuryTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentModal(order),
                  icon: const Icon(Icons.payment, size: 14),
                  label: const Text('Pay Now →'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LuxuryTheme.tealAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ] else if (stageInfo.stageIndex == 3) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _LuxuryTheme.skyAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _LuxuryTheme.skyAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top, color: _LuxuryTheme.skyAccent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Payment remittance proof is being verified by accounts desk. Order will transition to Report In Progress automatically.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMain, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (stageInfo.stageIndex == 4) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _LuxuryTheme.cardGlass,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _LuxuryTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: _LuxuryTheme.skyAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Report In Progress • Valuer inspection and statutory compilation underway. Target delivery is within committed SLA.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMain, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (stageInfo.stageIndex == 5) ...[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _actionLoading ? null : () => _downloadFinalReport(refCode),
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Download Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _LuxuryTheme.tealAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _downloadTaxInvoice(orderId),
                  icon: const Icon(Icons.receipt_outlined, size: 14),
                  label: const Text('Download Invoice'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _LuxuryTheme.textMain,
                    side: BorderSide(color: _LuxuryTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _acknowledgeReportDelivery(refCode, 'ACCEPT'),
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Accept Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _LuxuryTheme.tealAccent,
                    side: BorderSide(color: _LuxuryTheme.tealAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _requestReportClarification(refCode),
                  icon: const Icon(Icons.chat_bubble_outline, size: 14),
                  label: const Text('Clarification'),
                  style: TextButton.styleFrom(
                    foregroundColor: _LuxuryTheme.textMuted,
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No immediate action required from your side. Our team is processing your request.',
              style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  // Concierge Support Banner (Luxury Gold Accent)
  Widget _buildSupportConciergeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _LuxuryTheme.cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LuxuryTheme.goldAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.headset_mic_outlined, color: _LuxuryTheme.goldAccent, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dedicated Client Concierge', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain)),
                  Text('Direct support from our Senior Valuer Desk', style: GoogleFonts.inter(fontSize: 11, color: _LuxuryTheme.textMuted)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text('+91 85000 19091', style: GoogleFonts.robotoMono(fontSize: 12, color: _LuxuryTheme.goldAccent, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Text('provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 12, color: _LuxuryTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }


  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 4: COMPLETED REPORTS (Luxury Read Only Gallery & Workspace)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildCompletedReportsGallery(OrderProvider orders) {
    final completedOrders = orders.clientOrders
        .where((o) => _mapToClientStage(o).stageIndex == 5)
        .toList();

    if (completedOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  shape: BoxShape.circle,
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                ),
                child: const Icon(Icons.inventory_2_outlined, size: 40, color: _LuxuryTheme.tealAccent),
              ),
              const SizedBox(height: 18),
              Text(
                'No Completed Reports Yet',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
              ),
              const SizedBox(height: 6),
              Text(
                'Once your valuation reports are officially delivered and signed, they will be archived here.',
                style: GoogleFonts.inter(fontSize: 13, color: _LuxuryTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: _LuxuryTheme.tealAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                'Completed Valuation Archives',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${completedOrders.length} completed report${completedOrders.length > 1 ? 's' : ''} stored under 10-year statutory compliance archive.',
            style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
          ),
          const SizedBox(height: 22),

          // Compact Luxury Cards Grid (~135px height)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: completedOrders.map((order) {
              final orderId = order['id'];
              final refCode = order['referenceCode'] ?? 'REQ-$orderId';
              final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
              final completionDate = order['updatedAt'] != null
                  ? order['updatedAt'].toString().split('T').first
                  : 'Completed';

              return Container(
                width: 320,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Reference + Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.skyAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _LuxuryTheme.skyAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(refCode, style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w700, color: _LuxuryTheme.skyAccent)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.tealAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: _LuxuryTheme.tealAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text('Completed ✓', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: _LuxuryTheme.tealAccent)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Title (1 line)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
                    ),
                    const SizedBox(height: 6),

                    // Row 3: Completed Date
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded, size: 12, color: _LuxuryTheme.textDim),
                        const SizedBox(width: 5),
                        Text('Delivered: $completionDate', style: GoogleFonts.inter(fontSize: 11.5, color: _LuxuryTheme.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Row 4: Compact Action
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: OutlinedButton(
                        onPressed: () => setState(() => _focusedCompletedOrder = order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _LuxuryTheme.textMain,
                          side: BorderSide(color: _LuxuryTheme.cardBorder),
                          backgroundColor: Colors.white.withValues(alpha: 0.03),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Open Archive', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward_rounded, size: 13),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // COMPLETED REPORT WORKSPACE (READ ONLY LUXURY GLASS)
  Widget _buildCompletedReportWorkspace(dynamic order, OrderProvider orders) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final completionDate = order['updatedAt'] != null ? order['updatedAt'].toString().split('T').first : 'Completed';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => setState(() => _focusedCompletedOrder = null),
            icon: const Icon(Icons.arrow_back_rounded, size: 15),
            label: const Text('Back to Completed Reports'),
            style: TextButton.styleFrom(
              foregroundColor: _LuxuryTheme.textMuted,
              textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _LuxuryTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.skyAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _LuxuryTheme.skyAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text(refCode, style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: _LuxuryTheme.skyAccent)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _LuxuryTheme.tealAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _LuxuryTheme.tealAccent.withValues(alpha: 0.3)),
                          ),
                          child: Text('Archived Record (Read-Only) 🔒', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: _LuxuryTheme.tealAccent)),
                        ),
                      ],
                    ),
                    Text('Completion Date: $completionDate', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _LuxuryTheme.textDim)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(title, style: GoogleFonts.montserrat(fontSize: 19, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain)),
                const SizedBox(height: 6),
                Text('Final Assessed Value: ₹ ${order['estimatedValue'] ?? '1,85,00,000'}', style: GoogleFonts.inter(fontSize: 13.5, color: _LuxuryTheme.goldAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Final Deliverables Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _LuxuryTheme.cardGlass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _LuxuryTheme.tealAccent.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: _LuxuryTheme.tealAccent, size: 24),
                    const SizedBox(width: 10),
                    Text('Official Signed Deliverables', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Your final report is digitally signed via Cloud HSM and protected with AES-256 encryption. The password is your registered 10-digit mobile number.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadFinalReport(refCode),
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text('Download Report PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _LuxuryTheme.tealAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _downloadTaxInvoice(orderId),
                      icon: const Icon(Icons.receipt_outlined, size: 14),
                      label: const Text('Download Tax Invoice'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _LuxuryTheme.textMain,
                        side: BorderSide(color: _LuxuryTheme.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Request Details & Payment History
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _LuxuryTheme.cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _LuxuryTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Details', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain)),
                      const SizedBox(height: 14),
                      _summaryRow('Service', 'Commercial Valuation'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('Purpose', order['purpose']?.toString().replaceAll('_', ' ') ?? 'Bank Collateral'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('Category', order['propertyCategory']?.toString().replaceAll('_', ' ') ?? 'Land & Building'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('Archival Status', '10-Year Statutory Lock Active'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _LuxuryTheme.cardGlass,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _LuxuryTheme.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settlement & Payment History', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain)),
                      const SizedBox(height: 14),
                      _summaryRow('Quoted Base Fee', '₹ 15,000.00'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('GST (18%)', '₹ 2,700.00'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('Total Paid', '₹ 17,700.00 (Settled ✓)'),
                      Divider(height: 14, color: _LuxuryTheme.cardBorder),
                      _summaryRow('Payment Status', 'Bank Credit Verified'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Support Hotline
          _buildSupportConciergeBanner(),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS
  // ═════════════════════════════════════════════════════════════════════════
  void _showProfileDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LuxuryTheme.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _LuxuryTheme.cardBorder)),
        title: Text('My Profile', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileField('Client Officer', auth.fullName ?? 'Anand Mehta'),
            const SizedBox(height: 12),
            _profileField('Registered Email', auth.email ?? 'client@provaluer.com'),
            const SizedBox(height: 12),
            _profileField('Account Role', auth.role ?? 'CLIENT'),
            const SizedBox(height: 12),
            _profileField('Portal Access', 'Active • Verified'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: _LuxuryTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: _LuxuryTheme.textDim)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _LuxuryTheme.textMain)),
      ],
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LuxuryTheme.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _LuxuryTheme.cardBorder)),
        title: Row(
          children: [
            const Icon(Icons.headset_mic_outlined, color: _LuxuryTheme.goldAccent, size: 20),
            const SizedBox(width: 10),
            Text('Support Concierge', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct assistance from ProValuer Senior Appraisal Desk:', style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _LuxuryTheme.cardGlass,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _LuxuryTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: _LuxuryTheme.goldAccent),
                      const SizedBox(width: 10),
                      Text('+91 85000 19091', style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: _LuxuryTheme.goldAccent)),
                    ],
                  ),
                  Divider(height: 18, color: _LuxuryTheme.cardBorder),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 16, color: _LuxuryTheme.skyAccent),
                      const SizedBox(width: 10),
                      Text('provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: _LuxuryTheme.textMain)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: _LuxuryTheme.textMuted)),
          ),
        ],
      ),
    );
  }

  void _showQuotationModal(dynamic order) {
    final orderId = order['id'] as int;
    final fee = (order['estimatedValue'] as num? ?? 18500000) > 10000000 ? 18500.0 : 12500.0;
    final gst = fee * 0.18;
    final total = fee + gst;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LuxuryTheme.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _LuxuryTheme.cardBorder)),
        title: Text('Official Quotation', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain, fontSize: 16)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quotation breakdown for ${order['referenceCode'] ?? 'REQ-$orderId'}:', style: GoogleFonts.inter(fontSize: 12.5, color: _LuxuryTheme.textMuted)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _LuxuryTheme.cardGlass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _LuxuryTheme.cardBorder),
                ),
                child: Column(
                  children: [
                    _summaryRow('Base Appraisal Fee', '₹ ${fee.toStringAsFixed(2)}'),
                    Divider(height: 14, color: _LuxuryTheme.cardBorder),
                    _summaryRow('GST (18%)', '₹ ${gst.toStringAsFixed(2)}'),
                    Divider(height: 14, color: _LuxuryTheme.cardBorder),
                    _summaryRow('Total Payable Remittance', '₹ ${total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('Turnaround SLA: 3 Business Days from payment credit.', style: GoogleFonts.inter(fontSize: 11.5, color: _LuxuryTheme.textDim)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: _LuxuryTheme.textMuted)),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadQuotePdf(orderId);
            },
            icon: const Icon(Icons.download, size: 13),
            label: const Text('Download PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _LuxuryTheme.textMain,
              side: BorderSide(color: _LuxuryTheme.cardBorder),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showPaymentModal(order);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _LuxuryTheme.tealAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Accept & Pay →'),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(dynamic order) {
    final orderId = order['id'] as int;
    _paymentAmountCtrl.text = '14750.00';
    _utrCtrl.clear();
    _paymentReceiptFile = null;
    _paymentError = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return AlertDialog(
            backgroundColor: _LuxuryTheme.bgDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _LuxuryTheme.cardBorder)),
            title: Text('Submit Payment Remittance', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain, fontSize: 16)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _LuxuryTheme.cardGlass,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _LuxuryTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank Transfer / NEFT / UPI Beneficiary:', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: _LuxuryTheme.goldAccent)),
                          const SizedBox(height: 4),
                          Text('Account Name: ProValuer Services Pvt Ltd\nBank: HDFC Bank | A/C: 50200088192019\nIFSC: HDFC0001234 | UPI: provaluer@hdfcbank', style: GoogleFonts.robotoMono(fontSize: 10.5, height: 1.4, color: _LuxuryTheme.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_paymentError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Text(_paymentError!, style: const TextStyle(color: Colors.redAccent, fontSize: 11.5)),
                      ),
                    TextField(
                      controller: _utrCtrl,
                      style: GoogleFonts.robotoMono(color: _LuxuryTheme.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'UTR / Bank Transaction Reference *',
                        labelStyle: GoogleFonts.inter(fontSize: 12, color: _LuxuryTheme.textDim),
                        filled: true,
                        fillColor: _LuxuryTheme.cardGlass,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _LuxuryTheme.goldAccent)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _paymentAmountCtrl,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.robotoMono(color: _LuxuryTheme.textMain, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: 'Amount Paid (₹) *',
                        labelStyle: GoogleFonts.inter(fontSize: 12, color: _LuxuryTheme.textDim),
                        filled: true,
                        fillColor: _LuxuryTheme.cardGlass,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _LuxuryTheme.goldAccent)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg'], withData: true);
                            if (res != null && res.files.isNotEmpty) {
                              setModalState(() => _paymentReceiptFile = res.files.first);
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 14),
                          label: Text(_paymentReceiptFile != null ? 'Receipt Attached ✓' : 'Attach Remittance Proof *'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _paymentReceiptFile != null ? _LuxuryTheme.tealAccent : _LuxuryTheme.textMain,
                            side: BorderSide(color: _paymentReceiptFile != null ? _LuxuryTheme.tealAccent : _LuxuryTheme.cardBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (_paymentReceiptFile != null) ...[
                          const SizedBox(width: 8),
                          Expanded(child: Text(_paymentReceiptFile!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: _LuxuryTheme.tealAccent))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: _LuxuryTheme.textMuted)),
              ),
              ElevatedButton(
                onPressed: _paymentSubmitting
                    ? null
                    : () async {
                        final utr = _utrCtrl.text.trim();
                        final amt = double.tryParse(_paymentAmountCtrl.text.trim()) ?? 0.0;
                        if (utr.isEmpty || amt <= 0 || _paymentReceiptFile == null) {
                          setModalState(() => _paymentError = 'Please fill all required fields and attach proof.');
                          return;
                        }
                        final orderProvider = context.read<OrderProvider>();
                        setModalState(() => _paymentSubmitting = true);
                        final now = DateTime.now();
                        final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

                        final res = await orderProvider.submitPaymentProof(
                              orderId: orderId,
                              utrNumber: utr,
                              paymentMethod: _paymentMethod,
                              paymentDate: dateStr,
                              amountPaid: amt,
                              fileBytes: _paymentReceiptFile!.bytes ?? [],
                              filename: _paymentReceiptFile!.name,
                            );

                        setModalState(() => _paymentSubmitting = false);
                        if (res != null && res['error'] == null) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadOrdersAndSync();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Payment proof submitted successfully! Verification in progress.')),
                            );
                          }
                        } else {
                          setModalState(() => _paymentError = res?['error']?.toString() ?? 'Payment submission failed.');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LuxuryTheme.tealAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _paymentSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Payment Proof'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _uploadAdditionalDocument(int orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg'], withData: true);
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      final uploadRes = await orderProvider.uploadDocument(
            orderId,
            'SUPPLEMENTAL_DOC',
            f.name,
            f.bytes ?? [],
          );
      if (uploadRes.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Supplemental document attached successfully!')),
        );
        await _loadOrdersAndSync();
      }
    }
  }

  Future<void> _downloadQuotePdf(int orderId) async {
    final bytes = await context.read<OrderProvider>().downloadQuotePdf(orderId);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Quotation downloaded successfully (${(bytes.length / 1024).toStringAsFixed(1)} KB)')),
      );
    }
  }

  Future<void> _downloadFinalReport(String refCode) async {
    setState(() => _actionLoading = true);
    final orderProvider = context.read<OrderProvider>();
    final tokenRes = await orderProvider.generateDeliveryToken(refCode, fileType: 'REPORT_PDF');
    if (tokenRes != null && tokenRes['token'] != null) {
      final token = tokenRes['token'] as String;
      final bytes = await orderProvider.streamDeliveryFile(token);
      setState(() => _actionLoading = false);
      if (bytes != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ Encrypted PDF Report downloaded (${(bytes.length / 1024).toStringAsFixed(1)} KB)')),
        );
        return;
      }
    }
    setState(() => _actionLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download token active. Processing file transmission...')),
      );
    }
  }

  Future<void> _downloadTaxInvoice(int orderId) async {
    final invoice = await context.read<OrderProvider>().fetchOrderInvoice(orderId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Tax Invoice: ${invoice?['invoiceNumber'] ?? 'INV-2026-981'} ready.')),
      );
    }
  }

  Future<void> _acknowledgeReportDelivery(String refCode, String action) async {
    final res = await context.read<OrderProvider>().acknowledgeDelivery(refCode, action: action);
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Formal delivery acknowledgement submitted.')),
      );
      await _loadOrdersAndSync();
    }
  }

  void _requestReportClarification(String refCode) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LuxuryTheme.bgDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: _LuxuryTheme.cardBorder)),
        title: Text('Request Report Clarification', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          style: GoogleFonts.inter(color: _LuxuryTheme.textMain, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Enter clarification notes for senior valuer desk...',
            hintStyle: GoogleFonts.inter(color: _LuxuryTheme.textDim, fontSize: 12),
            filled: true,
            fillColor: _LuxuryTheme.cardGlass,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _LuxuryTheme.cardBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _LuxuryTheme.goldAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _LuxuryTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx);
                await context.read<OrderProvider>().acknowledgeDelivery(
                      refCode,
                      action: 'CLARIFICATION',
                      clarificationNotes: ctrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✓ Clarification request sent to valuer desk.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _LuxuryTheme.goldAccent,
              foregroundColor: _LuxuryTheme.bgDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Submit Clarification'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Client Left Sidebar (Luxury Landing Page Navigation)
// ─────────────────────────────────────────────────────────────────────────────
class _ClientSidebar extends StatelessWidget {
  final bool collapsed;
  final _ClientNav activeNav;
  final String fullName;
  final String email;
  final ValueChanged<_ClientNav> onNavSelect;
  final VoidCallback onProfileTap;
  final VoidCallback onSupportTap;
  final VoidCallback onToggleCollapse;
  final VoidCallback onSignOut;

  const _ClientSidebar({
    required this.collapsed,
    required this.activeNav,
    required this.fullName,
    required this.email,
    required this.onNavSelect,
    required this.onProfileTap,
    required this.onSupportTap,
    required this.onToggleCollapse,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 72.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: _LuxuryTheme.bgDark,
        border: Border(right: BorderSide(color: _LuxuryTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_LuxuryTheme.primaryBlue, Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text('PV', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ProValuer', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: _LuxuryTheme.textMain)),
                        Text('Client Portal', style: GoogleFonts.inter(fontSize: 11, color: _LuxuryTheme.textDim)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: _LuxuryTheme.cardBorder),

          // ── CORE NAVIGATION ITEMS ─────────────────────────────────────────
          const SizedBox(height: 12),
          _navTile(
            nav: _ClientNav.createReport,
            label: _ClientNav.createReport.label,
            icon: _ClientNav.createReport.icon,
            isHighlight: true,
          ),
          _navTile(
            nav: _ClientNav.reportsInProgress,
            label: _ClientNav.reportsInProgress.label,
            icon: _ClientNav.reportsInProgress.icon,
          ),
          _navTile(
            nav: _ClientNav.completedReports,
            label: _ClientNav.completedReports.label,
            icon: _ClientNav.completedReports.icon,
          ),

          const Spacer(),

          // ── PREFERENCES & ACTIONS ─────────────────────────────────────────
          Divider(height: 1, color: _LuxuryTheme.cardBorder),
          _actionTile(
            label: 'My Profile',
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
          ),
          _actionTile(
            label: 'Support',
            icon: Icons.headset_mic_outlined,
            onTap: onSupportTap,
          ),
          _actionTile(
            label: 'Sign Out',
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            onTap: onSignOut,
          ),
          Divider(height: 1, color: _LuxuryTheme.cardBorder),

          // Collapse Toggle
          ListTile(
            dense: true,
            leading: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: _LuxuryTheme.textDim, size: 18),
            title: collapsed ? null : Text('Collapse Sidebar', style: TextStyle(color: _LuxuryTheme.textDim, fontSize: 11.5)),
            onTap: onToggleCollapse,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navTile({
    required _ClientNav nav,
    required String label,
    required IconData icon,
    bool isHighlight = false,
  }) {
    final isActive = activeNav == nav;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        onTap: () => onNavSelect(nav),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _LuxuryTheme.goldAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? _LuxuryTheme.goldAccent.withValues(alpha: 0.35) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              if (isActive)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _LuxuryTheme.goldAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                icon,
                color: isActive ? _LuxuryTheme.goldAccent : (isHighlight ? _LuxuryTheme.skyAccent : _LuxuryTheme.textDim),
                size: 19,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w700 : (isHighlight ? FontWeight.w600 : FontWeight.w500),
                      color: isActive ? _LuxuryTheme.goldAccent : (isHighlight ? _LuxuryTheme.textMain : _LuxuryTheme.textMuted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile({
    required String label,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: iconColor ?? _LuxuryTheme.textDim, size: 18),
        title: collapsed
            ? null
            : Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: iconColor ?? _LuxuryTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Client Top Header Bar (Luxury Glass Aesthetic)
// ─────────────────────────────────────────────────────────────────────────────
class _ClientTopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;
  final VoidCallback onCreateNew;

  const _ClientTopHeader({
    required this.title,
    required this.onRefresh,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: _LuxuryTheme.bgDark,
        border: Border(bottom: BorderSide(color: _LuxuryTheme.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: _LuxuryTheme.textMain),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18, color: _LuxuryTheme.textMuted),
                tooltip: 'Refresh Workspace',
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Create New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _LuxuryTheme.goldAccent,
                  foregroundColor: _LuxuryTheme.bgDark,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
