// ─────────────────────────────────────────────────────────────────────────────
// ClientWorkspaceHub
// Unified Client Portal — Evolved Target Architecture
// Route: /client
// Preserves entire existing production backend, state machine, and API contracts.
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';

// ─── Final Client Navigation Menu (Section 11 Specification) ──────────────────
enum _Section {
  overview,
  myProjects,
  newRequest,
  documentsVault,
  quotations,
  paymentsBilling,
  trackingEngine,
  deliverables,
  taxInvoices,
  complianceSupport,
}

extension _SectionMeta on _Section {
  String get label => switch (this) {
        _Section.overview => 'Overview',
        _Section.myProjects => 'My Projects',
        _Section.newRequest => 'New Request',
        _Section.documentsVault => 'Documents Vault',
        _Section.quotations => 'Quotations',
        _Section.paymentsBilling => 'Payments & Billing',
        _Section.trackingEngine => 'Tracking Engine',
        _Section.deliverables => 'Deliverables',
        _Section.taxInvoices => 'Tax Invoices',
        _Section.complianceSupport => 'Compliance & Support',
      };

  IconData get icon => switch (this) {
        _Section.overview => Icons.dashboard_outlined,
        _Section.myProjects => Icons.folder_open_outlined,
        _Section.newRequest => Icons.add_circle_outline,
        _Section.documentsVault => Icons.shield_outlined,
        _Section.quotations => Icons.receipt_long_outlined,
        _Section.paymentsBilling => Icons.payment_outlined,
        _Section.trackingEngine => Icons.track_changes_outlined,
        _Section.deliverables => Icons.download_outlined,
        _Section.taxInvoices => Icons.receipt_outlined,
        _Section.complianceSupport => Icons.headset_mic_outlined,
      };
}

// ─── 16 Canonical Production Lifecycle Stages ─────────────────────────────────
enum _StageId {
  requestCreated,
  documentsUploaded,
  underCommercialReview,
  quoteProvided,
  quoteAccepted,
  paymentSubmitted,
  paymentVerified,
  inGeneralPool,
  assigned,
  inspection,
  drafting,
  spaReview,
  snapshotCreated,
  deliveryReady,
  clientDownloaded,
  closed,
}

class _StageMeta {
  final _StageId id;
  final String label;
  final String shortCode;
  final String description;

  const _StageMeta({
    required this.id,
    required this.label,
    required this.shortCode,
    required this.description,
  });
}

const List<_StageMeta> _kLifecycleStages = [
  _StageMeta(
    id: _StageId.requestCreated,
    label: 'REQUEST_CREATED',
    shortCode: 'REQ',
    description: 'Valuation mandate parameters initialized.',
  ),
  _StageMeta(
    id: _StageId.documentsUploaded,
    label: 'DOCUMENTS_UPLOADED',
    shortCode: 'DOCS',
    description: 'Mandatory ownership & municipal deeds attached.',
  ),
  _StageMeta(
    id: _StageId.underCommercialReview,
    label: 'UNDER_COMMERCIAL_REVIEW',
    shortCode: 'REVIEW',
    description: 'Operational desk reviewing scope & circle rates.',
  ),
  _StageMeta(
    id: _StageId.quoteProvided,
    label: 'QUOTE_PROVIDED',
    shortCode: 'QUOTE',
    description: 'Official quotation & turnaround SLA issued.',
  ),
  _StageMeta(
    id: _StageId.quoteAccepted,
    label: 'QUOTE_ACCEPTED',
    shortCode: 'ACCPT',
    description: 'Client accepted commercial scope & payment terms.',
  ),
  _StageMeta(
    id: _StageId.paymentSubmitted,
    label: 'PAYMENT_SUBMITTED',
    shortCode: 'PAY_SUB',
    description: 'Remittance proof & UTR under settlement review.',
  ),
  _StageMeta(
    id: _StageId.paymentVerified,
    label: 'PAYMENT_VERIFIED',
    shortCode: 'PAY_OK',
    description: 'Bank credit confirmed; pending intake clearance.',
  ),
  _StageMeta(
    id: _StageId.inGeneralPool,
    label: 'IN_GENERAL_POOL',
    shortCode: 'POOL',
    description: 'Released to Common Pool; sequential Report ID generated.',
  ),
  _StageMeta(
    id: _StageId.assigned,
    label: 'ASSIGNED',
    shortCode: 'ASSIGN',
    description: 'Claimed by registered Property Analyst (PA).',
  ),
  _StageMeta(
    id: _StageId.inspection,
    label: 'INSPECTION',
    shortCode: 'INSP',
    description: 'Physical site visit, boundaries & photo audit.',
  ),
  _StageMeta(
    id: _StageId.drafting,
    label: 'DRAFTING',
    shortCode: 'DRAFT',
    description: 'Compiling report via dynamic docx4j template engine.',
  ),
  _StageMeta(
    id: _StageId.spaReview,
    label: 'SPA_REVIEW',
    shortCode: 'SPA_REV',
    description: 'Senior Valuer QA audit & Cloud HSM signing review.',
  ),
  _StageMeta(
    id: _StageId.snapshotCreated,
    label: 'SNAPSHOT_CREATED',
    shortCode: 'SEALED',
    description: 'Immutable Valuation Snapshot sealed cryptographically.',
  ),
  _StageMeta(
    id: _StageId.deliveryReady,
    label: 'DELIVERY_READY',
    shortCode: 'READY',
    description: 'Commercial clearance passed; tax invoice generated.',
  ),
  _StageMeta(
    id: _StageId.clientDownloaded,
    label: 'CLIENT_DOWNLOADED',
    shortCode: 'DL_OK',
    description: 'Encrypted report retrieved; acknowledgement open.',
  ),
  _StageMeta(
    id: _StageId.closed,
    label: 'CLOSED',
    shortCode: 'CLOSED',
    description: 'Order finalized and locked under 10-year statutory compliance archive.',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main Hub Widget
// ─────────────────────────────────────────────────────────────────────────────
class ClientWorkspaceHub extends StatefulWidget {
  const ClientWorkspaceHub({super.key});

  @override
  State<ClientWorkspaceHub> createState() => _ClientWorkspaceHubState();
}

class _ClientWorkspaceHubState extends State<ClientWorkspaceHub> {
  _Section _activeSection = _Section.overview;
  dynamic _selectedOrder;
  bool _sidebarCollapsed = false;

  // New Request Intake Form State (Original Commercial Wizard)
  int _intakeStep = 1;
  String _intakeService = 'VALUATION';
  String _intakeAsset = 'LAND_AND_BUILDING';
  final _assetNameCtrl = TextEditingController(text: 'Cyber Towers Unit 402');
  final _assetLocationCtrl = TextEditingController(text: 'HITEC City, Hyderabad');
  final _estimatedValueCtrl = TextEditingController(text: '18500000');
  String _intakePurpose = 'BANK_COLLATERAL';
  final _targetBankCtrl = TextEditingController(text: 'State Bank of India');
  String _intakeUrgency = 'STANDARD_3D';
  final _specialNotesCtrl = TextEditingController();
  final Map<String, PlatformFile> _uploadedFiles = {};
  bool _intakeLoading = false;
  String? _intakeError;
  int? _draftOrderId;

  // Payment Form State
  final _utrCtrl = TextEditingController();
  final _paymentDateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _paymentMethod = 'UPI';
  PlatformFile? _paymentReceiptFile;
  bool _paymentLoading = false;
  String? _paymentError;

  // Delivery State
  bool _deliveryLoading = false;

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
    _assetLocationCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _targetBankCtrl.dispose();
    _specialNotesCtrl.dispose();
    _utrCtrl.dispose();
    _paymentDateCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOrdersAndSync() async {
    final orderProvider = context.read<OrderProvider>();
    await orderProvider.fetchClientOrders();
    if (mounted && orderProvider.clientOrders.isNotEmpty) {
      if (_selectedOrder == null) {
        setState(() {
          _selectedOrder = orderProvider.clientOrders.first;
        });
      } else {
        // Refresh focused order
        final found = orderProvider.clientOrders.firstWhere(
          (o) => o['id'] == _selectedOrder['id'],
          orElse: () => orderProvider.clientOrders.first,
        );
        setState(() {
          _selectedOrder = found;
        });
      }
    }
  }

  void _navigate(_Section section, {dynamic order}) {
    setState(() {
      _activeSection = section;
      if (order != null) _selectedOrder = order;
      _intakeError = null;
      _paymentError = null;
    });
  }

  // ─── Evaluator: Map Backend Order to 16 Lifecycle Stages ───────────────────
  int _evaluateCurrentStageIndex(dynamic order) {
    if (order == null) return 0;
    final status = (order['status'] as String? ?? 'DRAFT').toUpperCase();
    final paymentStatus = (order['paymentStatus'] as String? ?? 'PENDING').toUpperCase();

    switch (status) {
      case 'DRAFT':
        return 0; // REQUEST_CREATED
      case 'QUOTE_PENDING':
        return 2; // UNDER_COMMERCIAL_REVIEW
      case 'QUOTE_PROVIDED':
        if (paymentStatus == 'SUBMITTED') return 5; // PAYMENT_SUBMITTED
        return 3; // QUOTE_PROVIDED
      case 'PAYMENT_SUBMITTED':
        return 5; // PAYMENT_SUBMITTED
      case 'PAYMENT_REJECTED':
        return 3; // QUOTE_PROVIDED (Action: Resubmit)
      case 'PAYMENT_VERIFIED':
        return 6; // PAYMENT_VERIFIED
      case 'PAID_INTAKE':
        return 7; // IN_GENERAL_POOL
      case 'ASSIGNED':
        return 8; // ASSIGNED
      case 'INSPECTION_SCHEDULED':
      case 'INSPECTION_IN_PROGRESS':
      case 'INSPECTION_COMPLETED':
        return 9; // INSPECTION
      case 'DRAFTING':
        return 10; // DRAFTING
      case 'UNDER_REVIEW':
      case 'SPA_REVIEW':
      case 'SPA_CONFIRMED':
        return 11; // SPA_REVIEW
      case 'SNAPSHOT_CREATED':
      case 'ON_HOLD_PAYMENT_PENDING':
        return 12; // SNAPSHOT_CREATED
      case 'DELIVERY_READY':
        return 13; // DELIVERY_READY
      case 'FINAL_DELIVERY':
      case 'CLIENT_DOWNLOADED':
        return 14; // CLIENT_DOWNLOADED
      case 'CLOSED':
        return 15; // CLOSED
      default:
        return 0;
    }
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
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          // ── Sidebar ────────────────────────────────────────────────────────
          _Sidebar(
            collapsed: _sidebarCollapsed || isNarrow,
            activeSection: _activeSection,
            fullName: auth.fullName ?? 'Client Officer',
            email: auth.email ?? 'client@provaluer.com',
            onSection: (s) => _navigate(s),
            onToggleCollapse: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onLogout: () {
              auth.logout();
              context.go('/');
            },
          ),

          // ── Main Workspace View ───────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(
                  sectionLabel: _activeSection.label,
                  order: _selectedOrder,
                  onHomePressed: () => context.go('/'),
                  onRefreshPressed: _loadOrdersAndSync,
                  onNewRequestPressed: () => _navigate(_Section.newRequest),
                ),

                // Main Scrollable Body
                Expanded(
                  child: _buildSectionContent(orders, auth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(OrderProvider orders, AuthProvider auth) {
    return switch (_activeSection) {
      _Section.overview => _buildOverviewView(orders),
      _Section.myProjects => _buildMyProjectsView(orders),
      _Section.newRequest => _buildCommercialIntakeWizard(orders),
      _Section.documentsVault => _buildDocumentsVaultView(orders),
      _Section.quotations => _buildQuotationsView(orders),
      _Section.paymentsBilling => _buildPaymentsBillingView(orders),
      _Section.trackingEngine => _buildTrackingEngineView(orders),
      _Section.deliverables => _buildDeliverablesView(orders),
      _Section.taxInvoices => _buildTaxInvoicesView(orders),
      _Section.complianceSupport => _buildComplianceSupportView(orders),
    };
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 1: OVERVIEW — TARGET DASHBOARD
  // Permanent Lifecycle Tracker + Single Next Valid Action Spotlight + Panels
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildOverviewView(OrderProvider orders) {
    if (orders.clientOrders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.note_add_outlined, size: 56, color: AppColors.slate),
              const SizedBox(height: 16),
              Text('No Active Valuation Mandates',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('Initialize your first commercial valuation mandate to trigger automated quote generation.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigate(_Section.newRequest),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Start New Valuation Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final order = _selectedOrder ?? orders.clientOrders.first;
    final stageIdx = _evaluateCurrentStageIndex(order);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header Metadata Bar
          _buildOrderHeaderPill(order),
          const SizedBox(height: 24),

          // ── TOP OF DASHBOARD: PERMANENT LIFECYCLE TRACKER ─────────────────
          _PermanentLifecycleTracker(
            stages: _kLifecycleStages,
            currentStageIndex: stageIdx,
            order: order,
          ),
          const SizedBox(height: 28),

          // ── MIDDLE OF DASHBOARD: SINGLE NEXT VALID ACTION SPOTLIGHT ───────
          _SingleNextValidActionSpotlight(
            order: order,
            currentStageIndex: stageIdx,
            onActionTriggered: (action) => _handleSpotlightAction(action, order),
          ),
          const SizedBox(height: 32),

          // ── LOWER DASHBOARD: 5 SUPPORTING PANELS ──────────────────────────
          Text('Mandate Context & Operational Records',
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 16),

          _SupportingPanelsWorkspace(
            order: order,
            onViewDocuments: () => _navigate(_Section.documentsVault),
            onViewQuote: () => _navigate(_Section.quotations),
            onViewPayment: () => _navigate(_Section.paymentsBilling),
            onViewDelivery: () => _navigate(_Section.deliverables),
            onRefresh: _loadOrdersAndSync,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderPill(dynamic order) {
    final ref = order['referenceCode'] ?? 'REQ-${order['id']}';
    final reportNum = order['reportNumber'] ?? 'Pending Release';
    final asset = order['clientName'] ?? order['propertyCategory'] ?? 'Commercial Asset';
    final status = order['status'] ?? 'DRAFT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              ref,
              style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset,
                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Official Report No: $reportNum  •  Status: $status',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _navigate(_Section.myProjects),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('Switch Mandate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandNavy,
              side: const BorderSide(color: AppColors.hairlineStrong),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Spotlight Action Handler (Zero Workflow Guessing) ────────────────────
  void _handleSpotlightAction(String action, dynamic order) {
    switch (action) {
      case 'SELECT_SERVICE':
      case 'SELECT_ASSET':
      case 'ENTER_DETAILS':
      case 'UPLOAD_DOCS':
        _navigate(_Section.newRequest, order: order);
        break;
      case 'SUBMIT_REQUEST':
        _submitDraftOrder(order['id']);
        break;
      case 'VIEW_DOSSIER':
      case 'VIEW_DOCUMENTS':
        _navigate(_Section.documentsVault, order: order);
        break;
      case 'VIEW_QUOTE':
      case 'ACCEPT_QUOTE':
        _navigate(_Section.quotations, order: order);
        break;
      case 'SUBMIT_PAYMENT':
      case 'RESUBMIT_PAYMENT':
      case 'VIEW_PAYMENT_STATUS':
        _navigate(_Section.paymentsBilling, order: order);
        break;
      case 'TRACK_PROGRESS':
      case 'TRACK_ALLOCATION':
      case 'VIEW_ASSIGNMENT':
      case 'VIEW_INSPECTION':
        _navigate(_Section.trackingEngine, order: order);
        break;
      case 'DOWNLOAD_REPORT':
      case 'DOWNLOAD_INVOICE':
      case 'ACKNOWLEDGE_REPORT':
      case 'REQUEST_CLARIFICATION':
        _navigate(_Section.deliverables, order: order);
        break;
      default:
        _navigate(_Section.overview, order: order);
        break;
    }
  }

  Future<void> _submitDraftOrder(int orderId) async {
    final orderProvider = context.read<OrderProvider>();
    final res = await orderProvider.submitRequest(orderId);
    if (res != null && res['error'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Valuation request submitted successfully. Operations desk notified via Telegram.'),
          backgroundColor: AppColors.successAccent,
        ),
      );
      await _loadOrdersAndSync();
      _navigate(_Section.overview);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['error']?.toString() ?? 'Failed to submit request.'),
          backgroundColor: AppColors.brandRedDark,
        ),
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 2: MY PROJECTS (Order Archive & Switching)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildMyProjectsView(OrderProvider orders) {
    final list = orders.clientOrders;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('My Projects & Valuation Mandates',
                      style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text('Historical repository of commercial and residential property valuation orders.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _navigate(_Section.newRequest),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ New Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (list.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No orders found.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final o = list[i];
                final isSelected = _selectedOrder != null && _selectedOrder['id'] == o['id'];
                final ref = o['referenceCode'] ?? 'REQ-${o['id']}';
                final report = o['reportNumber'] ?? 'Pending Release';
                final asset = o['clientName'] ?? o['propertyCategory'] ?? 'Asset';
                final status = o['status'] ?? 'DRAFT';

                return InkWell(
                  onTap: () {
                    setState(() => _selectedOrder = o);
                    _navigate(_Section.overview, order: o);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryBlueLight : AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.business_outlined, color: isSelected ? AppColors.primaryBlue : AppColors.slate),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asset,
                                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              const SizedBox(height: 4),
                              Text('Ref: $ref  •  Report: $report  •  Purpose: ${o['purpose'] ?? 'Valuation'}',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.hairline),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 3: ORIGINAL COMMERCIAL INTAKE WIZARD (6 Steps)
  // Replaces simplified form with rigorous statutory underwriting capture.
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildCommercialIntakeWizard(OrderProvider orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Intake Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valuation Request Intake Wizard',
                        style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    const SizedBox(height: 4),
                    Text('Step $_intakeStep of 6 — Complete all statutory parameters for automated quotation issuance.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                  ],
                ),
                TextButton(
                  onPressed: () => _navigate(_Section.overview),
                  child: const Text('Cancel'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step Progress Indicator
            LinearProgressIndicator(
              value: _intakeStep / 6.0,
              backgroundColor: AppColors.hairline,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 28),

            // Error banner if any
            if (_intakeError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandRed,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.brandRedDark, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_intakeError!, style: const TextStyle(color: AppColors.brandRedDark, fontSize: 13))),
                  ],
                ),
              ),

            // Wizard Step Container
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairline),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: switch (_intakeStep) {
                1 => _buildStep1ServiceCategory(),
                2 => _buildStep2AssetCategory(),
                3 => _buildStep3PropertyDetails(),
                4 => _buildStep4Purpose(),
                5 => _buildStep5Institution(),
                6 => _buildStep6DocumentUpload(orders),
                _ => _buildStep1ServiceCategory(),
              },
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Service Category
  Widget _buildStep1ServiceCategory() {
    final services = [
      {
        'id': 'VALUATION',
        'title': 'Commercial & Residential Property Valuation',
        'desc': 'Formal asset appraisal under Wealth Tax Rule 8A and Companies Act 2013 for banks, embassy, and corporate filings.',
        'badge': 'Standard Service',
      },
      {
        'id': 'NET_WORTH_CERTIFICATE',
        'title': 'Net Worth & Solvency Certification',
        'desc': 'Consolidated financial solvency certificates verified by IBBI certified valuers for global visa & overseas education.',
        'badge': 'Visa / Solvency',
      },
      {
        'id': 'CHARTERED_ENGINEER',
        'title': 'Chartered Engineer Technical Certification',
        'desc': 'Structural integrity certifications, plant installation audit, customs EPCG depreciation appraisals.',
        'badge': 'Technical',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Select Service Category',
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Select the statutory compliance mandate for your appraisal request.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        ...services.map((s) {
          final isSelected = _intakeService == s['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _intakeService = s['id']!),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: s['id']!,
                      groupValue: _intakeService,
                      onChanged: (v) => setState(() => _intakeService = v!),
                      activeColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(s['title']!,
                                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(s['badge']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(s['desc']!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => setState(() => _intakeStep = 2),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
            child: const Text('Continue to Asset Category →'),
          ),
        ),
      ],
    );
  }

  // Step 2: Asset Category
  Widget _buildStep2AssetCategory() {
    final assets = [
      {
        'id': 'LAND_AND_BUILDING',
        'title': 'Land & Building (Real Estate)',
        'desc': 'Commercial office bays, IT parks, retail shops, industrial sheds, residential flats, villas, open plots.',
        'icon': Icons.business_outlined,
      },
      {
        'id': 'PLANT_AND_MACHINERY',
        'title': 'Plant & Machinery',
        'desc': 'Heavy manufacturing equipment, production lines, commercial fleets, factory installations.',
        'icon': Icons.precision_manufacturing_outlined,
      },
      {
        'id': 'SECURITIES_FINANCIAL_ASSETS',
        'title': 'Securities & Financial Assets',
        'desc': 'Unquoted equity shares, corporate debentures, partnership shares, business enterprise valuation.',
        'icon': Icons.trending_up_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Select Asset Classification',
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Specify the asset class to load the proper statutory valuation checklist.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        ...assets.map((a) {
          final isSelected = _intakeAsset == a['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => setState(() => _intakeAsset = a['id'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(a['icon'] as IconData, color: isSelected ? AppColors.primaryBlue : AppColors.slate, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] as String,
                              style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Text(a['desc'] as String, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: a['id'] as String,
                      groupValue: _intakeAsset,
                      onChanged: (v) => setState(() => _intakeAsset = v!),
                      activeColor: AppColors.primaryBlue,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(onPressed: () => setState(() => _intakeStep = 1), child: const Text('← Back')),
            ElevatedButton(
              onPressed: () => setState(() => _intakeStep = 3),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
              child: const Text('Continue to Property Details →'),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Property Details
  Widget _buildStep3PropertyDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 3: Property & Asset Particulars',
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Enter the legal name, municipal location, and tentative estimated market value.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        TextField(
          controller: _assetNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Asset / Property Name *',
            hintText: 'e.g. Cyber Towers Suite 402 / Prestige Meridian Tower',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _assetLocationCtrl,
          decoration: const InputDecoration(
            labelText: 'Asset Location (City, State) *',
            hintText: 'e.g. HITEC City, Hyderabad, Telangana',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _estimatedValueCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated Market Value (₹, Optional)',
            hintText: 'e.g. 18500000',
            border: OutlineInputBorder(),
            prefixText: '₹ ',
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(onPressed: () => setState(() => _intakeStep = 2), child: const Text('← Back')),
            ElevatedButton(
              onPressed: () {
                if (_assetNameCtrl.text.trim().isEmpty || _assetLocationCtrl.text.trim().isEmpty) {
                  setState(() => _intakeError = 'Asset Name and Location are required fields.');
                  return;
                }
                setState(() {
                  _intakeError = null;
                  _intakeStep = 4;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
              child: const Text('Continue to Purpose →'),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: Purpose
  Widget _buildStep4Purpose() {
    final purposes = [
      {'id': 'BANK_COLLATERAL', 'title': 'Bank Collateral / Loan Mortgage'},
      {'id': 'VISA_IMMIGRATION', 'title': 'Visa & Embassy Financial Net Worth'},
      {'id': 'TAXATION_COMPLIANCE', 'title': 'Capital Gains & Income Tax Sec 50C'},
      {'id': 'CORPORATE_INSOLVENCY', 'title': 'Corporate Audit, M&A & NCLT Liquidation'},
      {'id': 'CUSTOMS', 'title': 'Customs Valuation & EPCG Machinery Import'},
      {'id': 'DISPUTE', 'title': 'High Court Legal Dispute / Family Settlement'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 4: Valuation Mandate Purpose',
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Select the statutory purpose under which this valuation will be presented.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: purposes.map((p) {
            final isSelected = _intakePurpose == p['id'];
            return InkWell(
              onTap: () => setState(() => _intakePurpose = p['id']!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 380,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: p['id']!,
                      groupValue: _intakePurpose,
                      onChanged: (v) => setState(() => _intakePurpose = v!),
                      activeColor: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p['title']!,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(onPressed: () => setState(() => _intakeStep = 3), child: const Text('← Back')),
            ElevatedButton(
              onPressed: () => setState(() => _intakeStep = 5),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
              child: const Text('Continue to Institution & SLA →'),
            ),
          ],
        ),
      ],
    );
  }

  // Step 5: Institution & Turnaround
  Widget _buildStep5Institution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 5: Target Institution & Priority Window',
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text('Specify recipient bank / embassy and turnaround urgency.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        const SizedBox(height: 20),

        TextField(
          controller: _targetBankCtrl,
          decoration: const InputDecoration(
            labelText: 'Target Bank / Embassy / Institution *',
            hintText: 'e.g. State Bank of India / US Embassy Mumbai',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),

        Text('Turnaround SLA Priority', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Standard SLA (3–5 Working Days)')),
                selected: _intakeUrgency == 'STANDARD_3D',
                onSelected: (v) => setState(() => _intakeUrgency = 'STANDARD_3D'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('⚡ Express Priority (24–48 Hours)')),
                selected: _intakeUrgency == 'EXPRESS_24H',
                onSelected: (v) => setState(() => _intakeUrgency = 'EXPRESS_24H'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _specialNotesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Special Underwriting Remarks (Optional)',
            hintText: 'e.g. Physical key handover with society secretary Mr. Sharma',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(onPressed: () => setState(() => _intakeStep = 4), child: const Text('← Back')),
            ElevatedButton(
              onPressed: () => setState(() => _intakeStep = 6),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
              child: const Text('Continue to Document Upload →'),
            ),
          ],
        ),
      ],
    );
  }

  // Step 6: Original Document Upload Matrix
  Widget _buildStep6DocumentUpload(OrderProvider orders) {
    // Determine mandatory slots based on asset category
    final List<Map<String, dynamic>> slots = switch (_intakeAsset) {
      'PLANT_AND_MACHINERY' => [
          {'key': 'INVOICE_BILL', 'label': '1. Purchase Invoice / Machinery Bill *', 'mandatory': true},
          {'key': 'UTILITY_BILL', 'label': '2. Factory Power Connection Bill', 'mandatory': false},
          {'key': 'SITE_PHOTOS', 'label': '3. Machine Plate & Nameplate Photos', 'mandatory': false},
        ],
      'SECURITIES_FINANCIAL_ASSETS' => [
          {'key': 'FIN_AUDIT', 'label': '1. Audited Balance Sheet (Last 3 Years) *', 'mandatory': true},
          {'key': 'UTILITY_BILL', 'label': '2. Certificate of Incorporation / PAN', 'mandatory': false},
          {'key': 'SITE_PHOTOS', 'label': '3. Shareholding Pattern Statement', 'mandatory': false},
        ],
      _ => [
          {'key': 'TITLE_DEED', 'label': '1. Registered Title Deed / Conveyance *', 'mandatory': true},
          {'key': 'SANCTION_PLAN', 'label': '2. Approved Municipal Sanction Plan *', 'mandatory': true},
          {'key': 'TAX_RECEIPT', 'label': '3. Current Year Property Tax Challan *', 'mandatory': true},
          {'key': 'UTILITY_BILL', 'label': '4. Electricity / Utility Bill', 'mandatory': false},
          {'key': 'SITE_PHOTOS', 'label': '5. Site / Building Photographs', 'mandatory': false},
          {'key': 'ENCUMBRANCE_CERT', 'label': '6. Encumbrance Certificate (EC)', 'mandatory': false},
        ],
    };

    final mandatorySlots = slots.where((s) => s['mandatory'] == true).map((s) => s['key'] as String).toList();
    final hasAllMandatory = mandatorySlots.every((k) => _uploadedFiles.containsKey(k));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Step 6: Statutory Document Matrix',
                    style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Files are encrypted with SHA-256 integrity hash. Allowed: PDF, JPG, PNG (Max 20MB).',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hasAllMandatory ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: hasAllMandatory ? AppColors.successBorder : AppColors.warningBorder),
              ),
              child: Text(
                hasAllMandatory ? '✓ Mandatory Ready' : 'Mandatory Files Required',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: hasAllMandatory ? AppColors.successAccent : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        ...slots.map((s) {
          final key = s['key'] as String;
          final label = s['label'] as String;
          final isMandatory = s['mandatory'] as bool;
          final hasFile = _uploadedFiles.containsKey(key);
          final file = _uploadedFiles[key];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.successBg : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasFile ? AppColors.successBorder : (isMandatory ? AppColors.hairlineStrong : AppColors.hairline),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                  color: hasFile ? AppColors.successAccent : AppColors.slate,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      if (hasFile)
                        Text('${file!.name} (${(file.size / 1024).toStringAsFixed(1)} KB)',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.successAccent, fontWeight: FontWeight.w600))
                      else
                        Text(isMandatory ? 'Mandatory for quote issuance' : 'Optional supplementary verification',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickIntakeFile(key),
                  icon: const Icon(Icons.attach_file, size: 14),
                  label: Text(hasFile ? 'Replace' : 'Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFile ? Colors.white : (isMandatory ? AppColors.brandNavy : AppColors.surfaceSoft),
                    foregroundColor: hasFile ? AppColors.successAccent : (isMandatory ? Colors.white : AppColors.ink),
                    elevation: 0,
                    side: BorderSide(color: hasFile ? AppColors.successBorder : AppColors.hairline),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(onPressed: () => setState(() => _intakeStep = 5), child: const Text('← Back')),
            ElevatedButton(
              onPressed: (_intakeLoading || !hasAllMandatory) ? null : () => _executeIntakeSubmission(orders),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _intakeLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Submit Valuation Request →'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickIntakeFile(String category) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      if (f.size > 20 * 1024 * 1024) {
        setState(() => _intakeError = 'File exceeds maximum allowed size of 20 MB.');
        return;
      }
      setState(() {
        _uploadedFiles[category] = f;
        _intakeError = null;
      });
    }
  }

  Future<void> _executeIntakeSubmission(OrderProvider orders) async {
    setState(() {
      _intakeLoading = true;
      _intakeError = null;
    });

    try {
      final estVal = double.tryParse(_estimatedValueCtrl.text.trim()) ?? 0.0;
      final inputs = {
        'asset_name': _assetNameCtrl.text.trim(),
        'location': _assetLocationCtrl.text.trim(),
        'target_bank': _targetBankCtrl.text.trim(),
        'urgency_sla': _intakeUrgency,
        'special_notes': _specialNotesCtrl.text.trim(),
      };

      // 1. Save Draft Order
      final draftRes = await orders.saveDraft(
        _intakeAsset,
        _intakePurpose,
        estVal,
        inputs,
        id: _draftOrderId,
        serviceCategory: _intakeService,
      );

      if (draftRes == null || draftRes['id'] == null) {
        setState(() {
          _intakeError = 'Failed to create draft order.';
          _intakeLoading = false;
        });
        return;
      }

      final orderId = (draftRes['id'] as num).toInt();
      _draftOrderId = orderId;

      // 2. Upload all documents
      for (final entry in _uploadedFiles.entries) {
        await orders.uploadDocument(
          orderId,
          entry.key,
          entry.value.name,
          entry.value.bytes ?? [],
        );
      }

      // 3. Submit request (transitions to QUOTE_PENDING & dispatches Telegram alert)
      final submitRes = await orders.submitRequest(orderId);

      setState(() => _intakeLoading = false);

      if (submitRes != null && submitRes['error'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Request submitted! Status is QUOTE_PENDING. Operations desk alerted.'),
            backgroundColor: AppColors.successAccent,
          ),
        );
        await _loadOrdersAndSync();
        _navigate(_Section.overview);
      } else {
        setState(() {
          _intakeError = submitRes?['error']?.toString() ?? 'Request submission encountered error.';
        });
      }
    } catch (e) {
      setState(() {
        _intakeLoading = false;
        _intakeError = 'Intake execution error: $e';
      });
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 4: DOCUMENTS VAULT
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentsVaultView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final orderId = order['id'] as int;

    return FutureBuilder<List<dynamic>?>(
      future: orders.fetchOrderDocuments(orderId),
      builder: (ctx, snap) {
        final docs = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Documents Vault & Verification Badges',
                          style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text('Mandate legal records, sanction layouts, and municipal tax challans.',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showQuickUploadModal(orderId),
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (docs.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No documents uploaded for this order.')))
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final cat = d['category'] ?? 'OTHER';
                    final name = d['filename'] ?? 'Document.pdf';
                    final size = d['fileSizeBytes'] != null ? '${(d['fileSizeBytes'] / 1024).toStringAsFixed(1)} KB' : '—';
                    final isVerified = cat != 'OTHER' && cat != 'PAYMENT_PROOF';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryBlue, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 2),
                                Text('Category: $cat  •  Size: $size', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isVerified ? AppColors.successBg : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isVerified ? '✓ Verified' : 'Under Review',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isVerified ? AppColors.successAccent : AppColors.slate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.download_rounded, color: AppColors.slate),
                            tooltip: 'Download Document',
                            onPressed: () => _downloadDocFile(d['id'], name),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _downloadDocFile(int docId, String filename) async {
    final orderProvider = context.read<OrderProvider>();
    final bytes = await orderProvider.downloadDocument(docId);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Downloaded $filename (${(bytes.length / 1024).toStringAsFixed(1)} KB)')),
      );
    }
  }

  void _showQuickUploadModal(int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Supplementary Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select category and file to upload into the order vault.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final res = await FilePicker.platform.pickFiles(withData: true);
                if (res != null && res.files.isNotEmpty) {
                  Navigator.pop(ctx);
                  final file = res.files.first;
                  await context.read<OrderProvider>().uploadDocument(orderId, 'SUPPLEMENTARY', file.name, file.bytes ?? []);
                  setState(() {});
                }
              },
              child: const Text('Choose File & Upload'),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 5: QUOTATIONS
  // Itemized breakdown, GST 18%, PDF download, Validity countdown, Acceptance
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildQuotationsView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final orderId = order['id'] as int;

    return FutureBuilder<Map<String, dynamic>?>(
      future: orders.fetchOrderQuote(orderId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final q = snap.data;
        if (q == null || q['quoteNumber'] == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 48, color: AppColors.warning),
                  const SizedBox(height: 16),
                  Text('Quotation In Preparation', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('Your request dossier is under commercial review. Once circle rates are evaluated, the quotation will appear here.',
                      textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                ],
              ),
            ),
          );
        }

        final quoteNum = q['quoteNumber'] ?? 'QTE-PENDING';
        final amount = (q['quoteAmount'] as num?)?.toDouble() ?? 0.0;
        final tax = (q['quoteTax'] as num?)?.toDouble() ?? 0.0;
        final total = (q['quoteTotal'] as num?)?.toDouble() ?? 0.0;
        final turnaround = q['turnaroundTime'] ?? q['quoteTurnaround'] ?? '3-5 Working Days';
        final scope = q['scopeNotes'] ?? q['quoteNotes'] ?? 'Comprehensive commercial site inspection and valuation.';
        final terms = q['termsConditions'] ?? q['quoteTerms'] ?? 'Payment milestones disclosure. Quote valid for 15 days.';

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Commercial Quotation',
                            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        const SizedBox(height: 4),
                        Text('Quotation Number: $quoteNum  •  Status: ISSUED',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _downloadQuotePdfFile(orderId, quoteNum),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('Download Quote PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Itemized Fee Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    children: [
                      _feeRow('Professional Valuation Base Fee', '₹ ${amount.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _feeRow('Applicable GST (18.00%)', '₹ ${tax.toStringAsFixed(2)}'),
                      const Divider(height: 24),
                      _feeRow('Total Payable Remittance', '₹ ${total.toStringAsFixed(2)}', isTotal: true),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Turnaround & Scope
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Committed Turnaround SLA', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate)),
                            const SizedBox(height: 4),
                            Text(turnaround, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Validity Window', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.slate)),
                            const SizedBox(height: 4),
                            Text('15 Calendar Days', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.successAccent)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Scope & Terms
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mandate Scope of Work', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(scope, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.5)),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Text('Commercial Terms & Conditions', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(terms, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate, height: 1.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Acceptance Action Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ready to Proceed?', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                          Text('Accept the quotation terms and proceed directly to payment proof submission.',
                              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _navigate(_Section.paymentsBilling, order: order),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Accept Quote & Pay →'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _feeRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: isTotal ? 15 : 13, fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal, color: AppColors.ink)),
        Text(value, style: GoogleFonts.inter(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600, color: isTotal ? AppColors.primaryBlue : AppColors.ink)),
      ],
    );
  }

  Future<void> _downloadQuotePdfFile(int orderId, String quoteNum) async {
    final bytes = await context.read<OrderProvider>().downloadQuotePdf(orderId);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ Downloaded Quotation_$quoteNum.pdf (${(bytes.length / 1024).toStringAsFixed(1)} KB)')),
      );
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 6: PAYMENTS & BILLING
  // Beneficiary details, Account, IFSC, UPI ID, QR code, UTR submission, Rejection
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildPaymentsBillingView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final orderId = order['id'] as int;

    return FutureBuilder<Map<String, dynamic>?>(
      future: orders.fetchPaymentDetails(orderId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final p = snap.data ?? {};
        final bank = p['bankDetails'] as Map<String, dynamic>? ?? {};
        final benef = bank['beneficiaryName'] ?? 'ProValuer Commercial Advisory LLP';
        final bankName = bank['bankName'] ?? 'HDFC Bank Ltd';
        final accNum = bank['accountNumber'] ?? '50200088912345';
        final ifsc = bank['ifsc'] ?? 'HDFC0001234';
        final upi = bank['upiId'] ?? 'provaluer.commercial@hdfcbank';
        final qrPayload = bank['qrPayload'] ?? 'upi://pay?pa=$upi';
        final quoteTotal = (p['quoteTotal'] as num?)?.toDouble() ?? 17700.0;
        final latestPayment = p['latestPayment'] as Map<String, dynamic>?;
        final paymentStatus = (latestPayment?['status'] ?? order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payments & Remittance Settlement',
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Remit quotation fees to the company escrow account and upload transaction UTR.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                const SizedBox(height: 24),

                // PAYMENT REJECTION BANNER (If Rejected)
                if (paymentStatus == 'REJECTED' || order['status'] == 'PAYMENT_REJECTED')
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.brandRed,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.errorBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_rounded, color: AppColors.brandRedDark, size: 20),
                            const SizedBox(width: 8),
                            Text('Payment Proof Rejected by Accounts Desk',
                                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.brandRedDark)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Rejection Reason: ${latestPayment?['rejectionReason'] ?? 'FUNDS_NOT_RECEIVED — UTR not reflected in 24h bank settlement cycle.'}',
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.brandRedDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted UTR: ${latestPayment?['utrNumber'] ?? '—'}',
                          style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brandRedDark),
                        ),
                        const SizedBox(height: 12),
                        const Text('Please verify transfer in your banking app and submit the correct UTR reference below.',
                            style: TextStyle(fontSize: 12, color: AppColors.brandRedDark)),
                      ],
                    ),
                  ),

                // Bank Transfer Coordinates Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Direct NEFT / RTGS / IMPS Bank Transfer',
                              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          Text('Amount Due: ₹ ${quoteTotal.toStringAsFixed(2)}',
                              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _coordRow('Beneficiary Entity', benef),
                      _coordRow('Bank Name & Branch', '$bankName, Corporate Banking'),
                      _coordRow('Account Number', accNum, isMono: true),
                      _coordRow('IFSC Code', ifsc, isMono: true),
                      _coordRow('UPI ID (VPA)', upi, isMono: true),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.qr_code_2_rounded, size: 28, color: AppColors.primaryBlue),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Instant UPI Scan & Pay Payload',
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                                Text(qrPayload,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.slate)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            tooltip: 'Copy UPI ID',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: upi));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied to clipboard!')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Payment Proof Submission Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Submit Payment Proof & UTR Reference',
                          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 4),
                      Text('Enter the transaction UTR number exactly as shown in your bank debit advice.',
                          style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                      const SizedBox(height: 18),

                      if (_paymentError != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.brandRed, borderRadius: BorderRadius.circular(6)),
                          child: Text(_paymentError!, style: const TextStyle(color: AppColors.brandRedDark, fontSize: 12.5)),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _utrCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Bank UTR / Transaction Reference *',
                                hintText: 'e.g. HDFCR5202610038921',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _paymentMethod,
                              decoration: const InputDecoration(labelText: 'Payment Mode', border: OutlineInputBorder()),
                              items: ['UPI', 'NEFT', 'RTGS', 'IMPS', 'NET_BANKING'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (v) => setState(() => _paymentMethod = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _amountCtrl..text = quoteTotal.toStringAsFixed(2),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Amount Remitted (₹) *',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickPaymentReceiptFile,
                              icon: const Icon(Icons.attach_file),
                              label: Text(_paymentReceiptFile != null ? _paymentReceiptFile!.name : 'Attach Bank Receipt (PDF/Image) *'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: _paymentLoading ? null : () => _executePaymentSubmit(orderId),
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: _paymentLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit Payment Proof for Verification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coordRow(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
          SelectableText(
            value,
            style: isMono
                ? GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)
                : GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPaymentReceiptFile() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (res != null && res.files.isNotEmpty) {
      final f = res.files.first;
      if (f.size > 10 * 1024 * 1024) {
        setState(() => _paymentError = 'Receipt file exceeds 10MB limit.');
        return;
      }
      setState(() {
        _paymentReceiptFile = f;
        _paymentError = null;
      });
    }
  }

  Future<void> _executePaymentSubmit(int orderId) async {
    final utr = _utrCtrl.text.trim();
    if (utr.isEmpty) {
      setState(() => _paymentError = 'UTR transaction reference number is mandatory.');
      return;
    }
    if (_paymentReceiptFile == null) {
      setState(() => _paymentError = 'Bank receipt attachment (PDF/Image) is mandatory.');
      return;
    }

    final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (amt <= 0) {
      setState(() => _paymentError = 'Please enter a valid positive payment amount.');
      return;
    }

    setState(() {
      _paymentLoading = true;
      _paymentError = null;
    });

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final res = await context.read<OrderProvider>().submitPaymentProof(
      orderId: orderId,
      utrNumber: utr,
      paymentMethod: _paymentMethod,
      paymentDate: dateStr,
      amountPaid: amt,
      fileBytes: _paymentReceiptFile!.bytes ?? [],
      filename: _paymentReceiptFile!.name,
      notes: 'Submitted via Client Workspace Hub',
    );

    setState(() => _paymentLoading = false);

    if (res != null && res['error'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Payment submitted for verification. Order moved to PAYMENT_SUBMITTED.'),
          backgroundColor: AppColors.successAccent,
        ),
      );
      await _loadOrdersAndSync();
      _navigate(_Section.overview);
    } else {
      setState(() {
        _paymentError = res?['error']?.toString() ?? 'Payment submission failed.';
      });
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 7: TRACKING ENGINE (SLA Clock, Surveyor, Inspection, Drafting)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTrackingEngineView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final status = order['status'] ?? 'DRAFT';
    final ref = order['referenceCode'] ?? 'REQ-${order['id']}';
    final report = order['reportNumber'] ?? 'Pending Release';
    final paId = order['paId'];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operational Tracking & Telemetry Engine',
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Real-time telemetry heartbeat, valuer assignment, and inspection progress.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
            const SizedBox(height: 24),

            // SLA & Status Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Operational Status', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                          Text(status, style: GoogleFonts.robotoMono(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.successAccent),
                            const SizedBox(width: 6),
                            Text('SLA Clock Active', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.successAccent)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  _coordRow('Reference Code', ref, isMono: true),
                  _coordRow('Report Number', report, isMono: true),
                  _coordRow('Assigned Property Analyst', paId != null ? 'Valuer #$paId (IBBI Certified)' : 'Queued in Common Pool'),
                  _coordRow('Telemetry Heartbeat', '● Active (Synced 30s interval)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Detailed Stage Cards
            _trackingTimelineItem(
              title: '1. Intake Clearance & Pool Release',
              subtitle: 'Payment verified and report number assigned under strict 10-step governance gates.',
              isComplete: order['reportNumber'] != null,
            ),
            _trackingTimelineItem(
              title: '2. Certified Surveyor Assignment',
              subtitle: paId != null ? 'Assigned to Property Analyst for site coordination.' : 'Awaiting claim from unassigned pool.',
              isComplete: paId != null,
            ),
            _trackingTimelineItem(
              title: '3. Site Inspection & Photo Verification',
              subtitle: 'Physical inspection, boundary verification, and 4-category geo-tagged photo capture.',
              isComplete: status.contains('INSPECTION_COMPLETED') || status == 'DRAFTING' || status == 'UNDER_REVIEW' || status == 'DELIVERY_READY' || status == 'CLOSED',
            ),
            _trackingTimelineItem(
              title: '4. Dynamic Report Compilation',
              subtitle: 'Docx4j template compilation, formula indexation, and replacement cost benchmarks.',
              isComplete: status == 'UNDER_REVIEW' || status == 'SNAPSHOT_CREATED' || status == 'DELIVERY_READY' || status == 'CLOSED',
            ),
            _trackingTimelineItem(
              title: '5. Senior Valuer QA & Digital Signature',
              subtitle: 'SPA audit sign-off and Class 3 Cloud HSM cryptographic token sealing.',
              isComplete: status == 'SNAPSHOT_CREATED' || status == 'DELIVERY_READY' || status == 'CLOSED',
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingTimelineItem({required String title, required String subtitle, required bool isComplete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete ? AppColors.successBg : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isComplete ? AppColors.successBorder : AppColors.hairline),
      ),
      child: Row(
        children: [
          Icon(isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isComplete ? AppColors.successAccent : AppColors.slate),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 8: DELIVERABLES (Delivery Center, Tokenized AES-256 Download)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildDeliverablesView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final ref = order['referenceCode'] ?? 'REQ-${order['id']}';
    final status = order['status'] ?? 'DRAFT';
    final isDeliveryReady = status == 'DELIVERY_READY' || status == 'FINAL_DELIVERY' || status == 'CLIENT_DOWNLOADED' || status == 'CLOSED';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliverables & Secure Download Center',
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Cryptographically sealed valuation reports and compliance deliverables.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
            const SizedBox(height: 24),

            if (!isDeliveryReady)
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
                child: Column(
                  children: [
                    const Icon(Icons.lock_clock_outlined, size: 48, color: AppColors.warning),
                    const SizedBox(height: 16),
                    Text('Report Sealed & Pending Delivery Gate',
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('This order is currently in status $status. Once Senior Valuer QA sign-off and commercial gate clearance are completed, the AES-256 encrypted report will be released here.',
                        textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                  ],
                ),
              )
            else
              Column(
                children: [
                  // Deliverable Package Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.successBorder),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: AppColors.successAccent, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Certified Valuation Report Package Released',
                                      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  Text('Digitally signed via Cloud HSM Class 3 & protected with AES-256 encryption.',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 28),
                        Text('PDF Security Key Information',
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Your final report is encrypted for compliance. The password to open the PDF is your 10-digit registered mobile number.',
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _deliveryLoading ? null : () => _downloadReportViaToken(ref, 'REPORT_PDF'),
                              icon: const Icon(Icons.download_rounded, size: 16),
                              label: const Text('Download Encrypted PDF Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 14),
                            OutlinedButton.icon(
                              onPressed: () => _navigate(_Section.taxInvoices),
                              icon: const Icon(Icons.receipt_outlined, size: 16),
                              label: const Text('View Tax Invoice'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery Acknowledgement Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delivery Sign-Off & Clarification Window',
                            style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('Inspect your report. You can formally accept the report or request clarification within your SLA window prior to 10-year archival lock.',
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _acknowledgeReport(ref, 'ACCEPT'),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Acknowledge & Accept Report'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _promptClarification(ref),
                              icon: const Icon(Icons.chat_bubble_outline, size: 16),
                              label: const Text('Request Clarification'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReportViaToken(String refCode, String fileType) async {
    setState(() => _deliveryLoading = true);
    final orderProvider = context.read<OrderProvider>();

    try {
      final tokenRes = await orderProvider.generateDeliveryToken(refCode, fileType: fileType);
      if (tokenRes != null && tokenRes['token'] != null) {
        final token = tokenRes['token'] as String;
        final fileBytes = await orderProvider.streamDeliveryFile(token);

        setState(() => _deliveryLoading = false);

        if (fileBytes != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Downloaded Valuation_Report_$refCode.pdf (${(fileBytes.length / 1024).toStringAsFixed(1)} KB)'),
              backgroundColor: AppColors.successAccent,
            ),
          );
          await _loadOrdersAndSync();
        }
      } else {
        setState(() => _deliveryLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate secure delivery token.'), backgroundColor: AppColors.brandRedDark),
        );
      }
    } catch (e) {
      setState(() => _deliveryLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery error: $e'), backgroundColor: AppColors.brandRedDark),
      );
    }
  }

  Future<void> _acknowledgeReport(String refCode, String action) async {
    final res = await context.read<OrderProvider>().acknowledgeDelivery(
      refCode,
      action: action,
      acceptanceDeclaration: 'Client verified and accepted report deliverables under mandate terms.',
    );
    if (res != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Delivery acknowledged successfully.'), backgroundColor: AppColors.successAccent),
      );
      await _loadOrdersAndSync();
    }
  }

  void _promptClarification(String refCode) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Clarification from Valuer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter specific technical or boundary points requiring valuer clarification:'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context.read<OrderProvider>().acknowledgeDelivery(
                refCode,
                action: 'CLARIFICATION_REQUESTED',
                clarificationNotes: ctrl.text.trim(),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✓ Clarification request dispatched to Senior Valuer.')),
              );
            },
            child: const Text('Submit Clarification'),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 9: TAX INVOICES (GST Compliance SAC 998311)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTaxInvoicesView(OrderProvider orders) {
    final order = _selectedOrder;
    if (order == null) return const Center(child: Text('No mandate selected.'));

    final orderId = order['id'] as int;

    return FutureBuilder<Map<String, dynamic>?>(
      future: orders.fetchOrderInvoice(orderId),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final inv = snap.data;
        if (inv == null || inv['invoiceNumber'] == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_outlined, size: 48, color: AppColors.slate),
                  const SizedBox(height: 16),
                  Text('Tax Invoice Pending Release Gate', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('GST Tax invoices are generated during commercial gate release (DELIVERY_READY).',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                ],
              ),
            ),
          );
        }

        final invNum = inv['invoiceNumber'] ?? 'INV-PENDING';
        final total = (inv['grandTotal'] as num?)?.toDouble() ?? 0.0;
        final base = (inv['baseAmount'] as num?)?.toDouble() ?? 0.0;
        final tax = (inv['totalTax'] as num?)?.toDouble() ?? 0.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GST Tax Invoice & Compliance Voucher',
                    style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Official tax invoice under Section 31 of CGST Act 2017 (SAC Code 998311).',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Invoice No: $invNum', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700)),
                          Text('Status: ISSUED', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.successAccent)),
                        ],
                      ),
                      const Divider(height: 24),
                      _coordRow('Services Accounting Code (SAC)', '998311 (Valuation Services)'),
                      _coordRow('Base Professional Amount', '₹ ${base.toStringAsFixed(2)}'),
                      _coordRow('CGST + SGST (18%)', '₹ ${tax.toStringAsFixed(2)}'),
                      _coordRow('Total Stamped Value', '₹ ${total.toStringAsFixed(2)}', isMono: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SECTION 10: COMPLIANCE & SUPPORT
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildComplianceSupportView(OrderProvider orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compliance Archival & Helpdesk Support',
                style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text('Statutory governance archive and valuer helpdesk coordinates.',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.hairline)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statutory Archival Governance', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('All completed orders are sealed with a 10-year immutable audit lock as mandated under IBBI Asset Valuation rules. Once closed, reports remain perpetually verifiable via SHA-256 checksums.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Operations Helpdesk Contacts', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('• Email: operations@provaluer.com\n• Direct Line: +91 40 4859 1100 (09:00 - 18:00 IST)\n• Escalation: compliance@provaluer.com',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 1: Top Permanent Lifecycle Progress Tracker (16 Stages)
// ─────────────────────────────────────────────────────────────────────────────
class _PermanentLifecycleTracker extends StatelessWidget {
  final List<_StageMeta> stages;
  final int currentStageIndex;
  final dynamic order;

  const _PermanentLifecycleTracker({
    required this.stages,
    required this.currentStageIndex,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final currentStage = stages[currentStageIndex];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tracker Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.polyline_rounded, size: 20, color: AppColors.primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Permanent Lifecycle Progress Tracker',
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlueLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stage ${currentStageIndex + 1} of 16: ${currentStage.label}',
                  style: GoogleFonts.robotoMono(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Horizontal 16-Stage Chain
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(stages.length, (idx) {
                final s = stages[idx];
                final isCompleted = idx < currentStageIndex;
                final isCurrent = idx == currentStageIndex;

                return Row(
                  children: [
                    // Node
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? AppColors.successAccent
                                : (isCurrent ? AppColors.primaryBlue : AppColors.surfaceSoft),
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.successAccent
                                  : (isCurrent ? AppColors.primaryBlue : AppColors.hairlineStrong),
                              width: isCurrent ? 2 : 1,
                            ),
                            boxShadow: isCurrent
                                ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
                                : null,
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent ? Colors.white : AppColors.slate,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.shortCode,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                            color: isCompleted
                                ? AppColors.successAccent
                                : (isCurrent ? AppColors.primaryBlue : AppColors.slate),
                          ),
                        ),
                      ],
                    ),

                    // Connector line (except last)
                    if (idx < stages.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        color: idx < currentStageIndex ? AppColors.successAccent : AppColors.hairline,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 2: Middle Single Next Valid Action Spotlight
// ─────────────────────────────────────────────────────────────────────────────
class _SingleNextValidActionSpotlight extends StatelessWidget {
  final dynamic order;
  final int currentStageIndex;
  final ValueChanged<String> onActionTriggered;

  const _SingleNextValidActionSpotlight({
    required this.order,
    required this.currentStageIndex,
    required this.onActionTriggered,
  });

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] as String? ?? 'DRAFT').toUpperCase();
    final paymentStatus = (order['paymentStatus'] as String? ?? 'PENDING').toUpperCase();

    // Determine Spotlight Action Title, Description, and Buttons
    String title = 'Configure Valuation Parameters';
    String desc = 'Select your statutory service category to begin mandate processing.';
    List<Widget> actionButtons = [];

    if (status == 'DRAFT') {
      title = 'Select Service Category';
      desc = 'Choose between Valuation, Net Worth Certification, or Chartered Engineer services.';
      actionButtons = [
        _buildActionBtn('[ Select Service Category ]', Icons.category_outlined, () => onActionTriggered('SELECT_SERVICE')),
      ];
    } else if (status == 'QUOTE_PENDING') {
      title = 'Submission Under Commercial Review';
      desc = 'Your valuation dossier has been received and circle rates are being evaluated by our pricing desk.';
      actionButtons = [
        _buildActionBtn('[ View Submission Dossier ]', Icons.visibility_outlined, () => onActionTriggered('VIEW_DOSSIER')),
      ];
    } else if (status == 'QUOTE_PROVIDED') {
      if (paymentStatus == 'REJECTED') {
        title = 'Payment Proof Discrepancy — Action Required';
        desc = 'The accounts desk rejected the previous remittance. Please check the reason and resubmit fresh UTR.';
        actionButtons = [
          _buildActionBtn('[ Resubmit Payment Proof ]', Icons.refresh_rounded, () => onActionTriggered('RESUBMIT_PAYMENT'), isWarning: true),
        ];
      } else {
        title = 'Official Quotation Issued';
        desc = 'Your fee schedule and SLA commitment have been issued. Review and accept quote to proceed.';
        actionButtons = [
          _buildActionBtn('[ View Official Quotation ]', Icons.receipt_long_outlined, () => onActionTriggered('VIEW_QUOTE')),
          const SizedBox(width: 12),
          _buildActionBtn('[ Accept Quote & Proceed ]', Icons.check_circle_outline, () => onActionTriggered('ACCEPT_QUOTE'), isSecondary: true),
        ];
      }
    } else if (status == 'PAYMENT_SUBMITTED') {
      title = 'Payment Proof Under Verification';
      desc = 'Your remittance UTR and receipt document are undergoing bank settlement verification.';
      actionButtons = [
        _buildActionBtn('[ View Payment Status ]', Icons.hourglass_bottom_rounded, () => onActionTriggered('VIEW_PAYMENT_STATUS')),
      ];
    } else if (status == 'PAYMENT_VERIFIED') {
      title = 'Payment Verified & Confirmed';
      desc = 'Bank credit confirmed. Order is queued for administrative intake clearance and pool release.';
      actionButtons = [
        _buildActionBtn('[ Track Intake Clearance ]', Icons.fact_check_outlined, () => onActionTriggered('TRACK_ALLOCATION')),
      ];
    } else if (status == 'PAID_INTAKE') {
      title = 'Released to Operational Pool';
      desc = 'Official sequential Report ID assigned. Order is visible in global unassigned pool awaiting valuer claim.';
      actionButtons = [
        _buildActionBtn('[ Track Allocation Status ]', Icons.track_changes_outlined, () => onActionTriggered('TRACK_ALLOCATION')),
      ];
    } else if (status == 'ASSIGNED') {
      title = 'Property Analyst Claimed File';
      desc = 'Your mandate is actively claimed by a certified valuer. Telemetry heartbeat timer is running.';
      actionButtons = [
        _buildActionBtn('[ View Valuer Assignment ]', Icons.person_pin_outlined, () => onActionTriggered('VIEW_ASSIGNMENT')),
      ];
    } else if (status == 'INSPECTION_SCHEDULED') {
      title = 'Site Inspection Scheduled';
      desc = 'Physical site visit appointment confirmed with surveyor.';
      actionButtons = [
        _buildActionBtn('[ View Inspection Details ]', Icons.calendar_today_outlined, () => onActionTriggered('VIEW_INSPECTION')),
      ];
    } else if (status == 'INSPECTION_IN_PROGRESS') {
      title = 'Site Inspection In Progress';
      desc = 'Surveyor is actively capturing geo-tagged boundary photographs and notes.';
      actionButtons = [
        _buildActionBtn('[ Track Inspection Progress ]', Icons.camera_alt_outlined, () => onActionTriggered('TRACK_PROGRESS')),
      ];
    } else if (status == 'DRAFTING') {
      title = 'Dynamic Template Compilation Active';
      desc = 'Docx4j template engine is compiling land circle rates, building depreciation, and fair market value.';
      actionButtons = [
        _buildActionBtn('[ Track Compilation Progress ]', Icons.description_outlined, () => onActionTriggered('TRACK_PROGRESS')),
      ];
    } else if (status == 'UNDER_REVIEW' || status == 'SPA_REVIEW') {
      title = 'Senior Valuer Quality Audit';
      desc = 'Senior Property Analyst is verifying calculations and preparing Cloud HSM digital signature tokens.';
      actionButtons = [
        _buildActionBtn('[ Track Quality Review ]', Icons.verified_user_outlined, () => onActionTriggered('TRACK_PROGRESS')),
      ];
    } else if (status == 'SNAPSHOT_CREATED') {
      title = 'Valuation Snapshot Sealed';
      desc = 'Cryptographic document snapshot sealed. Passing commercial balance-due clearance check.';
      actionButtons = [
        _buildActionBtn('[ View Finalization Status ]', Icons.lock_outline, () => onActionTriggered('TRACK_PROGRESS')),
      ];
    } else if (status == 'DELIVERY_READY') {
      title = 'Final Report Ready for Download';
      desc = 'Commercial clearance passed. Stamped PDF report and tax invoice are released for secure retrieval.';
      actionButtons = [
        _buildActionBtn('[ Download Valuation Report ]', Icons.download_rounded, () => onActionTriggered('DOWNLOAD_REPORT')),
        const SizedBox(width: 12),
        _buildActionBtn('[ Download Tax Invoice ]', Icons.receipt_outlined, () => onActionTriggered('DOWNLOAD_INVOICE'), isSecondary: true),
      ];
    } else if (status == 'FINAL_DELIVERY' || status == 'CLIENT_DOWNLOADED') {
      title = 'Delivery Complete — Acknowledgement Open';
      desc = 'Inspect your report deliverables. Submit formal delivery acknowledgement or request clarification.';
      actionButtons = [
        _buildActionBtn('[ Acknowledge Report ]', Icons.check_circle_outline, () => onActionTriggered('ACKNOWLEDGE_REPORT')),
        const SizedBox(width: 12),
        _buildActionBtn('[ Request Clarification ]', Icons.chat_bubble_outline, () => onActionTriggered('REQUEST_CLARIFICATION'), isSecondary: true),
      ];
    } else if (status == 'CLOSED') {
      title = 'Mandate Closed & Archival Locked';
      desc = 'Order finalized under 10-year statutory compliance archive. Lifetime document download remains active.';
      actionButtons = [
        _buildActionBtn('[ Download Stored Report ]', Icons.download_done_rounded, () => onActionTriggered('DOWNLOAD_REPORT')),
        const SizedBox(width: 12),
        _buildActionBtn('[ Download Tax Invoice ]', Icons.receipt_outlined, () => onActionTriggered('DOWNLOAD_INVOICE'), isSecondary: true),
      ];
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFABB1F),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SINGLE NEXT VALID ACTION',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Guaranteed Zero Workflow Confusion',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFFCBD5E1), height: 1.4),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: actionButtons,
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, VoidCallback onPressed, {bool isSecondary = false, bool isWarning = false}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isWarning
            ? const Color(0xFFB91C1C)
            : (isSecondary ? const Color(0xFF1E293B) : AppColors.primaryBlue),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isSecondary ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 3: Lower Supporting Panels Workspace (5 Panels)
// ─────────────────────────────────────────────────────────────────────────────
class _SupportingPanelsWorkspace extends StatefulWidget {
  final dynamic order;
  final VoidCallback onViewDocuments;
  final VoidCallback onViewQuote;
  final VoidCallback onViewPayment;
  final VoidCallback onViewDelivery;
  final VoidCallback onRefresh;

  const _SupportingPanelsWorkspace({
    required this.order,
    required this.onViewDocuments,
    required this.onViewQuote,
    required this.onViewPayment,
    required this.onViewDelivery,
    required this.onRefresh,
  });

  @override
  State<_SupportingPanelsWorkspace> createState() => _SupportingPanelsWorkspaceState();
}

class _SupportingPanelsWorkspaceState extends State<_SupportingPanelsWorkspace> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryBlue,
            unselectedLabelColor: AppColors.slate,
            indicatorColor: AppColors.primaryBlue,
            indicatorWeight: 3,
            labelStyle: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(icon: Icon(Icons.shield_outlined, size: 18), text: 'Document Vault'),
              Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Order Timeline'),
              Tab(icon: Icon(Icons.payment_outlined, size: 18), text: 'Payment History'),
              Tab(icon: Icon(Icons.receipt_long_outlined, size: 18), text: 'Quote History'),
              Tab(icon: Icon(Icons.download_done_rounded, size: 18), text: 'Delivery Center'),
            ],
          ),
          SizedBox(
            height: 280,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Panel 1: Document Vault
                _buildPanel1DocumentVault(),
                // Panel 2: Order Timeline
                _buildPanel2OrderTimeline(),
                // Panel 3: Payment History
                _buildPanel3PaymentHistory(),
                // Panel 4: Quote History
                _buildPanel4QuoteHistory(),
                // Panel 5: Delivery Center
                _buildPanel5DeliveryCenter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel1DocumentVault() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Legal Ownership & Municipal Sanction Files',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
              TextButton(onPressed: widget.onViewDocuments, child: const Text('Open Full Vault →')),
            ],
          ),
          const SizedBox(height: 10),
          _docMiniRow('Registered Title Deed (Form 1)', 'VERIFIED', AppColors.successAccent),
          _docMiniRow('Approved Sanction Layout Drawing', 'VERIFIED', AppColors.successAccent),
          _docMiniRow('Current Year Municipal Tax Paid Receipt', 'VERIFIED', AppColors.successAccent),
        ],
      ),
    );
  }

  Widget _docMiniRow(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(name, style: GoogleFonts.inter(fontSize: 12.5)),
            ],
          ),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildPanel2OrderTimeline() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lifecycle State Transitions & Audit Trail',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _timelineMiniRow('Intake Order Initialized (REQ Code assigned)', 'Today, 10:15 AM'),
          _timelineMiniRow('Mandatory Title Documents Attached', 'Today, 10:16 AM'),
          _timelineMiniRow('Telegram Alert Dispatched to Operations Desk', 'Today, 10:17 AM'),
          _timelineMiniRow('Official Quotation Generated & Stamped', 'Today, 10:20 AM'),
        ],
      ),
    );
  }

  Widget _timelineMiniRow(String event, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Expanded(child: Text(event, style: GoogleFonts.inter(fontSize: 12))),
          Text(time, style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.slate)),
        ],
      ),
    );
  }

  Widget _buildPanel3PaymentHistory() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settlement History & Remittance Vouchers',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
              TextButton(onPressed: widget.onViewPayment, child: const Text('Manage Payments →')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Payment Status: ${widget.order['paymentStatus'] ?? 'PENDING'}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Latest UTR: ${widget.order['latestPaymentId'] != null ? 'Recorded in Payment Ledger' : 'No submission yet'}',
              style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text('Fee Balance Due: ₹ ${(widget.order['balanceDue'] ?? 0.0).toString()}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
        ],
      ),
    );
  }

  Widget _buildPanel4QuoteHistory() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quotation Record & Stamped PDF',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
              TextButton(onPressed: widget.onViewQuote, child: const Text('View Quotation Details →')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Quote Reference: ${widget.order['quoteNumber'] ?? 'Pending Issuance'}',
              style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Turnaround Commitment: ${widget.order['quoteTurnaround'] ?? '3-5 Working Days'}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text('Total Stamped Value: ₹ ${(widget.order['quoteTotal'] ?? widget.order['feeCharged'] ?? 0.0).toString()}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
        ],
      ),
    );
  }

  Widget _buildPanel5DeliveryCenter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Encrypted Package & Tax Invoice',
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
              TextButton(onPressed: widget.onViewDelivery, child: const Text('Open Delivery Center →')),
            ],
          ),
          const SizedBox(height: 12),
          Text('Deliverable Status: ${widget.order['status'] ?? 'DRAFT'}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('AES-256 PDF Password: 10-Digit Client Mobile Number',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text('Ephemeral Token: Single-use, 15-minute expiration window',
              style: GoogleFonts.robotoMono(fontSize: 11, color: AppColors.slate)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 4: Sidebar Navigation (Final Approved Menu)
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final bool collapsed;
  final _Section activeSection;
  final String fullName;
  final String email;
  final ValueChanged<_Section> onSection;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.collapsed,
    required this.activeSection,
    required this.fullName,
    required this.email,
    required this.onSection,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 72.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.brandNavy,
        border: Border(right: BorderSide(color: AppColors.brandNavyLight)),
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('PV', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ProValuer', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Client Portal', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // User Card
          if (!collapsed)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue,
                    child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _Section.values.map((s) {
                final isActive = activeSection == s;
                return ListTile(
                  dense: true,
                  leading: Icon(s.icon, color: isActive ? AppColors.primaryBlue : const Color(0xFF94A3B8), size: 20),
                  title: collapsed
                      ? null
                      : Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? Colors.white : const Color(0xFFCBD5E1),
                          ),
                        ),
                  selected: isActive,
                  selectedTileColor: const Color(0xFF1E293B),
                  onTap: () => onSection(s),
                );
              }).toList(),
            ),
          ),

          // Collapse & Logout
          const Divider(height: 1, color: Color(0xFF1E293B)),
          ListTile(
            dense: true,
            leading: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: const Color(0xFF94A3B8)),
            title: collapsed ? null : const Text('Collapse', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            onTap: onToggleCollapse,
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            title: collapsed ? null : const Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 5: Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String sectionLabel;
  final dynamic order;
  final VoidCallback onHomePressed;
  final VoidCallback onRefreshPressed;
  final VoidCallback onNewRequestPressed;

  const _TopBar({
    required this.sectionLabel,
    required this.order,
    required this.onHomePressed,
    required this.onRefreshPressed,
    required this.onNewRequestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(sectionLabel, style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
              if (order != null) ...[
                const SizedBox(width: 14),
                Text('•', style: TextStyle(color: AppColors.slate)),
                const SizedBox(width: 14),
                Text(
                  order['referenceCode'] ?? 'REQ-${order['id']}',
                  style: GoogleFonts.robotoMono(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                ),
              ],
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.slate),
                tooltip: 'Refresh Workspace',
                onPressed: onRefreshPressed,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onNewRequestPressed,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
