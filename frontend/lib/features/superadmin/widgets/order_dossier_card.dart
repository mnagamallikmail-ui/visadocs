import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/order_provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../placeholder_catalog_screen.dart';
import '../../quotations/admin_request_review_modal.dart';
import '../../quotations/admin_payment_review_modal.dart';
import '../../quotations/admin_quote_creation_modal.dart';

/// Professional Operational Command Center Dossier Card
/// Inspired by Google Cloud Console, Linear, and Stripe Dashboard.
/// Enforces 100% certified business rules with ZERO governance alterations.
class OrderDossierCard extends StatefulWidget {
  final dynamic order;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onRefresh;
  final bool canDelete;
  final Function(dynamic order)? onReassign;
  final Function(dynamic order)? onForceRecovery;
  final Function(dynamic order)? onChangeStatus;
  final Function(dynamic order)? onDelete;
  final Function(dynamic order)? onWaivePayment;
  final Function(dynamic order)? onResendQuote;
  final Function(dynamic order)? onViewInvoice;
  final Function(dynamic order)? onViewQuote;

  const OrderDossierCard({
    super.key,
    required this.order,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRefresh,
    this.canDelete = false,
    this.onReassign,
    this.onForceRecovery,
    this.onChangeStatus,
    this.onDelete,
    this.onWaivePayment,
    this.onResendQuote,
    this.onViewInvoice,
    this.onViewQuote,
  });

  @override
  State<OrderDossierCard> createState() => _OrderDossierCardState();
}

class _OrderDossierCardState extends State<OrderDossierCard> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  int _activeTabIndex = 0; // 0: Overview, 1: Commercial & Payment, 2: Documents, 3: Timeline & Audit, 4: Governance

  // Lazy-loaded data
  List<Map<String, dynamic>> _documents = [];
  bool _isLoadingDocs = false;
  String? _docsError;

  Map<String, dynamic>? _paymentDetails;
  bool _isLoadingPayment = false;
  String? _paymentError;

  List<dynamic> _auditLogs = [];
  bool _isLoadingAudit = false;
  String? _auditError;

  // Processing state for inline actions
  bool _isProcessingAction = false;

  // Search filter queries for Documents and Timeline tabs
  String _docSearchQuery = '';
  String _auditSearchQuery = '';

  int get _orderId => (widget.order['id'] as num?)?.toInt() ?? 0;
  String get _refCode => widget.order['referenceCode']?.toString() ?? 'REQ-$_orderId';
  String get _reportNum => widget.order['reportNumber']?.toString().isNotEmpty == true
      ? widget.order['reportNumber'].toString()
      : _refCode;
  String get _status => (widget.order['status']?.toString() ?? 'DRAFT').toUpperCase();

  @override
  void initState() {
    super.initState();
    if (widget.isExpanded) {
      _loadDataForActiveTab();
    }
  }

  @override
  void didUpdateWidget(OrderDossierCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _loadDataForActiveTab();
    }
  }

  void _loadDataForActiveTab() {
    if (_activeTabIndex == 1) {
      _loadPaymentDetails();
    } else if (_activeTabIndex == 2) {
      _loadDocuments();
    } else if (_activeTabIndex == 3) {
      _loadAuditLogs();
    }
  }

  void _onTabSelected(int index) {
    setState(() => _activeTabIndex = index);
    if (index == 1) {
      _loadPaymentDetails();
    } else if (index == 2) {
      _loadDocuments();
    } else if (index == 3) {
      _loadAuditLogs();
    }
  }

  Future<void> _loadDocuments() async {
    if (_documents.isNotEmpty && !_isLoadingDocs) return;
    setState(() {
      _isLoadingDocs = true;
      _docsError = null;
    });
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final docs = await orderProvider.fetchOrderDocuments(_orderId);
      if (mounted) {
        setState(() {
          _documents = (docs ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoadingDocs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _docsError = "Failed to load documents";
          _isLoadingDocs = false;
        });
      }
    }
  }

  Future<void> _loadPaymentDetails() async {
    if (_paymentDetails != null && !_isLoadingPayment) return;
    setState(() {
      _isLoadingPayment = true;
      _paymentError = null;
    });
    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final details = await orderProvider.fetchPaymentDetails(_orderId);
      if (mounted) {
        setState(() {
          _paymentDetails = details;
          _isLoadingPayment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _paymentError = "Failed to load payment details";
          _isLoadingPayment = false;
        });
      }
    }
  }

  Future<void> _loadAuditLogs() async {
    if (_auditLogs.isNotEmpty && !_isLoadingAudit) return;
    setState(() {
      _isLoadingAudit = true;
      _auditError = null;
    });
    try {
      final res = await _api.dio.get('/api/v1/admin/audit/entity/ORDER/$_orderId');
      if (mounted) {
        setState(() {
          _auditLogs = (res.data is List) ? (res.data as List) : [];
          _isLoadingAudit = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _auditError = "Audit history unavailable";
          _isLoadingAudit = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FORMATTERS & UTILITIES
  // ─────────────────────────────────────────────────────────────

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      DateTime dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final d = dt.day.toString().padLeft(2, '0');
      final m = months[dt.month - 1];
      final y = dt.year.toString();
      final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final h = hour12.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$d-$m-$y $h:$min $ampm';
    } catch (_) {
      return raw.toString();
    }
  }

  String _formatStatusAge(dynamic raw) {
    if (raw == null) return '—';
    try {
      DateTime dt = raw is DateTime ? raw : DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.isNegative) return 'Just now';
      final totalHours = diff.inMinutes / 60.0;
      if (totalHours >= 48.0) {
        final days = totalHours / 24.0;
        return '${days.toStringAsFixed(1)} Days (${totalHours.toStringAsFixed(0)}h)';
      } else if (totalHours >= 1.0) {
        return '${totalHours.toStringAsFixed(1)} Hours';
      } else {
        return '${diff.inMinutes} Mins';
      }
    } catch (_) {
      return '—';
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '—';
    final n = num.tryParse(amount.toString());
    if (n == null) return '₹ $amount';
    final str = n.toInt().toString();
    if (str.length > 3) {
      final lastThree = str.substring(str.length - 3);
      var otherNumbers = str.substring(0, str.length - 3);
      otherNumbers = otherNumbers.replaceAllMapped(RegExp(r'(\d)(?=(\d{2})+(?!\d))'), (Match m) => '${m[1]},');
      return '₹ $otherNumbers,$lastThree';
    }
    return '₹ $str';
  }

  String _extractPropertyAddress() {
    try {
      if (widget.order['inputValues'] != null) {
        final raw = widget.order['inputValues'];
        final Map<String, dynamic> map = raw is Map ? Map<String, dynamic>.from(raw) : jsonDecode(raw.toString());
        for (final key in ['PROPERTY_ADDRESS', 'property_address', 'SITE_ADDRESS', 'Property_Address']) {
          if (map.containsKey(key) && map[key]?.toString().trim().isNotEmpty == true) {
            return map[key].toString().trim();
          }
        }
      }
    } catch (_) {}
    return widget.order['purpose'] != null ? '${widget.order['purpose']} Location' : 'Location on record';
  }

  String _deriveRecoveryStateText() {
    final status = _status;
    if (status == 'ACTION_NEEDED' || status == 'ABANDONED') {
      return 'Analyst Inactive • Work Preserved';
    }
    final hbStr = widget.order['lastHeartbeat']?.toString();
    if (hbStr != null) {
      final hb = DateTime.tryParse(hbStr);
      if (hb != null) {
        final staleMins = DateTime.now().difference(hb).inMinutes;
        if (staleMins >= 60) return 'Session Idle (${(staleMins / 60.0).toStringAsFixed(1)}h)';
        if (staleMins >= 30) return 'Heartbeat Warning';
      }
    }
    return 'Normal Active';
  }

  String _deriveSlaStatusText() {
    final expStr = widget.order['slaExpiryTime']?.toString();
    if (expStr == null) return 'Standard SLA (Active)';
    final exp = DateTime.tryParse(expStr);
    if (exp == null) return 'Standard SLA';
    final now = DateTime.now();
    if (now.isAfter(exp)) {
      final h = now.difference(exp).inMinutes / 60.0;
      return 'Overdue (${h.toStringAsFixed(1)}h)';
    }
    final h = exp.difference(now).inMinutes / 60.0;
    if (h <= 4.0) return 'Warning (< 4h)';
    return 'On Track';
  }

  String _deriveSlaRemainingText() {
    final expStr = widget.order['slaExpiryTime']?.toString();
    if (expStr == null) return '—';
    final exp = DateTime.tryParse(expStr);
    if (exp == null) return '—';
    final now = DateTime.now();
    if (now.isAfter(exp)) {
      final h = now.difference(exp).inMinutes / 60.0;
      return '-${h.toStringAsFixed(1)} Hours';
    }
    final h = exp.difference(now).inMinutes / 60.0;
    return '${h.toStringAsFixed(1)} Hours Remaining';
  }

  // ─────────────────────────────────────────────────────────────
  // STATUS BADGE WITH MUTED ENTERPRISE COLORS
  // ─────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    Color border;
    String displayLabel = status.replaceAll('_', ' ');

    switch (status) {
      case 'QUOTE_PENDING':
        bg = const Color(0xFFFEF3C7); // Soft Amber
        fg = const Color(0xFF92400E);
        border = const Color(0xFFFDE68A);
        displayLabel = 'QUOTE PENDING';
        break;
      case 'QUOTE_PROVIDED':
        bg = const Color(0xFFEFF6FF); // Muted Blue
        fg = const Color(0xFF1E40AF);
        border = const Color(0xFFBFDBFE);
        displayLabel = 'QUOTE ISSUED';
        break;
      case 'PAYMENT_SUBMITTED':
        bg = const Color(0xFFFFFBEB); // Soft Amber Highlight
        fg = const Color(0xFFB45309);
        border = const Color(0xFFFCD34D);
        displayLabel = 'VERIFICATION PENDING';
        break;
      case 'PAYMENT_VERIFIED':
        bg = const Color(0xFFECFDF5); // Muted Green
        fg = const Color(0xFF065F46);
        border = const Color(0xFFA7F3D0);
        displayLabel = 'PAYMENT VERIFIED';
        break;
      case 'PAID_INTAKE':
        bg = const Color(0xFFF1F5F9); // Neutral Slate
        fg = const Color(0xFF334155);
        border = const Color(0xFFCBD5E1);
        displayLabel = 'UNASSIGNED POOL';
        break;
      case 'ASSIGNED':
      case 'WORKSPACE_READY':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1E40AF);
        border = const Color(0xFFBFDBFE);
        displayLabel = status == 'WORKSPACE_READY' ? 'WORKSPACE READY' : 'ASSIGNED TO PA';
        break;
      case 'DRAFTING':
        bg = const Color(0xFFF0FDF4);
        fg = const Color(0xFF166534);
        border = const Color(0xFFBBF7D0);
        displayLabel = 'DRAFTING IN PROGRESS';
        break;
      case 'ACTION_NEEDED':
        bg = const Color(0xFFFFF7ED); // Muted Orange (Work Preserved)
        fg = const Color(0xFF9A3412);
        border = const Color(0xFFFED7AA);
        displayLabel = 'AWAITING REASSIGNMENT';
        break;
      case 'SPA_GATE':
      case 'SPA_REVIEW':
        bg = const Color(0xFFF5F3FF); // Muted Violet
        fg = const Color(0xFF5B21B6);
        border = const Color(0xFFDDD6FE);
        displayLabel = 'SPA REVIEW GATE';
        break;
      case 'SPA_CONFIRMED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF065F46);
        border = const Color(0xFFA7F3D0);
        displayLabel = 'APPROVED BY SPA';
        break;
      case 'FINAL_DELIVERY':
      case 'CLIENT_DOWNLOADED':
      case 'CLOSED':
        bg = const Color(0xFFF8FAFC);
        fg = const Color(0xFF0F172A);
        border = const Color(0xFFE2E8F0);
        displayLabel = status == 'CLIENT_DOWNLOADED' ? 'DOWNLOADED BY CLIENT' : 'FINAL DELIVERED';
        break;
      case 'PAYMENT_REJECTED':
        bg = const Color(0xFFFEF2F2); // Muted Red
        fg = const Color(0xFF991B1B);
        border = const Color(0xFFFECACA);
        displayLabel = 'PAYMENT REJECTED';
        break;
      default:
        bg = const Color(0xFFF8FAFC);
        fg = const Color(0xFF475569);
        border = const Color(0xFFE2E8F0);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        displayLabel,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RECOVERY & STALENESS INDICATORS (IMPROVED HUMAN LABELS)
  // ─────────────────────────────────────────────────────────────

  Widget _buildRecoveryAndSlaBadge() {
    final status = _status;
    final now = DateTime.now();
    final chips = <Widget>[];

    // SLA Badge
    final slaExpiryStr = widget.order['slaExpiryTime']?.toString();
    if (slaExpiryStr != null) {
      final exp = DateTime.tryParse(slaExpiryStr);
      if (exp != null) {
        if (now.isAfter(exp)) {
          final overdueH = now.difference(exp).inMinutes / 60.0;
          chips.add(_statusTag(
            'SLA Overdue (${overdueH.toStringAsFixed(1)}h)',
            const Color(0xFFFEF2F2),
            const Color(0xFF991B1B),
            const Color(0xFFFECACA),
            Icons.error_outline_rounded,
          ));
        } else {
          final remH = exp.difference(now).inMinutes / 60.0;
          if (remH <= 4.0) {
            chips.add(_statusTag(
              'SLA Warning (${remH.toStringAsFixed(1)}h left)',
              const Color(0xFFFFFBEB),
              const Color(0xFF92400E),
              const Color(0xFFFDE68A),
              Icons.alarm_on_rounded,
            ));
          } else {
            chips.add(_statusTag(
              '${remH.toStringAsFixed(1)}h SLA Remaining',
              const Color(0xFFECFDF5),
              const Color(0xFF065F46),
              const Color(0xFFA7F3D0),
              Icons.timer_outlined,
            ));
          }
        }
      }
    }

    // Inactivity & Stalled Detection (Replaces "Abandoned" with Operational Clarity)
    final isActiveAuthoring = status == 'ASSIGNED' || status == 'WORKSPACE_READY' || status == 'DRAFTING' || status == 'ACTION_NEEDED';
    if (isActiveAuthoring) {
      final hbStr = widget.order['lastHeartbeat']?.toString();
      final claimStr = widget.order['claimedAt']?.toString();
      final upStr = widget.order['updatedAt']?.toString();
      final crStr = widget.order['createdAt']?.toString();

      DateTime? lastActive = DateTime.tryParse(hbStr ?? '') ??
          DateTime.tryParse(claimStr ?? '') ??
          DateTime.tryParse(upStr ?? '') ??
          DateTime.tryParse(crStr ?? '');

      if (lastActive != null) {
        final hoursStale = now.difference(lastActive).inMinutes / 60.0;

        if (status == 'ACTION_NEEDED') {
          chips.add(_statusTag(
            'Analyst Inactive • Work Preserved',
            const Color(0xFFFFF7ED),
            const Color(0xFFC2410C),
            const Color(0xFFFED7AA),
            Icons.lock_clock_outlined,
          ));
        } else if (hoursStale >= 6.0) {
          chips.add(_statusTag(
            'Session Idle (${hoursStale.toStringAsFixed(0)}h)',
            const Color(0xFFF8FAFC),
            const Color(0xFF475569),
            const Color(0xFFE2E8F0),
            Icons.hourglass_bottom_rounded,
          ));
        }
      }
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips,
    );
  }

  Widget _statusTag(String text, Color bg, Color fg, Color border, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // RESPONSIBLE PARTY & TEAM DERIVATION (ZERO BACKEND CHANGES)
  // ─────────────────────────────────────────────────────────────

  Map<String, String> _deriveOwnershipData() {
    final status = _status;
    final paId = widget.order['paId'];
    String team = 'Operations Team';
    String party = 'Platform Administrator';
    String reviewer = 'Senior Property Analyst Pool';

    switch (status) {
      case 'DRAFT':
      case 'QUOTE_PENDING':
        team = 'Commercial Team';
        party = 'Quotation Desk';
        break;
      case 'QUOTE_PROVIDED':
        team = 'Client Desk';
        party = 'Client (Awaiting Remittance)';
        break;
      case 'PAYMENT_SUBMITTED':
        team = 'Finance & Accounts';
        party = 'Accounts Verification Officer';
        break;
      case 'PAYMENT_VERIFIED':
        team = 'Operations Dispatch';
        party = 'Intake Release Desk';
        break;
      case 'PAID_INTAKE':
        team = 'Valuation Pool';
        party = 'Global Property Analyst Pool (Unassigned)';
        break;
      case 'ASSIGNED':
      case 'WORKSPACE_READY':
      case 'DRAFTING':
        team = 'Authoring Team';
        party = paId != null ? 'Assigned PA #$paId' : 'Assigned Analyst';
        break;
      case 'ACTION_NEEDED':
        team = 'Super Admin / Lead';
        party = 'Operations Supervisor (Reassignment Required)';
        break;
      case 'SPA_GATE':
      case 'SPA_REVIEW':
        team = 'Quality Assurance';
        party = 'Senior Property Analyst Pool';
        reviewer = 'Active Reviewing SPA';
        break;
      case 'SPA_CONFIRMED':
      case 'DELIVERY_READY':
        team = 'Delivery & Signing';
        party = 'Signing Authority / Admin';
        reviewer = 'Approved by SPA';
        break;
      case 'FINAL_DELIVERY':
      case 'CLIENT_DOWNLOADED':
      case 'CLOSED':
        team = 'Client Fulfillment';
        party = 'Delivered to Client';
        reviewer = 'Approved & Certified';
        break;
    }

    return {
      'team': team,
      'party': party,
      'reviewer': reviewer,
      'pa': paId != null ? 'Property Analyst #$paId' : 'Unassigned (Pool)',
    };
  }

  // ─────────────────────────────────────────────────────────────
  // PRIMARY ACTION BUTTON (HIGH-PRIORITY SINGLE CTA)
  // ─────────────────────────────────────────────────────────────

  Widget _buildPrimaryAction() {
    final status = _status;

    switch (status) {
      case 'QUOTE_PENDING':
        return _primaryDarkBtn(
          'Review Quote',
          Icons.rate_review_outlined,
          () => _handleGenerateQuote(),
        );

      case 'QUOTE_PROVIDED':
        return _secondaryLightBtn(
          'View Quote',
          Icons.description_outlined,
          () => widget.onViewQuote != null
              ? widget.onViewQuote!(widget.order)
              : AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        );

      case 'PAYMENT_SUBMITTED':
        return _primaryDarkBtn(
          'Verify & Release To Pool',
          Icons.verified_outlined,
          () => _handleVerifyAndReleaseToPool(),
        );

      case 'PAYMENT_VERIFIED':
        return _primaryDarkBtn(
          'Release To Pool',
          Icons.rocket_launch_outlined,
          () => _handleReleaseOnly(),
        );

      case 'PAID_INTAKE':
        return _primaryDarkBtn(
          'Assign',
          Icons.person_add_alt_outlined,
          () => widget.onReassign != null ? widget.onReassign!(widget.order) : null,
        );

      case 'ASSIGNED':
      case 'WORKSPACE_READY':
      case 'DRAFTING':
        return _primaryDarkBtn(
          'Open Workspace',
          Icons.edit_note_outlined,
          () => widget.onViewQuote != null
              ? widget.onViewQuote!(widget.order)
              : AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        );

      case 'ACTION_NEEDED':
      case 'ABANDONED':
        return _primaryDarkBtn(
          'Recover',
          Icons.replay_outlined,
          () => widget.onForceRecovery != null
              ? widget.onForceRecovery!(widget.order)
              : widget.onReassign != null
                  ? widget.onReassign!(widget.order)
                  : null,
        );

      case 'SPA_GATE':
      case 'SPA_REVIEW':
      case 'SUBMITTED_TO_SPA':
      case 'UNDER_REVIEW':
        return _primaryDarkBtn(
          'Review',
          Icons.fact_check_outlined,
          () => AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        );

      case 'DELIVERY_READY':
      case 'SPA_CONFIRMED':
        return _primaryDarkBtn(
          'Deliver',
          Icons.send_outlined,
          () => AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        );

      case 'FINAL_DELIVERY':
      case 'CLIENT_DOWNLOADED':
      case 'CLOSED':
        return _secondaryLightBtn(
          'View Report',
          Icons.article_outlined,
          () => AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        );

      default:
        return _secondaryLightBtn(
          'View Dossier',
          Icons.open_in_new_outlined,
          widget.onToggleExpand,
        );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // WORKFLOW ACTION: VERIFY & RELEASE TO POOL (ORCHESTRATION)
  // ─────────────────────────────────────────────────────────────

  Future<void> _handleVerifyAndReleaseToPool() async {
    final double amountPaid = (widget.order['paymentAmount'] as num?)?.toDouble() ??
        (widget.order['quoteTotal'] as num?)?.toDouble() ??
        0.0;
    final utr = widget.order['utrNumber'] ?? 'Bank Transfer';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.verified_outlined, color: Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "Verify & Release To Pool",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order #$_orderId (${widget.order['clientName'] ?? 'Client'})",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Text(
              "This action executes payment settlement verification and clears the file to the common Property Analyst intake pool.",
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _miniRow("UTR Number:", utr.toString()),
                  const SizedBox(height: 4),
                  _miniRow("Amount:", _formatCurrency(amountPaid)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Cancel", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A), // Charcoal
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("CONFIRM & RELEASE", style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isProcessingAction = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    try {
      // Step 1: verify-payment
      final vRes = await orderProvider.verifyPayment(
        orderId: _orderId,
        verifiedAmount: amountPaid,
        adminNotes: "Verified via Operational Command Center (UTR: $utr)",
      );

      if (vRes != null && vRes['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF991B1B),
            content: Text("Payment verification failed: ${vRes['error']}"),
          ));
        }
        setState(() => _isProcessingAction = false);
        return;
      }

      // Step 2: release-to-pool
      final rRes = await orderProvider.releaseToPool(orderId: _orderId);

      if (rRes != null && rRes['error'] != null) {
        // If release fails (e.g. missing intake documents), display exact backend error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF9A3412),
            content: Text("Payment verified, but held in Release Queue: ${rRes['error']}"),
            duration: const Duration(seconds: 5),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color(0xFF065F46),
            content: Text("✓ Payment verified and order released to common pool (PAID_INTAKE)."),
          ));
        }
      }

      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF991B1B),
          content: Text("Action failed: ${ApiService.getErrorMessage(e)}"),
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _handleReleaseOnly() async {
    setState(() => _isProcessingAction = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      final rRes = await orderProvider.releaseToPool(orderId: _orderId);
      if (rRes != null && rRes['error'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF9A3412),
            content: Text("Release failed: ${rRes['error']}"),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            backgroundColor: Color(0xFF065F46),
            content: Text("✓ Order released to Common Pool (PAID_INTAKE)."),
          ));
        }
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF991B1B),
          content: Text("Release failed: ${ApiService.getErrorMessage(e)}"),
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _handleGenerateQuote() {
    final clientName = widget.order['clientName']?.toString().isNotEmpty == true
        ? widget.order['clientName'].toString()
        : 'Client';
    final serviceCat = widget.order['serviceCategory']?.toString() ?? 'Valuation Report';
    final assetCat = widget.order['propertyCategory']?.toString() ?? 'Land & Building';
    final purpose = widget.order['purpose']?.toString() ?? 'Bank Collateral / Loan';

    AdminQuoteCreationModal.show(
      context: context,
      orderId: _orderId,
      referenceCode: _refCode,
      clientName: clientName,
      serviceCategory: serviceCat,
      assetCategory: assetCat,
      purpose: purpose,
      onQuoteProvided: widget.onRefresh,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // COLLAPSED ROW PRESENTATION (EXECUTIVE & CLEAN)
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final ownership = _deriveOwnershipData();
    final clientDisplay = widget.order['clientName']?.toString().isNotEmpty == true
        ? widget.order['clientName'].toString()
        : 'Client #${widget.order['clientId'] ?? _orderId}';

    final updatedAt = widget.order['updatedAt'] ?? widget.order['createdAt'];
    final statusAge = _formatStatusAge(updatedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.isExpanded ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
          width: widget.isExpanded ? 1.2 : 1.0,
        ),
        boxShadow: widget.isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Collapsed Master Row ──────────────────────────────
          InkWell(
            onTap: widget.onToggleExpand,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 1. Report Number & Reference Code
                  SizedBox(
                    width: 170,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reportNum,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A), // Charcoal
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _refCode,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        _buildRecoveryAndSlaBadge(),
                      ],
                    ),
                  ),

                  // 2. Client & Property Location
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientDisplay,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _extractPropertyAddress(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 3. Current Status & Entry Age
                  SizedBox(
                    width: 175,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatusBadge(_status),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 10, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(
                              'Age: $statusAge',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 4. Responsible Party / Owner
                  SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ownership['team']!,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownership['pa']!,
                          style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 5. Action Hub & Expand Toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _isProcessingAction
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                          : _buildPrimaryAction(),
                      const SizedBox(width: 8),

                      // Overflow Menu (Neutral Secondary Actions)
                      _buildOverflowMenu(),

                      const SizedBox(width: 8),

                      // Expand Chevron Toggle
                      IconButton(
                        onPressed: widget.onToggleExpand,
                        icon: AnimatedRotation(
                          turns: widget.isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(Icons.expand_more_rounded, size: 20, color: Color(0xFF64748B)),
                        ),
                        tooltip: widget.isExpanded ? 'Collapse Dossier' : 'Expand Dossier',
                        splashRadius: 18,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded Operational Dossier ──────────────────────
          if (widget.isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            _buildExpandedDossier(ownership),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // EXPANDED OPERATIONAL DOSSIER (STRUCTURED SEGMENTED VIEW)
  // ─────────────────────────────────────────────────────────────

  Widget _buildExpandedDossier(Map<String, String> ownership) {
    return Container(
      color: const Color(0xFFF8FAFC), // Google soft grey surface
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dossier Navigation Tabs
          Row(
            children: [
              _dossierTab(0, "Overview & Mandate", Icons.dashboard_outlined),
              const SizedBox(width: 6),
              _dossierTab(1, "Commercial & Remittance", Icons.payments_outlined),
              const SizedBox(width: 6),
              _dossierTab(2, "Document Vault (${widget.order['documentCount'] ?? _documents.length})", Icons.folder_outlined),
              const SizedBox(width: 6),
              _dossierTab(3, "Audit & Milestones", Icons.timeline_outlined),
              const Spacer(),
              // Quick action toolbar
              _buildExpandedQuickToolbar(),
            ],
          ),

          const SizedBox(height: 14),

          // Tab Body
          IndexedStack(
            index: _activeTabIndex,
            children: [
              _buildOverviewTab(ownership),
              _buildCommercialTab(),
              _buildDocumentsTab(),
              _buildTimelineTab(),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Categorized Action Footer
          _buildCategorizedActionFooter(),
        ],
      ),
    );
  }

  Widget _dossierTab(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFFCBD5E1) : Colors.transparent),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedQuickToolbar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _loadDataForActiveTab,
          icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF64748B)),
          tooltip: 'Refresh Dossier Data',
          splashRadius: 16,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
        const SizedBox(width: 6),
        InkWell(
          onTap: () => AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF475569)),
                const SizedBox(width: 4),
                Text("Full Review Modal", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: OVERVIEW & MANDATE
  // ─────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(Map<String, String> ownership) {
    final clientName = widget.order['clientName']?.toString().isNotEmpty == true
        ? widget.order['clientName'].toString()
        : 'Client #${widget.order['clientId'] ?? _orderId}';
    final bankName = widget.order['bankName']?.toString().isNotEmpty == true
        ? widget.order['bankName'].toString()
        : 'Bank on Record';
    final branchName = widget.order['branchName']?.toString().isNotEmpty == true
        ? widget.order['branchName'].toString()
        : 'Head Office';
    final purpose = widget.order['purpose']?.toString().isNotEmpty == true
        ? widget.order['purpose'].toString()
        : 'Standard Mortgage Valuation';
    final propType = widget.order['propertyCategory']?.toString() ?? 'Commercial / Industrial';
    final address = _extractPropertyAddress();

    final enteredAt = _formatDateTime(widget.order['updatedAt'] ?? widget.order['createdAt']);
    final currentAge = _formatStatusAge(widget.order['updatedAt'] ?? widget.order['createdAt']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SECTION A: Overview & Mandate
        Expanded(
          flex: 4,
          child: _panelBox("SECTION A: Overview & Mandate", Icons.apartment_outlined, [
            _metaItem("Report Number", _reportNum),
            _metaItem("Reference Number", _refCode),
            _metaItem("Client Name", clientName),
            _metaItem("Bank Name", bankName),
            _metaItem("Branch Name", branchName),
            _metaItem("Property Address", address),
            _metaItem("Property Type", propType),
            _metaItem("Purpose Of Valuation", purpose),
          ]),
        ),

        const SizedBox(width: 12),

        // SECTION B: Ownership
        Expanded(
          flex: 3,
          child: _panelBox("SECTION B: Operational Ownership", Icons.people_outline, [
            _metaItem("Client Owner", clientName),
            _metaItem("Assigned PA", ownership['pa']!),
            _metaItem("Active Reviewer", ownership['reviewer']!),
            _metaItem("Supervisor", "Super Admin / Valuation Lead"),
            _metaItem("Responsible Team", ownership['team']!),
            _metaItem("Responsible Party", ownership['party']!),
          ]),
        ),

        const SizedBox(width: 12),

        // SECTION C: Status & Lifecycle
        Expanded(
          flex: 4,
          child: _panelBox("SECTION C: Status & Lifecycle", Icons.schedule_outlined, [
            _metaItem("Current Status", _status),
            _metaItem("Entered At", enteredAt),
            _metaItem("Current Age", currentAge),
            _metaItem("Last Activity", _formatDateTime(widget.order['lastHeartbeat'] ?? widget.order['updatedAt'] ?? widget.order['createdAt'])),
            _metaItem("Last Heartbeat", _formatDateTime(widget.order['lastHeartbeat'])),
            _metaItem("Recovery State", _deriveRecoveryStateText()),
            _metaItem("SLA Status", _deriveSlaStatusText()),
            _metaItem("SLA Due Time", _formatDateTime(widget.order['slaExpiryTime'])),
            _metaItem("SLA Remaining", _deriveSlaRemainingText()),
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 2: COMMERCIAL & PAYMENT HUB (INLINE VERIFICATION)
  // ─────────────────────────────────────────────────────────────

  Widget _buildCommercialTab() {
    final quoteNum = widget.order['quoteNumber']?.toString() ?? _paymentDetails?['quoteNumber'] ?? '—';
    final quoteTotal = widget.order['quoteTotal'] ?? _paymentDetails?['quoteTotal'];
    final quoteAmount = widget.order['quoteAmount'] ?? _paymentDetails?['quoteAmount'];
    final quoteTax = widget.order['quoteTax'] ?? _paymentDetails?['quoteTax'];
    final quotedAt = _formatDateTime(widget.order['quotedAt']);
    final validUntil = _formatDateTime(widget.order['quoteValidUntil'] ?? _paymentDetails?['quoteValidUntil']);

    final utr = widget.order['utrNumber'] ?? _paymentDetails?['payments']?[0]?['utrNumber'] ?? '—';
    final payAmount = widget.order['paymentAmount'] ?? _paymentDetails?['payments']?[0]?['amountPaid'] ?? quoteTotal;
    final payMethod = widget.order['paymentMethod'] ?? _paymentDetails?['payments']?[0]?['paymentMethod'] ?? 'NEFT / RTGS';
    final paySubmitted = _formatDateTime(widget.order['paymentSubmittedAt'] ?? _paymentDetails?['payments']?[0]?['submittedAt']);
    final payVerified = _formatDateTime(widget.order['paymentVerifiedAt'] ?? _paymentDetails?['payments']?[0]?['verifiedAt']);
    final paymentStatus = (widget.order['paymentStatus'] ?? _paymentDetails?['paymentStatus'] ?? 'PENDING').toString().toUpperCase();

    final paymentsList = (_paymentDetails?['payments'] as List<dynamic>?) ?? [];
    final latestPayment = paymentsList.isNotEmpty ? paymentsList.first as Map<String, dynamic>? : null;
    final receiptDocId = latestPayment?['receiptDocumentId'] as num?;
    final receiptFilename = latestPayment?['receiptFilename']?.toString() ?? 'payment_receipt.pdf';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Formal Quotation
        Expanded(
          flex: 4,
          child: _panelBox("Commercial Quotation Details", Icons.receipt_long_outlined, [
            _metaItem("Quotation Number", quoteNum),
            _metaItem("Base Professional Fee", _formatCurrency(quoteAmount)),
            _metaItem("GST / Taxes (18%)", _formatCurrency(quoteTax)),
            _metaItem("Total Payable", _formatCurrency(quoteTotal), highlight: true),
            _metaItem("Issued At", quotedAt),
            _metaItem("Quotation Valid Until", validUntil),
          ]),
        ),

        const SizedBox(width: 12),

        // Right: Remittance & Verification Gate
        Expanded(
          flex: 6,
          child: _panelBox("Client Remittance & Settlement Gate", Icons.account_balance_outlined, [
            _metaItem("Payment Settlement Status", paymentStatus),
            _metaItem("UTR / Reference Number", utr.toString()),
            _metaItem("Amount Paid / Remitted", _formatCurrency(payAmount)),
            _metaItem("Payment Method", payMethod.toString()),
            _metaItem("Submitted Date", paySubmitted),
            _metaItem("Verified Date", payVerified),

            // Receipt preview & download row
            if (receiptDocId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attachment_rounded, size: 16, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "Receipt Proof: $receiptFilename",
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _handleDownloadDocument(receiptDocId.toInt(), receiptFilename),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text("Download Proof", style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // If PAYMENT_SUBMITTED: Display Inline Quick Verification Actions
            if (_status == 'PAYMENT_SUBMITTED') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Remittance submitted by client. Verify settlement against bank statement and clear to common pool.",
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _primaryDarkBtn(
                      'VERIFY & RELEASE',
                      Icons.check_circle_outline,
                      _handleVerifyAndReleaseToPool,
                    ),
                  ],
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: DOCUMENT REPOSITORY (CATEGORIZED VAULT)
  // ─────────────────────────────────────────────────────────────

  Widget _buildDocumentsTab() {
    if (_isLoadingDocs) {
      return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.folder_open_outlined, size: 36, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text("No documents uploaded for this order yet.", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 13)),
            ],
          ),
        ),
      );
    }

    final query = _docSearchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _documents
        : _documents.where((doc) {
            final name = (doc['originalFilename'] ?? doc['filename'] ?? '').toString().toLowerCase();
            final cat = (doc['category'] ?? '').toString().toLowerCase();
            return name.contains(query) || cat.contains(query);
          }).toList();

    // Group documents into certified classifications
    final legalDocs = <Map<String, dynamic>>[];
    final technicalPlans = <Map<String, dynamic>>[];
    final taxDocs = <Map<String, dynamic>>[];
    final paymentProofs = <Map<String, dynamic>>[];
    final propertyPhotos = <Map<String, dynamic>>[];
    final deliverables = <Map<String, dynamic>>[];

    for (final doc in filtered) {
      final cat = (doc['category']?.toString() ?? '').toUpperCase();
      if (cat.contains('PAYMENT')) {
        paymentProofs.add(doc);
      } else if (cat.contains('PLAN') || cat.contains('LAYOUT') || cat.contains('DRAWING')) {
        technicalPlans.add(doc);
      } else if (cat.contains('TAX') || cat.contains('ELECTRICITY') || cat.contains('RECEIPT')) {
        taxDocs.add(doc);
      } else if (cat.contains('PHOTO') || cat.contains('IMAGE') || cat.contains('SITE')) {
        propertyPhotos.add(doc);
      } else if (cat.contains('FINAL') || cat.contains('REPORT') || cat.contains('SIGNED')) {
        deliverables.add(doc);
      } else {
        legalDocs.add(doc);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document search bar
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _docSearchQuery = val),
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search documents by filename or category...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
              suffixIcon: _docSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 14, color: Color(0xFF64748B)),
                      onPressed: () => setState(() => _docSearchQuery = ''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("No documents matching '$_docSearchQuery'.", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
          )
        else ...[
          if (legalDocs.isNotEmpty) _docCategoryGroup("Legal & Title Documents", legalDocs, Icons.gavel_outlined),
          if (technicalPlans.isNotEmpty) _docCategoryGroup("Technical Plans & Sanctions", technicalPlans, Icons.architecture_outlined),
          if (taxDocs.isNotEmpty) _docCategoryGroup("Tax & Utility Proofs", taxDocs, Icons.receipt_outlined),
          if (propertyPhotos.isNotEmpty) _docCategoryGroup("Site & Property Photographs", propertyPhotos, Icons.photo_camera_back_outlined),
          if (paymentProofs.isNotEmpty) _docCategoryGroup("Bank Remittance Proofs", paymentProofs, Icons.account_balance_wallet_outlined),
          if (deliverables.isNotEmpty) _docCategoryGroup("Certified Final Deliverables", deliverables, Icons.verified_user_outlined),
        ],
      ],
    );
  }

  Widget _docCategoryGroup(String title, List<Map<String, dynamic>> docs, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF334155)),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                child: Text('${docs.length}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: docs.map((d) => _docCard(d)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc) {
    final int docId = (doc['id'] as num?)?.toInt() ?? 0;
    final filename = doc['filename']?.toString() ?? 'document.pdf';
    final uploadedBy = doc['uploadedBy']?.toString() ?? 'Staff';
    final uploadDate = _formatDateTime(doc['createdAt']);

    return Container(
      width: 250,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
            child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename,
                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "$uploadDate • $uploadedBy",
                  style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _handleDownloadDocument(docId, filename),
            icon: const Icon(Icons.download_rounded, size: 16, color: Color(0xFF475569)),
            tooltip: 'Download File',
            splashRadius: 14,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadDocument(int docId, String filename) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await orderProvider.downloadDocument(docId);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF065F46),
        content: Text("✓ Downloaded '$filename' (${(bytes.length / 1024).toStringAsFixed(1)} KB)"),
      ));
    }
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 4: OPERATIONAL TIMELINE & AUDIT LOG
  // ─────────────────────────────────────────────────────────────

  Widget _buildTimelineTab() {
    final auditQuery = _auditSearchQuery.trim().toLowerCase();
    final filteredAudit = auditQuery.isEmpty
        ? _auditLogs
        : _auditLogs.where((log) {
            final action = (log['actionType'] ?? '').toString().toLowerCase();
            final actor = (log['actorEmail'] ?? '').toString().toLowerCase();
            final desc = (log['description'] ?? '').toString().toLowerCase();
            return action.contains(auditQuery) || actor.contains(auditQuery) || desc.contains(auditQuery);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Audit & Timeline search bar
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _auditSearchQuery = val),
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Search audit history by event, actor, or details...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
              suffixIcon: _auditSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 14, color: Color(0xFF64748B)),
                      onPressed: () => setState(() => _auditSearchQuery = ''),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: 11 Lifecycle Milestones
            Expanded(
              flex: 5,
              child: _panelBox("11 Certified Operational Milestones", Icons.alt_route_outlined, [
                _timelineItem(1, "Created", _formatDateTime(widget.order['createdAt']), isCompleted: true),
                _timelineItem(2, "Quote Issued", _formatDateTime(widget.order['quotedAt']), isCompleted: widget.order['quotedAt'] != null),
                _timelineItem(3, "Payment Submitted", _formatDateTime(widget.order['paymentSubmittedAt']), isCompleted: widget.order['paymentSubmittedAt'] != null),
                _timelineItem(4, "Payment Verified", _formatDateTime(widget.order['paymentVerifiedAt']), isCompleted: widget.order['paymentVerifiedAt'] != null),
                _timelineItem(5, "Released To Pool", _formatDateTime(widget.order['releasedToPoolAt']), isCompleted: widget.order['releasedToPoolAt'] != null),
                _timelineItem(6, "Claimed by PA", _formatDateTime(widget.order['claimedAt']), isCompleted: widget.order['claimedAt'] != null),
                _timelineItem(7, "Workspace Ready", _status == 'WORKSPACE_READY' || _status == 'DRAFTING' || _status == 'SPA_GATE' || _status == 'SPA_CONFIRMED' || _status == 'FINAL_DELIVERY' ? 'Completed' : 'Pending', isCompleted: widget.order['paId'] != null),
                _timelineItem(8, "Drafting Authored", _status == 'DRAFTING' || _status == 'SPA_GATE' || _status == 'SPA_CONFIRMED' || _status == 'FINAL_DELIVERY' ? 'In Progress / Completed' : 'Pending', isCompleted: _status == 'DRAFTING' || _status == 'SPA_GATE' || _status == 'SPA_CONFIRMED' || _status == 'FINAL_DELIVERY'),
                _timelineItem(9, "Submitted To SPA", _status == 'SPA_GATE' || _status == 'SPA_CONFIRMED' || _status == 'FINAL_DELIVERY' ? 'Gate Reached' : 'Pending', isCompleted: _status == 'SPA_GATE' || _status == 'SPA_CONFIRMED' || _status == 'FINAL_DELIVERY'),
                _timelineItem(10, "Approved by SPA", widget.order['finalValue'] != null ? 'Verified: ₹ ${widget.order['finalValue']}' : 'Pending', isCompleted: widget.order['finalValue'] != null),
                _timelineItem(11, "Final Delivered", _formatDateTime(widget.order['deliveredAt']), isCompleted: widget.order['deliveredAt'] != null, isLast: true),
              ]),
            ),

            const SizedBox(width: 12),

            // Right: Immutable Audit Trail
            Expanded(
              flex: 5,
              child: _panelBox("Immutable Audit Trail (${filteredAudit.length} Events)", Icons.history_outlined, [
                if (_isLoadingAudit)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)))
                else if (filteredAudit.isEmpty)
                  Text(
                    _auditSearchQuery.isNotEmpty ? "No audit events matching '$_auditSearchQuery'." : "No external audit logs recorded yet.",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                  )
                else
                  ...filteredAudit.take(10).map((log) => _auditLogItem(log)),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timelineItem(int step, String title, String timestamp, {required bool isCompleted, bool isLast = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFF065F46) : const Color(0xFFE2E8F0),
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, size: 11, color: Colors.white)
                : Text('$step', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w500, color: const Color(0xFF0F172A)),
            ),
          ),
          Expanded(
            child: Text(
              timestamp,
              style: GoogleFonts.inter(fontSize: 11, color: isCompleted ? const Color(0xFF065F46) : const Color(0xFF94A3B8)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _auditLogItem(dynamic log) {
    final action = log['actionType']?.toString() ?? 'SYSTEM_EVENT';
    final actor = log['actorEmail']?.toString() ?? 'System';
    final time = _formatDateTime(log['timestamp']);
    final desc = log['description']?.toString() ?? log['actionType']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(3)),
            child: Text(action, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF1E293B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text("$time • $actor", style: GoogleFonts.inter(fontSize: 9.5, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CATEGORIZED ACTION TOOLBAR (COMMERCIAL, WORKFLOW, GOVERNANCE, DANGER)
  // ─────────────────────────────────────────────────────────────

  Widget _buildCategorizedActionFooter() {
    final status = _status;
    final isDelivered = status == 'FINAL_DELIVERY' || status == 'CLIENT_DOWNLOADED' || status == 'CLOSED';

    return Row(
      children: [
        // 1. COMMERCIAL ACTIONS
        _actionGroupLabel("COMMERCIAL"),
        const SizedBox(width: 6),
        _secondaryLightBtn(
          "View Quote",
          Icons.visibility_outlined,
          () => widget.onViewQuote != null
              ? widget.onViewQuote!(widget.order)
              : AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh),
        ),
        if (widget.order['quoteNumber'] != null) ...[
          const SizedBox(width: 6),
          _secondaryLightBtn(
            "Resend Quote",
            Icons.send_outlined,
            () => widget.onResendQuote != null ? widget.onResendQuote!(widget.order) : null,
          ),
        ],
        if (status == 'PAYMENT_SUBMITTED') ...[
          const SizedBox(width: 6),
          _primaryDarkBtn(
            "Verify & Release",
            Icons.verified_outlined,
            _handleVerifyAndReleaseToPool,
          ),
        ],
        if (status == 'QUOTE_PROVIDED' && widget.onWaivePayment != null) ...[
          const SizedBox(width: 6),
          _secondaryLightBtn(
            "Waive Fee",
            Icons.money_off_outlined,
            () => widget.onWaivePayment!(widget.order),
          ),
        ],

        const SizedBox(width: 14),
        Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),

        // 2. WORKFLOW ACTIONS
        _actionGroupLabel("WORKFLOW"),
        const SizedBox(width: 6),
        if (widget.onReassign != null) ...[
          _secondaryLightBtn(
            status == 'PAID_INTAKE' ? "Assign PA" : "Reassign",
            Icons.person_add_alt_outlined,
            () => widget.onReassign!(widget.order),
          ),
          const SizedBox(width: 6),
        ],
        if (status == 'PAYMENT_VERIFIED' || status == 'ACTION_NEEDED' || status == 'ASSIGNED') ...[
          _secondaryLightBtn(
            "Release To Pool",
            Icons.rocket_launch_outlined,
            _handleReleaseOnly,
          ),
          const SizedBox(width: 6),
        ],
        if ((status == 'DRAFTING' || status == 'ACTION_NEEDED' || status == 'WORKSPACE_READY') && widget.onForceRecovery != null) ...[
          _secondaryLightBtn(
            "Recover Session",
            Icons.replay_rounded,
            () => widget.onForceRecovery!(widget.order),
          ),
          const SizedBox(width: 6),
        ],

        const SizedBox(width: 14),
        Container(width: 1, height: 24, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),

        // 3. GOVERNANCE
        _actionGroupLabel("GOVERNANCE"),
        const SizedBox(width: 6),
        if (widget.onChangeStatus != null) ...[
          _secondaryLightBtn(
            "Change Status",
            Icons.swap_horiz_rounded,
            () => widget.onChangeStatus!(widget.order),
          ),
        ],

        const Spacer(),

        // 4. DANGER ZONE (DELETE) - ISOLATED ON RIGHT
        if (widget.canDelete && !isDelivered && widget.onDelete != null) ...[
          _dangerBtn("Delete", Icons.delete_outline_rounded, () => widget.onDelete!(widget.order)),
        ],
      ],
    );
  }

  Widget _actionGroupLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF94A3B8),
        letterSpacing: 0.5,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BUTTON DESIGN SYSTEM (CHARCOAL, SOFT GREY, WHITE, NO NEON)
  // ─────────────────────────────────────────────────────────────

  Widget _primaryDarkBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Charcoal / Graphite
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _secondaryLightBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFF334155)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dangerBtn(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCA5A5)), // Muted red border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: const Color(0xFFDC2626)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
      tooltip: 'More Operations',
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (val) {
        switch (val) {
          case 'full_modal':
            AdminRequestReviewModal.show(context: context, order: widget.order, onRefresh: widget.onRefresh);
            break;
          case 'reassign':
            if (widget.onReassign != null) widget.onReassign!(widget.order);
            break;
          case 'recover':
            if (widget.onForceRecovery != null) widget.onForceRecovery!(widget.order);
            break;
          case 'change_status':
            if (widget.onChangeStatus != null) widget.onChangeStatus!(widget.order);
            break;
          case 'invoice':
            if (widget.onViewInvoice != null) widget.onViewInvoice!(widget.order);
            break;
          case 'delete':
            if (widget.onDelete != null) widget.onDelete!(widget.order);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'full_modal',
          child: Row(
            children: [
              Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFF334155)),
              SizedBox(width: 8),
              Text('Detailed Review Dossier', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'reassign',
          child: Row(
            children: [
              Icon(Icons.person_add_alt_outlined, size: 15, color: Color(0xFF334155)),
              SizedBox(width: 8),
              Text('Assign / Reassign Analyst', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'change_status',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 15, color: Color(0xFF334155)),
              SizedBox(width: 8),
              Text('Override Status', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        if (widget.canDelete && widget.onDelete != null) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Text('Delete Order', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // REUSABLE PRESENTATION BOXES & ROWS
  // ─────────────────────────────────────────────────────────────

  Widget _panelBox(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
              ),
            ],
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          ...children,
        ],
      ),
    );
  }

  Widget _metaItem(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight ? const Color(0xFF065F46) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
        Text(val, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ],
    );
  }
}
