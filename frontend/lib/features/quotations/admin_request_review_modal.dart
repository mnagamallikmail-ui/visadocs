import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  int get _orderId => (widget.order['id'] as num?)?.toInt() ?? 0;
  String get _refCode => widget.order['referenceCode'] ?? 'REQ-${widget.order['id']}';
  String get _status => widget.order['status'] ?? 'QUOTE_PENDING';
  String get _clientName => widget.order['clientName'] ?? widget.order['clientUsername'] ?? 'Client #${widget.order['clientId']}';
  String get _clientMobile => widget.order['clientMobile'] ?? 'N/A';
  String get _clientEmail => widget.order['clientEmail'] ?? 'N/A';
  String get _serviceCategory => widget.order['serviceCategory'] ?? 'Valuation Report';
  String get _assetCategory => widget.order['propertyCategory'] ?? 'Land & Building';
  String get _purpose => widget.order['purpose'] ?? 'Bank Collateral / Loan';

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _isLoadingDocs = true;
      _docError = null;
    });

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    try {
      final docs = await orderProvider.fetchOrderDocuments(_orderId);
      setState(() {
        _documents = (docs ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoadingDocs = false;
      });
    } catch (e) {
      setState(() {
        _docError = "Failed to load documents: $e";
        _isLoadingDocs = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840, maxHeight: 860),
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
                child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Review Dossier: $_refCode",
                    style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    "Intake Review & Commercial Quotation Desk",
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _status == "QUOTE_PENDING" ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _status,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _status == "QUOTE_PENDING" ? const Color(0xFFB45309) : const Color(0xFF047857),
              ),
            ),
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
            width: 70,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Uploaded Mandate Documents", style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
            if (_documents.isNotEmpty)
              Text("${_documents.length} verified attachments", style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
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
                  0: FlexColumnWidth(2.0),
                  1: FlexColumnWidth(3.0),
                  2: FlexColumnWidth(2.0),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                    children: [
                      Padding(padding: const EdgeInsets.all(12), child: Text("CATEGORY", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                      Padding(padding: const EdgeInsets.all(12), child: Text("FILENAME", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                      Padding(padding: const EdgeInsets.all(12), child: Text("ACTIONS", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))),
                    ],
                  ),
                  ..._documents.map((d) {
                    final docId = (d['id'] as num?)?.toInt() ?? 0;
                    final category = d['category'] ?? 'OTHER';
                    final filename = d['filename'] ?? 'document.pdf';

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
              child: Text("Quotation already provided for this request", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF047857))),
            ),
        ],
      ),
    );
  }
}
