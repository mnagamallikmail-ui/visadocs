import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';

class AdminLeadsCrmSection extends StatefulWidget {
  const AdminLeadsCrmSection({super.key});

  @override
  State<AdminLeadsCrmSection> createState() => _AdminLeadsCrmSectionState();
}

class _AdminLeadsCrmSectionState extends State<AdminLeadsCrmSection> {
  final ApiService _api = ApiService();
  bool _loading = false;
  String? _errorMessage;
  List<dynamic> _leads = [];

  String? _statusFilter;
  String? _serviceFilter;
  String? _intentFilter;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await _api.dio.get(
        '/api/leads',
        queryParameters: {
          if (_statusFilter != null && _statusFilter != 'ALL') 'status': _statusFilter,
          if (_serviceFilter != null && _serviceFilter != 'ALL') 'service': _serviceFilter,
          if (_intentFilter != null && _intentFilter != 'ALL') 'intent': _intentFilter,
        },
      );
      setState(() {
        _leads = res.data as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load commercial leads: $e';
        _loading = false;
      });
    }
  }

  void _showQuoteDialog(Map<String, dynamic> lead) {
    final feeCtrl = TextEditingController(text: '35000');
    final daysCtrl = TextEditingController(text: '3');
    final scopeCtrl = TextEditingController(text: 'Statutory Valuation Appraisal Report & Signed Certification');
    final termsCtrl = TextEditingController(text: '50% advance on engagement, 50% on draft report delivery.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Issue Valuation Quotation — ${lead['referenceCode']}'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: feeCtrl,
                decoration: const InputDecoration(labelText: 'Estimated Fee (₹ ex. GST) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: daysCtrl,
                decoration: const InputDecoration(labelText: 'Turnaround Days (SLA) *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scopeCtrl,
                decoration: const InputDecoration(labelText: 'Scope of Work *', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: termsCtrl,
                decoration: const InputDecoration(labelText: 'Terms & Conditions', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              try {
                final fee = double.tryParse(feeCtrl.text) ?? 0;
                final days = int.tryParse(daysCtrl.text) ?? 3;
                await _api.dio.post('/api/leads/${lead['id']}/quote', data: {
                  'estimatedFee': fee,
                  'turnaroundDays': days,
                  'scopeOfWork': scopeCtrl.text,
                  'termsConditions': termsCtrl.text,
                });
                Navigator.pop(ctx);
                _loadLeads();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quotation generated successfully and client notified.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate quote: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Dispatch Quotation'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(Map<String, dynamic> lead) {
    String selectedStatus = lead['status'] ?? 'NEW';
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          title: Text('Update Lead Status — ${lead['referenceCode']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                  DropdownMenuItem(value: 'QUALIFIED', child: Text('QUALIFIED')),
                  DropdownMenuItem(value: 'QUOTED', child: Text('QUOTED')),
                  DropdownMenuItem(value: 'WON', child: Text('WON (Converted)')),
                  DropdownMenuItem(value: 'LOST', child: Text('LOST')),
                ],
                onChanged: (v) => ss(() => selectedStatus = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Action / Audit Note', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _api.dio.post('/api/leads/${lead['id']}/status', data: {
                    'status': selectedStatus,
                    'note': noteCtrl.text.trim(),
                  });
                  Navigator.pop(ctx);
                  _loadLeads();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                }
              },
              child: const Text('Save Status'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailsDialog(Map<String, dynamic> lead) {
    final docs = lead['documents'] as List<dynamic>? ?? [];
    final quotes = lead['quotations'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Text('Lead Dossier: ${lead['referenceCode']}'),
            const Spacer(),
            _intentBadge(lead['intentLevel'] ?? 'MEDIUM', lead['leadScore'] ?? 0),
          ],
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Contact Name:', '${lead['contactName']} (${lead['contactRole'] ?? "N/A"})'),
                _detailRow('Organization:', lead['companyName'] ?? 'Individual / Sole Proprietor'),
                _detailRow('Email:', lead['contactEmail'] ?? ''),
                _detailRow('Phone:', lead['contactPhone'] ?? ''),
                _detailRow('Service Vertical:', lead['serviceVertical'] ?? ''),
                _detailRow('Mandate Purpose:', lead['mandatePurpose'] ?? ''),
                _detailRow('Asset Name:', lead['assetName'] ?? ''),
                _detailRow('Location:', lead['assetLocation'] ?? 'N/A'),
                _detailRow('Value Scale:', lead['valueBracket'] ?? ''),
                _detailRow('Required SLA:', lead['urgencySla'] ?? ''),
                _detailRow('Preferred Channel:', lead['preferredChannel'] ?? 'EMAIL'),
                const Divider(height: 24),
                Text('Attached Documents (${docs.length}):', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (docs.isEmpty)
                  const Text('No documents uploaded during intake.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...docs.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.attachment_rounded, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d['fileName'] ?? 'Document', style: const TextStyle(fontSize: 12))),
                            Text('${((d['fileSizeBytes'] ?? 0) / 1024).toStringAsFixed(0)} KB', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      )),
                const Divider(height: 24),
                Text('Issued Quotations (${quotes.length}):', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                if (quotes.isEmpty)
                  const Text('No quotations generated yet.', style: TextStyle(color: Colors.grey, fontSize: 12))
                else
                  ...quotes.map((q) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'Quote ${q['quoteNumber']} — Total: Rs ${q['totalFee']} (${q['turnaroundDays']} days SLA)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showQuoteDialog(lead);
            },
            child: const Text('⚡ Issue Quote'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF475569)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)))),
        ],
      ),
    );
  }

  Widget _intentBadge(String intent, int score) {
    Color bg;
    Color fg;
    switch (intent.toUpperCase()) {
      case 'CRITICAL':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        break;
      case 'HIGH':
        bg = const Color(0xFFFFEDD5);
        fg = const Color(0xFFC2410C);
        break;
      case 'MEDIUM':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        '$intent ($score pts)',
        style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commercial Leads CRM', style: AppTypography.pageTitle(color: AppColors.ink)),
                  Text('Inbound Valuation Inquiries, AI Scoring & Quotation Desk', style: AppTypography.bodySm()),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _loadLeads,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Leads'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))),
                ],
              ),
            ),
          Row(
            children: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter ?? 'ALL',
                  decoration: const InputDecoration(labelText: 'Status', isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'NEW', child: Text('NEW')),
                    DropdownMenuItem(value: 'QUALIFIED', child: Text('QUALIFIED')),
                    DropdownMenuItem(value: 'QUOTED', child: Text('QUOTED')),
                    DropdownMenuItem(value: 'WON', child: Text('WON')),
                    DropdownMenuItem(value: 'LOST', child: Text('LOST')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v);
                    _loadLeads();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  value: _intentFilter ?? 'ALL',
                  decoration: const InputDecoration(labelText: 'Intent Level', isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Intents')),
                    DropdownMenuItem(value: 'CRITICAL', child: Text('CRITICAL')),
                    DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                    DropdownMenuItem(value: 'LOW', child: Text('LOW')),
                  ],
                  onChanged: (v) {
                    setState(() => _intentFilter = v);
                    _loadLeads();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Leads List Table
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _leads.isEmpty
                    ? Center(
                        child: Text(
                          'No valuation leads found. Inbound requests from service pages will appear here.',
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
                        ),
                      )
                    : Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Color(0xFFE2E8F0))),
                        child: ListView.separated(
                          itemCount: _leads.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final lead = _leads[idx] as Map<String, dynamic>;
                            final docs = lead['documents'] as List<dynamic>? ?? [];

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: _intentBadge(lead['intentLevel'] ?? 'MEDIUM', lead['leadScore'] ?? 0),
                              title: Row(
                                children: [
                                  Text(
                                    lead['referenceCode'] ?? '',
                                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${lead['contactName']} (${lead['companyName'] ?? "Individual"})',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                                    child: Text(
                                      lead['status'] ?? 'NEW',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '${lead['serviceVertical']} • ${lead['mandatePurpose']} • ${lead['valueBracket']} • SLA: ${lead['urgencySla']} • ${docs.length} Doc(s)',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 18),
                                    tooltip: 'View Details',
                                    onPressed: () => _showDetailsDialog(lead),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.request_quote_outlined, size: 18),
                                    tooltip: 'Issue Quote',
                                    onPressed: () => _showQuoteDialog(lead),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_outlined, size: 18),
                                    tooltip: 'Update Status',
                                    onPressed: () => _showStatusDialog(lead),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
