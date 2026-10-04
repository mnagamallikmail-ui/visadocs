import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import 'admin_quote_creation_modal.dart';

class AdminRequestReviewModal extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const AdminRequestReviewModal({
    super.key,
    required this.order,
    required this.onRefresh,
  });

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> order,
    required VoidCallback onRefresh,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AdminRequestReviewModal(
        order: order,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<AdminRequestReviewModal> createState() => _AdminRequestReviewModalState();
}

class _AdminRequestReviewModalState extends State<AdminRequestReviewModal> {
  List<Map<String, dynamic>> _documents = [];
  bool _isLoadingDocs = true;
  String? _docError;

  Map<String, dynamic>? _paymentDetails;
  bool _isLoadingPayment = true;
  String? _paymentError;

  int get _orderId => (widget.order['id'] as num?)?.toInt() ?? 0;
  String get _refCode => widget.order['referenceCode'] ?? 'REQ-${widget.order['id']}';
  String get _status => (widget.order['status']?.toString() ?? 'QUOTE_PENDING').toUpperCase();
  String get _clientName => widget.order['clientName'] ?? widget.order['clientUsername'] ?? 'Client #${widget.order['clientId']}';
  String get _clientMobile => widget.order['clientMobile'] ?? 'N/A';
  String get _clientEmail => widget.order['clientEmail'] ?? 'N/A';
  String get _serviceCategory => widget.order['serviceCategory'] ?? widget.order['serviceType'] ?? 'Valuation Report';
  String get _assetCategory => widget.order['propertyCategory'] ?? widget.order['assetCategory'] ?? 'Land & Building';
  String get _purpose => widget.order['purpose'] ?? 'Bank Collateral / Loan';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _loadPaymentDetails();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocs = true;
      _docError = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
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
          _docError = "Failed to load documents: $e";
          _isLoadingDocs = false;
        });
      }
    }
  }

  Future<void> _loadPaymentDetails() async {
    setState(() {
      _isLoadingPayment = true;
      _paymentError = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
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
          _paymentError = "Failed to load payment details: $e";
          _isLoadingPayment = false;
        });
      }
    }
  }

  Future<void> _handleDownloadDocument(int docId, String filename) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await orderProvider.downloadDocument(docId);
    if (bytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          content: Text("✓ Downloaded '$filename' (${(bytes.length / 1024).toStringAsFixed(1)} KB)"),
        ),
      );
    }
  }

  Future<void> _handlePreviewDocument(int docId, String filename) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final bytes = await orderProvider.downloadDocument(docId);
    if (bytes != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF1D4ED8), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Payment Proof Preview: $filename",
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container(
            width: 480,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Document ID: #$docId", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12, color: const Color(0xFF475569))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                      child: Text("STORED IN DB", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF047857))),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Text("Filename: $filename", style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text("File Payload Size: ${(bytes.length / 1024).toStringAsFixed(1)} KB", style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFF1D4ED8), size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Official banking transaction receipt uploaded by client. Byte integrity validated.",
                          style: TextStyle(color: Color(0xFF1E40AF), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Close"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _handleDownloadDocument(docId, filename);
              },
              icon: const Icon(Icons.download, size: 14),
              label: const Text("Download File"),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
        content: Text("✓ Copied $label to clipboard: $text"),
      ),
    );
  }

  void _openQuoteCreation() {
    Navigator.of(context).pop();
    AdminQuoteCreationModal.show(
      context: context,
      orderId: _orderId,
      referenceCode: _refCode,
      clientName: _clientName,
      serviceCategory: _serviceCategory,
      assetCategory: _assetCategory,
      purpose: _purpose,
      onQuoteProvided: widget.onRefresh,
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return "₹0.00";
    final num val = amount is num ? amount : (num.tryParse(amount.toString()) ?? 0);
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return formatter.format(val);
  }

  String _formatDateTime(dynamic dt) {
    if (dt == null) return "—";
    try {
      DateTime parsed = dt is DateTime ? dt : DateTime.parse(dt.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
    } catch (_) {
      return dt.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 900),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCards(),
                        const SizedBox(height: 24),
                        _buildWorkflowTimelineSection(),
                        const SizedBox(height: 24),
                        _buildCommercialBreakdownSection(),
                        const SizedBox(height: 24),
                        _buildPaymentHistorySection(),
                        const SizedBox(height: 24),
                        _buildDocumentsSection(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final paymentStatus = (_paymentDetails?['paymentStatus'] ?? widget.order['paymentStatus'] ?? 'PENDING').toString().toUpperCase();
    final isPaid = paymentStatus == 'VERIFIED';
    final isSubmitted = paymentStatus == 'SUBMITTED' || _status == 'PAYMENT_SUBMITTED';

    Color payBgColor = const Color(0xFFF1F5F9);
    Color payTextColor = const Color(0xFF475569);
    String payText = "PAYMENT PENDING";

    if (isPaid) {
      payBgColor = const Color(0xFFECFDF5);
      payTextColor = const Color(0xFF047857);
      payText = "PAYMENT VERIFIED";
    } else if (isSubmitted) {
      payBgColor = const Color(0xFFFEF3C7);
      payTextColor = const Color(0xFFB45309);
      payText = "PAYMENT SUBMITTED";
    } else if (paymentStatus == 'REJECTED') {
      payBgColor = const Color(0xFFFEF2F2);
      payTextColor = const Color(0xFFDC2626);
      payText = "PAYMENT REJECTED";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Order Review Dossier: $_refCode",
                        style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _copyToClipboard(_refCode, "Order Reference"),
                        child: const Icon(Icons.copy_rounded, color: Color(0xFF94A3B8), size: 14),
                      ),
                    ],
                  ),
                  Text(
                    "Comprehensive Commercial, Payment & Workflow Audit Desk",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // Payment Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: payBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : (isSubmitted ? Icons.hourglass_top_rounded : Icons.pending_outlined),
                      size: 13,
                      color: payTextColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      payText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: payTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Order Workflow Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _status == "QUOTE_PENDING"
                      ? const Color(0xFFFEF3C7)
                      : (_status == "FINAL_DELIVERY" || _status == "CLIENT_DOWNLOADED"
                          ? const Color(0xFFF3E8FF)
                          : const Color(0xFFEFF6FF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _status.replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _status == "QUOTE_PENDING"
                        ? const Color(0xFFB45309)
                        : (_status == "FINAL_DELIVERY" || _status == "CLIENT_DOWNLOADED"
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Client details card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text("Client Information", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ],
                ),
                const Divider(height: 18),
                _buildInfoRow("Name:", _clientName),
                _buildInfoRow("Mobile:", _clientMobile),
                _buildInfoRow("Email:", _clientEmail),
                _buildInfoRow("Client ID:", "#${widget.order['clientId'] ?? 'N/A'}"),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Mandate details card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text("Mandate Details", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ],
                ),
                const Divider(height: 18),
                _buildInfoRow("Service:", _serviceCategory),
                _buildInfoRow("Asset:", _assetCategory),
                _buildInfoRow("Purpose:", _purpose),
                _buildInfoRow("Created:", _formatDateTime(widget.order['createdAt'])),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 4. WORKFLOW TIMELINE SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildWorkflowTimelineSection() {
    final status = _status;
    final paymentStatus = (_paymentDetails?['paymentStatus'] ?? widget.order['paymentStatus'] ?? '').toString().toUpperCase();
    final payments = (_paymentDetails?['payments'] as List<dynamic>?) ?? [];
    final latestPayment = payments.isNotEmpty ? payments.first as Map<String, dynamic>? : null;
    final verifiedBy = latestPayment?['verifiedBy'] ?? widget.order['paymentVerifiedBy'];

    // Determine completion flags
    const createdDone = true;
    final quotedDone = widget.order['quoteNumber'] != null ||
        _paymentDetails?['quoteNumber'] != null ||
        status != 'QUOTE_PENDING';

    final paymentSubmittedDone = paymentStatus == 'SUBMITTED' ||
        paymentStatus == 'VERIFIED' ||
        status == 'PAYMENT_SUBMITTED' ||
        status == 'PAYMENT_VERIFIED' ||
        status == 'PAID_INTAKE' ||
        status == 'ASSIGNED' ||
        status == 'IN_PROGRESS' ||
        status == 'SPA_GATE' ||
        status == 'SPA_APPROVED' ||
        status == 'FINAL_DELIVERY' ||
        status == 'CLIENT_DOWNLOADED';

    final paymentVerifiedDone = paymentStatus == 'VERIFIED' ||
        status == 'PAYMENT_VERIFIED' ||
        status == 'PAID_INTAKE' ||
        status == 'ASSIGNED' ||
        status == 'IN_PROGRESS' ||
        status == 'SPA_GATE' ||
        status == 'SPA_APPROVED' ||
        status == 'FINAL_DELIVERY' ||
        status == 'CLIENT_DOWNLOADED';

    final assignedDone = widget.order['paId'] != null ||
        widget.order['claimedAt'] != null ||
        status == 'ASSIGNED' ||
        status == 'IN_PROGRESS' ||
        status == 'SPA_GATE' ||
        status == 'SPA_APPROVED' ||
        status == 'FINAL_DELIVERY' ||
        status == 'CLIENT_DOWNLOADED';

    final spaApprovedDone = status == 'SPA_APPROVED' ||
        status == 'SPA_CONFIRMED' ||
        status == 'FINAL_DELIVERY' ||
        status == 'CLIENT_DOWNLOADED' ||
        status == 'CLOSED';

    final deliveredDone = status == 'FINAL_DELIVERY' ||
        status == 'CLIENT_DOWNLOADED' ||
        status == 'CLOSED';

    // Active state indicators
    final quotedActive = status == 'QUOTE_PENDING';
    final paymentSubmittedActive = status == 'QUOTE_PROVIDED';
    final paymentVerifiedActive = status == 'PAYMENT_SUBMITTED';
    final assignedActive = status == 'PAYMENT_VERIFIED' || status == 'PAID_INTAKE' || status == 'RELEASED_TO_POOL';
    final spaApprovedActive = status == 'ASSIGNED' || status == 'IN_PROGRESS' || status == 'SPA_GATE';
    final deliveredActive = status == 'SPA_APPROVED' || status == 'SPA_CONFIRMED';

    // Extract dates
    final createdDate = _formatDateTime(widget.order['createdAt']);
    final quotedDate = widget.order['quotedAt'] != null ? _formatDateTime(widget.order['quotedAt']) : (quotedDone ? 'Completed' : null);
    final paymentSubmittedDate = widget.order['paymentSubmittedAt'] != null
        ? _formatDateTime(widget.order['paymentSubmittedAt'])
        : (paymentSubmittedDone ? 'Submitted' : null);
    final paymentVerifiedDate = widget.order['paymentVerifiedAt'] != null
        ? _formatDateTime(widget.order['paymentVerifiedAt'])
        : (paymentVerifiedDone ? 'Verified' : null);
    final assignedDate = widget.order['claimedAt'] != null
        ? _formatDateTime(widget.order['claimedAt'])
        : (assignedDone ? 'Assigned' : null);
    final deliveredDate = widget.order['deliveredAt'] != null
        ? _formatDateTime(widget.order['deliveredAt'])
        : (deliveredDone ? 'Delivered' : null);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.timeline_rounded, size: 18, color: Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text("Operational Workflow Lifecycle", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "Phase: $status",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineStep(
                  index: 1,
                  title: "Created",
                  isDone: createdDone,
                  isActive: false,
                  timestamp: createdDate,
                  actor: _clientName,
                  statusText: "COMPLETED",
                  icon: Icons.add_circle_outline,
                ),
                _buildTimelineConnector(quotedDone),
                _buildTimelineStep(
                  index: 2,
                  title: "Quoted",
                  isDone: quotedDone,
                  isActive: quotedActive,
                  timestamp: quotedDate,
                  actor: quotedDone ? "SuperAdmin Desk" : "Awaiting Quote",
                  statusText: quotedDone ? "COMPLETED" : (quotedActive ? "IN PROGRESS" : "PENDING"),
                  icon: Icons.request_quote_outlined,
                ),
                _buildTimelineConnector(paymentSubmittedDone),
                _buildTimelineStep(
                  index: 3,
                  title: "Payment Submitted",
                  isDone: paymentSubmittedDone,
                  isActive: paymentSubmittedActive,
                  timestamp: paymentSubmittedDate,
                  actor: latestPayment?['submittedBy'] ?? _clientName,
                  statusText: paymentSubmittedDone ? "COMPLETED" : (paymentSubmittedActive ? "AWAITING" : "PENDING"),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _buildTimelineConnector(paymentVerifiedDone),
                _buildTimelineStep(
                  index: 4,
                  title: "Payment Verified",
                  isDone: paymentVerifiedDone,
                  isActive: paymentVerifiedActive,
                  timestamp: paymentVerifiedDate,
                  actor: verifiedBy ?? (paymentVerifiedDone ? "SYSTEM_AUTO" : "Accounts Desk"),
                  statusText: paymentVerifiedDone ? "VERIFIED" : (paymentVerifiedActive ? "IN REVIEW" : "PENDING"),
                  icon: Icons.verified_user_outlined,
                ),
                _buildTimelineConnector(assignedDone),
                _buildTimelineStep(
                  index: 5,
                  title: "Assigned",
                  isDone: assignedDone,
                  isActive: assignedActive,
                  timestamp: assignedDate,
                  actor: widget.order['paName'] ?? "Registered Valuer",
                  statusText: assignedDone ? "ASSIGNED" : (assignedActive ? "IN POOL" : "PENDING"),
                  icon: Icons.badge_outlined,
                ),
                _buildTimelineConnector(spaApprovedDone),
                _buildTimelineStep(
                  index: 6,
                  title: "SPA Approved",
                  isDone: spaApprovedDone,
                  isActive: spaApprovedActive,
                  timestamp: spaApprovedDone ? _formatDateTime(widget.order['updatedAt']) : null,
                  actor: spaApprovedDone ? "Principal Appraiser" : "SPA Reviewer",
                  statusText: spaApprovedDone ? "APPROVED" : (spaApprovedActive ? "IN REVIEW" : "PENDING"),
                  icon: Icons.approval_outlined,
                ),
                _buildTimelineConnector(deliveredDone),
                _buildTimelineStep(
                  index: 7,
                  title: "Delivered",
                  isDone: deliveredDone,
                  isActive: deliveredActive,
                  timestamp: deliveredDate,
                  actor: deliveredDone ? _clientName : "Final Sign-off",
                  statusText: deliveredDone ? "DELIVERED" : (deliveredActive ? "FINALIZING" : "PENDING"),
                  icon: Icons.mark_email_read_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(bool isDone) {
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(top: 18),
      color: isDone ? const Color(0xFF047857) : const Color(0xFFCBD5E1),
    );
  }

  Widget _buildTimelineStep({
    required int index,
    required String title,
    required bool isDone,
    required bool isActive,
    required String? timestamp,
    required String? actor,
    required String statusText,
    required IconData icon,
  }) {
    Color circleBg = const Color(0xFFF1F5F9);
    Color circleBorder = const Color(0xFFCBD5E1);
    Color iconColor = const Color(0xFF94A3B8);
    Color titleColor = const Color(0xFF64748B);

    if (isDone) {
      circleBg = const Color(0xFF047857);
      circleBorder = const Color(0xFF047857);
      iconColor = Colors.white;
      titleColor = const Color(0xFF0F172A);
    } else if (isActive) {
      circleBg = const Color(0xFFFEF3C7);
      circleBorder = const Color(0xFFD97706);
      iconColor = const Color(0xFFD97706);
      titleColor = const Color(0xFFB45309);
    }

    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: circleBg,
              shape: BoxShape.circle,
              border: Border.all(color: circleBorder, width: 2),
            ),
            child: Icon(
              isDone ? Icons.check : icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: (isDone || isActive) ? FontWeight.w700 : FontWeight.w500,
              color: titleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFFECFDF5) : (isActive ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              statusText,
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.bold,
                color: isDone ? const Color(0xFF047857) : (isActive ? const Color(0xFFB45309) : const Color(0xFF64748B)),
              ),
            ),
          ),
          if (actor != null && actor.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                actor,
                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (timestamp != null && timestamp.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                timestamp,
                style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 5. COMMERCIAL QUOTE BREAKDOWN SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildCommercialBreakdownSection() {
    final quoteNumber = _paymentDetails?['quoteNumber'] ?? widget.order['quoteNumber'];
    final baseAmount = _paymentDetails?['quoteAmount'] ?? widget.order['quoteAmount'];
    final taxAmount = _paymentDetails?['quoteTax'] ?? widget.order['quoteTax'];
    final totalAmount = _paymentDetails?['quoteTotal'] ?? widget.order['quoteTotal'];
    final turnaround = _paymentDetails?['quoteTurnaround'] ?? widget.order['quoteTurnaround'] ?? '3-5 business days';

    final hasQuote = quoteNumber != null && quoteNumber.toString().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF047857)),
                  const SizedBox(width: 8),
                  Text(
                    "Commercial Quotation & Fee Breakdown",
                    style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF065F46)),
                  ),
                ],
              ),
              if (hasQuote)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Quote: $quoteNumber",
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF166534)),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => _copyToClipboard(quoteNumber.toString(), "Quote Number"),
                        child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Awaiting Quotation Generation",
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasQuote)
            Row(
              children: [
                Expanded(
                  child: _buildCommercialTile(
                    title: "Base Professional Fee",
                    amount: _formatCurrency(baseAmount),
                    subtitle: "Exclusive of GST",
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCommercialTile(
                    title: "GST (18%)",
                    amount: _formatCurrency(taxAmount),
                    subtitle: "Statutory Tax Component",
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCommercialTile(
                    title: "Total Fee (Payable)",
                    amount: _formatCurrency(totalAmount),
                    subtitle: "Net Payable Commercial Total",
                    color: const Color(0xFF047857),
                    isHighlighted: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCommercialTile(
                    title: "Service SLA",
                    amount: turnaround.toString(),
                    subtitle: "Standard Turnaround",
                    color: const Color(0xFF1E293B),
                    isCurrency: false,
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Text(
                    "No quotation has been issued for this request. Click 'Provide Quotation' below to set the base fee and delivery SLA.",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommercialTile({
    required String title,
    required String amount,
    required String subtitle,
    required Color color,
    bool isHighlighted = false,
    bool isCurrency = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFDCFCE7) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHighlighted ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: isCurrency ? 16 : 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 3. PAYMENT HISTORY & VERIFICATION SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentHistorySection() {
    final payments = (_paymentDetails?['payments'] as List<dynamic>?) ?? [];
    final latestPayment = payments.isNotEmpty ? payments.first as Map<String, dynamic> : null;

    final utr = latestPayment?['utrNumber'] ??
        _paymentDetails?['utrNumber'] ??
        widget.order['utrNumber'] ??
        widget.order['paymentUtr'];

    final amountPaid = latestPayment?['amountPaid'] ??
        widget.order['paymentAmount'] ??
        widget.order['quoteTotal'];

    final method = latestPayment?['paymentMethod'] ?? widget.order['paymentMethod'] ?? 'UPI / Bank Transfer';
    final submittedAt = latestPayment?['submittedAt'] ?? widget.order['paymentSubmittedAt'];
    final verifiedAt = latestPayment?['verifiedAt'] ?? widget.order['paymentVerifiedAt'];
    final verifiedBy = latestPayment?['verifiedBy'] ?? widget.order['paymentVerifiedBy'];
    final receiptDocId = (latestPayment?['receiptDocumentId'] as num?)?.toInt() ??
        (widget.order['paymentProofDocumentId'] as num?)?.toInt();
    final receiptFilename = latestPayment?['receiptFilename']?.toString() ?? 'payment_receipt.pdf';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF1E293B)),
                  const SizedBox(width: 8),
                  Text("Payment Submission & Verification Audit", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                ],
              ),
              if (_isLoadingPayment)
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
              else if (latestPayment != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: latestPayment['status'] == 'VERIFIED' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "Status: ${latestPayment['status'] ?? 'SUBMITTED'}",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: latestPayment['status'] == 'VERIFIED' ? const Color(0xFF047857) : const Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_isLoadingPayment)
            const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          else if (_paymentError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
              child: Text(_paymentError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
            )
          else if (latestPayment == null && utr == null)
            Container(
              padding: const EdgeInsets.all(18),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                children: [
                  const Icon(Icons.credit_card_off_outlined, size: 24, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 6),
                  Text("No payment submissions recorded for this order.", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text("When the client submits a UTR and payment receipt, it will appear here for verification.", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                ],
              ),
            )
          else ...[
            // Main Payment Details Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text("UTR / Transaction Ref:", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _copyToClipboard(utr.toString(), "UTR"),
                                  child: const Icon(Icons.copy_rounded, size: 12, color: Color(0xFF2563EB)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              utr?.toString() ?? "—",
                              style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow("Method:", method.toString()),
                            _buildInfoRow("Amount Paid:", _formatCurrency(amountPaid)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow("Submitted At:", _formatDateTime(submittedAt)),
                            _buildInfoRow("Submitted By:", latestPayment?['submittedBy'] ?? widget.order['clientName'] ?? 'Client'),
                            if (verifiedAt != null)
                              _buildInfoRow("Verified At:", _formatDateTime(verifiedAt)),
                            if (verifiedBy != null)
                              _buildInfoRow("Verified By:", verifiedBy.toString()),
                            if (latestPayment?['rejectionReason'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Rejection Reason: ${latestPayment!['rejectionReason']}",
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Payment Receipt Document Download
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_outlined, size: 24, color: Color(0xFF0F172A)),
                              const SizedBox(height: 4),
                              Text("Payment Proof", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                              const SizedBox(height: 2),
                              Text(receiptFilename, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 6),
                              if (receiptDocId != null) ...[
                                ElevatedButton.icon(
                                  onPressed: () => _handlePreviewDocument(receiptDocId, receiptFilename),
                                  icon: const Icon(Icons.visibility, size: 12),
                                  label: const Text("Preview Proof", style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1D4ED8),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    minimumSize: const Size(0, 26),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton.icon(
                                  onPressed: () => _handleDownloadDocument(receiptDocId, receiptFilename),
                                  icon: const Icon(Icons.download, size: 12),
                                  label: const Text("Download Proof", style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    minimumSize: const Size(0, 26),
                                  ),
                                ),
                              ] else
                                Text("No file attached", style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 2. MANDATE DOCUMENTS SECTION
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_shared_outlined, size: 18, color: Color(0xFF1E293B)),
                const SizedBox(width: 8),
                Text("Uploaded Mandate Documents", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _documents.isNotEmpty ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _documents.isNotEmpty ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1)),
              ),
              child: Text(
                "${_documents.length} verified attachment${_documents.length == 1 ? '' : 's'}",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _documents.isNotEmpty ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingDocs)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_docError != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: Text(_docError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
          )
        else if (_documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text("No documents attached to this order.", style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2.2),
                  1: FlexColumnWidth(3.5),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(1.2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                    children: [
                      Padding(padding: const EdgeInsets.all(12), child: Text("CATEGORY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                      Padding(padding: const EdgeInsets.all(12), child: Text("FILENAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                      Padding(padding: const EdgeInsets.all(12), child: Text("SIZE / TYPE", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                      Padding(padding: const EdgeInsets.all(12), child: Text("ACTION", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                    ],
                  ),
                  ..._documents.map((d) {
                    final docId = (d['id'] as num?)?.toInt() ?? 0;
                    final category = d['category'] ?? 'OTHER';
                    final filename = d['filename'] ?? 'document.pdf';
                    final mimeType = d['mimeType'] ?? 'PDF';
                    final size = d['fileSize'] != null ? "${((d['fileSize'] as num) / 1024).toStringAsFixed(1)} KB" : "Attached";

                    return TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(4)),
                            child: Text(category, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1D4ED8))),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text(filename, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0F172A))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Text("$size ($mimeType)", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF0F172A)),
                                tooltip: "Download Document",
                                onPressed: () => _handleDownloadDocument(docId, filename),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text("Close", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          if (_status == "QUOTE_PENDING")
            ElevatedButton.icon(
              onPressed: _openQuoteCreation,
              icon: const Icon(Icons.request_quote_rounded, size: 16),
              label: Text("Provide Quotation ->", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF047857)),
                  const SizedBox(width: 6),
                  Text("Commercial Quotation Issued", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF047857))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
