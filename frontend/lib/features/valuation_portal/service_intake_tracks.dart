import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/web_file_picker.dart';
import '../../theme/design_system.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Shared tile helpers ──────────────────────────────────────

BoxDecoration _tileDecor(bool sel) => BoxDecoration(
  color: sel ? AppColors.sidebarSelected : Colors.white,
  border: Border.all(
    color: sel ? AppColors.brandBlue : DesignSystem.border,
    width: sel ? 1.5 : 1.0,
  ),
  borderRadius: BorderRadius.circular(12),
  boxShadow: sel ? [
    BoxShadow(
      color: AppColors.brandBlue.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    )
  ] : [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    )
  ],
);

TextStyle _tileLabelStyle(bool sel) => DesignSystem.body(
  color: sel ? AppColors.brandBlue : DesignSystem.textPrimary,
  fontSize: 11,
  fontWeight: sel ? FontWeight.bold : FontWeight.w600,
);

// ─── Networth Certificate Track ───────────────────────────────

class NetworthTrackWidget extends StatefulWidget {
  final String clientName;
  final VoidCallback onSubmitted;
  final VoidCallback onBack;

  const NetworthTrackWidget({
    super.key,
    required this.clientName,
    required this.onSubmitted,
    required this.onBack,
  });

  @override
  State<NetworthTrackWidget> createState() => _NetworthTrackWidgetState();
}

class _NetworthTrackWidgetState extends State<NetworthTrackWidget> {
  String? _purpose;
  final Map<String, String> _docs = {};

  static const List<String> _purposes = [
    'Bank Loans & Credit Assessment',
    'Visa & Immigration',
    'Business & Government Work',
    'Regulatory / Legal Compliance',
    'High-Value Transactions',
  ];

  static const Map<String, String> _docGroups = {
    'A. Basic KYC Documents': 'PAN Card, ID Proof (Aadhaar/Passport/Voter ID), Address Proof',
    'B. Income & Financial Records': 'ITR (last 1–3 years), Income statement / salary details',
    'C. Bank & Investment Proofs': 'Bank statements (6–12 months), FD receipts, DEMAT, PF/PPF, Insurance proofs',
    'D. Asset Documents': 'Property docs, Vehicle RC, Gold/jewellery bills, Business ownership details',
    'E. Liability Documents': 'Loan statements, Credit card dues, Outstanding liabilities',
  };

  Future<void> _pick(String cat) async {
    try {
      final r = await WebFilePicker.pickFile();
      if (r != null) {
        setState(() => _docs[cat] = r.name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.95),
          decoration: DesignSystem.cardDecoration,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: DesignSystem.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 12, color: DesignSystem.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'NETWORTH CERTIFICATE INTAKE',
                        style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.bold).copyWith(letterSpacing: 0.5),
                      ),
                    ]),
                    TextButton.icon(
                      onPressed: () => setState(() { _purpose = null; _docs.clear(); }),
                      icon: const Icon(Icons.refresh, size: 14, color: DesignSystem.error),
                      label: Text('Reset', style: DesignSystem.body(color: DesignSystem.error, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Step 1: Purpose
                Text('1. SELECT PURPOSE FOR NETWORTH CERTIFICATE',
                  style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: _purposes.length,
                  itemBuilder: (c, i) {
                    final opt = _purposes[i];
                    final sel = _purpose == opt;
                    return InkWell(
                      onTap: () => setState(() => _purpose = opt),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        decoration: _tileDecor(sel),
                        child: Text(opt, textAlign: TextAlign.center, style: _tileLabelStyle(sel)),
                      ),
                    );
                  },
                ),

                // Step 2: Document Vault (progressive reveal)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _purpose == null
                      ? const SizedBox.shrink()
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _purpose != null ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('2. REQUIRED COMPLIANCE DOCUMENTATION',
                                  style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ..._docGroups.entries.map((e) => _buildDocRow(e.key, e.value)),
                                const SizedBox(height: 28),
                                const Divider(height: 24),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _docs.length == _docGroups.length ? widget.onSubmitted : null,
                                    style: DesignSystem.primaryButton,
                                    child: Text('SUBMIT NETWORTH CERTIFICATE REQUEST',
                                      style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDocRow(String cat, String hint) {
    final uploaded = _docs.containsKey(cat);
    final name = _docs[cat] ?? '';
    final display = name.length > 22 ? '${name.substring(0, 12)}...${name.substring(name.length - 8)}' : name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignSystem.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: uploaded ? DesignSystem.successBg : DesignSystem.structural,
            shape: BoxShape.circle,
          ),
          child: Icon(
            uploaded ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
            color: uploaded ? DesignSystem.success : DesignSystem.textSecondary,
            size: 16,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat, style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                uploaded ? display : hint,
                style: DesignSystem.body(
                  color: uploaded ? DesignSystem.success : DesignSystem.textSecondary,
                  fontSize: 10,
                  fontWeight: uploaded ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: uploaded ? () => setState(() => _docs.remove(cat)) : () => _pick(cat),
          style: (uploaded ? DesignSystem.outlinedButton : DesignSystem.primaryButton).copyWith(
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          ),
          child: Text(
            uploaded ? 'Remove' : 'Upload File',
            style: DesignSystem.body(
              color: uploaded ? DesignSystem.error : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Chartered Engineer Certificate Track ─────────────────────

class CharteredTrackWidget extends StatefulWidget {
  final String clientName;
  final VoidCallback onSubmitted;
  final VoidCallback onBack;

  const CharteredTrackWidget({
    super.key,
    required this.clientName,
    required this.onSubmitted,
    required this.onBack,
  });

  @override
  State<CharteredTrackWidget> createState() => _CharteredTrackWidgetState();
}

class _CharteredTrackWidgetState extends State<CharteredTrackWidget> {
  String? _purpose;
  final Map<String, String> _docs = {};

  static const List<String> _purposes = [
    'Import of Used Machinery',
    'DGFT / EPCG / Export-Import Compliance',
    'Installation & Project Certification',
    'Valuation & Financial Purposes',
    'Tender & Government Projects',
    'Legal & Compliance Cases',
  ];

  static const Map<String, String> _docGroups = {
    'A. Basic Documents': 'ID proof of individual/company, Business details',
    'B. Machinery / Asset Details': 'Machine specs, Serial number/make/model, Technical data sheets',
    'C. Purchase & Financial Documents': 'Invoice/purchase bill, Proforma invoice, Original purchase value',
    'D. Import / Export Documents': 'Packing list, Bill of lading, Import/export documents',
    'E. Supporting Proofs': 'Photographs of machinery, Maintenance records, Refurbishment details',
  };

  Future<void> _pick(String cat) async {
    try {
      final r = await WebFilePicker.pickFile();
      if (r != null) {
        setState(() => _docs[cat] = r.name);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Container(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.95),
          decoration: DesignSystem.cardDecoration,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(color: DesignSystem.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, size: 12, color: DesignSystem.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CHARTERED ENGINEER CERTIFICATE INTAKE',
                        style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 13, fontWeight: FontWeight.bold).copyWith(letterSpacing: 0.5),
                      ),
                    ]),
                    TextButton.icon(
                      onPressed: () => setState(() { _purpose = null; _docs.clear(); }),
                      icon: const Icon(Icons.refresh, size: 14, color: DesignSystem.error),
                      label: Text('Reset', style: DesignSystem.body(color: DesignSystem.error, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Step 1: Purpose
                Text('1. SELECT PURPOSE FOR CHARTERED ENGINEER CERTIFICATION',
                  style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: _purposes.length,
                  itemBuilder: (c, i) {
                    final opt = _purposes[i];
                    final sel = _purpose == opt;
                    return InkWell(
                      onTap: () => setState(() => _purpose = opt),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        decoration: _tileDecor(sel),
                        child: Text(opt, textAlign: TextAlign.center, style: _tileLabelStyle(sel)),
                      ),
                    );
                  },
                ),

                // Step 2: Document Vault (progressive reveal)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _purpose == null
                      ? const SizedBox.shrink()
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _purpose != null ? 1.0 : 0.0,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('2. REQUIRED COMPLIANCE DOCUMENTATION',
                                  style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 10.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ..._docGroups.entries.map((e) => _buildDocRow(e.key, e.value)),
                                const SizedBox(height: 28),
                                const Divider(height: 24),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed: _docs.length == _docGroups.length ? widget.onSubmitted : null,
                                    style: DesignSystem.primaryButton,
                                    child: Text('SUBMIT CHARTERED ENGINEER REQUEST',
                                      style: DesignSystem.body(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDocRow(String cat, String hint) {
    final uploaded = _docs.containsKey(cat);
    final name = _docs[cat] ?? '';
    final display = name.length > 22 ? '${name.substring(0, 12)}...${name.substring(name.length - 8)}' : name;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: DesignSystem.border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          )
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: uploaded ? DesignSystem.successBg : DesignSystem.structural,
            shape: BoxShape.circle,
          ),
          child: Icon(
            uploaded ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
            color: uploaded ? DesignSystem.success : DesignSystem.textSecondary,
            size: 16,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat, style: DesignSystem.body(color: DesignSystem.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                uploaded ? display : hint,
                style: DesignSystem.body(
                  color: uploaded ? DesignSystem.success : DesignSystem.textSecondary,
                  fontSize: 10,
                  fontWeight: uploaded ? FontWeight.bold : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: uploaded ? () => setState(() => _docs.remove(cat)) : () => _pick(cat),
          style: (uploaded ? DesignSystem.outlinedButton : DesignSystem.primaryButton).copyWith(
            padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
          ),
          child: Text(
            uploaded ? 'Remove' : 'Upload File',
            style: DesignSystem.body(
              color: uploaded ? DesignSystem.error : Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
    );
  }
}
