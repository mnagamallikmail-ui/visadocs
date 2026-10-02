// ─────────────────────────────────────────────────────────────────────────────
// ClientWorkspaceHub
// Unified Client Portal — replaces all legacy intake / quote / payment modals.
// Route: /client
// RBAC: CLIENT role only — no access to PA / SPA / Admin workspaces.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_components.dart';

// ─── Nav Sections ────────────────────────────────────────────────────────────
enum _Section {
  myProjects,
  newRequest,
  documents,
  quotation,
  payment,
  tracking,
  delivery,
}

extension _SectionMeta on _Section {
  String get label => switch (this) {
        _Section.myProjects => 'My Projects',
        _Section.newRequest => 'New Request',
        _Section.documents => 'Documents',
        _Section.quotation => 'Quotation',
        _Section.payment => 'Payment',
        _Section.tracking => 'Tracking',
        _Section.delivery => 'Delivery',
      };

  IconData get icon => switch (this) {
        _Section.myProjects => Icons.folder_open_outlined,
        _Section.newRequest => Icons.add_circle_outline,
        _Section.documents => Icons.upload_file_outlined,
        _Section.quotation => Icons.receipt_long_outlined,
        _Section.payment => Icons.payment_outlined,
        _Section.tracking => Icons.track_changes_outlined,
        _Section.delivery => Icons.download_outlined,
      };
}

// ─── Document categories ─────────────────────────────────────────────────────
const List<String> _kDocCategories = [
  'IDENTITY_PROOF',
  'PROPERTY_OWNERSHIP',
  'SITE_PLAN',
  'NOC',
  'OTHER',
];

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class ClientWorkspaceHub extends StatefulWidget {
  const ClientWorkspaceHub({super.key});

  @override
  State<ClientWorkspaceHub> createState() => _ClientWorkspaceHubState();
}

class _ClientWorkspaceHubState extends State<ClientWorkspaceHub>
    with TickerProviderStateMixin {
  _Section _activeSection = _Section.myProjects;
  dynamic _selectedOrder; // currently focused order map
  bool _sidebarCollapsed = false;

  // New Request form state
  final _newReqFormKey = GlobalKey<FormState>();
  final _purposeCtrl = TextEditingController();
  final _estimatedValueCtrl = TextEditingController();
  String _selectedCategory = 'PROPERTY';
  bool _newReqLoading = false;
  String? _newReqError;

  // Document upload state
  bool _uploadLoading = false;
  String? _uploadError;
  String? _uploadSuccess;
  String _selectedDocCategory = _kDocCategories.first;

  // Payment form state
  final _utrCtrl = TextEditingController();
  final _paymentDateCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _paymentMethod = 'NEFT';
  bool _paymentLoading = false;
  String? _paymentError;
  String? _paymentSuccess;
  List<int>? _paymentFileBytes;
  String? _paymentFileName;

  // Delivery state
  bool _deliveryLoading = false;
  String? _deliveryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchClientOrders();
    });
  }

  @override
  void dispose() {
    _purposeCtrl.dispose();
    _estimatedValueCtrl.dispose();
    _utrCtrl.dispose();
    _paymentDateCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  void _navigate(_Section section, {dynamic order}) {
    setState(() {
      _activeSection = section;
      if (order != null) _selectedOrder = order;
      _newReqError = null;
      _uploadError = null;
      _uploadSuccess = null;
      _paymentError = null;
      _paymentSuccess = null;
      _paymentFileBytes = null;
      _paymentFileName = null;
      _deliveryError = null;
    });
  }

  Color _statusColor(String? status) => switch (status) {
        'DRAFT' => AppColors.steel,
        'SUBMITTED' => AppColors.primaryBlue,
        'QUOTE_PENDING' || 'QUOTED' => AppColors.warning,
        'PAYMENT_PENDING' || 'PAYMENT_REVIEW' => AppColors.warning,
        'PAID' || 'RELEASED_TO_POOL' => AppColors.successAccent,
        'IN_PROGRESS' ||
        'INSPECTION_SCHEDULED' ||
        'INSPECTION_COMPLETE' =>
          AppColors.primaryBlue,
        'REPORT_DRAFT' || 'SPA_REVIEW' => AppColors.brandNavyLight,
        'DELIVERED' => AppColors.successAccent,
        'CLOSED' => AppColors.steel,
        _ => AppColors.steel,
      };

  String _statusLabel(String? status) => switch (status) {
        'DRAFT' => 'Draft',
        'SUBMITTED' => 'Submitted',
        'QUOTE_PENDING' => 'Awaiting Quote',
        'QUOTED' => 'Quote Ready',
        'PAYMENT_PENDING' => 'Payment Required',
        'PAYMENT_REVIEW' => 'Payment Under Review',
        'PAID' => 'Paid',
        'RELEASED_TO_POOL' => 'Assigned',
        'IN_PROGRESS' => 'In Progress',
        'INSPECTION_SCHEDULED' => 'Inspection Scheduled',
        'INSPECTION_COMPLETE' => 'Inspection Done',
        'REPORT_DRAFT' => 'Report Drafting',
        'SPA_REVIEW' => 'Under Review',
        'BALANCE_PAYMENT_PENDING' => 'Balance Due',
        'DELIVERED' => 'Delivered',
        'CLOSED' => 'Closed',
        _ => status ?? '—',
      };

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final orders = context.watch<OrderProvider>();
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────────────
          _Sidebar(
            collapsed: _sidebarCollapsed || isNarrow,
            activeSection: _activeSection,
            fullName: auth.fullName ?? 'Client',
            email: auth.email ?? '',
            onSection: _navigate,
            onToggleCollapse: () =>
                setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            onLogout: () {
              auth.logout();
              context.go('/');
            },
          ),

          // ── Main Content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _TopBar(
                  sectionLabel: _activeSection.label,
                  onHomePressed: () => context.go('/'),
                ),
                // Content
                Expanded(
                  child: _buildSection(orders, auth),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(OrderProvider orders, AuthProvider auth) {
    return switch (_activeSection) {
      _Section.myProjects => _MyProjectsSection(
          orders: orders.clientOrders,
          isLoading: false,
          onRefresh: () => orders.fetchClientOrders(),
          onSelectOrder: (o) => _navigate(_Section.tracking, order: o),
          onNewRequest: () => _navigate(_Section.newRequest),
          statusColor: _statusColor,
          statusLabel: _statusLabel,
        ),
      _Section.newRequest => _NewRequestSection(
          formKey: _newReqFormKey,
          purposeCtrl: _purposeCtrl,
          estimatedValueCtrl: _estimatedValueCtrl,
          selectedCategory: _selectedCategory,
          loading: _newReqLoading,
          error: _newReqError,
          onCategoryChanged: (v) => setState(() => _selectedCategory = v),
          onSubmit: () => _handleNewRequest(orders),
          onBack: () => _navigate(_Section.myProjects),
        ),
      _Section.documents => _DocumentsSection(
          order: _selectedOrder,
          loading: _uploadLoading,
          error: _uploadError,
          success: _uploadSuccess,
          selectedCategory: _selectedDocCategory,
          onCategoryChanged: (v) =>
              setState(() => _selectedDocCategory = v),
          onUpload: (bytes, filename) =>
              _handleUpload(orders, bytes, filename),
          onBack: () => _navigate(_Section.myProjects),
        ),
      _Section.quotation => _QuotationSection(
          order: _selectedOrder,
          orders: orders,
          onBack: () => _navigate(_Section.myProjects),
          onPayNow: () => _navigate(_Section.payment),
        ),
      _Section.payment => _PaymentSection(
          order: _selectedOrder,
          utrCtrl: _utrCtrl,
          paymentDateCtrl: _paymentDateCtrl,
          amountCtrl: _amountCtrl,
          paymentMethod: _paymentMethod,
          loading: _paymentLoading,
          error: _paymentError,
          success: _paymentSuccess,
          fileBytes: _paymentFileBytes,
          fileName: _paymentFileName,
          onMethodChanged: (v) => setState(() => _paymentMethod = v),
          onFilePicked: (bytes, name) => setState(() {
            _paymentFileBytes = bytes;
            _paymentFileName = name;
          }),
          onSubmit: () => _handlePaymentSubmit(orders),
          onBack: () => _navigate(_Section.quotation),
        ),
      _Section.tracking => _TrackingSection(
          order: _selectedOrder,
          orders: orders,
          statusColor: _statusColor,
          statusLabel: _statusLabel,
          onUploadDocs: () => _navigate(_Section.documents),
          onViewQuote: () => _navigate(_Section.quotation),
          onPay: () => _navigate(_Section.payment),
          onDownload: () => _navigate(_Section.delivery),
          onBack: () => _navigate(_Section.myProjects),
        ),
      _Section.delivery => _DeliverySection(
          order: _selectedOrder,
          orders: orders,
          loading: _deliveryLoading,
          error: _deliveryError,
          onDownload: (refCode) => _handleDeliveryDownload(orders, refCode),
          onAcknowledge: (refCode) => _handleAcknowledge(orders, refCode),
          onBack: () => _navigate(_Section.tracking),
        ),
    };
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleNewRequest(OrderProvider orders) async {
    if (!_newReqFormKey.currentState!.validate()) return;
    setState(() {
      _newReqLoading = true;
      _newReqError = null;
    });
    final estimatedValue =
        double.tryParse(_estimatedValueCtrl.text.trim()) ?? 0.0;
    final result = await orders.saveDraft(
      _selectedCategory,
      _purposeCtrl.text.trim(),
      estimatedValue,
      {},
    );
    setState(() => _newReqLoading = false);
    if (result != null && result['id'] != null) {
      final submitResult =
          await orders.submitRequest(result['id'] as int);
      if (submitResult != null) {
        _purposeCtrl.clear();
        _estimatedValueCtrl.clear();
        await orders.fetchClientOrders();
        _navigate(_Section.myProjects);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request submitted — check My Projects.'),
              backgroundColor: AppColors.successAccent,
            ),
          );
        }
      } else {
        setState(
            () => _newReqError = 'Submission failed. Please try again.');
      }
    } else {
      setState(
          () => _newReqError = 'Could not create request. Please retry.');
    }
  }

  Future<void> _handleUpload(
      OrderProvider orders, List<int> bytes, String filename) async {
    if (_selectedOrder == null) return;
    setState(() {
      _uploadLoading = true;
      _uploadError = null;
      _uploadSuccess = null;
    });
    final result = await orders.uploadDocument(
      _selectedOrder['id'] as int,
      _selectedDocCategory,
      filename,
      bytes,
    );
    setState(() => _uploadLoading = false);
    if (result.success) {
      setState(() => _uploadSuccess = 'Document uploaded successfully.');
    } else {
      setState(() => _uploadError =
          result.errorMessage ?? 'Upload failed. Please retry.');
    }
  }

  Future<void> _handlePaymentSubmit(OrderProvider orders) async {
    if (_selectedOrder == null) return;
    if (_paymentFileBytes == null || _paymentFileName == null) {
      setState(() => _paymentError = 'Please select a payment receipt file.');
      return;
    }
    final utr = _utrCtrl.text.trim();
    final date = _paymentDateCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    if (utr.isEmpty || date.isEmpty || amount <= 0) {
      setState(() => _paymentError =
          'Please fill in UTR number, payment date, and amount.');
      return;
    }
    setState(() {
      _paymentLoading = true;
      _paymentError = null;
      _paymentSuccess = null;
    });
    final result = await orders.submitPaymentProof(
      orderId: _selectedOrder['id'] as int,
      utrNumber: utr,
      paymentMethod: _paymentMethod,
      paymentDate: date,
      amountPaid: amount,
      fileBytes: _paymentFileBytes!,
      filename: _paymentFileName!,
    );
    setState(() => _paymentLoading = false);
    if (result != null && result['error'] == null) {
      await orders.fetchClientOrders();
      setState(() => _paymentSuccess =
          'Payment proof submitted. Awaiting verification.');
    } else {
      setState(() => _paymentError =
          result?['error']?.toString() ?? 'Submission failed. Please retry.');
    }
  }

  Future<void> _handleDeliveryDownload(
      OrderProvider orders, String refCode) async {
    setState(() {
      _deliveryLoading = true;
      _deliveryError = null;
    });
    final tokenResp =
        await orders.generateDeliveryToken(refCode);
    if (tokenResp == null || tokenResp['token'] == null) {
      setState(() {
        _deliveryLoading = false;
        _deliveryError = 'Could not generate download link.';
      });
      return;
    }
    await orders.streamDeliveryFile(tokenResp['token'] as String);
    setState(() => _deliveryLoading = false);
    // Bytes are available for further processing (save/web download).
  }

  Future<void> _handleAcknowledge(
      OrderProvider orders, String refCode) async {
    await orders.acknowledgeDelivery(refCode, action: 'ACCEPT');
    await orders.fetchClientOrders();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.activeSection,
    required this.fullName,
    required this.email,
    required this.onSection,
    required this.onToggleCollapse,
    required this.onLogout,
  });

  final bool collapsed;
  final _Section activeSection;
  final String fullName;
  final String email;
  final void Function(_Section) onSection;
  final VoidCallback onToggleCollapse;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final w = collapsed ? 64.0 : 228.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: w,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        children: [
          // Logo
          InkWell(
            onTap: () => context.go('/'),
            child: Container(
              height: 64,
              padding: EdgeInsets.symmetric(
                horizontal: collapsed ? 0 : AppSpacing.lg,
              ),
              alignment: collapsed ? Alignment.center : Alignment.centerLeft,
              child: collapsed
                  ? const Icon(Icons.verified_outlined,
                      color: AppColors.brandNavy, size: 26)
                  : Row(
                      children: [
                        const Icon(Icons.verified_outlined,
                            color: AppColors.brandNavy, size: 22),
                        const SizedBox(width: 8),
                        Text('ProValuer',
                            style: AppTypography.cardTitle(
                                    color: AppColors.brandNavy)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.hairline),

          // Nav items
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: _Section.values
                  .map((s) => _SidebarItem(
                        section: s,
                        active: activeSection == s,
                        collapsed: collapsed,
                        onTap: () => onSection(s),
                      ))
                  .toList(),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: AppColors.hairline),

          // User + Logout
          if (!collapsed)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fullName,
                      style: AppTypography.bodySm(color: AppColors.ink)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(email,
                      style: AppTypography.bodySm(color: AppColors.slate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_outlined,
                          size: 15, color: AppColors.brandRedDark),
                      label: Text('Sign Out',
                          style: AppTypography.bodySm(
                              color: AppColors.brandRedDark)),
                      style: TextButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_outlined,
                  color: AppColors.brandRedDark, size: 18),
              tooltip: 'Sign Out',
            ),

          // Collapse toggle
          IconButton(
            onPressed: onToggleCollapse,
            icon: Icon(
              collapsed
                  ? Icons.chevron_right_outlined
                  : Icons.chevron_left_outlined,
              color: AppColors.slate,
              size: 20,
            ),
            tooltip: collapsed ? 'Expand' : 'Collapse',
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar Item
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.section,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  final _Section section;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? section.label : '',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlueLight : Colors.transparent,
            borderRadius: AppRadius.brMd,
          ),
          child: collapsed
              ? Center(
                  child: Icon(
                    section.icon,
                    color:
                        active ? AppColors.primaryBlue : AppColors.slate,
                    size: 20,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      section.icon,
                      color:
                          active ? AppColors.primaryBlue : AppColors.slate,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      section.label,
                      style: AppTypography.bodySm(
                        color: active
                            ? AppColors.primaryBlue
                            : AppColors.slate,
                      ).copyWith(
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top Bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.sectionLabel, required this.onHomePressed});
  final String sectionLabel;
  final VoidCallback onHomePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Text(sectionLabel,
              style: AppTypography.sectionTitle(color: AppColors.ink)),
          const Spacer(),
          TextButton.icon(
            onPressed: onHomePressed,
            icon: const Icon(Icons.home_outlined,
                size: 16, color: AppColors.slate),
            label: Text('Back to Home',
                style: AppTypography.bodySm(color: AppColors.slate)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: My Projects ────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _MyProjectsSection extends StatelessWidget {
  const _MyProjectsSection({
    required this.orders,
    required this.isLoading,
    required this.onRefresh,
    required this.onSelectOrder,
    required this.onNewRequest,
    required this.statusColor,
    required this.statusLabel,
  });

  final List<dynamic> orders;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(dynamic order) onSelectOrder;
  final VoidCallback onNewRequest;
  final Color Function(String?) statusColor;
  final String Function(String?) statusLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('My Projects',
                  style: AppTypography.sectionTitle(color: AppColors.ink)),
              const Spacer(),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_outlined,
                    color: AppColors.slate, size: 20),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: onNewRequest,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Request'),
                style: AppComponents.primaryButtonStyle(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          if (isLoading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else if (orders.isEmpty)
            _EmptyState(
              icon: Icons.folder_open_outlined,
              title: 'No projects yet',
              subtitle:
                  'Click "New Request" above to start your first valuation.',
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: orders.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final o = orders[i];
                  final status = o['status'] as String?;
                  return _ProjectCard(
                    order: o,
                    statusColor: statusColor(status),
                    statusLabel: statusLabel(status),
                    onTap: () => onSelectOrder(o),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Project Card ────────────────────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  final dynamic order;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final id = order['id'];
    final refCode = order['refCode'] ?? '—';
    final category = order['propertyCategory'] ?? '—';
    final purpose = order['purpose'] ?? '—';

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brLg,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.hairline),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryBlueLight,
                borderRadius: AppRadius.brMd,
              ),
              child: const Icon(Icons.folder_outlined,
                  color: AppColors.primaryBlue, size: 22),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #$id · $refCode',
                      style: AppTypography.bodyMdMedium(color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('$category · $purpose',
                      style: AppTypography.bodySm(color: AppColors.slate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.brFull,
              ),
              child: Text(statusLabel,
                  style: AppTypography.caption(color: statusColor)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.chevron_right_outlined,
                color: AppColors.slate, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: New Request ────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _NewRequestSection extends StatelessWidget {
  const _NewRequestSection({
    required this.formKey,
    required this.purposeCtrl,
    required this.estimatedValueCtrl,
    required this.selectedCategory,
    required this.loading,
    required this.error,
    required this.onCategoryChanged,
    required this.onSubmit,
    required this.onBack,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController purposeCtrl;
  final TextEditingController estimatedValueCtrl;
  final String selectedCategory;
  final bool loading;
  final String? error;
  final void Function(String) onCategoryChanged;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  static const _categories = [
    'PROPERTY',
    'COMMERCIAL',
    'PLANT_MACHINERY',
    'SHARE',
    'OTHER',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Breadcrumb(
                    items: ['My Projects', 'New Request'], onBack: onBack),
                const SizedBox(height: AppSpacing.xl),
                Text('Start a New Valuation Request',
                    style: AppTypography.sectionTitle(color: AppColors.ink)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                    'Fill in the details below. Our team will review and '
                    'provide you with a quotation shortly.',
                    style: AppTypography.bodyMd(color: AppColors.slate)),
                const SizedBox(height: AppSpacing.xxxl),

                Text('Valuation Category',
                    style: AppTypography.bodySm(color: AppColors.ink)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _inputDecor('Select category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.replaceAll('_', ' '))))
                      .toList(),
                  onChanged: (v) => v != null ? onCategoryChanged(v) : null,
                  validator: (v) =>
                      v == null ? 'Please select a category' : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Purpose of Valuation',
                    style: AppTypography.bodySm(color: AppColors.ink)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: purposeCtrl,
                  decoration: _inputDecor(
                      'e.g., Bank collateral, Visa application, Legal dispute'),
                  maxLines: 2,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? 'Please describe the purpose'
                          : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Estimated Value (₹)',
                    style: AppTypography.bodySm(color: AppColors.ink)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: estimatedValueCtrl,
                  decoration: _inputDecor('e.g., 5000000'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter an estimated value';
                    }
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid numeric amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxxl),

                if (error != null) ...[
                  _ErrorBanner(message: error!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: onSubmit,
                          style: AppComponents.primaryButtonStyle(),
                          child: const Text('Submit Request'),
                        ),
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.steel),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: Documents ──────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({
    required this.order,
    required this.loading,
    required this.error,
    required this.success,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onUpload,
    required this.onBack,
  });

  final dynamic order;
  final bool loading;
  final String? error;
  final String? success;
  final String selectedCategory;
  final void Function(String) onCategoryChanged;
  final void Function(List<int> bytes, String filename) onUpload;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(
                  items: ['My Projects', 'Documents'], onBack: onBack),
              const SizedBox(height: AppSpacing.xl),
              Text('Upload Supporting Documents',
                  style: AppTypography.sectionTitle(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Upload documents required for your valuation. '
                  'Each upload is securely stored and linked to your project.',
                  style: AppTypography.bodyMd(color: AppColors.slate)),
              const SizedBox(height: AppSpacing.xxxl),

              if (order != null) ...[
                _InfoRow(
                    label: 'Order',
                    value: '#${order['id']} · ${order['refCode'] ?? '—'}'),
                const SizedBox(height: AppSpacing.xl),
              ],

              Text('Document Category',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: AppColors.hairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.brMd,
                    borderSide: BorderSide(color: AppColors.hairline),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                ),
                items: _kDocCategories
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => v != null ? onCategoryChanged(v) : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              _UploadDropZone(loading: loading, onFilePicked: onUpload),
              const SizedBox(height: AppSpacing.lg),

              if (error != null) _ErrorBanner(message: error!),
              if (success != null) _SuccessBanner(message: success!),
              const SizedBox(height: AppSpacing.xxl),

              TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_outlined,
                    size: 12, color: AppColors.slate),
                label: Text('Back to My Projects',
                    style: AppTypography.bodySm(color: AppColors.slate)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: Quotation ──────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _QuotationSection extends StatefulWidget {
  const _QuotationSection({
    required this.order,
    required this.orders,
    required this.onBack,
    required this.onPayNow,
  });

  final dynamic order;
  final OrderProvider orders;
  final VoidCallback onBack;
  final VoidCallback onPayNow;

  @override
  State<_QuotationSection> createState() => _QuotationSectionState();
}

class _QuotationSectionState extends State<_QuotationSection> {
  Map<String, dynamic>? _quote;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    if (widget.order == null) {
      setState(() => _loading = false);
      return;
    }
    final q =
        await widget.orders.fetchOrderQuote(widget.order['id'] as int);
    setState(() {
      _quote = q?.cast<String, dynamic>();
      _loading = false;
      if (q == null) _error = 'No quotation found for this order.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(
                  items: ['My Projects', 'Quotation'],
                  onBack: widget.onBack),
              const SizedBox(height: AppSpacing.xl),
              Text('Your Quotation',
                  style: AppTypography.sectionTitle(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Review the fee structure prepared by our team. '
                  'Accept to proceed to payment.',
                  style: AppTypography.bodyMd(color: AppColors.slate)),
              const SizedBox(height: AppSpacing.xxxl),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                _ErrorBanner(message: _error!)
              else if (_quote != null) ...[
                _QuoteCard(quote: _quote!),
                const SizedBox(height: AppSpacing.xxxl),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: widget.onPayNow,
                    icon:
                        const Icon(Icons.payment_outlined, size: 18),
                    label: const Text('Accept & Proceed to Payment'),
                    style: AppComponents.primaryButtonStyle(),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});
  final Map<String, dynamic> quote;

  @override
  Widget build(BuildContext context) {
    final depositAmount =
        (quote['depositAmount'] as num?)?.toStringAsFixed(2) ?? '—';
    final balanceAmount =
        (quote['balanceAmount'] as num?)?.toStringAsFixed(2) ?? '—';
    final totalAmount =
        (quote['totalAmount'] as num?)?.toStringAsFixed(2) ?? '—';
    final notes = quote['notes'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _QuoteRow(
              label: 'Deposit (Due Now)',
              value: '₹ $depositAmount',
              highlight: true),
          const Divider(height: AppSpacing.xl, color: AppColors.hairline),
          _QuoteRow(
              label: 'Balance (Upon Delivery)',
              value: '₹ $balanceAmount'),
          const Divider(height: AppSpacing.xl, color: AppColors.hairline),
          _QuoteRow(
              label: 'Total',
              value: '₹ $totalAmount',
              highlight: true,
              bold: true),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: AppRadius.brMd,
              ),
              child: Text(notes,
                  style: AppTypography.bodyMd(color: AppColors.slate)),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool highlight;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodyMd(
                    color: highlight ? AppColors.ink : AppColors.slate)
                .copyWith(fontWeight: bold ? FontWeight.w700 : null)),
        Text(value,
            style: AppTypography.bodyMd(
                    color: highlight
                        ? AppColors.primaryBlue
                        : AppColors.ink)
                .copyWith(fontWeight: bold ? FontWeight.w700 : null)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: Payment ────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.order,
    required this.utrCtrl,
    required this.paymentDateCtrl,
    required this.amountCtrl,
    required this.paymentMethod,
    required this.loading,
    required this.error,
    required this.success,
    required this.fileBytes,
    required this.fileName,
    required this.onMethodChanged,
    required this.onFilePicked,
    required this.onSubmit,
    required this.onBack,
  });

  final dynamic order;
  final TextEditingController utrCtrl;
  final TextEditingController paymentDateCtrl;
  final TextEditingController amountCtrl;
  final String paymentMethod;
  final bool loading;
  final String? error;
  final String? success;
  final List<int>? fileBytes;
  final String? fileName;
  final void Function(String) onMethodChanged;
  final void Function(List<int> bytes, String filename) onFilePicked;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  static const _methods = ['NEFT', 'RTGS', 'IMPS', 'UPI', 'CHEQUE'];

  static InputDecoration _inputDecor(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.steel),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        filled: true,
        fillColor: AppColors.surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(
                  items: ['My Projects', 'Quotation', 'Payment'],
                  onBack: onBack),
              const SizedBox(height: AppSpacing.xl),
              Text('Submit Payment Proof',
                  style: AppTypography.sectionTitle(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                  'Transfer the deposit amount and complete the form below '
                  'with your payment details.',
                  style: AppTypography.bodyMd(color: AppColors.slate)),
              const SizedBox(height: AppSpacing.xxxl),

              if (order != null) ...[
                _InfoRow(
                    label: 'Order',
                    value:
                        '#${order['id']} · ${order['refCode'] ?? '—'}'),
                const SizedBox(height: AppSpacing.xl),
              ],

              _BankDetails(),
              const SizedBox(height: AppSpacing.xxl),

              // UTR
              Text('UTR / Reference Number',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: utrCtrl,
                  decoration: _inputDecor('e.g., HDFC23840923840')),
              const SizedBox(height: AppSpacing.xl),

              // Payment method
              Text('Payment Method',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: _inputDecor('Select method'),
                items: _methods
                    .map((m) =>
                        DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => v != null ? onMethodChanged(v) : null,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Payment date
              Text('Payment Date (YYYY-MM-DD)',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: paymentDateCtrl,
                  decoration: _inputDecor('e.g., 2026-10-02'),
                  keyboardType: TextInputType.datetime),
              const SizedBox(height: AppSpacing.xl),

              // Amount
              Text('Amount Paid (₹)',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: amountCtrl,
                  decoration: _inputDecor('e.g., 25000.00'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.xxl),

              Text('Payment Receipt / Screenshot',
                  style: AppTypography.bodySm(color: AppColors.ink)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              if (fileName != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: AppRadius.brMd,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file,
                          color: AppColors.successAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(fileName!,
                              style: AppTypography.bodySm(
                                  color: AppColors.successAccent))),
                    ],
                  ),
                )
              else
                _UploadDropZone(
                    loading: false, onFilePicked: onFilePicked),
              const SizedBox(height: AppSpacing.xxl),

              if (error != null) ...[
                _ErrorBanner(message: error!),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (success != null) ...[
                _SuccessBanner(message: success!),
                const SizedBox(height: AppSpacing.lg),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: onSubmit,
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Submit Payment Proof'),
                        style: AppComponents.primaryButtonStyle(),
                      ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _BankDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueLight,
        borderRadius: AppRadius.brLg,
        border:
            Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Bank Transfer Details',
                  style: AppTypography.bodyMdMedium(color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _InfoRow(
              label: 'Bank', value: 'HDFC Bank Ltd.'),
          const _InfoRow(
              label: 'Account Name',
              value: 'ProValuer Commercial Pvt. Ltd.'),
          const _InfoRow(
              label: 'Account No.', value: 'XXXXXXXXXXXXXXXX'),
          const _InfoRow(label: 'IFSC', value: 'HDFC0000XXX'),
          const _InfoRow(label: 'UPI', value: 'provaluer@hdfcbank'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: Tracking ───────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _TrackingSection extends StatelessWidget {
  const _TrackingSection({
    required this.order,
    required this.orders,
    required this.statusColor,
    required this.statusLabel,
    required this.onUploadDocs,
    required this.onViewQuote,
    required this.onPay,
    required this.onDownload,
    required this.onBack,
  });

  final dynamic order;
  final OrderProvider orders;
  final Color Function(String?) statusColor;
  final String Function(String?) statusLabel;
  final VoidCallback onUploadDocs;
  final VoidCallback onViewQuote;
  final VoidCallback onPay;
  final VoidCallback onDownload;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_outlined,
                size: 48, color: AppColors.steel),
            const SizedBox(height: AppSpacing.lg),
            Text('No project selected.',
                style: AppTypography.bodyMd(color: AppColors.slate)),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
                onPressed: onBack,
                child: const Text('Go to My Projects')),
          ],
        ),
      );
    }

    final status = order['status'] as String?;
    final sColor = statusColor(status);
    final sLabel = statusLabel(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(
                  items: ['My Projects', 'Tracking'], onBack: onBack),
              const SizedBox(height: AppSpacing.xl),

              // Status hero
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.brLg,
                  border: Border.all(color: AppColors.hairline),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Order #${order['id']} · ${order['refCode'] ?? '—'}',
                              style: AppTypography.sectionTitle(
                                  color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Text(
                              '${order['propertyCategory'] ?? '—'} · ${order['purpose'] ?? '—'}',
                              style: AppTypography.bodyMd(
                                  color: AppColors.slate)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.brFull,
                      ),
                      child: Text(sLabel,
                          style: AppTypography.bodyMdMedium(color: sColor)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              _StatusTimeline(status: status),
              const SizedBox(height: AppSpacing.xl),

              _ContextActions(
                status: status,
                onUploadDocs: onUploadDocs,
                onViewQuote: onViewQuote,
                onPay: onPay,
                onDownload: onDownload,
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Timeline ─────────────────────────────────────────────────────────
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final String? status;

  static const _steps = [
    ('SUBMITTED', 'Request Submitted', Icons.check_circle_outline),
    ('QUOTED', 'Quotation Received', Icons.receipt_long_outlined),
    ('PAYMENT_REVIEW', 'Payment Under Review', Icons.payment_outlined),
    ('IN_PROGRESS', 'Valuation In Progress', Icons.work_outline),
    ('SPA_REVIEW', 'Under Senior Review', Icons.verified_user_outlined),
    ('DELIVERED', 'Report Delivered', Icons.download_done_outlined),
  ];

  static const _lifecycleOrder = [
    'DRAFT',
    'SUBMITTED',
    'QUOTE_PENDING',
    'QUOTED',
    'PAYMENT_PENDING',
    'PAYMENT_REVIEW',
    'PAID',
    'RELEASED_TO_POOL',
    'IN_PROGRESS',
    'INSPECTION_SCHEDULED',
    'INSPECTION_COMPLETE',
    'REPORT_DRAFT',
    'SPA_REVIEW',
    'BALANCE_PAYMENT_PENDING',
    'DELIVERED',
    'CLOSED',
  ];

  static const _stepPositions = [1, 3, 5, 8, 12, 14];

  int _activeIndex() => _lifecycleOrder.indexOf(status ?? '');

  bool _stepDone(int stepLifecyclePos) => _activeIndex() >= stepLifecyclePos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress',
              style: AppTypography.bodyMdMedium(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.lg),
          ..._steps.asMap().entries.map((e) {
            final idx = e.key;
            final (_, label, icon) = e.value;
            final done = _stepDone(_stepPositions[idx]);
            final isLast = idx == _steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.successAccent
                            : AppColors.surfaceSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? AppColors.successAccent
                              : AppColors.hairline,
                        ),
                      ),
                      child: Icon(
                        done ? Icons.check : icon,
                        size: 14,
                        color: done ? Colors.white : AppColors.steel,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: done
                            ? AppColors.successAccent.withValues(alpha: 0.3)
                            : AppColors.hairline,
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label,
                      style: AppTypography.bodySm(
                          color: done ? AppColors.ink : AppColors.slate)),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ─── Context Actions ─────────────────────────────────────────────────────────
class _ContextActions extends StatelessWidget {
  const _ContextActions({
    required this.status,
    required this.onUploadDocs,
    required this.onViewQuote,
    required this.onPay,
    required this.onDownload,
  });

  final String? status;
  final VoidCallback onUploadDocs;
  final VoidCallback onViewQuote;
  final VoidCallback onPay;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[];

    if ([
      'SUBMITTED',
      'QUOTE_PENDING',
      'QUOTED',
      'PAYMENT_PENDING',
      'PAYMENT_REVIEW',
      'PAID'
    ].contains(status)) {
      actions.add(_ActionButton(
        icon: Icons.upload_file_outlined,
        label: 'Upload Documents',
        onTap: onUploadDocs,
      ));
    }
    if (['QUOTED', 'PAYMENT_PENDING'].contains(status)) {
      actions.add(_ActionButton(
        icon: Icons.receipt_long_outlined,
        label: 'View Quotation',
        onTap: onViewQuote,
        primary: true,
      ));
    }
    if (['PAYMENT_PENDING', 'BALANCE_PAYMENT_PENDING'].contains(status)) {
      actions.add(_ActionButton(
        icon: Icons.payment_outlined,
        label: 'Make Payment',
        onTap: onPay,
        primary: true,
      ));
    }
    if (status == 'DELIVERED') {
      actions.add(_ActionButton(
        icon: Icons.download_outlined,
        label: 'Download Report',
        onTap: onDownload,
        primary: true,
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
        spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: actions);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: AppComponents.primaryButtonStyle(),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: AppColors.slate),
      label: Text(label,
          style: AppTypography.bodySm(color: AppColors.slate)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: AppColors.hairline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SECTION: Delivery ───────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _DeliverySection extends StatefulWidget {
  const _DeliverySection({
    required this.order,
    required this.orders,
    required this.loading,
    required this.error,
    required this.onDownload,
    required this.onAcknowledge,
    required this.onBack,
  });

  final dynamic order;
  final OrderProvider orders;
  final bool loading;
  final String? error;
  final void Function(String refCode) onDownload;
  final void Function(String refCode) onAcknowledge;
  final VoidCallback onBack;

  @override
  State<_DeliverySection> createState() => _DeliverySectionState();
}

class _DeliverySectionState extends State<_DeliverySection> {
  Map<String, dynamic>? _deliverable;
  bool _fetchLoading = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.order == null) {
      setState(() => _fetchLoading = false);
      return;
    }
    final refCode = widget.order['refCode'] as String?;
    if (refCode == null) {
      setState(() {
        _fetchLoading = false;
        _fetchError = 'No reference code available.';
      });
      return;
    }
    final d = await widget.orders.fetchClientDeliverable(refCode);
    setState(() {
      _deliverable = d?.cast<String, dynamic>();
      _fetchLoading = false;
      if (d == null) _fetchError = 'Delivery information not found.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Breadcrumb(
                  items: ['My Projects', 'Tracking', 'Delivery'],
                  onBack: widget.onBack),
              const SizedBox(height: AppSpacing.xl),
              Text('Report Delivery',
                  style: AppTypography.sectionTitle(color: AppColors.ink)),
              const SizedBox(height: AppSpacing.xs),
              Text('Your valuation report is ready. Download below.',
                  style: AppTypography.bodyMd(color: AppColors.slate)),
              const SizedBox(height: AppSpacing.xxxl),

              if (_fetchLoading)
                const Center(child: CircularProgressIndicator())
              else if (_fetchError != null)
                _ErrorBanner(message: _fetchError!)
              else if (_deliverable != null)
                _DeliveryCard(
                  deliverable: _deliverable!,
                  loading: widget.loading,
                  onDownload: widget.onDownload,
                  onAcknowledge: widget.onAcknowledge,
                ),

              if (widget.error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _ErrorBanner(message: widget.error!),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({
    required this.deliverable,
    required this.loading,
    required this.onDownload,
    required this.onAcknowledge,
  });

  final Map<String, dynamic> deliverable;
  final bool loading;
  final void Function(String) onDownload;
  final void Function(String) onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final refCode = deliverable['refCode'] as String? ?? '';
    final acknowledged =
        deliverable['clientAcknowledged'] as bool? ?? false;
    final files = (deliverable['files'] as List<dynamic>?) ?? [];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Reference', value: refCode),
          const SizedBox(height: AppSpacing.lg),

          if (files.isNotEmpty) ...[
            Text('Deliverable Files',
                style: AppTypography.bodyMdMedium(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.md),
            ...files.map((f) {
              final fType = f['fileType'] as String? ?? 'FILE';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        size: 16, color: AppColors.primaryBlue),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(fType,
                            style: AppTypography.bodySm(
                                color: AppColors.ink))),
                    loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                        : TextButton(
                            onPressed: () => onDownload(refCode),
                            child: const Text('Download'),
                          ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (!acknowledged)
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => onAcknowledge(refCode),
                icon: const Icon(Icons.check_outlined, size: 16),
                label: const Text('Acknowledge Receipt'),
                style: AppComponents.primaryButtonStyle(),
              ),
            )
          else
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.successAccent, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('You have acknowledged receipt.',
                    style: AppTypography.bodySm(
                        color: AppColors.successAccent)),
              ],
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── Shared Utility Widgets ──────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _UploadDropZone extends StatelessWidget {
  const _UploadDropZone(
      {required this.loading, required this.onFilePicked});
  final bool loading;
  final void Function(List<int> bytes, String filename) onFilePicked;

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      if (f.bytes != null) {
        onFilePicked(f.bytes!.toList(), f.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : _pick,
      borderRadius: AppRadius.brLg,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xxxl, horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.brLg,
          border: Border.all(color: AppColors.hairlineStrong),
        ),
        child: Column(
          children: [
            loading
                ? const CircularProgressIndicator()
                : const Icon(Icons.cloud_upload_outlined,
                    size: 36, color: AppColors.steel),
            const SizedBox(height: AppSpacing.md),
            Text(
              loading ? 'Uploading…' : 'Click to select a file',
              style: AppTypography.bodyMd(color: AppColors.slate),
            ),
            if (!loading) ...[
              const SizedBox(height: 4),
              Text('PDF, JPG, PNG, DOCX accepted',
                  style:
                      AppTypography.caption(color: AppColors.steel)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.items, required this.onBack});
  final List<String> items;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              size: 12, color: AppColors.slate),
          label: Text(items.first,
              style: AppTypography.bodySm(color: AppColors.slate)),
        ),
        ...items.skip(1).map((item) => Row(children: [
              const Icon(Icons.chevron_right_outlined,
                  size: 14, color: AppColors.steel),
              Text(item,
                  style: AppTypography.bodySm(color: AppColors.ink)),
            ])),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTypography.bodySm(color: AppColors.slate)),
          ),
          Expanded(
            child: Text(value,
                style: AppTypography.bodySm(color: AppColors.ink)
                    .copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.steel),
            const SizedBox(height: AppSpacing.xl),
            Text(title,
                style: AppTypography.sectionTitle(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style: AppTypography.bodyMd(color: AppColors.slate),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandRed,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.brandRedDark, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style:
                    AppTypography.bodySm(color: AppColors.brandRedDark)),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.successAccent, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTypography.bodySm(color: AppColors.successAccent)),
          ),
        ],
      ),
    );
  }
}
