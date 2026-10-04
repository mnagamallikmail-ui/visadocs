// ─────────────────────────────────────────────────────────────────────────────
// ClientWorkspaceHub
// Client Portal — Landing Page Design System Enforcement
// Route: /client
// Preserves entire existing backend, database, state machine, and API contracts.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';

// ─── Simplified Client Navigation ─────────────────────────────────────────────
enum _ClientNav {
  createReport,
  reportsInProgress,
  completedReports,
}

extension _ClientNavMeta on _ClientNav {
  String get label => switch (this) {
        _ClientNav.createReport => 'New Request',
        _ClientNav.reportsInProgress => 'Reports',
        _ClientNav.completedReports => 'Delivered Reports',
      };

  IconData get icon => switch (this) {
        _ClientNav.createReport => Icons.add_circle_outline_rounded,
        _ClientNav.reportsInProgress => Icons.hourglass_top_rounded,
        _ClientNav.completedReports => Icons.check_circle_outline_rounded,
      };
}

// ─── 6 Human Advisory Stages ─────────────────────────────────────────────────
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
  'Request Received',
  'Review Quotation',
  'Payment Under Review',
  'Scheduled for Inspection',
  'Report Being Prepared',
  'Ready for Download',
];

// ─── Landing Page Design System Tokens ────────────────────────────────────────
class _LandingDesignSystem {
  // Pure White & Monochromatic Pearl Foundation (from LandingTheme)
  static const Color bgCanvas = Color(0xFFF8FAFC); // Pearl Slate Ambient
  static const Color bgSurface = Color(0xFFFFFFFF); // Pure White Base
  static const Color bgSubtle = Color(0xFFF1F5F9); // Soft Architectural Mists / Platinum

  // Card Surfaces & Platinum Borders
  static const Color cardSurface = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color cardBorder = Color(0xFFE2E8F0); // Delicate Platinum Hairline

  // Dominant Primary Brand Accent: Deep Teal (from LandingTheme.brandGreen)
  static const Color tealBrand = Color(0xFF005C5C); // Solid Deep Teal / Institutional Brand Green
  static const Color tealSubtle = Color(0xFFF0FDFA); // Subtle Teal Tint for active nav / soft badges
  static const Color tealBorder = Color(0xFF99F6E4); // Subtle Teal Rim

  // Sparingly Used Secondary Accent: Gold (Badges & Small Highlights ONLY)
  static const Color goldAccent = Color(0xFFFABB1F);
  static const Color goldSubtle = Color(0xFFFEF9C3);
  static const Color goldBorder = Color(0xFFFDE047);

  // Status Colors
  static const Color stateSuccess = Color(0xFF10B981);
  static const Color stateSuccessSubtle = Color(0xFFECFDF5);
  static const Color stateWarning = Color(0xFFF59E0B);
  static const Color stateError = Color(0xFFEF4444);
  static const Color stateErrorSubtle = Color(0xFFFEF2F2);
  static const Color stateInfo = Color(0xFF0284C7);

  // High-Contrast Luxury Typography (from LandingTheme)
  static const Color textPrimary = Color(0xFF111827); // Deepest Charcoal Slate
  static const Color textSecondary = Color(0xFF64748B); // Soft Graphite Grey
  static const Color textMuted = Color(0xFF94A3B8); // Subdued Caption Grey

  // Multi-Layer Physical Crystal Shadows (from LandingTheme)
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A), // 3% ambient dark slate
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x05000000), // 2% contact shadow
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> cardHoverShadow = [
    BoxShadow(
      color: Color(0x120F172A),
      blurRadius: 28,
      offset: Offset(0, 8),
    ),
  ];

  // Soft Advisory Button Tokens (Calm, Non-Dominant Hierarchy)
  static const Color buttonNeutralBg          = Color(0xFFF5F7F8);
  static const Color buttonNeutralBorder      = Color(0xFFDDE5EA);
  static const Color buttonNeutralText        = Color(0xFF334155); // Slate 700
  static const Color buttonNeutralHoverBg     = Color(0xFFEEF2F5);
  static const Color buttonNeutralHoverBorder = Color(0xFFC7D2DA);

  static const List<BoxShadow> buttonNeutralShadow = [
    BoxShadow(
      color: Color(0x06000000), // Very subtle daylight shadow
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> buttonPrimaryShadow = [
    BoxShadow(
      color: Color(0x14005C5C), // Calibrated soft teal shadow (no aggressive marketing glow)
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];
}

_ClientStageInfo _mapToClientStage(dynamic order) {
  if (order == null) {
    return const _ClientStageInfo(
      stageIndex: 0,
      stageTitle: 'Request Received',
      statusBadge: 'Request Received',
      statusColor: _LandingDesignSystem.tealBrand,
      statusDescription: 'Your valuation request has been received and is being processed.',
      requiredActionLabel: 'Request Received',
    );
  }

  final status = (order['status'] as String? ?? 'DRAFT').toUpperCase();
  final paymentStatus = (order['paymentStatus'] as String? ?? 'PENDING').toUpperCase();

  switch (status) {
    case 'DRAFT':
      return const _ClientStageInfo(
        stageIndex: 0,
        stageTitle: 'Request Received',
        statusBadge: 'Request Received',
        statusColor: _LandingDesignSystem.tealBrand,
        statusDescription: 'Your valuation request has been submitted successfully.',
        requiredActionLabel: 'Request Received',
      );

    case 'QUOTE_PENDING':
      return const _ClientStageInfo(
        stageIndex: 1,
        stageTitle: 'Review Quotation',
        statusBadge: 'Review Quotation',
        statusColor: _LandingDesignSystem.stateWarning,
        statusDescription: 'Our team is preparing your custom quotation and scope of work.',
        requiredActionLabel: 'Quote in Progress',
      );

    case 'QUOTE_PROVIDED':
      if (paymentStatus == 'SUBMITTED') {
        return const _ClientStageInfo(
          stageIndex: 2,
          stageTitle: 'Payment Under Review',
          statusBadge: 'Payment Under Review',
          statusColor: _LandingDesignSystem.stateInfo,
          statusDescription: 'Payment remittance submitted. Accounts team is verifying settlement.',
          requiredActionLabel: 'Verification Pending',
        );
      }
      return const _ClientStageInfo(
        stageIndex: 1,
        stageTitle: 'Review Quotation',
        statusBadge: 'Review Quotation',
        statusColor: _LandingDesignSystem.stateWarning,
        statusDescription: 'Your formal quotation and service scope are ready for your review.',
        requiredActionLabel: 'Review Quotation',
      );

    case 'PAYMENT_SUBMITTED':
      return const _ClientStageInfo(
        stageIndex: 2,
        stageTitle: 'Payment Under Review',
        statusBadge: 'Payment Under Review',
        statusColor: _LandingDesignSystem.stateInfo,
        statusDescription: 'Payment remittance submitted. Accounts desk is confirming settlement.',
        requiredActionLabel: 'Verification Pending',
      );

    case 'PAYMENT_REJECTED':
      return const _ClientStageInfo(
        stageIndex: 2,
        stageTitle: 'Payment Under Review',
        statusBadge: 'Payment Clarification',
        statusColor: _LandingDesignSystem.stateError,
        statusDescription: 'Payment remittance details could not be matched. Please re-submit your transaction reference.',
        requiredActionLabel: 'Re-submit Payment Proof',
      );

    case 'PAYMENT_VERIFIED':
      return const _ClientStageInfo(
        stageIndex: 3,
        stageTitle: 'Scheduled for Inspection',
        statusBadge: 'Scheduled for Inspection',
        statusColor: _LandingDesignSystem.stateSuccess,
        statusDescription: 'Payment confirmed. Valuation order is confirmed and scheduled for inspection.',
        requiredActionLabel: 'View Details',
      );

    case 'PAID_INTAKE':
    case 'IN_GENERAL_POOL':
    case 'ASSIGNED':
    case 'INSPECTION_SCHEDULED':
      return const _ClientStageInfo(
        stageIndex: 3,
        stageTitle: 'Scheduled for Inspection',
        statusBadge: 'Scheduled for Inspection',
        statusColor: _LandingDesignSystem.stateInfo,
        statusDescription: 'Inspection is being scheduled with certified field valuers.',
        requiredActionLabel: 'View Details',
      );

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
        stageTitle: 'Report Being Prepared',
        statusBadge: 'Report Being Prepared',
        statusColor: _LandingDesignSystem.tealBrand,
        statusDescription: 'Registered valuers are conducting calculations and preparing your formal report.',
        requiredActionLabel: 'View Details',
      );

    case 'DELIVERY_READY':
    case 'FINAL_DELIVERY':
    case 'CLIENT_DOWNLOADED':
    case 'CLOSED':
      return const _ClientStageInfo(
        stageIndex: 5,
        stageTitle: 'Ready for Download',
        statusBadge: 'Ready for Download',
        statusColor: _LandingDesignSystem.stateSuccess,
        statusDescription: 'Your finalized, digitally certified valuation report and commercial invoice are available for download.',
        requiredActionLabel: 'Download Report',
        isDelivered: true,
      );

    default:
      return const _ClientStageInfo(
        stageIndex: 0,
        stageTitle: 'Request Received',
        statusBadge: 'Request Received',
        statusColor: _LandingDesignSystem.tealBrand,
        statusDescription: 'Request initialized.',
        requiredActionLabel: 'Request Received',
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

  // ─── Payment Form State (Encapsulated Inside Active Report) ─────────────────
  final _utrCtrl = TextEditingController();
  final _paymentAmountCtrl = TextEditingController();
  PlatformFile? _paymentReceiptFile;
  String? _paymentError;

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
    return [
      {'key': 'TITLE_DEED', 'label': 'Title Deed / Ownership Proof', 'mandatory': true},
      {'key': 'SANCTION_PLAN', 'label': 'Approved Plan / Layout', 'mandatory': true},
      {'key': 'TAX_RECEIPT', 'label': 'Latest Tax Receipt', 'mandatory': true},
    ];
  }

  List<Map<String, String>> _getMandatoryRequirementsList() {
    return const [
      {'key': 'TITLE_DEED', 'label': 'Title Deed / Ownership Proof'},
      {'key': 'SANCTION_PLAN', 'label': 'Approved Plan / Layout'},
      {'key': 'TAX_RECEIPT', 'label': 'Latest Tax Receipt'},
    ];
  }

  List<String> _getMissingMandatoryDocCategories() {
    final missing = <String>[];
    for (final req in _getMandatoryRequirementsList()) {
      final key = req['key']!;
      if (!_wizardDocs.containsKey(key) || _wizardDocs[key] == null) {
        missing.add(req['label']!);
      }
    }
    return missing;
  }

  bool _areAllMandatoryDocsUploaded() {
    return _getMissingMandatoryDocCategories().isEmpty;
  }

  Widget _buildMissingDocsCard() {
    final missing = _getMissingMandatoryDocCategories();
    final allComplete = missing.isEmpty;

    if (allComplete) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All mandatory documents attached. Ready to proceed.',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 20, color: _LandingDesignSystem.stateError),
              const SizedBox(width: 10),
              Text(
                'Required Documents Missing',
                style: GoogleFonts.montserrat(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _LandingDesignSystem.stateError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._getMandatoryRequirementsList().map((item) {
            final isUploaded = _wizardDocs.containsKey(item['key']) && _wizardDocs[item['key']] != null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    isUploaded ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 16,
                    color: isUploaded ? const Color(0xFF16A34A) : _LandingDesignSystem.stateError,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['label']!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isUploaded ? FontWeight.w500 : FontWeight.w600,
                      color: isUploaded ? _LandingDesignSystem.textSecondary : _LandingDesignSystem.stateError,
                      decoration: isUploaded ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            'Upload all required documents before submission.',
            style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.stateError, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Future<void> _pickWizardDoc(String key) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      if (f.size > 25 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File exceeds 25 MB limit.')),
          );
        }
        return;
      }
      setState(() {
        _wizardDocs[key] = f;
      });
    }
  }

  void _removeWizardDoc(String key) {
    setState(() {
      _wizardDocs.remove(key);
    });
  }

  Future<void> _submitWizardReport() async {
    final missing = _getMissingMandatoryDocCategories();
    if (missing.isNotEmpty) {
      setState(() {
        _wizardSubmitting = false;
        _wizardError = "Required Documents Missing:\n" +
            missing.map((m) => "• $m").join("\n") +
            "\nUpload all required documents before submission.";
      });
      return;
    }

    setState(() {
      _wizardSubmitting = true;
      _wizardError = null;
    });

    try {
      final orderProvider = context.read<OrderProvider>();
      final cleanVal = _estimatedValueCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsedValue = double.tryParse(cleanVal) ?? 15000000.0;

      final initialInputs = {
        'asset_name': _assetNameCtrl.text.trim(),
        'property_address': _propertyAddressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'service_type': _wizardService,
      };

      final created = await orderProvider.saveDraft(
        _wizardAsset,
        _wizardPurpose,
        parsedValue,
        initialInputs,
        serviceCategory: _wizardService,
      );
      final orderId = created['id'] as int;

      for (final entry in _wizardDocs.entries) {
        if (entry.value.bytes != null) {
          await orderProvider.uploadDocument(
            orderId,
            entry.key,
            entry.value.name,
            entry.value.bytes!,
          );
        }
      }

      final submitResult = await orderProvider.submitRequest(orderId);
      if (submitResult == null || submitResult['error'] != null) {
        final err = submitResult != null && submitResult['error'] != null
            ? submitResult['error'].toString()
            : "Failed to submit valuation request. Please ensure all mandatory documents are uploaded.";
        throw Exception(err);
      }

      await orderProvider.fetchClientOrders();

      if (mounted) {
        setState(() {
          _wizardSubmitting = false;
          _wizardError = null;
          _wizardStep = 7;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _wizardSubmitting = false;
          _wizardError = e.toString().replaceAll('Exception: ', '');
          // Block wizard completion: remain on current step (Step 6)
        });
      }
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
      _wizardSubmitting = false;
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
      backgroundColor: _LandingDesignSystem.bgCanvas,
      body: Row(
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
                    _ClientNav.createReport => 'New Request',
                    _ClientNav.reportsInProgress => _focusedActiveOrder == null
                        ? 'Reports'
                        : 'Report • ${_focusedActiveOrder['referenceCode'] ?? 'REQ-${_focusedActiveOrder['id']}'}',
                    _ClientNav.completedReports => _focusedCompletedOrder == null
                        ? 'Delivered Reports'
                        : 'Delivered Report • ${_focusedCompletedOrder['referenceCode'] ?? 'REQ-${_focusedCompletedOrder['id']}'}',
                  },
                  onRefresh: _loadOrdersAndSync,
                ),
                Expanded(
                  child: _buildCurrentView(orders, auth),
                ),
              ],
            ),
          ),
        ],
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
// FLOW 1: NEW ADVISORY REQUEST (Landing Page Design System Enforcement)
  // Flattened hierarchy: Typography is hero. No boxes-inside-boxes.
  // Named progress tracker: Service • Asset • Purpose • Details • Documents • Review
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildWizardView() {
    if (_wizardStep == 7) {
      return _buildWizardSuccessScreen();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Named Advisory Stepper
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'PROVALUER INTAKE',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _LandingDesignSystem.tealBrand,
                    ),
                  ),
                  _buildNamedProgressTracker(),
                ],
              ),
              const SizedBox(height: 24),

              // FIX 1 & FIX 3: Confident, Authority-Driven Editorial Headline as Hero
              Text(
                _wizardStepHeadline,
                style: GoogleFonts.montserrat(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: _LandingDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _wizardStepSubhead,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _LandingDesignSystem.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // FIX 2: Content breathes directly on canvas — no nested boxes inside boxes
              if (_wizardStep == 1) _buildWizardStep1(),
              if (_wizardStep == 2) _buildWizardStep2(),
              if (_wizardStep == 3) _buildWizardStep3(),
              if (_wizardStep == 4) _buildWizardStep4(),
              if (_wizardStep == 5) _buildWizardStep5(),
              if (_wizardStep == 6) _buildWizardStep6(),

              if (_wizardError != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _LandingDesignSystem.stateErrorSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: _LandingDesignSystem.stateError),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wizardError!,
                          style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.stateError),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // FIX 1 & FIX 3: Human, Advisory Step Headlines
  String get _wizardStepHeadline => switch (_wizardStep) {
        1 => "Let's Begin",
        2 => "Tell us about the asset involved.",
        3 => "What is the purpose of this engagement?",
        4 => "Provide a few details about the subject asset.",
        5 => "Supporting Documentation",
        6 => "Review Your Request",
        _ => "Valuation Request Intake",
      };

  String get _wizardStepSubhead => switch (_wizardStep) {
        1 => "Choose the service that best matches your requirement.",
        2 => "Select the asset class so we can tailor the advisory framework and documentation checklist.",
        3 => "Select the official requirement for your valuation report.",
        4 => "Enter property identification and location details to establish appraisal scope.",
        5 => "Attach relevant deeds, sanction plans, or financial statements. You may also provide these later.",
        6 => "Confirm your engagement parameters before submitting to our valuation desk.",
        _ => "Professional valuation advisory services.",
      };

  // FIX 7: Named Progress Tracker: Service • Asset • Purpose • Details • Documents • Review
  Widget _buildNamedProgressTracker() {
    const steps = [
      'Service',
      'Asset',
      'Purpose',
      'Details',
      'Documents',
      'Review',
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps.length, (index) {
        final stepNum = index + 1;
        final isDone = _wizardStep > stepNum;
        final isCurrent = _wizardStep == stepNum;

        return Row(
          children: [
            GestureDetector(
              onTap: isDone ? () => setState(() => _wizardStep = stepNum) : null,
              child: MouseRegion(
                cursor: isDone ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone
                            ? _LandingDesignSystem.tealBrand
                            : (isCurrent ? _LandingDesignSystem.tealBrand : Colors.transparent),
                        border: Border.all(
                          color: (isDone || isCurrent)
                              ? _LandingDesignSystem.tealBrand
                              : _LandingDesignSystem.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, size: 11, color: Colors.white)
                            : (isCurrent
                                ? Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  )
                                : Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _LandingDesignSystem.cardBorder,
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      steps[index],
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: isCurrent ? FontWeight.w700 : (isDone ? FontWeight.w600 : FontWeight.w500),
                        color: isCurrent
                            ? _LandingDesignSystem.tealBrand
                            : (isDone ? _LandingDesignSystem.textPrimary : _LandingDesignSystem.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (index < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 14,
                  height: 1.5,
                  color: isDone ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                ),
              ),
          ],
        );
      }),
    );
  }

  // FIX 6: Upgraded Service Practice Area Cards
  Widget _buildWizardStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _serviceCard(
              title: 'Asset Valuation',
              description: 'Professional valuation reports for banking, taxation, compliance and regulatory requirements.',
              iconText: '🏛️',
              isSelected: _wizardService == 'VALUATION',
              onTap: () => setState(() {
                _wizardService = 'VALUATION';
                _wizardStep = 2;
              }),
            ),
            const SizedBox(width: 18),
            _serviceCard(
              title: 'Net Worth Certification',
              description: 'Certified net worth statements for immigration, banking and statutory purposes.',
              iconText: '📜',
              isSelected: _wizardService == 'NET_WORTH',
              onTap: () => setState(() {
                _wizardService = 'NET_WORTH';
                _wizardStep = 2;
              }),
            ),
            const SizedBox(width: 18),
            _serviceCard(
              title: 'Technical Assessment',
              description: 'Independent technical inspection and certification services.',
              iconText: '⚙️',
              isSelected: _wizardService == 'CHARTERED_ENGINEER',
              onTap: () => setState(() {
                _wizardService = 'CHARTERED_ENGINEER';
                _wizardStep = 2;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _serviceCard({
    required String title,
    required String description,
    required String iconText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isSelected ? _LandingDesignSystem.tealSubtle : _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected ? _LandingDesignSystem.cardHoverShadow : _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _LandingDesignSystem.bgSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(iconText, style: const TextStyle(fontSize: 26)),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 22, color: _LandingDesignSystem.tealBrand),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: _LandingDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 2: Asset Involved
  Widget _buildWizardStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _assetCard(
              title: 'Land & Building',
              description: 'Commercial offices, industrial plots, flats, and developments',
              iconText: '🏢',
              isSelected: _wizardAsset == 'LAND_AND_BUILDING',
              onTap: () => setState(() {
                _wizardAsset = 'LAND_AND_BUILDING';
                _wizardStep = 3;
              }),
            ),
            const SizedBox(width: 18),
            _assetCard(
              title: 'Plant & Machinery',
              description: 'Industrial equipment, machinery lines, and manufacturing units',
              iconText: '🏭',
              isSelected: _wizardAsset == 'PLANT_AND_MACHINERY',
              onTap: () => setState(() {
                _wizardAsset = 'PLANT_AND_MACHINERY';
                _wizardStep = 3;
              }),
            ),
            const SizedBox(width: 18),
            _assetCard(
              title: 'Financial Assets',
              description: 'Securities, unlisted shares, and financial portfolios',
              iconText: '📊',
              isSelected: _wizardAsset == 'SECURITIES_FINANCIAL_ASSETS',
              onTap: () => setState(() {
                _wizardAsset = 'SECURITIES_FINANCIAL_ASSETS';
                _wizardStep = 3;
              }),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _secondaryButton(label: '← Back to Service', onTap: () => setState(() => _wizardStep = 1)),
      ],
    );
  }

  Widget _assetCard({
    required String title,
    required String description,
    required String iconText,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isSelected ? _LandingDesignSystem.tealSubtle : _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected ? _LandingDesignSystem.cardHoverShadow : _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : _LandingDesignSystem.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(iconText, style: const TextStyle(fontSize: 22)),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, size: 20, color: _LandingDesignSystem.tealBrand),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: _LandingDesignSystem.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // STEP 3: Purpose of Engagement
  Widget _buildWizardStep3() {
    final purposes = [
      {'key': 'BANK_COLLATERAL', 'title': 'Bank Collateral', 'sub': 'Mortgage & credit facility appraisal'},
      {'key': 'VISA_IMMIGRATION', 'title': 'Visa & Immigration', 'sub': 'Embassy verified wealth documentation'},
      {'key': 'TAX_STATUTORY', 'title': 'Tax & Statutory', 'sub': 'Capital gains & balance sheet filing'},
      {'key': 'INTERNAL_ACCOUNTING', 'title': 'Company Asset', 'sub': 'Corporate books & regulatory audit'},
      {'key': 'DISPUTE_RESOLUTION', 'title': 'Legal Settlement', 'sub': 'Court proceedings & family partition'},
      {'key': 'INSURANCE', 'title': 'Insurable Value', 'sub': 'Replacement cost & reinstatement coverage'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: purposes.map((p) {
            final isSel = _wizardPurpose == p['key'];
            return SizedBox(
              width: 310,
              child: GestureDetector(
                onTap: () => setState(() {
                  _wizardPurpose = p['key']!;
                  _wizardStep = 4;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSel ? _LandingDesignSystem.tealSubtle : _LandingDesignSystem.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                      width: isSel ? 1.8 : 1.0,
                    ),
                    boxShadow: isSel ? _LandingDesignSystem.cardHoverShadow : _LandingDesignSystem.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            p['title']!,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isSel ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textPrimary,
                            ),
                          ),
                          if (isSel)
                            const Icon(Icons.check_circle_rounded, size: 18, color: _LandingDesignSystem.tealBrand),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['sub']!,
                        style: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        _secondaryButton(label: '← Back to Asset Involved', onTap: () => setState(() => _wizardStep = 2)),
      ],
    );
  }

  // STEP 4: Asset Details
  Widget _buildWizardStep4() {
    InputDecoration fieldDec(String label, String hint, {String? prefix}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefix,
        labelStyle: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.textSecondary),
        hintStyle: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textMuted),
        prefixStyle: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.tealBrand),
        filled: true,
        fillColor: _LandingDesignSystem.bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _LandingDesignSystem.tealBrand, width: 1.6),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _LandingDesignSystem.cardBorder),
            boxShadow: _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _assetNameCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textPrimary),
                decoration: fieldDec('Subject Asset / Property Name *', 'e.g. Apex Horizon Tower 3'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _propertyAddressCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textPrimary),
                decoration: fieldDec('Full Property Location & Address *', 'Plot/Door No, Street, Landmark'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      onChanged: (_) => _onStep4FieldChanged(),
                      style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textPrimary),
                      decoration: fieldDec('City / District *', 'e.g. Hyderabad'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateCtrl,
                      onChanged: (_) => _onStep4FieldChanged(),
                      style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textPrimary),
                      decoration: fieldDec('State *', 'e.g. Telangana'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _estimatedValueCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textPrimary),
                decoration: fieldDec('Estimated Asset Value (₹)', '15000000', prefix: '₹ '),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _secondaryButton(label: '← Back to Purpose', onTap: () => setState(() => _wizardStep = 3)),
            if (_step4AutoAdvancing)
              Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _LandingDesignSystem.tealBrand),
                  ),
                  const SizedBox(width: 8),
                  Text('Advancing to documents...', style: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.tealBrand)),
                ],
              )
            else
              _primaryCtaButton(
                label: 'Continue to Documents',
                onTap: () {
                  if (_assetNameCtrl.text.trim().isEmpty || _propertyAddressCtrl.text.trim().isEmpty || _cityCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please provide all mandatory property details.')),
                    );
                    return;
                  }
                  setState(() => _wizardStep = 5);
                },
              ),
          ],
        ),
      ],
    );
  }

  // STEP 5: Supporting Documentation
  Widget _buildWizardStep5() {
    final slots = _getRequiredDocumentSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _LandingDesignSystem.cardBorder),
            boxShadow: _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...slots.map((slot) {
                final key = slot['key'] as String;
                final label = slot['label'] as String;
                final uploaded = _wizardDocs[key];

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: uploaded != null ? _LandingDesignSystem.tealSubtle : _LandingDesignSystem.bgCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: uploaded != null ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        uploaded != null ? Icons.check_circle_rounded : Icons.description_outlined,
                        size: 22,
                        color: uploaded != null ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
                            const SizedBox(height: 3),
                            Text(
                              uploaded != null ? '${uploaded.name} (${(uploaded.size / 1024).toStringAsFixed(1)} KB)' : 'PDF, JPG, PNG up to 25 MB',
                              style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (uploaded != null)
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18, color: _LandingDesignSystem.textSecondary),
                          onPressed: () => _removeWizardDoc(key),
                        )
                      else
                        GestureDetector(
                          onTap: () => _pickWizardDoc(key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: _LandingDesignSystem.tealBrand,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_file_rounded, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Upload',
                                  style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        _buildMissingDocsCard(),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _secondaryButton(label: '← Back to Details', onTap: () => setState(() => _wizardStep = 4)),
            _primaryCtaButton(
              label: 'Review Your Request',
              onTap: _areAllMandatoryDocsUploaded() ? () => setState(() => _wizardStep = 6) : null,
            ),
          ],
        ),
      ],
    );
  }

  // STEP 6: Review Your Request
  Widget _buildWizardStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_areAllMandatoryDocsUploaded()) ...[
          _buildMissingDocsCard(),
          const SizedBox(height: 16),
        ],
        if (_wizardError != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _LandingDesignSystem.stateErrorSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, size: 20, color: _LandingDesignSystem.stateError),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submission Blocked',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _LandingDesignSystem.stateError,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _wizardError!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: _LandingDesignSystem.stateError,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _LandingDesignSystem.cardBorder),
            boxShadow: _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            children: [
              _summaryRow('Service Type', _wizardService.replaceAll('_', ' ')),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Asset Category', _wizardAsset.replaceAll('_', ' ')),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Engagement Purpose', _wizardPurpose.replaceAll('_', ' ')),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Subject Property', _assetNameCtrl.text.isEmpty ? '—' : _assetNameCtrl.text),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Location', '${_cityCtrl.text}, ${_stateCtrl.text}'),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Estimated Market Value', '₹ ${_estimatedValueCtrl.text.isEmpty ? '1,50,00,000' : _estimatedValueCtrl.text}'),
              const Divider(height: 18, color: _LandingDesignSystem.cardBorder),
              _summaryRow('Supporting Documents', '${_wizardDocs.length} document(s) attached'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _secondaryButton(
              label: '← Edit Information',
              onTap: _wizardSubmitting ? null : () => setState(() => _wizardStep = 5),
            ),
            _wizardSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _LandingDesignSystem.tealBrand),
                  )
                : _primaryCtaButton(
                    label: 'Submit Request',
                    onTap: (_areAllMandatoryDocsUploaded() && !_wizardSubmitting) ? _submitWizardReport : null,
                  ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary)),
        Text(
          value,
          style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
        ),
      ],
    );
  }

  Widget _buildWizardSuccessScreen() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            color: _LandingDesignSystem.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _LandingDesignSystem.cardBorder),
            boxShadow: _LandingDesignSystem.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _LandingDesignSystem.tealSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: _LandingDesignSystem.tealBorder),
                ),
                child: const Icon(Icons.check_rounded, size: 36, color: _LandingDesignSystem.tealBrand),
              ),
              const SizedBox(height: 20),
              Text(
                'Valuation Request Received',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _LandingDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Your valuation mandate has been registered with our senior appraisal desk. Our registered valuers are reviewing your asset parameters.',
                style: GoogleFonts.inter(fontSize: 13.5, color: _LandingDesignSystem.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              _primaryCtaButton(
                label: 'Track Engagement',
                onTap: () {
                  setState(() {
                    _activeNav = _ClientNav.reportsInProgress;
                    _resetWizard();
                  });
                  _loadOrdersAndSync();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 2: REPORTS IN PROGRESS (Landing Page Design System)
  // Content-first experience: Welcome banner, prominent advisory cards.
  // ═════════════════════════════════════════════════════════════════════════
Widget _buildReportsInProgressGallery(OrderProvider orders) {
    final allOrders = orders.clientOrders;

    // 1. Needs Attention: Quote provided (awaiting acceptance), Payment rejected, or Action needed
    final needsAttentionOrders = allOrders.where((o) {
      final s = (o['status'] as String? ?? '').toUpperCase();
      final ps = (o['paymentStatus'] as String? ?? '').toUpperCase();
      if (s == 'QUOTE_PROVIDED' && ps != 'SUBMITTED' && ps != 'VERIFIED') return true;
      if (s == 'PAYMENT_REJECTED') return true;
      if (s == 'ACTION_NEEDED') return true;
      return false;
    }).toList();

    // 2. Active Reports: In-flight reports that do not require immediate client blocker action
    final activeOrders = allOrders.where((o) {
      final stage = _mapToClientStage(o);
      if (stage.stageIndex >= 5) return false;
      return !needsAttentionOrders.contains(o);
    }).toList();

    // 3. Delivered Reports: Concluded & certified reports available for download
    final deliveredOrders = allOrders.where((o) {
      return _mapToClientStage(o).stageIndex == 5;
    }).toList();

    // If client has zero total reports in database, show direct action launchpad
    if (allOrders.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _LandingDesignSystem.tealSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: _LandingDesignSystem.tealBorder),
                ),
                child: const Icon(Icons.article_outlined, size: 36, color: _LandingDesignSystem.tealBrand),
              ),
              const SizedBox(height: 20),
              Text(
                "You don't have any reports yet",
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _LandingDesignSystem.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a request to commission a property valuation or net worth certificate.',
                style: GoogleFonts.inter(fontSize: 14, color: _LandingDesignSystem.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _primaryCtaButton(
                label: '+ Start New Request',
                onTap: () {
                  setState(() {
                    _activeNav = _ClientNav.createReport;
                    _resetWizard();
                  });
                },
              ),
              const SizedBox(height: 36),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Row(
                  children: [
                    Expanded(
                      child: _emptyServiceOption(
                        title: 'Property Valuation',
                        desc: 'Commercial, industrial & residential asset appraisal for bank collateral.',
                        icon: Icons.business_outlined,
                        onTap: () {
                          setState(() {
                            _activeNav = _ClientNav.createReport;
                            _wizardAsset = 'COMMERCIAL';
                            _wizardService = 'VALUATION';
                            _wizardStep = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _emptyServiceOption(
                        title: 'Net Worth Certificate',
                        desc: 'Certified statement of personal or enterprise net assets for visa & banking.',
                        icon: Icons.account_balance_outlined,
                        onTap: () {
                          setState(() {
                            _activeNav = _ClientNav.createReport;
                            _wizardAsset = 'NET_WORTH';
                            _wizardService = 'NET_WORTH';
                            _wizardStep = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _emptyServiceOption(
                        title: 'Plant & Machinery',
                        desc: 'Depreciation appraisal and valuation of industrial plant & equipment.',
                        icon: Icons.precision_manufacturing_outlined,
                        onTap: () {
                          setState(() {
                            _activeNav = _ClientNav.createReport;
                            _wizardAsset = 'PLANT_AND_MACHINERY';
                            _wizardService = 'VALUATION';
                            _wizardStep = 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── TOP SUMMARY HEADER ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Reports',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _LandingDesignSystem.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  _metricPill(
                    label: '${activeOrders.length + needsAttentionOrders.length} Active',
                    bgColor: _LandingDesignSystem.tealSubtle,
                    borderColor: _LandingDesignSystem.tealBorder,
                    textColor: _LandingDesignSystem.tealBrand,
                  ),
                  if (needsAttentionOrders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _metricPill(
                      label: '${needsAttentionOrders.length} Needs Attention',
                      bgColor: _LandingDesignSystem.stateErrorSubtle,
                      borderColor: const Color(0xFFFECACA),
                      textColor: _LandingDesignSystem.stateError,
                    ),
                  ],
                  if (deliveredOrders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _metricPill(
                      label: '${deliveredOrders.length} Delivered',
                      bgColor: _LandingDesignSystem.stateSuccessSubtle,
                      borderColor: const Color(0xFFA7F3D0),
                      textColor: _LandingDesignSystem.stateSuccess,
                    ),
                  ],
                ],
              ),
              _secondaryButton(
                label: '+ Start New Request',
                onTap: () {
                  setState(() {
                    _activeNav = _ClientNav.createReport;
                    _resetWizard();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── SECTION 1: NEEDS ATTENTION (Sticky Top Priority) ──
          if (needsAttentionOrders.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: _LandingDesignSystem.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Text(
                        'NEEDS ATTENTION (${needsAttentionOrders.length})',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '• Action required from you to proceed',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF78350F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...needsAttentionOrders.map((order) => _buildNeedsAttentionCard(order)),
                ],
              ),
            ),
          ],

          // ── SECTION 2: ACTIVE REPORTS ──
          Text(
            'ACTIVE REPORTS (${activeOrders.length})',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: _LandingDesignSystem.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          if (activeOrders.isEmpty && needsAttentionOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _LandingDesignSystem.cardSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _LandingDesignSystem.cardBorder),
              ),
              child: Text(
                'No active reports currently undergoing inspection or preparation.',
                style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary),
              ),
            )
          else
            ...activeOrders.map((order) => _buildCompactActiveReportCard(order)),

          const SizedBox(height: 24),

          // ── SECTION 3: DELIVERED REPORTS ──
          if (deliveredOrders.isNotEmpty) ...[
            Text(
              'DELIVERED REPORTS (${deliveredOrders.length})',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _LandingDesignSystem.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: _LandingDesignSystem.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _LandingDesignSystem.cardBorder),
                boxShadow: _LandingDesignSystem.cardShadow,
              ),
              child: Column(
                children: deliveredOrders.map((order) => _buildDeliveredReportRow(order)).toList(),
              ),
            ),
          ],

          // ── SECTION 4: DIRECT SUPPORT STRIP ──
          _buildCompactSupportStrip(),
        ],
      ),
    );
  }

  Widget _metricPill({
    required String label,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNeedsAttentionCard(dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final status = (order['status'] as String? ?? '').toUpperCase();
    final assetName = order['assetName'] != null && order['assetName'].toString().isNotEmpty
        ? order['assetName'].toString()
        : '$title Valuation';

    final isQuote = status == 'QUOTE_PROVIDED';
    final isPaymentRejected = status == 'PAYMENT_REJECTED';

    String actionMsg = 'Additional action required from client to proceed.';
    if (isQuote) {
      actionMsg = 'Valuation quotation and service scope are ready for your review and approval.';
    } else if (isPaymentRejected) {
      actionMsg = 'Payment remittance could not be matched. Please re-submit your transaction reference.';
    } else if (status == 'ACTION_NEEDED') {
      actionMsg = 'Additional property deeds or sanction plans requested by valuation desk.';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded, size: 20, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: _LandingDesignSystem.bgSubtle,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: _LandingDesignSystem.cardBorder),
                      ),
                      child: Text(
                        refCode,
                        style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      assetName,
                      style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  actionMsg,
                  style: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isQuote)
                _primaryCtaButton(
                  label: 'Review Quotation',
                  onTap: () => _showQuotationModal(order),
                )
              else if (isPaymentRejected)
                _primaryCtaButton(
                  label: 'Re-submit Payment',
                  onTap: () => _showPaymentModal(order),
                )
              else
                _primaryCtaButton(
                  label: 'Upload Documents',
                  onTap: () => _uploadAdditionalDocument(orderId),
                ),
              const SizedBox(width: 8),
              _secondaryButton(
                label: 'View Details',
                onTap: () => setState(() => _focusedActiveOrder = order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActiveReportCard(dynamic order) {
    final stageInfo = _mapToClientStage(order);
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final purpose = (order['purpose'] ?? 'Bank Collateral').toString().replaceAll('_', ' ');
    final assetName = order['assetName'] != null && order['assetName'].toString().isNotEmpty
        ? order['assetName'].toString()
        : '$title Valuation';
    final isActionNeeded = (order['status'] as String? ?? '').toUpperCase() == 'ACTION_NEEDED';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
        boxShadow: _LandingDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category, Ref, Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: _LandingDesignSystem.tealBrand,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _LandingDesignSystem.bgSubtle,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _LandingDesignSystem.cardBorder),
                    ),
                    child: Text(
                      refCode,
                      style: GoogleFonts.robotoMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _LandingDesignSystem.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: _LandingDesignSystem.tealSubtle,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: _LandingDesignSystem.tealBorder),
                ),
                child: Text(
                  stageInfo.statusBadge,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _LandingDesignSystem.tealBrand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Asset Name • Purpose
          Text(
            '$assetName • Purpose: $purpose',
            style: GoogleFonts.montserrat(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _LandingDesignSystem.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Row 3: Progress Tracker
          _buildInlineProgressTracker(stageInfo.stageIndex),
          const SizedBox(height: 12),

          // Row 4: Last update & View Details button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Last Update: ${stageInfo.statusDescription}',
                  style: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActionNeeded) ...[
                    _secondaryButton(
                      label: 'Upload Documents',
                      onTap: () => _uploadAdditionalDocument(orderId),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _secondaryButton(
                    label: 'View Details',
                    onTap: () => setState(() => _focusedActiveOrder = order),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredReportRow(dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final assetName = order['assetName'] != null && order['assetName'].toString().isNotEmpty
        ? order['assetName'].toString()
        : '$title Valuation';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _LandingDesignSystem.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: _LandingDesignSystem.stateSuccessSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, size: 18, color: _LandingDesignSystem.stateSuccess),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _LandingDesignSystem.bgSubtle,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _LandingDesignSystem.cardBorder),
                  ),
                  child: Text(
                    refCode,
                    style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    assetName,
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _LandingDesignSystem.stateSuccessSubtle,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Text(
              'Ready for Download',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _LandingDesignSystem.stateSuccess),
            ),
          ),
          const SizedBox(width: 14),
          _primaryCtaButton(
            label: 'Download PDF',
            onTap: () => _downloadFinalReport(refCode),
          ),
          const SizedBox(width: 8),
          _secondaryButton(
            label: 'Invoice',
            onTap: () => _downloadTaxInvoice(orderId),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSupportStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 18, color: _LandingDesignSystem.tealBrand),
              const SizedBox(width: 10),
              Text(
                'Need assistance? Direct Valuer Desk: +91 85000 19091 • provaluer.india@gmail.com • Mon–Sat 9AM–7PM IST',
                style: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.textSecondary),
              ),
            ],
          ),
          _secondaryButton(
            label: 'Contact Support',
            onTap: _showSupportDialog,
          ),
        ],
      ),
    );
  }

  Widget _emptyServiceOption({
    required String title,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _LandingDesignSystem.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _LandingDesignSystem.cardBorder),
          boxShadow: _LandingDesignSystem.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: _LandingDesignSystem.tealBrand),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              desc,
              style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineProgressTracker(int activeIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: List.generate(6, (index) {
            final isDone = index < activeIndex;
            final isCurrent = index == activeIndex;

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? _LandingDesignSystem.tealBrand
                          : (isCurrent ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.bgSubtle),
                      border: Border.all(
                        color: (isDone || isCurrent) ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 10, color: Colors.white)
                          : (isCurrent
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                )
                              : const SizedBox.shrink()),
                    ),
                  ),
                  if (index < 5)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                      ),
                    ),
                ],
              ),
            );
          }),
        );
      },
    );
  }

    Widget _buildActiveReportWorkspace(dynamic order, OrderProvider orders) {
    final stageInfo = _mapToClientStage(order);
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
    final createdDate = order['createdAt'] != null ? order['createdAt'].toString().split('T').first : 'Recent';
    final reportNumber = order['reportNumber'] ?? 'PV-2026-PENDING';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb Back
          GestureDetector(
            onTap: () => setState(() => _focusedActiveOrder = null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: _LandingDesignSystem.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Back to Reports',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _LandingDesignSystem.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // SECTION 1: REPORT HEADER
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _LandingDesignSystem.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _LandingDesignSystem.cardBorder),
              boxShadow: _LandingDesignSystem.cardShadow,
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
                            color: _LandingDesignSystem.bgSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _LandingDesignSystem.cardBorder),
                          ),
                          child: Text(
                            refCode,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _LandingDesignSystem.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _LandingDesignSystem.tealSubtle,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _LandingDesignSystem.tealBorder),
                          ),
                          child: Text(
                            stageInfo.statusBadge,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: _LandingDesignSystem.tealBrand,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Report No: $reportNumber',
                      style: GoogleFonts.robotoMono(fontSize: 12, color: _LandingDesignSystem.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purpose: ${order['purpose'] != null ? order['purpose'].toString().replaceAll('_', ' ') : 'Valuation Mandate'}',
                  style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary),
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: _LandingDesignSystem.cardBorder),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _headerMetaCol('Created Date', createdDate),
                    const SizedBox(width: 40),
                    _headerMetaCol('Expected Completion', '3 Business Days'),
                    const SizedBox(width: 40),
                    _headerMetaCol('Subject Category', order['propertyCategory']?.toString().replaceAll('_', ' ') ?? 'Real Estate'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // SECTION 2: CLIENT PROGRESS TRACKER (6 Human Advisory Stages)
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _LandingDesignSystem.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _LandingDesignSystem.cardBorder),
              boxShadow: _LandingDesignSystem.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Progress',
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                ),
                const SizedBox(height: 20),
                _buildClientProgressTracker(stageInfo.stageIndex),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // SECTION 3: STATUS HERO ACTION
          _buildStatusHeroAction(stageInfo, order),
          const SizedBox(height: 22),

          // SECTION 4: WORKSPACE DOCUMENTS
          _buildWorkspaceDocumentsList(order),
          const SizedBox(height: 22),

          // SECTION 5: TIMELINE / RECENT ACTIVITY
          _buildUpdatesTimeline(stageInfo.stageIndex, createdDate),
          const SizedBox(height: 22),

          // SECTION 6: CONTEXTUAL ACTION CENTER
          _buildContextualActionCenter(stageInfo, order),
          const SizedBox(height: 22),

          // SECTION 7: SUPPORT CONCIERGE BANNER
          _buildSupportConciergeBanner(),
        ],
      ),
    );
  }

  Widget _headerMetaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary)),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
      ],
    );
  }

  Widget _buildClientProgressTracker(int activeIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        if (isMobile) {
          return Column(
            children: List.generate(_kClientStages.length, (i) {
              final isDone = i < activeIndex;
              final isCurrent = i == activeIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : (isCurrent ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded),
                      size: 18,
                      color: (isDone || isCurrent) ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _kClientStages[i],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(_kClientStages.length, (i) {
            final isDone = i < activeIndex;
            final isCurrent = i == activeIndex;

            return Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == 0 ? Colors.transparent : (i <= activeIndex ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? _LandingDesignSystem.tealBrand
                              : (isCurrent ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.bgSubtle),
                          border: Border.all(
                            color: (isDone || isCurrent) ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : Text(
                                  '${i + 1}',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? Colors.white : _LandingDesignSystem.textSecondary,
                                  ),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == _kClientStages.length - 1
                              ? Colors.transparent
                              : (i < activeIndex ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _kClientStages[i],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textSecondary,
                    ),
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
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
        boxShadow: _LandingDesignSystem.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _LandingDesignSystem.tealSubtle,
              shape: BoxShape.circle,
              border: Border.all(color: _LandingDesignSystem.tealBorder),
            ),
            child: const Center(
              child: Icon(Icons.verified_outlined, size: 24, color: _LandingDesignSystem.tealBrand),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageInfo.stageTitle,
                  style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  stageInfo.statusDescription,
                  style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (stageInfo.stageIndex == 2)
            _primaryCtaButton(
              label: 'View Proposal',
              onTap: () => _showQuotationModal(order),
            )
          else if (stageInfo.stageIndex == 5 && order['referenceCode'] != null)
            _primaryCtaButton(
              label: 'Download Report',
              onTap: () => _downloadFinalReport(order['referenceCode'].toString()),
            ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceDocumentsList(dynamic order) {
    final orderId = order['id'] as int;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
        boxShadow: _LandingDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Supporting Documents',
                style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
              ),
              TextButton.icon(
                onPressed: () => _uploadAdditionalDocument(orderId),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Document'),
                style: TextButton.styleFrom(
                  foregroundColor: _LandingDesignSystem.tealBrand,
                  textStyle: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _docItemRow('Title Deed / Registered Sale Deed', 'Verified by Desk', true),
          const SizedBox(height: 8),
          _docItemRow('Approved Sanction Plan', 'Document Attached', false),
          const SizedBox(height: 8),
          _docItemRow('Property Tax Receipt', 'Document Attached', false),
        ],
      ),
    );
  }

  Widget _docItemRow(String name, String status, bool verified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.bgCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 18, color: _LandingDesignSystem.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: _LandingDesignSystem.textPrimary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: verified ? _LandingDesignSystem.stateSuccessSubtle : _LandingDesignSystem.bgSubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: verified ? _LandingDesignSystem.stateSuccess : _LandingDesignSystem.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesTimeline(int currentStageIndex, String createdDate) {
    final events = [
      {'title': 'Valuation Request Received', 'time': createdDate, 'done': true},
      {'title': 'Desk Review & Benchmark Analysis', 'time': 'In Progress', 'done': currentStageIndex >= 1},
      {'title': 'Proposal & SLA Schedule Issued', 'time': 'Pending', 'done': currentStageIndex >= 2},
      {'title': 'Remittance Verification & Confirmed Engagement', 'time': 'Pending', 'done': currentStageIndex >= 3},
      {'title': 'Asset Appraisal & Report Compilation', 'time': 'Pending', 'done': currentStageIndex >= 4},
      {'title': 'Certified Valuation Report Ready', 'time': 'Pending', 'done': currentStageIndex >= 5},
    ];

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
        boxShadow: _LandingDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Advisory Activity',
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
          ),
          const SizedBox(height: 18),
          ...events.map((e) {
            final isDone = e['done'] as bool;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.cardBorder,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      e['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
                        color: isDone ? _LandingDesignSystem.textPrimary : _LandingDesignSystem.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    e['time'] as String,
                    style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContextualActionCenter(_ClientStageInfo stageInfo, dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
        boxShadow: _LandingDesignSystem.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Engagement Actions',
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (stageInfo.stageIndex == 2) ...[
                _primaryCtaButton(
                  label: 'View Proposal',
                  onTap: () => _showQuotationModal(order),
                ),
                _secondaryButton(
                  label: 'Download Proposal PDF',
                  onTap: () => _downloadQuotePdf(orderId),
                ),
              ],
              if (stageInfo.stageIndex == 5) ...[
                _primaryCtaButton(
                  label: 'Download Certified Report',
                  onTap: () => _downloadFinalReport(refCode),
                ),
                _secondaryButton(
                  label: 'Download Commercial Invoice',
                  onTap: () => _downloadTaxInvoice(orderId),
                ),
              ],
              _secondaryButton(
                label: 'Request Clarification',
                onTap: () => _requestReportClarification(refCode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportConciergeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: _LandingDesignSystem.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _LandingDesignSystem.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('🎧', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dedicated Valuation Advisory Desk',
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
                  ),
                  Text(
                    'Direct contact for inquiries regarding this engagement',
                    style: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text('📞 +91 85000 19091', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
              const SizedBox(width: 16),
              Text('✉️ provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 4: COMPLETED REPORTS (Landing Page Design System)
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
                  color: _LandingDesignSystem.tealSubtle,
                  shape: BoxShape.circle,
                  border: Border.all(color: _LandingDesignSystem.tealBorder),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 36, color: _LandingDesignSystem.tealBrand),
              ),
              const SizedBox(height: 18),
              Text(
                'No Completed Reports Yet',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Your concluded and digitally signed reports will be archived here for statutory records.',
                style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completed Valuation Records',
            style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Statutorily certified valuation reports archived under digital compliance.',
            style: GoogleFonts.inter(fontSize: 13.5, color: _LandingDesignSystem.textSecondary),
          ),
          const SizedBox(height: 24),
          ...completedOrders.map((order) {
            final orderId = order['id'] as int;
            final refCode = order['referenceCode'] ?? 'REQ-$orderId';
            final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _LandingDesignSystem.cardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _LandingDesignSystem.cardBorder),
                boxShadow: _LandingDesignSystem.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: _LandingDesignSystem.stateSuccessSubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified_rounded, size: 20, color: _LandingDesignSystem.stateSuccess),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(refCode, style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                        const SizedBox(height: 2),
                        Text(title, style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                      ],
                    ),
                  ),
                  _primaryCtaButton(
                    label: 'Download Report',
                    onTap: () => _downloadFinalReport(refCode),
                  ),
                  const SizedBox(width: 10),
                  _secondaryButton(
                    label: 'Invoice',
                    onTap: () => _downloadTaxInvoice(orderId),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletedReportWorkspace(dynamic order, OrderProvider orders) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';
    final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _focusedCompletedOrder = null),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16, color: _LandingDesignSystem.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Back to Reports',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _LandingDesignSystem.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: _LandingDesignSystem.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _LandingDesignSystem.cardBorder),
              boxShadow: _LandingDesignSystem.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(refCode, style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                const SizedBox(height: 4),
                Text(title, style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _primaryCtaButton(label: 'Download Certified PDF', onTap: () => _downloadFinalReport(refCode)),
                    const SizedBox(width: 12),
                    _secondaryButton(label: 'Download Commercial Invoice', onTap: () => _downloadTaxInvoice(orderId)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS (Landing Page Design System)
  // ═════════════════════════════════════════════════════════════════════════
  void _showProfileDialog(AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LandingDesignSystem.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        title: Text(
          'Client Account Details',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _profileField('Full Name', auth.fullName ?? 'Client Officer'),
            _profileField('Email Address', auth.email ?? 'client@provaluer.com'),
            _profileField('Role', auth.role ?? 'CLIENT'),
          ],
        ),
        actions: [
          _secondaryButton(label: 'Close', onTap: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LandingDesignSystem.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        title: Text(
          'Appraisal Concierge Support',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contact our Senior Appraisal Concierge Desk directly:', style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textSecondary)),
            const SizedBox(height: 14),
            Text('📞 Phone: +91 85000 19091', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
            const SizedBox(height: 6),
            Text('✉️ Email: provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textPrimary)),
          ],
        ),
        actions: [
          _secondaryButton(label: 'Close', onTap: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  void _showQuotationModal(dynamic order) {
    final orderId = order['id'] as int;
    final double fee = (order['quoteAmount'] as num?)?.toDouble() ??
        ((order['estimatedValue'] as num? ?? 18500000) > 10000000 ? 18500.0 : 12500.0);
    final double gst = (order['quoteTax'] as num?)?.toDouble() ?? (fee * 0.18);
    final double total = (order['quoteTotal'] as num?)?.toDouble() ?? (fee + gst);
    final String quoteNum = order['quoteNumber']?.toString() ?? 'QTE-$orderId';
    final String turnaround = order['quoteTurnaround']?.toString() ?? '3 Business Days from payment credit.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LandingDesignSystem.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        title: Text(
          'Official Valuation Proposal',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary, fontSize: 16),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mandate: ${order['referenceCode'] ?? 'REQ-$orderId'}', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _LandingDesignSystem.textSecondary)),
                    Text(quoteNum, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.tealBrand)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _LandingDesignSystem.bgCanvas,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _LandingDesignSystem.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Base Appraisal Fee', '₹ ${fee.toStringAsFixed(2)}'),
                      const Divider(height: 14, color: _LandingDesignSystem.cardBorder),
                      _summaryRow('GST (18%)', '₹ ${gst.toStringAsFixed(2)}'),
                      const Divider(height: 14, color: _LandingDesignSystem.cardBorder),
                      _summaryRow('Total Remittance', '₹ ${total.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _LandingDesignSystem.bgCanvas,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _LandingDesignSystem.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bank Remittance Account Details', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Beneficiary: ProValuer Valuation & Advisory Services Pvt Ltd', style: GoogleFonts.inter(fontSize: 11, color: _LandingDesignSystem.textSecondary)),
                      Text('Bank: HDFC Bank Ltd | A/C: 50200088912345 (Current)', style: GoogleFonts.inter(fontSize: 11, color: _LandingDesignSystem.textSecondary)),
                      Text('IFSC: HDFC0001234 | UPI: provaluer.commercial@hdfcbank', style: GoogleFonts.inter(fontSize: 11, color: _LandingDesignSystem.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('Turnaround SLA: $turnaround', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: _LandingDesignSystem.textSecondary)),
              ],
            ),
          ),
        ),
        actions: [
          _secondaryButton(label: 'Close', onTap: () => Navigator.pop(ctx)),
          _secondaryButton(
            label: 'Download PDF',
            onTap: () {
              Navigator.pop(ctx);
              _downloadQuotePdf(orderId);
            },
          ),
          _primaryCtaButton(
            label: 'Accept & Proceed',
            onTap: () {
              Navigator.pop(ctx);
              _showPaymentModal(order);
            },
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(dynamic order) {
    final orderId = order['id'] as int;
    final double fee = (order['quoteAmount'] as num?)?.toDouble() ??
        ((order['estimatedValue'] as num? ?? 18500000) > 10000000 ? 18500.0 : 12500.0);
    final double total = (order['quoteTotal'] as num?)?.toDouble() ?? (fee * 1.18);

    _paymentAmountCtrl.text = total.toStringAsFixed(2);
    _utrCtrl.clear();
    _paymentError = null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: _LandingDesignSystem.bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: _LandingDesignSystem.cardBorder),
          ),
          title: Text(
            'Remittance & UTR Submission',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary, fontSize: 16),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _LandingDesignSystem.bgCanvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _LandingDesignSystem.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bank Remittance Account Details', style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary)),
                        const SizedBox(height: 6),
                        Text('A/C Name: ProValuer Valuation & Advisory Services Pvt Ltd', style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary)),
                        Text('Bank: HDFC Bank Ltd | A/C: 50200088912345', style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary)),
                        Text('IFSC: HDFC0001234 | UPI: provaluer.commercial@hdfcbank', style: GoogleFonts.inter(fontSize: 11.5, color: _LandingDesignSystem.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _utrCtrl,
                    style: GoogleFonts.inter(fontSize: 13.5, color: _LandingDesignSystem.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Bank UTR / Transaction Reference *',
                      labelStyle: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.textSecondary),
                      filled: true,
                      fillColor: _LandingDesignSystem.bgCanvas,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _LandingDesignSystem.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _LandingDesignSystem.cardBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _LandingDesignSystem.tealBrand, width: 1.5)),
                    ),
                  ),
                  if (_paymentError != null) ...[
                    const SizedBox(height: 12),
                    Text(_paymentError!, style: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.stateError)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            _secondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
            _primaryCtaButton(
              label: 'Submit Payment Proof',
              onTap: () async {
                final utr = _utrCtrl.text.trim();
                if (utr.isEmpty) {
                  setDlgState(() => _paymentError = 'Please enter your bank UTR reference.');
                  return;
                }
                setDlgState(() => _paymentError = null);
                try {
                  final orderProvider = context.read<OrderProvider>();
                  final messenger = ScaffoldMessenger.of(context);
                  await orderProvider.submitPaymentProof(
                    orderId: orderId,
                    utrNumber: utr,
                    paymentMethod: 'UPI',
                    paymentDate: DateTime.now().toIso8601String().split('T').first,
                    amountPaid: total,
                    fileBytes: _paymentReceiptFile?.bytes ?? [0],
                    filename: _paymentReceiptFile?.name ?? 'payment_receipt.png',
                  );
                  await orderProvider.fetchClientOrders();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted) {
                    _loadOrdersAndSync();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Payment details submitted for verification.')),
                    );
                  }
                } catch (e) {
                  setDlgState(() => _paymentError = e.toString().replaceAll('Exception: ', ''));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAdditionalDocument(int orderId) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      if (f.bytes != null) {
        if (!mounted) return;
        final orderProvider = context.read<OrderProvider>();
        final messenger = ScaffoldMessenger.of(context);
        await orderProvider.uploadDocument(
          orderId,
          'ADDITIONAL_SUPPORTING',
          f.name,
          f.bytes!,
        );
        await orderProvider.fetchClientOrders();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully.')),
          );
        }
      }
    }
  }

  void _triggerBrowserFileDownload(Uint8List bytes, String filename, String mimeType) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _downloadQuotePdf(int orderId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating and downloading quotation PDF for Order #$orderId...')),
    );
    try {
      final orderProvider = context.read<OrderProvider>();
      final bytes = await orderProvider.downloadQuotePdf(orderId);
      if (bytes != null && bytes.isNotEmpty) {
        _triggerBrowserFileDownload(bytes, 'Quotation_Order_$orderId.pdf', 'application/pdf');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text('Quotation PDF downloaded successfully.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFEF4444),
              content: Text('Unable to download Quotation PDF. Please verify quote has been issued.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Download failed: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    }
  }

  Future<void> _downloadFinalReport(String refCode) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating secure download token for $refCode...')),
    );
    try {
      final orderProvider = context.read<OrderProvider>();
      final tokenData = await orderProvider.generateDeliveryToken(refCode, fileType: 'REPORT_PDF');
      if (tokenData != null && tokenData['token'] != null) {
        final token = tokenData['token'].toString();
        final bytes = await orderProvider.streamDeliveryFile(token);
        if (bytes != null && bytes.isNotEmpty) {
          _triggerBrowserFileDownload(bytes, 'Valuation_Report_${refCode}_Secured.pdf', 'application/pdf');
          await orderProvider.fetchClientOrders();
          if (mounted) {
            _loadOrdersAndSync();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text('Signed valuation report downloaded successfully.'),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFEF4444),
                content: Text(orderProvider.lastError ?? 'Failed to stream valuation report.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text(orderProvider.lastError ?? 'Valuation report is not yet released for client delivery.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Report download failed: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    }
  }

  Future<void> _downloadTaxInvoice(int orderId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating download token for Order #$orderId Tax Invoice...')),
    );
    try {
      final orderProvider = context.read<OrderProvider>();
      final order = orderProvider.clientOrders.firstWhere(
        (o) => o['id'] == orderId,
        orElse: () => <String, dynamic>{},
      );
      final refCode = (order['referenceCode'] != null && order['referenceCode'].toString().isNotEmpty)
          ? order['referenceCode'].toString()
          : orderId.toString();

      final tokenData = await orderProvider.generateDeliveryToken(refCode, fileType: 'INVOICE_PDF');
      if (tokenData != null && tokenData['token'] != null) {
        final token = tokenData['token'].toString();
        final bytes = await orderProvider.streamDeliveryFile(token);
        if (bytes != null && bytes.isNotEmpty) {
          _triggerBrowserFileDownload(bytes, 'Tax_Invoice_$refCode.pdf', 'application/pdf');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Color(0xFF10B981),
                content: Text('Commercial tax invoice downloaded successfully.'),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFEF4444),
                content: Text(orderProvider.lastError ?? 'Failed to stream tax invoice.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFEF4444),
              content: Text(orderProvider.lastError ?? 'Tax invoice is not yet available for this order.'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFEF4444),
            content: Text('Invoice download failed: ${e.toString().replaceAll('Exception: ', '')}'),
          ),
        );
      }
    }
  }

  void _requestReportClarification(String refCode) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _LandingDesignSystem.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _LandingDesignSystem.cardBorder),
        ),
        title: Text(
          'Request Clarification',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: _LandingDesignSystem.textPrimary, fontSize: 16),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Clarification inquiry for $refCode:', style: GoogleFonts.inter(fontSize: 12.5, color: _LandingDesignSystem.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 13, color: _LandingDesignSystem.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter your inquiry...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: _LandingDesignSystem.textMuted),
                  filled: true,
                  fillColor: _LandingDesignSystem.bgCanvas,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _LandingDesignSystem.cardBorder)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          _secondaryButton(label: 'Cancel', onTap: () => Navigator.pop(ctx)),
          _primaryCtaButton(
            label: 'Send Inquiry',
            onTap: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry routed to senior appraisal desk.')),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Refined Button Hierarchy (Calm, Professional, Non-Dominant) ───────────
  // Primary Action: Only ONE action per screen uses teal, with reduced height (~18%).
  static Widget _primaryCtaButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool showArrow = true,
  }) {
    return _RefinedPrimaryButton(
      label: label,
      onTap: onTap,
      icon: icon,
      showArrow: showArrow,
    );
  }

  // Soft Advisory Button: Neutral background #F5F7F8, border #DDE5EA, text #334155.
  // Supports content instead of competing with it.
  static Widget _secondaryButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool showArrow = false,
  }) {
    return _SoftAdvisoryButton(
      label: label,
      onTap: onTap,
      icon: icon,
      showArrow: showArrow,
    );
  }

  static Widget _advisoryButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool showArrow = true,
  }) {
    return _SoftAdvisoryButton(
      label: label,
      onTap: onTap,
      icon: icon,
      showArrow: showArrow,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Soft Advisory Button (Default Portal Style)
// Background: #F5F7F8, Border: #DDE5EA, Text: #334155
// Height reduced by ~18% (padding: 14h, 7.5v)
// ─────────────────────────────────────────────────────────────────────────────
class _SoftAdvisoryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showArrow;

  const _SoftAdvisoryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.showArrow = false,
  });

  @override
  State<_SoftAdvisoryButton> createState() => _SoftAdvisoryButtonState();
}

class _SoftAdvisoryButtonState extends State<_SoftAdvisoryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
          decoration: BoxDecoration(
            color: !enabled
                ? const Color(0xFFF1F5F9)
                : (_hovered
                    ? _LandingDesignSystem.buttonNeutralHoverBg
                    : _LandingDesignSystem.buttonNeutralBg),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !enabled
                  ? const Color(0xFFE2E8F0)
                  : (_hovered
                      ? _LandingDesignSystem.buttonNeutralHoverBorder
                      : _LandingDesignSystem.buttonNeutralBorder),
              width: 1.0,
            ),
            boxShadow: enabled ? _LandingDesignSystem.buttonNeutralShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: enabled ? _LandingDesignSystem.buttonNeutralText : _LandingDesignSystem.textMuted),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? _LandingDesignSystem.buttonNeutralText : _LandingDesignSystem.textMuted,
                ),
              ),
              if (widget.showArrow && !widget.label.contains('→') && !widget.label.contains('←')) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 13,
                  color: enabled ? _LandingDesignSystem.buttonNeutralText : _LandingDesignSystem.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Refined Primary Action Button
// Calibrated Deep Teal (#005C5C) fill for ONE primary action per screen.
// Reduced height (~18%), subtle shadow without marketing glow.
// ─────────────────────────────────────────────────────────────────────────────
class _RefinedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool showArrow;

  const _RefinedPrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.showArrow = true,
  });

  @override
  State<_RefinedPrimaryButton> createState() => _RefinedPrimaryButtonState();
}

class _RefinedPrimaryButtonState extends State<_RefinedPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
          decoration: BoxDecoration(
            color: !enabled
                ? const Color(0xFFE2E8F0)
                : (_hovered ? const Color(0xFF007373) : _LandingDesignSystem.tealBrand),
            borderRadius: BorderRadius.circular(8),
            boxShadow: enabled ? _LandingDesignSystem.buttonPrimaryShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.white : _LandingDesignSystem.textMuted,
                  letterSpacing: -0.2,
                ),
              ),
              if (widget.showArrow && !widget.label.contains('→')) ...[
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Client Sidebar (Landing Page Design System)
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
    // FIX 4: Reduce sidebar width by 18% so content dominates
    final width = collapsed ? 64.0 : 210.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: _LandingDesignSystem.bgSurface,
        border: Border(right: BorderSide(color: _LandingDesignSystem.cardBorder)),
      ),
      child: Column(
        children: [
          // Logo Header — compact, refined
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_LandingDesignSystem.tealBrand, Color(0xFF0F766E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('PV', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ProValuer', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w800, color: _LandingDesignSystem.textPrimary)),
                        Text('Advisory Workspace', style: GoogleFonts.inter(fontSize: 10, color: _LandingDesignSystem.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _LandingDesignSystem.cardBorder),

          // ── CORE NAVIGATION ITEMS (FIX 5) ─────────────────────────────────
          const SizedBox(height: 10),
          _navTile(
            nav: _ClientNav.createReport,
            label: _ClientNav.createReport.label,
            icon: _ClientNav.createReport.icon,
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

          // ── PREFERENCES & ACTIONS (FIX 5: Client Profile & Your Advisory Desk) ──
          const Divider(height: 1, color: _LandingDesignSystem.cardBorder),
          _actionTile(
            label: 'Client Profile',
            icon: Icons.person_outline_rounded,
            onTap: onProfileTap,
          ),
          _actionTile(
            label: 'Your Advisory Desk',
            icon: Icons.support_agent_rounded,
            onTap: onSupportTap,
          ),
          _actionTile(
            label: 'Sign Out',
            icon: Icons.logout_rounded,
            iconColor: _LandingDesignSystem.stateError,
            onTap: onSignOut,
          ),
          const Divider(height: 1, color: _LandingDesignSystem.cardBorder),

          // Collapse Toggle
          ListTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            leading: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: _LandingDesignSystem.textSecondary, size: 16),
            title: collapsed ? null : const Text('Collapse', style: TextStyle(color: _LandingDesignSystem.textSecondary, fontSize: 11)),
            onTap: onToggleCollapse,
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _navTile({
    required _ClientNav nav,
    required String label,
    required IconData icon,
  }) {
    final isActive = activeNav == nav;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => onNavSelect(nav),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
          decoration: BoxDecoration(
            color: isActive ? _LandingDesignSystem.tealSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? _LandingDesignSystem.tealBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              if (isActive)
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: _LandingDesignSystem.tealBrand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              Icon(
                icon,
                size: 17,
                color: isActive ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textSecondary,
              ),
              if (!collapsed) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? _LandingDesignSystem.tealBrand : _LandingDesignSystem.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      leading: Icon(icon, size: 17, color: iconColor ?? _LandingDesignSystem.textSecondary),
      title: collapsed ? null : Text(label, style: GoogleFonts.inter(fontSize: 12, color: iconColor ?? _LandingDesignSystem.textSecondary)),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Client Top Header Bar (Landing Page Design System)
// ─────────────────────────────────────────────────────────────────────────────
class _ClientTopHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _ClientTopHeader({
    required this.title,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // TOP NAVIGATION CTA: Option C — Removed completely.
    // The portal focuses on Current Engagements, not creating another request.
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: _LandingDesignSystem.bgSurface,
        border: Border(bottom: BorderSide(color: _LandingDesignSystem.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _LandingDesignSystem.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18, color: _LandingDesignSystem.textSecondary),
            tooltip: 'Refresh Workspace',
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
