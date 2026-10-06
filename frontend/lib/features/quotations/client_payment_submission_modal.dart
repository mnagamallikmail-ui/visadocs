import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/order_provider.dart';

class ClientPaymentSubmissionModal extends StatefulWidget {
  final int orderId;
  final String? initialRefCode;
  final VoidCallback? onSuccess;
  final PlatformFile? initialFileForTesting;

  const ClientPaymentSubmissionModal({
    super.key,
    required this.orderId,
    this.initialRefCode,
    this.onSuccess,
    this.initialFileForTesting,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    String? initialRefCode,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ClientPaymentSubmissionModal(
        orderId: orderId,
        initialRefCode: initialRefCode,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ClientPaymentSubmissionModal> createState() => _ClientPaymentSubmissionModalState();
}

class _ClientPaymentSubmissionModalState extends State<ClientPaymentSubmissionModal> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentDetails;

  // Form controllers
  String _selectedMethod = "UPI";
  final TextEditingController _utrController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();

  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    if (widget.initialFileForTesting != null) {
      _selectedFile = widget.initialFileForTesting;
    }
    _loadDetails();
  }

  @override
  void dispose() {
    _utrController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final data = await orderProvider.fetchPaymentDetails(widget.orderId);

    if (mounted) {
      if (data != null && data['error'] == null) {
        setState(() {
          _paymentDetails = data;
          _isLoading = false;
          final total = (data['quoteTotal'] as num?)?.toDouble() ?? 0.0;
          _amountController.text = total.toStringAsFixed(2);
        });
      } else {
        setState(() {
          _errorMessage = data?['error'] ?? "Failed to load quotation and payment instructions.";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 10 * 1024 * 1024) {
        setState(() => _errorMessage = "Selected file exceeds 10 MB limit.");
        return;
      }
      setState(() {
        _selectedFile = file;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null || _selectedFile!.bytes == null) {
      setState(() => _errorMessage = "Payment proof document (PDF/Image) is required.");
      return;
    }

    if (_selectedFile!.bytes!.isEmpty || _selectedFile!.size <= 0) {
      setState(() => _errorMessage = "Selected payment receipt file cannot be empty.");
      return;
    }

    final ext = _selectedFile!.name.contains('.') ? _selectedFile!.name.split('.').last.toLowerCase() : '';
    const allowedExts = ['pdf', 'png', 'jpg', 'jpeg'];
    if (!allowedExts.contains(ext)) {
      setState(() => _errorMessage = "Unsupported file format (.$ext). Allowed formats: PDF, PNG, JPG, JPEG.");
      return;
    }

    final amountPaid = double.tryParse(_amountController.text.trim());
    if (amountPaid == null || amountPaid <= 0) {
      setState(() => _errorMessage = "Please enter a valid positive payment amount.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final dateStr = "${_paymentDate.year.toString().padLeft(4, '0')}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}";

    final res = await orderProvider.submitPaymentProof(
      orderId: widget.orderId,
      utrNumber: _utrController.text.trim().toUpperCase(),
      paymentMethod: _selectedMethod,
      paymentDate: dateStr,
      amountPaid: amountPaid,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      fileBytes: _selectedFile!.bytes!,
      filename: _selectedFile!.name,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      final paymentStatus = res?['status']?.toString().toUpperCase();
      if (res != null && res['error'] == null && res['id'] != null && (paymentStatus == 'SUBMITTED' || paymentStatus == 'PAYMENT_SUBMITTED')) {
        final messenger = ScaffoldMessenger.of(context);
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (widget.onSuccess != null) widget.onSuccess!();
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF047857),
            content: Text("✓ Payment submitted successfully. Awaiting administrative verification."),
          ),
        );
      } else {
        setState(() {
          _errorMessage = "Payment submission failed.\n${res?['error'] ?? "Failed to submit payment proof."}";
        });
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
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 860),
        child: _isLoading
            ? const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final ref = _paymentDetails?['referenceCode'] ?? widget.initialRefCode ?? 'REQ-${widget.orderId}';
    final quoteNum = _paymentDetails?['quoteNumber'] ?? 'QTE-${widget.orderId}';
    final total = (_paymentDetails?['quoteTotal'] as num?)?.toDouble() ?? 0.0;
    final baseAmount = (_paymentDetails?['quoteAmount'] as num?)?.toDouble() ?? 0.0;
    final taxAmount = (_paymentDetails?['quoteTax'] as num?)?.toDouble() ?? 0.0;
    final bank = _paymentDetails?['bankDetails'] as Map<String, dynamic>?;

    return Column(
      children: [
        // Modal Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: const BoxDecoration(
            color: Color(0xFF0B192C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Submit Payment Proof",
                      style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Quotation: $quoteNum | Reference: $ref",
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        // Modal Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Quotation Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("FEE BREAKDOWN", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF64748B), letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text("Base Fee: ₹ ${baseAmount.toStringAsFixed(2)}  |  GST (18%): ₹ ${taxAmount.toStringAsFixed(2)}", style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF334155))),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("TOTAL AMOUNT DUE", style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF047857), letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text("₹ ${total.toStringAsFixed(2)}", style: GoogleFonts.montserrat(fontSize: 19, fontWeight: FontWeight.w800, color: const Color(0xFF047857))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remittance Details (Dynamic from Backend Application Config)
                  Text("1. Remit Funds to Company Account", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBankRow("Beneficiary:", bank?['beneficiaryName'] ?? "ProValuer Valuation & Advisory Services Pvt Ltd"),
                              const SizedBox(height: 6),
                              _buildBankRow("Bank Name:", bank?['bankName'] ?? "HDFC Bank Ltd"),
                              const SizedBox(height: 6),
                              _buildBankRow("Account No:", bank?['accountNumber'] ?? "50200088912345"),
                              const SizedBox(height: 6),
                              _buildBankRow("IFSC Code:", bank?['ifsc'] ?? "HDFC0001234"),
                              const SizedBox(height: 6),
                              _buildBankRow("Corporate UPI:", bank?['upiId'] ?? "provaluer.commercial@hdfcbank"),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF1E40AF)),
                              const SizedBox(height: 4),
                              Text("Scan UPI QR", style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Evidence Input
                  Text("2. Enter Remittance Evidence", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: _selectedMethod,
                          decoration: InputDecoration(
                            labelText: "Payment Method *",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: "UPI", child: Text("UPI / GPay / PhonePe")),
                            DropdownMenuItem(value: "NEFT", child: Text("NEFT")),
                            DropdownMenuItem(value: "RTGS", child: Text("RTGS")),
                            DropdownMenuItem(value: "IMPS", child: Text("IMPS")),
                            DropdownMenuItem(value: "BANK_TRANSFER", child: Text("Direct Bank Transfer")),
                          ],
                          onChanged: (v) => setState(() => _selectedMethod = v ?? "UPI"),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextFormField(
                          controller: _utrController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: "UTR / Transaction Ref *",
                            hintText: "e.g. 428910284721",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "UTR is mandatory";
                            final clean = v.trim();
                            if (clean.length < 6 || clean.length > 30) return "UTR must be 6-30 chars";
                            if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(clean)) return "Alphanumeric only";
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Amount Paid (₹) *",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return "Amount is mandatory";
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) return "Invalid positive amount";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _paymentDate,
                              firstDate: DateTime(2025),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) setState(() => _paymentDate = picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: "Payment Date *",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            child: Text(
                              "${_paymentDate.day.toString().padLeft(2, '0')}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.year}",
                              style: GoogleFonts.inter(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Upload Receipt Button & Selected File
                  Text("Proof Receipt / Screenshot * (PDF, PNG, JPG ≤ 10 MB)", style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedFile != null ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedFile != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedFile != null ? Icons.check_circle : Icons.upload_file_rounded,
                            color: _selectedFile != null ? const Color(0xFF047857) : const Color(0xFF64748B),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile != null ? _selectedFile!.name : "Click to select payment receipt document",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: _selectedFile != null ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedFile != null ? const Color(0xFF047857) : const Color(0xFF334155),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedFile != null)
                                  Text(
                                    "${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB",
                                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF065F46)),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            _selectedFile != null ? "Change" : "Browse File",
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: "Notes / Remitter Remarks (Optional)",
                      hintText: "e.g. Transferred from Director's Current Account",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Footer Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text("Cancel", style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 14),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleSubmit,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _isSubmitting ? "Submitting..." : "Submit Payment Proof",
                  style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF047857),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1E3A8A))),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
