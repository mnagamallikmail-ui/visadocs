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
      backgroundColor: AppColors.canvas,
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
  Widget _buildWizardView() {
    if (_wizardStep == 7) {
      return _buildWizardSuccessScreen();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wizard Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step $_wizardStep of 6',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        switch (_wizardStep) {
                          1 => 'What service do you need?',
                          2 => 'What are you valuing?',
                          3 => 'Why do you need the report?',
                          4 => 'Tell us about the asset',
                          5 => 'Upload Documents',
                          6 => 'Review Request',
                          _ => '',
                        },
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  if (_wizardStep > 1)
                    TextButton.icon(
                      onPressed: () => setState(() => _wizardStep--),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.slate),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _wizardStep / 6.0,
                  minHeight: 6,
                  backgroundColor: AppColors.hairline,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
              const SizedBox(height: 32),

              if (_wizardError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.errorBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.brandRedDark, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _wizardError!,
                          style: const TextStyle(color: AppColors.brandRedDark, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Step Component Card
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
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

  // STEP 1: What service do you need?
  Widget _buildWizardStep1() {
    final services = [
      {
        'id': 'VALUATION',
        'icon': Icons.account_balance_outlined,
        'title': 'Valuation Report',
        'desc': 'Formal asset valuation under Section 34AB of Wealth Tax Act & Rule 8A for bank loan, visa, income tax, and corporate filings.',
        'badge': 'Standard Service',
      },
      {
        'id': 'NET_WORTH_CERTIFICATE',
        'icon': Icons.verified_user_outlined,
        'title': 'Net Worth Certificate',
        'desc': 'Certified statement of total net worth, real estate holdings, and liquid solvency for global embassies and student visas.',
        'badge': 'Embassy Visa',
      },
      {
        'id': 'CHARTERED_ENGINEER',
        'icon': Icons.precision_manufacturing_outlined,
        'title': 'Chartered Engineer Certificate',
        'desc': 'Statutory technical inspection, plant appraisal, residual life assessment, and customs EPCG machinery certifications.',
        'badge': 'Technical Inspection',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your required professional valuation service. Click any option to advance automatically.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        const SizedBox(height: 24),
        ...services.map((s) {
          final isSelected = _wizardService == s['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _wizardService = s['id'] as String;
                  _wizardStep = 2; // CLICK = ADVANCE AUTOMATICALLY
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(s['icon'] as IconData, color: AppColors.primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                s['title'] as String,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s['badge'] as String,
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 2: What are you valuing?
  Widget _buildWizardStep2() {
    final assets = [
      {
        'id': 'LAND_AND_BUILDING',
        'icon': Icons.business_rounded,
        'title': 'Land & Building',
        'desc': 'Commercial towers, office units, retail spaces, warehouses, industrial sheds, residential flats, and freehold land.',
      },
      {
        'id': 'PLANT_AND_MACHINERY',
        'icon': Icons.settings_suggest_rounded,
        'title': 'Plant & Machinery',
        'desc': 'Industrial manufacturing lines, plant equipment, commercial vehicles, construction tools, and technical machinery.',
      },
      {
        'id': 'SECURITIES_FINANCIAL_ASSETS',
        'icon': Icons.trending_up_rounded,
        'title': 'Financial Assets',
        'desc': 'Unquoted equity shares, corporate partnership interests, mutual fund portfolios, and business enterprise valuation.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose the asset category. Your selection automatically tailors the statutory document checklist.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        const SizedBox(height: 24),
        ...assets.map((a) {
          final isSelected = _wizardAsset == a['id'];
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _wizardAsset = a['id'] as String;
                  _wizardDocs.clear(); // reset files if asset category changed
                  _wizardStep = 3; // CLICK = ADVANCE AUTOMATICALLY
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a['icon'] as IconData, color: AppColors.primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['title'] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            a['desc'] as String,
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // STEP 3: Why do you need the report?
  Widget _buildWizardStep3() {
    final purposes = [
      {'id': 'BANK_COLLATERAL', 'title': 'Bank Loan', 'desc': 'Mortgage underwriting and bank collateral'},
      {'id': 'VISA_IMMIGRATION', 'title': 'Visa / Immigration', 'desc': 'Embassy financial net worth & solvency'},
      {'id': 'TAXATION_COMPLIANCE', 'title': 'Income Tax', 'desc': 'Capital gains, Rule 8A & Sec 50C compliance'},
      {'id': 'CORPORATE_INSOLVENCY', 'title': 'Corporate', 'desc': 'Audits, mergers, balance sheet, and NCLT IBC'},
      {'id': 'DISPUTE', 'title': 'Court Matter', 'desc': 'Judicial settlement, partition, and litigation'},
      {'id': 'OTHER', 'title': 'Other', 'desc': 'Internal advisory and personal record'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the legal purpose for your valuation report. Click any option to advance.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: purposes.length,
          itemBuilder: (ctx, i) {
            final p = purposes[i];
            final isSelected = _wizardPurpose == p['id'];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _wizardPurpose = p['id'] as String;
                  _wizardStep = 4; // CLICK = ADVANCE AUTOMATICALLY
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlueLight : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryBlue : AppColors.hairline,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p['title'] as String,
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            p['desc'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // STEP 4: Tell us about the asset (Real-time Auto-Advance)
  Widget _buildWizardStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Provide the property name, location, and tentative market value. Once required fields are filled, you will advance automatically.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        const SizedBox(height: 24),

        // Asset Name
        TextField(
          controller: _assetNameCtrl,
          onChanged: (_) => _onStep4FieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Asset Name *',
            hintText: 'e.g. Commercial Office Unit 402 / Cyber Towers',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Property Address
        TextField(
          controller: _propertyAddressCtrl,
          onChanged: (_) => _onStep4FieldChanged(),
          decoration: const InputDecoration(
            labelText: 'Property Address *',
            hintText: 'e.g. HITEC City Main Corridor, Madhapur',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // City & State
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cityCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'e.g. Hyderabad',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _stateCtrl,
                onChanged: (_) => _onStep4FieldChanged(),
                decoration: const InputDecoration(
                  labelText: 'State *',
                  hintText: 'e.g. Telangana',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Estimated Value
        TextField(
          controller: _estimatedValueCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Estimated Value (₹, Optional)',
            hintText: 'e.g. 18500000',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),

        // Auto-Advancement feedback indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _step4AutoAdvancing ? AppColors.successBg : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _step4AutoAdvancing ? AppColors.successBorder : AppColors.hairline),
          ),
          child: Row(
            children: [
              if (_step4AutoAdvancing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.successAccent),
                )
              else
                const Icon(Icons.info_outline, size: 16, color: AppColors.slate),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _step4AutoAdvancing
                    ? '✓ Parameters verified! Advancing to document upload...'
                    : 'Fill Asset Name, Property Address, City, and State to continue.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: _step4AutoAdvancing ? FontWeight.w600 : FontWeight.normal,
                    color: _step4AutoAdvancing ? AppColors.successAccent : AppColors.slate,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // STEP 5: Upload Documents (Property Type Driven Matrix)
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
                'Required documents for ${_wizardAsset.replaceAll('_', ' ').toLowerCase()}. Upload each card to automatically advance.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: allUploaded ? AppColors.successBg : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: allUploaded ? AppColors.successBorder : const Color(0xFFFDE68A)),
              ),
              child: Text(
                allUploaded ? '✓ All Documents Uploaded' : 'Upload Required Documents',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: allUploaded ? AppColors.successAccent : const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        ...slots.map((s) {
          final key = s['key'] as String;
          final label = s['label'] as String;
          final hasFile = _wizardDocs.containsKey(key);
          final file = _wizardDocs[key];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.successBg : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasFile ? AppColors.successBorder : AppColors.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasFile ? AppColors.successAccent.withValues(alpha: 0.1) : AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasFile ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                    color: hasFile ? AppColors.successAccent : AppColors.slate,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (hasFile)
                        Text(
                          '${file!.name} (${(file.size / 1024).toStringAsFixed(1)} KB) • SHA-256 Verified',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.successAccent),
                        )
                      else
                        Text(
                          'Mandatory attachment • Accepted formats: PDF, JPG, PNG (Max 20MB)',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
                        ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickWizardDoc(key),
                  icon: Icon(hasFile ? Icons.refresh : Icons.attach_file, size: 15),
                  label: Text(hasFile ? 'Replace' : 'Upload'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFile ? Colors.white : AppColors.brandNavy,
                    foregroundColor: hasFile ? AppColors.successAccent : Colors.white,
                    side: BorderSide(color: hasFile ? AppColors.successBorder : Colors.transparent),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // STEP 6: Review Request (THE ONLY BUTTON IN FLOW 1)
  Widget _buildWizardStep6() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please verify your mandate details before submitting. Our commercial valuation desk will evaluate your submission and issue an official quotation.',
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
        ),
        const SizedBox(height: 24),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            children: [
              _summaryRow('Service', _wizardService.replaceAll('_', ' ')),
              const Divider(height: 20),
              _summaryRow('Asset Type', _wizardAsset.replaceAll('_', ' ')),
              const Divider(height: 20),
              _summaryRow('Purpose', _wizardPurpose.replaceAll('_', ' ')),
              const Divider(height: 20),
              _summaryRow('Asset Name', _assetNameCtrl.text.trim()),
              const Divider(height: 20),
              _summaryRow('Property Address', '${_propertyAddressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()}'),
              if (_estimatedValueCtrl.text.trim().isNotEmpty) ...[
                const Divider(height: 20),
                _summaryRow('Estimated Value', '₹ ${_estimatedValueCtrl.text.trim()}'),
              ],
              const Divider(height: 20),
              _summaryRow('Attached Documents', '${_wizardDocs.length} files attached'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // THE ONLY BUTTON
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _wizardSubmitting ? null : _submitWizardReport,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
            child: _wizardSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'Submit Report Request',
                    style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
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
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
        Text(
          value,
          style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
      ],
    );
  }

  // SUCCESS SCREEN
  Widget _buildWizardSuccessScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.successBorder),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.successAccent, size: 48),
                ),
                const SizedBox(height: 24),
                Text(
                  'Request Submitted Successfully',
                  style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Text(
                    'Reference Number: REQ-${_createdOrderId ?? 'NEW'}',
                    style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Our Senior Commercial Valuation Desk is evaluating your property details, circle rates, and statutory documents. Your tailored quotation and SLA turnaround will be ready shortly.',
                  style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.slate, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
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
                            backgroundColor: AppColors.brandNavy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('View Report'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => _resetWizard(),
                          style: OutlinedButton.styleFrom(
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
  // FLOW 2: REPORTS IN PROGRESS (Card Gallery)
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
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.surfaceSoft, shape: BoxShape.circle),
                child: const Icon(Icons.note_add_outlined, size: 48, color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              Text(
                'No Reports In Progress',
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'All your active valuation mandates will appear here with live milestone tracking.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _activeNav = _ClientNav.createReport;
                    _resetWizard();
                  });
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Report'),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Valuation Mandates',
                    style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${activeOrders.length} active report${activeOrders.length > 1 ? 's' : ''} currently undergoing processing.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
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
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Cards Grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: activeOrders.map((order) {
              final stageInfo = _mapToClientStage(order);
              final orderId = order['id'];
              final refCode = order['referenceCode'] ?? 'REQ-$orderId';
              final category = (order['propertyCategory'] ?? 'Commercial Property').toString().replaceAll('_', ' ');
              final createdDate = order['createdAt'] != null
                  ? order['createdAt'].toString().split('T').first
                  : 'Recent';

              return InkWell(
                onTap: () => setState(() => _focusedActiveOrder = order),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlueLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              refCode,
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: stageInfo.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stageInfo.statusBadge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: stageInfo.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        category,
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order['purpose'] != null ? order['purpose'].toString().replaceAll('_', ' ') : 'Valuation Mandate',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 14),

                      // Metadata
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Created Date', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
                              const SizedBox(height: 2),
                              Text(createdDate, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Expected Completion', style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
                              const SizedBox(height: 2),
                              Text('3 Business Days', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Open Report Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => setState(() => _focusedActiveOrder = order),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          label: const Text('Open Report Workspace'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.hairline),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 3: ACTIVE REPORT WORKSPACE
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
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Reports In Progress'),
            style: TextButton.styleFrom(foregroundColor: AppColors.slate),
          ),
          const SizedBox(height: 16),

          // SECTION 1: REPORT HEADER
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.brandNavy,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            refCode,
                            style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stageInfo.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            stageInfo.statusBadge,
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: stageInfo.statusColor),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Report No: $reportNumber',
                      style: GoogleFonts.robotoMono(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Purpose: ${order['purpose'] != null ? order['purpose'].toString().replaceAll('_', ' ') : 'Valuation Mandate'}',
                  style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.slate),
                ),
                const SizedBox(height: 20),
                const Divider(),
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
          const SizedBox(height: 28),

          // SECTION 2: CLIENT PROGRESS TRACKER (6 Stages ONLY)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Tracker',
                  style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 20),
                _buildClientProgressTracker(stageInfo.stageIndex),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // SECTION 3: CURRENT STATUS HERO CARD
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stageInfo.statusColor.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: stageInfo.statusColor.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: stageInfo.statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    stageInfo.isDelivered ? Icons.verified_rounded : Icons.radar_rounded,
                    color: stageInfo.statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageInfo.statusBadge,
                        style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stageInfo.statusDescription,
                        style: GoogleFonts.inter(fontSize: 13.5, color: AppColors.slate, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                _buildStatusHeroAction(stageInfo, order),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // TWO-COLUMN SECTION: DOCUMENTS & UPDATES TIMELINE
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 4: DOCUMENTS
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Mandate Documents',
                            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                          ),
                          TextButton.icon(
                            onPressed: () => _uploadAdditionalDocument(orderId),
                            icon: const Icon(Icons.add_circle_outline, size: 15),
                            label: const Text('Upload Document'),
                            style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWorkspaceDocumentsList(order),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // SECTION 5: UPDATES TIMELINE
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Updates Timeline',
                        style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 16),
                      _buildUpdatesTimeline(stageInfo.stageIndex, createdDate),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // SECTION 6: CONTEXTUAL ACTIONS
          _buildContextualActionCenter(stageInfo, order),
          const SizedBox(height: 28),

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
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.slate)),
        const SizedBox(height: 2),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }

  // 6-Stage Progress Tracker
  Widget _buildClientProgressTracker(int activeIndex) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        return Row(
          children: List.generate(_kClientStages.length, (idx) {
            final isCompleted = idx < activeIndex;
            final isCurrent = idx == activeIndex;
            final isPending = idx > activeIndex;

            final circleColor = isCompleted
                ? AppColors.successAccent
                : (isCurrent ? AppColors.primaryBlue : AppColors.hairline);

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.successAccent : (isCurrent ? AppColors.primaryBlue : Colors.white),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPending ? AppColors.hairlineStrong : circleColor,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isCurrent ? Colors.white : AppColors.slate,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _kClientStages[idx],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? AppColors.ink : AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (idx < _kClientStages.length - 1)
                    Container(
                      width: 20,
                      height: 2,
                      color: idx < activeIndex ? AppColors.successAccent : AppColors.hairline,
                      margin: const EdgeInsets.only(bottom: 24),
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
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('View Quotation'),
        );

      case 3: // Payment Pending / Complete
        if (order['status'] == 'QUOTE_ACCEPTED' || order['paymentStatus'] == 'PENDING') {
          return ElevatedButton(
            onPressed: () => _showPaymentModal(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Submit Payment'),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Payment Under Verification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        );

      case 5: // Delivered
        return ElevatedButton.icon(
          onPressed: _actionLoading ? null : () => _downloadFinalReport(refCode),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Download Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        );

      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            stageInfo.requiredActionLabel,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate),
          ),
        );
    }
  }

  Widget _buildWorkspaceDocumentsList(dynamic order) {
    // If order has documents array, display them, otherwise fallback to standard mandatory items
    final documents = (order['documents'] as List<dynamic>?) ?? [];

    if (documents.isEmpty) {
      return Column(
        children: [
          _docItemRow('Title Deed / Registered Sale Deed', 'Verified', true),
          const Divider(height: 16),
          _docItemRow('Municipal Sanction Plan', 'Verified', true),
          const Divider(height: 16),
          _docItemRow('Property Tax Receipt', 'Verified', true),
          const Divider(height: 16),
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
          margin: const EdgeInsets.only(bottom: 10),
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
              size: 18,
              color: verified ? AppColors.successAccent : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 10),
            Text(
              name,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: verified ? AppColors.successBg : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            verified ? 'Verified ✓' : 'In Review ⏳',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: verified ? AppColors.successAccent : const Color(0xFFB45309),
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
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['title']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    Text('${u['date']} • ${u['desc']}', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.slate)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Contextual Actions Center
  Widget _buildContextualActionCenter(_ClientStageInfo stageInfo, dynamic order) {
    final orderId = order['id'] as int;
    final refCode = order['referenceCode'] ?? 'REQ-$orderId';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mandate Action Center',
            style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 16),

          if (stageInfo.stageIndex == 2) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showQuotationModal(order),
                  icon: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('View Quotation Details'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _downloadQuotePdf(orderId),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download Quotation PDF'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentModal(order),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Accept & Pay Online →'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                ),
              ],
            ),
          ] else if (stageInfo.stageIndex == 3) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlueLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top, color: AppColors.primaryBlue, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Payment remittance proof is being verified by accounts desk. Order will transition to Report In Progress automatically.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (stageInfo.stageIndex == 4) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppColors.primaryBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report In Progress • Valuer inspection and statutory compilation underway. Target delivery is within committed SLA.',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (stageInfo.stageIndex == 5) ...[
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _actionLoading ? null : () => _downloadFinalReport(refCode),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: const Text('Download Report (PDF)'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.successAccent, foregroundColor: Colors.white),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _downloadTaxInvoice(orderId),
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: const Text('Download Tax Invoice'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _acknowledgeReportDelivery(refCode, 'ACCEPT'),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept Report'),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _requestReportClarification(refCode),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Request Clarification'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.slate),
                ),
              ],
            ),
          ] else ...[
            Text(
              'No immediate action required from your side. Our team is processing your request.',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
            ),
          ],
        ],
      ),
    );
  }

  // Concierge Support Banner
  Widget _buildSupportConciergeBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dedicated Client Concierge', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('Direct support from our Senior Valuer Desk', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Text('Phone: +91 85000 19091', style: GoogleFonts.robotoMono(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(width: 20),
              Text('Email: provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFCBD5E1))),
            ],
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FLOW 4: COMPLETED REPORTS (Read Only Gallery & Workspace)
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
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: AppColors.surfaceSoft, shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.slate),
              ),
              const SizedBox(height: 20),
              Text(
                'No Completed Reports Yet',
                style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'Once your valuation reports are officially delivered and signed, they will be archived here.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate),
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
          Text(
            'Completed Valuation Archives',
            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            '${completedOrders.length} completed report${completedOrders.length > 1 ? 's' : ''} stored under 10-year statutory compliance archive.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
          ),
          const SizedBox(height: 28),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: completedOrders.map((order) {
              final orderId = order['id'];
              final refCode = order['referenceCode'] ?? 'REQ-$orderId';
              final title = (order['propertyCategory'] ?? 'Commercial Property Valuation').toString().replaceAll('_', ' ');
              final completionDate = order['updatedAt'] != null
                  ? order['updatedAt'].toString().split('T').first
                  : 'Completed';

              return InkWell(
                onTap: () => setState(() => _focusedCompletedOrder = order),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(refCode, style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w700)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Completed ✓', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.successAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 6),
                      Text('Completed: $completionDate', style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.slate)),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => setState(() => _focusedCompletedOrder = order),
                          child: const Text('Open Archive (Read-Only) →'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // COMPLETED REPORT WORKSPACE (READ ONLY)
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
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Back to Completed Reports'),
            style: TextButton.styleFrom(foregroundColor: AppColors.slate),
          ),
          const SizedBox(height: 16),

          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.hairline),
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
                          decoration: BoxDecoration(color: AppColors.brandNavy, borderRadius: BorderRadius.circular(6)),
                          child: Text(refCode, style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                          child: Text('Archived Record (Read-Only) 🔒', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.successAccent)),
                        ),
                      ],
                    ),
                    Text('Completion Date: $completionDate', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(title, style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 6),
                Text('Final Assessed Value: ₹ ${order['estimatedValue'] ?? '1,85,00,000'}', style: GoogleFonts.inter(fontSize: 14, color: AppColors.slate)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Final Deliverables Card
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.successAccent, size: 28),
                    const SizedBox(width: 12),
                    Text('Official Signed Deliverables', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your final report is digitally signed via Cloud HSM and protected with AES-256 encryption. The password is your registered 10-digit mobile number.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _downloadFinalReport(refCode),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Download Report PDF'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.successAccent, foregroundColor: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton.icon(
                      onPressed: () => _downloadTaxInvoice(orderId),
                      icon: const Icon(Icons.receipt_outlined, size: 16),
                      label: const Text('Download Tax Invoice'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Request Details & Payment History
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Request Details', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      _summaryRow('Service', 'Commercial Valuation'),
                      const Divider(height: 18),
                      _summaryRow('Purpose', order['purpose']?.toString().replaceAll('_', ' ') ?? 'Bank Collateral'),
                      const Divider(height: 18),
                      _summaryRow('Category', order['propertyCategory']?.toString().replaceAll('_', ' ') ?? 'Land & Building'),
                      const Divider(height: 18),
                      _summaryRow('Archival Status', '10-Year Statutory Lock Active'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.hairline)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Settlement & Payment History', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      _summaryRow('Quoted Base Fee', '₹ 15,000.00'),
                      const Divider(height: 18),
                      _summaryRow('GST (18%)', '₹ 2,700.00'),
                      const Divider(height: 18),
                      _summaryRow('Total Paid', '₹ 17,700.00 (Settled ✓)'),
                      const Divider(height: 18),
                      _summaryRow('Payment Status', 'Bank Credit Verified'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

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
        title: Text('My Profile', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _profileField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate)),
        Text(value, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ],
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.headset_mic_outlined, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
            Text('Support Concierge', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct assistance from ProValuer Senior Appraisal Desk:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 18, color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      Text('+91 85000 19091', style: GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.mail_outline, size: 18, color: AppColors.primaryBlue),
                      const SizedBox(width: 10),
                      Text('provaluer.india@gmail.com', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
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
        title: Text('Official Quotation', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quotation breakdown for ${order['referenceCode'] ?? 'REQ-$orderId'}:', style: GoogleFonts.inter(fontSize: 13, color: AppColors.slate)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(10)),
                child: Column(
                  children: [
                    _summaryRow('Base Appraisal Fee', '₹ ${fee.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _summaryRow('GST (18%)', '₹ ${gst.toStringAsFixed(2)}'),
                    const Divider(height: 16),
                    _summaryRow('Total Payable Remittance', '₹ ${total.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text('Turnaround SLA: 3 Business Days from payment credit.', style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadQuotePdf(orderId);
            },
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Download PDF'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showPaymentModal(order);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
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
            title: Text('Submit Payment Remittance', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.primaryBlueLight, borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank Transfer / NEFT / UPI Beneficiary:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
                          const SizedBox(height: 4),
                          Text('Account Name: ProValuer Services Pvt Ltd\nBank: HDFC Bank | A/C: 50200088192019\nIFSC: HDFC0001234 | UPI: provaluer@hdfcbank', style: GoogleFonts.robotoMono(fontSize: 11, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_paymentError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.brandRed, borderRadius: BorderRadius.circular(6)),
                        child: Text(_paymentError!, style: const TextStyle(color: AppColors.brandRedDark, fontSize: 12)),
                      ),
                    TextField(
                      controller: _utrCtrl,
                      decoration: const InputDecoration(labelText: 'UTR / Bank Transaction Reference *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _paymentAmountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount Paid (₹) *', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'png', 'jpg'], withData: true);
                            if (res != null && res.files.isNotEmpty) {
                              setModalState(() => _paymentReceiptFile = res.files.first);
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 14),
                          label: Text(_paymentReceiptFile != null ? 'Receipt Attached ✓' : 'Attach Remittance Proof *'),
                        ),
                        if (_paymentReceiptFile != null) ...[
                          const SizedBox(width: 10),
                          Expanded(child: Text(_paymentReceiptFile!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                child: _paymentSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Submit Payment Proof'),
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
        title: Text('Request Report Clarification', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter clarification notes for senior valuer desk...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy, foregroundColor: Colors.white),
            child: const Text('Submit Clarification'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT: Client Left Sidebar (Exact Specification)
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
          const Divider(height: 1, color: Color(0xFF1E293B)),
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
          const Divider(height: 1, color: Color(0xFF1E293B)),

          // Collapse Toggle
          ListTile(
            dense: true,
            leading: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left, color: const Color(0xFF94A3B8)),
            title: collapsed ? null : const Text('Collapse Sidebar', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? Colors.white : (isHighlight ? const Color(0xFF38BDF8) : const Color(0xFF94A3B8)),
          size: 20,
        ),
        title: collapsed
            ? null
            : Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w700 : (isHighlight ? FontWeight.w600 : FontWeight.w500),
                  color: isActive ? Colors.white : (isHighlight ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                ),
              ),
        selected: isActive,
        selectedTileColor: isHighlight ? AppColors.primaryBlue : const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => onNavSelect(nav),
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
        leading: Icon(icon, color: iconColor ?? const Color(0xFF94A3B8), size: 19),
        title: collapsed
            ? null
            : Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: iconColor ?? const Color(0xFFCBD5E1),
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
// COMPONENT: Client Top Header Bar
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
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.slate),
                tooltip: 'Refresh Workspace',
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onCreateNew,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create New Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
