import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'admin_payment_review_modal.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPRINT 4 + PAYMENT VERIFICATION FIX: Admin Intake Clearance & Verification Screen
// Tab 0: PAYMENT_SUBMITTED orders awaiting verification, proof inspection, rejection or waiver.
// Tab 1: PAYMENT_VERIFIED orders awaiting admin release to Common Pool.
// ─────────────────────────────────────────────────────────────────────────────

class AdminReleaseQueueSection extends StatefulWidget {
  const AdminReleaseQueueSection({super.key});

  @override
  State<AdminReleaseQueueSection> createState() => _AdminReleaseQueueSectionState();
}

class _AdminReleaseQueueSectionState extends State<AdminReleaseQueueSection> {
  int _selectedTab = 0; // 0 = Payment Review, 1 = Ready for Pool Release
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await Future.wait([
        context.read<OrderProvider>().fetchPaymentReviewQueue(),
        context.read<OrderProvider>().fetchReleaseQueue(),
      ]);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentQueue = context.watch<OrderProvider>().paymentReviewQueue;
    final releaseQueue = context.watch<OrderProvider>().releaseQueue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(paymentQueue.length, releaseQueue.length),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? _buildError(_errorMessage!)
                  : _selectedTab == 0
                      ? (paymentQueue.isEmpty
                          ? _buildEmptyPaymentQueue()
                          : _buildPaymentReviewList(paymentQueue))
                      : (releaseQueue.isEmpty
                          ? _buildEmptyReleaseQueue()
                          : _buildReleaseQueueList(releaseQueue)),
        ),
      ],
    );
  }

  Widget _buildHeader(int pendingPayments, int pendingRelease) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intake Clearance & Payment Verification',
                      style: AppTypography.heading3().copyWith(color: AppColors.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verify client payments, waive fees when authorized, and clear orders for Common Pool release.',
                      style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(foregroundColor: AppColors.brandBlue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tab selection buttons
          Row(
            children: [
              _buildTabButton(
                tabIndex: 0,
                label: 'Payment Review Queue',
                count: pendingPayments,
                activeColor: const Color(0xFFD97706),
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 12),
              _buildTabButton(
                tabIndex: 1,
                label: 'Ready for Pool Release',
                count: pendingRelease,
                activeColor: const Color(0xFF1B5E20),
                icon: Icons.rocket_launch_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int tabIndex,
    required String label,
    required int count,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == tabIndex;
    return InkWell(
      onTap: () => setState(() => _selectedTab = tabIndex),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.hairline,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : AppColors.slate),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.slate,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withOpacity(0.18)
                    : AppColors.sidebarSelected,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? activeColor : AppColors.slate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPaymentQueue() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.payment_rounded, size: 40, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 24),
            Text('No Pending Payments',
                style: AppTypography.heading3().copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              'No orders are awaiting payment verification.\nWhen clients upload payment receipts or UTRs, they will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm().copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyReleaseQueue() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 40, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 24),
            Text('All Clear for Release',
                style: AppTypography.heading3().copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              'No orders are currently pending Common Pool release.\nOnce payments are verified, orders move here for admin clearance.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySm().copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFD32F2F)),
            const SizedBox(height: 16),
            Text('Failed to load queue',
                style: AppTypography.heading3().copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(error, style: AppTypography.bodySm().copyWith(color: AppColors.slate)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentReviewList(List<dynamic> queue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: queue.map((item) {
          final order = item as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PaymentReviewCard(
              order: order,
              onRefresh: _refresh,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReleaseQueueList(List<dynamic> queue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: queue.map((item) {
          final order = item as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ReleaseQueueCard(
              order: order,
              onRefresh: _refresh,
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Review Queue Card (PAYMENT_SUBMITTED Orders)
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentReviewCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const _PaymentReviewCard({required this.order, required this.onRefresh});

  @override
  State<_PaymentReviewCard> createState() => _PaymentReviewCardState();
}

class _PaymentReviewCardState extends State<_PaymentReviewCard> {
  int get _orderId =>
      (widget.order['orderId'] as num?)?.toInt() ??
      (widget.order['id'] as num?)?.toInt() ??
      0;

  String _fmt(dynamic v) => v?.toString() ?? '—';
  String _fmtMoney(dynamic v) {
    if (v == null) return '—';
    final d = (v as num).toDouble();
    return '₹ ${d.toStringAsFixed(2)}';
  }

  Future<void> _promptWaivePayment(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(Icons.money_off_rounded, color: Color(0xFF047857), size: 22),
            const SizedBox(width: 10),
            Text('Waive Payment',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waiving payment will reset balance due to ₹0, mark payment status as VERIFIED, '
                'and transition the order to PAYMENT_VERIFIED so it can proceed to Intake Clearance.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF37474F)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Order Reference:',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate)),
                    Text(_fmt(widget.order['referenceCode']),
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.ink)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Mandatory Waiver Reason *',
                  style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. Corporate SLA pre-approved, Executive exemption, Direct bank transfer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Waiver'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final res = await context.read<OrderProvider>().waivePayment(
            orderId: _orderId,
            reason: reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      if (res != null && res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['error'].toString()),
          backgroundColor: const Color(0xFFD32F2F),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment waived successfully. Order moved to PAYMENT_VERIFIED.'),
          backgroundColor: Color(0xFF2E7D32),
        ));
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to waive payment: $e'),
          backgroundColor: const Color(0xFFD32F2F),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final utr = o['utrNumber']?.toString() ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PAYMENT_SUBMITTED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fmt(o['referenceCode']),
                      style: GoogleFonts.inter(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Client: ${_fmt(o['clientName'])} (${_fmt(o['clientEmail'])})',
                      style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtMoney(o['quoteTotal'] ?? o['quoteAmount']),
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text('Quote Total',
                      style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.hairline),
          const SizedBox(height: 16),

          // ── UTR & Details Row ─────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tag_rounded, size: 16, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 6),
                    Text(
                      'UTR: $utr',
                      style: GoogleFonts.robotoMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
              if (o['serviceCategory'] != null)
                _buildMiniPill('Service: ${_fmt(o['serviceCategory'])}'),
              if (o['assetCategory'] != null)
                _buildMiniPill('Asset: ${_fmt(o['assetCategory'])}'),
              if (o['purpose'] != null)
                _buildMiniPill('Purpose: ${_fmt(o['purpose'])}'),
              _buildMiniPill('Documents: ${o['documentCount'] ?? 0} attached'),
            ],
          ),
          const SizedBox(height: 16),

          // ── Actions ───────────────────────────────────────────────────────
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  AdminPaymentReviewModal.show(
                    context: context,
                    order: o,
                    onRefresh: widget.onRefresh,
                  );
                },
                icon: const Icon(Icons.verified_user_outlined, size: 16),
                label: const Text('Review & Verify Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _promptWaivePayment(context),
                icon: const Icon(Icons.money_off_rounded, size: 16),
                label: const Text('Waive Payment'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF047857),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Release Queue Card (PAYMENT_VERIFIED Orders)
// ─────────────────────────────────────────────────────────────────────────────

class _ReleaseQueueCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const _ReleaseQueueCard({required this.order, required this.onRefresh});

  @override
  State<_ReleaseQueueCard> createState() => _ReleaseQueueCardState();
}

class _ReleaseQueueCardState extends State<_ReleaseQueueCard> {
  bool _isExpanded = false;
  bool _isReleasing = false;
  bool _isHolding = false;

  int get _orderId =>
      (widget.order['orderId'] as num?)?.toInt() ??
      (widget.order['id'] as num?)?.toInt() ??
      0;

  String _fmt(dynamic v) => v?.toString() ?? '—';
  String _fmtMoney(dynamic v) {
    if (v == null) return '—';
    final d = (v as num).toDouble();
    return '₹ ${d.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final hasHold = o['intakeHoldReason'] != null && o['intakeHoldReason'].toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasHold
              ? const Color(0xFFFF9800).withOpacity(0.4)
              : AppColors.hairline,
          width: hasHold ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header row ──────────────────────────────────────────────────
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'PAYMENT_VERIFIED',
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1565C0)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(
                    builder: (_) {
                      DateTime? verifiedDt;
                      final dtStr = o['paymentVerifiedAt'] ?? o['updatedAt'] ?? o['createdAt'];
                      if (dtStr != null) {
                        verifiedDt = DateTime.tryParse(dtStr.toString());
                      }
                      final ageHours = verifiedDt != null ? DateTime.now().difference(verifiedDt).inHours : 0;
                      final isStagnant = ageHours >= 6;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isStagnant ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isStagnant ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isStagnant ? Icons.warning_amber_rounded : Icons.timer_outlined, size: 11, color: isStagnant ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                            const SizedBox(width: 4),
                            Text(
                              isStagnant ? 'STAGNANT (${ageHours}h)' : 'CLEARANCE (${ageHours}h)',
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: isStagnant ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Reference + client
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fmt(o['referenceCode']),
                          style: GoogleFonts.inter(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmt(o['clientName']),
                          style: AppTypography.bodySm().copyWith(color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  // Quote total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_fmtMoney(o['quoteTotal']),
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      const SizedBox(height: 2),
                      Text('Quote Total',
                          style: AppTypography.bodySm().copyWith(color: AppColors.slate, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Hold badge if applicable
                  if (hasHold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.4)),
                      ),
                      child: Text(
                        'ON HOLD',
                        style: GoogleFonts.inter(
                            fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFE65100)),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.slate,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ─────────────────────────────────────────────
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.hairline),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info grid
                  _buildInfoGrid(o),
                  const SizedBox(height: 20),
                  // Hold notice
                  if (hasHold)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pause_circle_outline, color: Color(0xFFE65100), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hold Reason: ${o['intakeHoldReason']}',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5D4037)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Action buttons
                  _buildActionRow(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoGrid(Map<String, dynamic> o) {
    final items = <_InfoItem>[
      _InfoItem('Quote Number', _fmt(o['quoteNumber'])),
      _InfoItem('Service Category', _fmt(o['serviceCategory'])),
      _InfoItem('Asset Category', _fmt(o['assetCategory'])),
      _InfoItem('Purpose', _fmt(o['purpose'])),
      _InfoItem('Quote Amount', _fmtMoney(o['quoteAmount'])),
      _InfoItem('GST', _fmtMoney(o['quoteTax'])),
      _InfoItem('Verified Amount', _fmtMoney(o['verifiedAmount'])),
      _InfoItem('UTR Number', _fmt(o['utrNumber'])),
      _InfoItem('Verified By', _fmt(o['paymentVerifiedBy'])),
      _InfoItem('Documents', '${o['documentCount'] ?? 0} uploaded'),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items.map((item) => _buildInfoTile(item.label, item.value)).toList(),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.slate)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Row(
      children: [
        // Release to Pool button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isReleasing || _isHolding ? null : () => _confirmRelease(context),
            icon: _isReleasing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch_rounded, size: 16),
            label: Text(_isReleasing ? 'Releasing…' : 'Release to Common Pool'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Hold button
        OutlinedButton.icon(
          onPressed: _isReleasing || _isHolding ? null : () => _confirmHold(context),
          icon: _isHolding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.pause_rounded, size: 16),
          label: Text(_isHolding ? 'Placing Hold…' : 'Hold Intake'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE65100),
            side: const BorderSide(color: Color(0xFFFF9800)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRelease(BuildContext context) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Color(0xFF1B5E20), size: 22),
            const SizedBox(width: 10),
            Text('Release to Common Pool',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will transition order ${widget.order['referenceCode']} from PAYMENT_VERIFIED to PAID_INTAKE.\n\n'
                'A report number (PV-YYMM-XXXX) will be generated and the SLA timer will start.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF37474F)),
              ),
              const SizedBox(height: 16),
              Text('Intake Notes (optional)',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any internal notes for this file…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirm Release'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isReleasing = true);
    try {
      final result = await context.read<OrderProvider>().releaseToPool(
            orderId: _orderId,
            intakeNotes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
          );
      if (!mounted) return;
      if (result != null && result['error'] != null) {
        _showSnack(context, result['error'].toString(), isError: true);
      } else {
        _showSnack(context,
            'Order released to Common Pool. Report number: ${result?['reportNumber'] ?? ''}');
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _isReleasing = false);
    }
  }

  Future<void> _confirmHold(BuildContext context) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: Color(0xFFE65100), size: 22),
            const SizedBox(width: 10),
            Text('Hold Intake',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will place order ${widget.order['referenceCode']} on intake hold. '
                'It will remain visible in the release queue but will not be released.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF37474F)),
              ),
              const SizedBox(height: 16),
              Text('Hold Reason *',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for holding this intake…',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Place Hold'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isHolding = true);
    try {
      final result = await context.read<OrderProvider>().holdIntake(
            orderId: _orderId,
            holdReason: reasonCtrl.text.trim(),
          );
      if (!mounted) return;
      if (result != null && result['error'] != null) {
        _showSnack(context, result['error'].toString(), isError: true);
      } else {
        _showSnack(context, 'Intake hold placed successfully.');
        widget.onRefresh();
      }
    } finally {
      if (mounted) setState(() => _isHolding = false);
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────────────────

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}
