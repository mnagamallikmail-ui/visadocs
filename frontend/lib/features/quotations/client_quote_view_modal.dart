import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import '../../providers/order_provider.dart';
import 'client_payment_submission_modal.dart';

class ClientQuoteViewModal extends StatefulWidget {
  final int orderId;
  final String? initialRefCode;

  const ClientQuoteViewModal({
    super.key,
    required this.orderId,
    this.initialRefCode,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    String? initialRefCode,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ClientQuoteViewModal(
        orderId: orderId,
        initialRefCode: initialRefCode,
      ),
    );
  }

  @override
  State<ClientQuoteViewModal> createState() => _ClientQuoteViewModalState();
}

class _ClientQuoteViewModalState extends State<ClientQuoteViewModal> {
  Map<String, dynamic>? _quoteData;
  bool _isLoading = true;
  bool _isDownloadingPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  Future<void> _loadQuote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final data = await orderProvider.fetchOrderQuote(widget.orderId);

    if (mounted) {
      if (data != null && data['quoteNumber'] != null) {
        setState(() {
          _quoteData = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = data?['error']?.toString() ?? "Quotation is being prepared by our valuation desk.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final Uint8List? pdfBytes = await orderProvider.downloadQuotePdf(widget.orderId);
    setState(() => _isDownloadingPdf = false);

    if (pdfBytes != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF047857),
          content: Text("✓ Quotation PDF downloaded successfully (${(pdfBytes.length / 1024).toStringAsFixed(1)} KB)"),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFB91C1C),
          content: Text("Failed to download Quotation PDF. Please try again or contact support."),
        ),
      );
    }
  }

  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Text("Valuation Support Desk", style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Have questions regarding your quote or scope of inspection?", style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Quotation Ref: ${_quoteData?['quoteNumber'] ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Text("Mandate Ref: ${_quoteData?['referenceCode'] ?? widget.initialRefCode ?? 'N/A'}", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                  const SizedBox(height: 8),
                  Text("Email: desk@provaluer.in", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1D4ED8))),
                  Text("Helpline: +91 98765 00000 (Mon - Sat 9:00 - 18:00 IST)", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 860),
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : (_errorMessage != null)
                          ? _buildErrorView()
                          : _buildQuoteContent(),
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
                child: const Icon(Icons.description_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Formal Commercial Quotation",
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    "Reference: ${_quoteData?['referenceCode'] ?? widget.initialRefCode ?? 'REQ-Pending'}",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFFB45309)),
            const SizedBox(height: 16),
            Text("Quotation In Preparation", style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteContent() {
    final quoteNumber = _quoteData!['quoteNumber'] ?? 'QTE-N/A';
    final quoteAmount = (_quoteData!['quoteAmount'] as num?)?.toDouble() ?? 0.0;
    final quoteTax = (_quoteData!['quoteTax'] as num?)?.toDouble() ?? 0.0;
    final quoteTotal = (_quoteData!['quoteTotal'] as num?)?.toDouble() ?? 0.0;
    final turnaround = _quoteData!['turnaroundTime'] ?? '3-5 Working Days';
    final scopeNotes = _quoteData!['scopeNotes'] ?? 'Full valuation scope as per standard engagement.';
    final terms = _quoteData!['termsConditions'] ?? 'Standard engagement terms apply.';
    final service = _quoteData!['serviceCategory'] ?? 'Valuation Report';
    final asset = _quoteData!['assetCategory'] ?? 'Land & Building';
    final validUntil = _quoteData!['validUntil'] != null ? _quoteData!['validUntil'].toString().split('T')[0] : '15 Days';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner with quote number and valid until
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("QUOTE NUMBER", style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(quoteNumber, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("VALID UNTIL", style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(validUntil, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Status Banner if applicable
          if (_quoteData!['status'] == 'PAYMENT_VERIFIED' || _quoteData!['paymentStatus'] == 'VERIFIED') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment Verified & Quotation Confirmed", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF047857))),
                        const SizedBox(height: 2),
                        Text("Your payment has been successfully reconciled. The valuation order is officially confirmed.", style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF065F46))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_quoteData!['status'] == 'PAYMENT_SUBMITTED' || _quoteData!['paymentStatus'] == 'SUBMITTED') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, color: Color(0xFFB45309), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment Proof Under Review", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                        const SizedBox(height: 2),
                        Text("Your bank payment receipt and UTR reference are currently being verified by our accounts desk.", style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF78350F))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_quoteData!['status'] == 'PAYMENT_REJECTED' || _quoteData!['paymentStatus'] == 'REJECTED') ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Payment Verification Rejected", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFB91C1C))),
                        const SizedBox(height: 2),
                        Text("Your previous payment submission was rejected. Please review your UTR and receipt, then re-submit below.", style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF7F1D1D))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Fee breakdown table card
          Text("Commercial Fee Schedule", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildFeeRow("Professional Valuation Fee (Base)", "₹ ${quoteAmount.toStringAsFixed(2)}"),
                const Divider(height: 1),
                _buildFeeRow("Goods & Services Tax (GST @ 18%)", "₹ ${quoteTax.toStringAsFixed(2)}"),
                const Divider(height: 1),
                Container(
                  color: const Color(0xFFECFDF5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("TOTAL PAYABLE FEE", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF047857))),
                      Text("₹ ${quoteTotal.toStringAsFixed(2)}", style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w800, color: const Color(0xFF047857))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bank Remittance Account Details card
          Text("Bank Remittance Account Details (NEFT / RTGS / IMPS / UPI)", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildFeeRow("Beneficiary Name", "ProValuer Valuation & Advisory Services Pvt Ltd"),
                const Divider(height: 1),
                _buildFeeRow("Bank Name & Branch", "HDFC Bank Ltd, Nariman Point, Mumbai"),
                const Divider(height: 1),
                _buildFeeRow("Account Number", "50200088912345 (Current Account)"),
                const Divider(height: 1),
                _buildFeeRow("IFSC Code", "HDFC0001234"),
                const Divider(height: 1),
                _buildFeeRow("UPI ID", "provaluer.commercial@hdfcbank"),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Turnaround & Service card
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Text("Committed Turnaround", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(turnaround, style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text("Post site inspection & physical verification", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 16, color: Color(0xFF475569)),
                          const SizedBox(width: 6),
                          Text("Mandate Scope", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("$service • $asset", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text("Standard IBBI compliant deliverable", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scope of Work description
          Text("Scope of Work & Deliverables", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(scopeNotes, style: GoogleFonts.inter(fontSize: 12.5, height: 1.45, color: const Color(0xFF334155))),
          ),
          const SizedBox(height: 18),

          // Terms & Conditions
          Text("Terms & Conditions", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Text(terms, style: GoogleFonts.inter(fontSize: 12, height: 1.45, color: const Color(0xFF475569))),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155))),
          Text(amount, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
        ],
      ),
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
          OutlinedButton.icon(
            onPressed: _showContactSupportDialog,
            icon: const Icon(Icons.headset_mic_outlined, size: 16, color: Color(0xFF475569)),
            label: Text("Contact Support", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (_quoteData != null)
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
                  icon: _isDownloadingPdf
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: Text(_isDownloadingPdf ? "Downloading..." : "Download PDF", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                if (_quoteData!['status'] == 'QUOTE_PROVIDED' || _quoteData!['status'] == 'PAYMENT_REJECTED' || _quoteData!['paymentStatus'] == 'UNPAID' || _quoteData!['paymentStatus'] == 'REJECTED') ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      ClientPaymentSubmissionModal.show(
                        context: context,
                        orderId: widget.orderId,
                        onSuccess: () {
                          _loadQuote();
                        },
                      );
                    },
                    icon: const Icon(Icons.payment_rounded, size: 16),
                    label: Text(
                      _quoteData!['status'] == 'PAYMENT_REJECTED' || _quoteData!['paymentStatus'] == 'REJECTED'
                          ? "Resubmit Payment Proof"
                          : "Pay & Submit Proof",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF047857),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
