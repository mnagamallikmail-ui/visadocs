import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';

class AdminPaymentReviewModal extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const AdminPaymentReviewModal({
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
      builder: (ctx) => AdminPaymentReviewModal(
        order: order,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  State<AdminPaymentReviewModal> createState() => _AdminPaymentReviewModalState();
}

class _AdminPaymentReviewModalState extends State<AdminPaymentReviewModal> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentDetails;

  int get _orderId => (widget.order['id'] as num?)?.toInt() ?? 0;
  String get _refCode => widget.order['referenceCode'] ?? 'REQ-${widget.order['id']}';
  String get _clientName => widget.order['clientName'] ?? widget.order['clientUsername'] ?? 'Client #${widget.order['clientId']}';

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final data = await orderProvider.fetchPaymentDetails(_orderId);

    if (mounted) {
      if (data != null && data['error'] == null) {
        setState(() {
          _paymentDetails = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data?['error'] ?? "Failed to load payment details.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownloadReceipt(int docId, String filename) async {
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

  Future<void> _promptVerifyPayment(Map<String, dynamic> latestPayment) async {
    final double amountPaid = (latestPayment['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final verifiedAmtController = TextEditingController(text: amountPaid.toStringAsFixed(2));
    final adminNotesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Confirm Bank Settlement", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Confirm that the remittance has credited the company bank account.", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
            const SizedBox(height: 16),
            TextFormField(
              controller: verifiedAmtController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: "Verified Amount Credited (₹) *",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: adminNotesController,
              maxLines: 2,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: "Internal Audit Notes (Optional)",
                hintText: "e.g. Verified in HDFC A/c statement",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF047857), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("VERIFY & CONFIRM"),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final verifiedAmt = double.tryParse(verifiedAmtController.text.trim()) ?? amountPaid;
      setState(() => _isProcessing = true);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final res = await orderProvider.verifyPayment(
        orderId: _orderId,
        verifiedAmount: verifiedAmt,
        adminNotes: adminNotesController.text.trim().isNotEmpty ? adminNotesController.text.trim() : null,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (res != null && res['error'] == null) {
          widget.onRefresh();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF047857),
              content: Text("✓ Payment verified. Order status updated to PAYMENT_VERIFIED."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text("Error: ${res?['error'] ?? 'Verification failed'}"),
            ),
          );
        }
      }
    }
  }

  Future<void> _promptRejectPayment(Map<String, dynamic> latestPayment) async {
    String selectedReason = "FUNDS_NOT_RECEIVED";
    final adminNotesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Reject Payment Proof", style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Select the reason for rejecting this remittance proof. The client will be alerted to re-submit.", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(labelText: "Rejection Reason *", border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: "FUNDS_NOT_RECEIVED", child: Text("Funds Not Received in Bank")),
                  DropdownMenuItem(value: "AMOUNT_MISMATCH", child: Text("Amount Mismatch / Underpaid")),
                  DropdownMenuItem(value: "UNREADABLE_RECEIPT", child: Text("Unreadable / Blurred Receipt")),
                  DropdownMenuItem(value: "DUPLICATE_OR_EXPIRED_UTR", child: Text("Duplicate or Expired UTR")),
                  DropdownMenuItem(value: "OTHER", child: Text("Other (Specified in Notes)")),
                ],
                onChanged: (v) => setDlgState(() => selectedReason = v ?? "FUNDS_NOT_RECEIVED"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: adminNotesController,
                maxLines: 3,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: "Detailed Instructions for Client",
                  hintText: "Explain why proof was rejected and what client should do...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("REJECT PROOF"),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      final res = await orderProvider.rejectPayment(
        orderId: _orderId,
        rejectionReason: selectedReason,
        adminNotes: adminNotesController.text.trim().isNotEmpty ? adminNotesController.text.trim() : null,
      );

      if (mounted) {
        setState(() => _isProcessing = false);
        if (res != null && res['error'] == null) {
          widget.onRefresh();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFB45309),
              content: Text("Payment rejected. Notification dispatched to client for re-submission."),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text("Error: ${res?['error'] ?? 'Rejection failed'}"),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 860),
        child: _isLoading
            ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
            : _errorMessage != null
                ? SizedBox(
                    height: 250,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 40),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final payments = (_paymentDetails?['payments'] as List<dynamic>?) ?? [];
    final latestPayment = payments.isNotEmpty ? payments.first as Map<String, dynamic> : null;
    final orderStatus = _paymentDetails?['orderStatus'] ?? widget.order['status'] ?? 'UNKNOWN';
    final quoteTotal = (_paymentDetails?['quoteTotal'] as num?)?.toDouble() ?? 0.0;
    final quoteNum = _paymentDetails?['quoteNumber'] ?? 'QTE-$_orderId';

    return Column(
      children: [
        // Modal Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Payment Verification & Audit",
                      style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Ref: $_refCode | Quote: $quoteNum | Client: $_clientName",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: orderStatus == "PAYMENT_VERIFIED"
                      ? const Color(0xFF047857)
                      : (orderStatus == "PAYMENT_REJECTED" ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  orderStatus.replaceAll('_', ' '),
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (latestPayment == null) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text("No payment proof submitted yet for this quotation.", style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                    ),
                  ),
                ] else ...[
                  // Primary Remittance Comparison Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricTile("EXPECTED TOTAL", "₹ ${quoteTotal.toStringAsFixed(2)}", const Color(0xFF334155)),
                            ),
                            Container(width: 1, height: 45, color: const Color(0xFFCBD5E1)),
                            Expanded(
                              child: _buildMetricTile("AMOUNT SUBMITTED", "₹ ${((latestPayment['amountPaid'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}", const Color(0xFF047857)),
                            ),
                            Container(width: 1, height: 45, color: const Color(0xFFCBD5E1)),
                            Expanded(
                              child: _buildMetricTile(
                                "VERIFIED AMOUNT",
                                latestPayment['verifiedAmount'] != null ? "₹ ${((latestPayment['verifiedAmount'] as num).toDouble()).toStringAsFixed(2)}" : "—",
                                const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildInfoItem("UTR / Trans Ref", latestPayment['utrNumber'] ?? "N/A", isCode: true)),
                            Expanded(child: _buildInfoItem("Payment Method", latestPayment['paymentMethod'] ?? "N/A")),
                            Expanded(child: _buildInfoItem("Remittance Date", latestPayment['paymentDate'] ?? "N/A")),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Receipt Document Card
                  Text("Remittance Evidence Receipt", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestPayment['receiptFilename'] ?? "receipt_proof.pdf",
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Submitted by: ${latestPayment['submittedBy'] ?? 'Client'}",
                                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (latestPayment['receiptDocumentId'] != null)
                          ElevatedButton.icon(
                            onPressed: () => _handleDownloadReceipt(
                              latestPayment['receiptDocumentId'] as int,
                              latestPayment['receiptFilename'] ?? "receipt.pdf",
                            ),
                            icon: const Icon(Icons.download_rounded, size: 15),
                            label: Text("View / Download", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF0F172A),
                              elevation: 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Client Notes
                  if (latestPayment['clientNotes'] != null && latestPayment['clientNotes'].toString().isNotEmpty) ...[
                    Text("Client Remitter Remarks", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        latestPayment['clientNotes'],
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Audit Trail if Verified or Rejected
                  if (latestPayment['status'] == 'VERIFIED' || latestPayment['status'] == 'REJECTED') ...[
                    Text("Verification Audit Trail", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: latestPayment['status'] == 'VERIFIED' ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: latestPayment['status'] == 'VERIFIED' ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                latestPayment['status'] == 'VERIFIED' ? Icons.check_circle : Icons.cancel,
                                size: 16,
                                color: latestPayment['status'] == 'VERIFIED' ? const Color(0xFF047857) : const Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Audited by: ${latestPayment['verifiedBy'] ?? 'Admin'} on ${latestPayment['verifiedAt'] ?? 'recently'}",
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          if (latestPayment['rejectionReason'] != null) ...[
                            const SizedBox(height: 6),
                            Text("Reason: ${latestPayment['rejectionReason']}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C))),
                          ],
                          if (latestPayment['adminNotes'] != null) ...[
                            const SizedBox(height: 4),
                            Text("Notes: ${latestPayment['adminNotes']}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155))),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ],
            ),
          ),
        ),

        // Action Bar (Only active when PAYMENT_SUBMITTED)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sprint 3 Boundary: Ends at PAYMENT_VERIFIED",
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    child: Text("Close", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  if (orderStatus == "PAYMENT_SUBMITTED" && latestPayment != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isProcessing ? null : () => _promptRejectPayment(latestPayment),
                      icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                      label: Text("Reject Payment", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _promptVerifyPayment(latestPayment),
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                      label: Text("Verify Payment", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF047857),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value, {bool isCode = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
        const SizedBox(height: 3),
        SelectableText(
          value,
          style: isCode
              ? GoogleFonts.sourceCodePro(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))
              : GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
