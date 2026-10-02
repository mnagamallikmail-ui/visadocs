import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';

class AdminQuoteCreationModal extends StatefulWidget {
  final int orderId;
  final String referenceCode;
  final String clientName;
  final String serviceCategory;
  final String assetCategory;
  final String purpose;
  final VoidCallback onQuoteProvided;

  const AdminQuoteCreationModal({
    super.key,
    required this.orderId,
    required this.referenceCode,
    required this.clientName,
    required this.serviceCategory,
    required this.assetCategory,
    required this.purpose,
    required this.onQuoteProvided,
  });

  static Future<void> show({
    required BuildContext context,
    required int orderId,
    required String referenceCode,
    required String clientName,
    required String serviceCategory,
    required String assetCategory,
    required String purpose,
    required VoidCallback onQuoteProvided,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AdminQuoteCreationModal(
        orderId: orderId,
        referenceCode: referenceCode,
        clientName: clientName,
        serviceCategory: serviceCategory,
        assetCategory: assetCategory,
        purpose: purpose,
        onQuoteProvided: onQuoteProvided,
      ),
    );
  }

  @override
  State<AdminQuoteCreationModal> createState() => _AdminQuoteCreationModalState();
}

class _AdminQuoteCreationModalState extends State<AdminQuoteCreationModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController(text: "15000");
  final _scopeNotesController = TextEditingController(
    text: "Comprehensive physical site inspection and valuation assessment. Valuer will inspect boundaries, construct, depreciation, and benchmark local circle rates and recent registry sales.",
  );
  final _termsController = TextEditingController(
    text: "1. Fee includes physical site visit within municipal limits.\n2. Draft valuation provided within committed turnaround.\n3. Digital stamped report issued upon completion.\n4. Quote valid for 15 days from issuance.",
  );

  double _gstRate = 18.0;
  String _selectedTurnaround = "3-5 Working Days";
  int _validityDays = 15;
  bool _isLoading = false;
  String? _errorMessage;

  double get _baseAmount => double.tryParse(_amountController.text) ?? 0.0;
  double get _gstAmount => (_baseAmount * (_gstRate / 100.0));
  double get _totalAmount => _baseAmount + _gstAmount;

  @override
  void dispose() {
    _amountController.dispose();
    _scopeNotesController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _handleIssueQuote() async {
    if (!_formKey.currentState!.validate()) return;
    if (_baseAmount <= 0) {
      setState(() => _errorMessage = "Please enter a valid quotation fee greater than zero.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final payload = {
      'quoteAmount': _baseAmount,
      'gstRate': _gstRate,
      'quoteTax': _gstAmount,
      'quoteTotal': _totalAmount,
      'turnaroundTime': _selectedTurnaround,
      'scopeNotes': _scopeNotesController.text.trim(),
      'termsConditions': _termsController.text.trim(),
      'validityDays': _validityDays,
    };

    final res = await orderProvider.provideQuote(widget.orderId, payload);
    setState(() => _isLoading = false);

    if (res != null && res['quoteNumber'] != null) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF047857),
            content: Text("✓ Quotation ${res['quoteNumber']} issued successfully to client!"),
          ),
        );
        widget.onQuoteProvided();
      }
    } else {
      final err = (res != null && res['error'] != null) ? res['error'].toString() : "Failed to issue quotation.";
      setState(() => _errorMessage = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_errorMessage != null) _buildErrorBanner(),
                          _buildMandateBanner(),
                          const SizedBox(height: 20),
                          _buildFeeSection(),
                          const SizedBox(height: 20),
                          _buildTimelineSection(),
                          const SizedBox(height: 20),
                          _buildScopeSection(),
                          const SizedBox(height: 20),
                          _buildTermsSection(),
                        ],
                      ),
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
                child: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Issue Valuation Quotation",
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    "Reference: ${widget.referenceCode}",
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB91C1C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFFB91C1C), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandateBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("CLIENT: ${widget.clientName}", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569))),
                const SizedBox(height: 2),
                Text("${widget.serviceCategory} • ${widget.assetCategory}", style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "STATUS: QUOTE_PENDING",
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("1. Fee Schedule", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Base Professional Fee (₹) *",
                  hintText: "e.g. 15000",
                  prefixText: "₹ ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "Required";
                  if (double.tryParse(v) == null) return "Invalid";
                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<double>(
                initialValue: _gstRate,
                decoration: InputDecoration(
                  labelText: "GST Rate (%)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 18.0, child: Text("18% (Std)")),
                  DropdownMenuItem(value: 12.0, child: Text("12%")),
                  DropdownMenuItem(value: 0.0, child: Text("0% (Exempt)")),
                ],
                onChanged: (v) => setState(() => _gstRate = v ?? 18.0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("GST (18%): ₹ ${_gstAmount.toStringAsFixed(2)}", style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF065F46))),
              Text("Total Quoted: ₹ ${_totalAmount.toStringAsFixed(2)}", style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF047857))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("2. Turnaround & Validity", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTurnaround,
                decoration: InputDecoration(
                  labelText: "Turnaround Time (SLA) *",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: "24-48 Hours Express", child: Text("24-48 Hours Express")),
                  DropdownMenuItem(value: "3-5 Working Days", child: Text("3-5 Working Days (Default)")),
                  DropdownMenuItem(value: "5-7 Working Days", child: Text("5-7 Working Days")),
                  DropdownMenuItem(value: "7-10 Working Days", child: Text("7-10 Working Days")),
                ],
                onChanged: (v) => setState(() => _selectedTurnaround = v ?? "3-5 Working Days"),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _validityDays,
                decoration: InputDecoration(
                  labelText: "Quote Validity",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 7, child: Text("7 Days")),
                  DropdownMenuItem(value: 15, child: Text("15 Days (Default)")),
                  DropdownMenuItem(value: 30, child: Text("30 Days")),
                ],
                onChanged: (v) => setState(() => _validityDays = v ?? 15),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("3. Valuation Scope & Deliverables *", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _scopeNotesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Enter specific scope, asset inspection parameters, and deliverable commitments...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Scope notes are required";
            if (v.trim().length < 10) return "Scope notes must be at least 10 characters";
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("4. Terms & Conditions", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _termsController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Standard engagement terms and client obligations...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            child: Text("Cancel", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _handleIssueQuote,
            icon: _isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 16),
            label: Text(_isLoading ? "Issuing Quote..." : "Issue Formal Quote (₹ ${_totalAmount.toStringAsFixed(0)})", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF047857),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
