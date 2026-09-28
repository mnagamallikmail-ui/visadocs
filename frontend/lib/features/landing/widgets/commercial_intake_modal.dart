import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../landing_theme.dart';
import '../../../services/api_service.dart';

/// Universal 6-Step Commercial Valuation Intake Modal
/// Designed for CFOs, CAs, Insolvency Professionals, Corporate Borrowers & HNIs.
class CommercialIntakeModal extends StatefulWidget {
  final String? initialService;

  const CommercialIntakeModal({super.key, this.initialService});

  static Future<void> show(BuildContext context, {String? initialService}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => CommercialIntakeModal(initialService: initialService),
    );
  }

  @override
  State<CommercialIntakeModal> createState() => _CommercialIntakeModalState();
}

class _CommercialIntakeModalState extends State<CommercialIntakeModal> {
  int _currentStep = 1;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Step 1: Service
  late String _selectedService;

  // Step 2: Purpose
  String _selectedPurpose = '';

  // Step 3: Asset Details & SLA
  final _assetNameCtrl = TextEditingController();
  final _assetLocationCtrl = TextEditingController();
  String _selectedValueBracket = '₹5 Cr – ₹25 Cr';
  String _selectedUrgencySla = 'STANDARD_3D';

  // Step 4: Documents
  List<PlatformFile> _pickedFiles = [];

  // Step 5: Contact
  final _nameCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _preferredChannel = 'EMAIL';

  // Step 6: Confirmation Result
  String? _referenceCode;

  final Map<String, List<String>> _servicePurposes = {
    'SHARE_VALUATION': [
      'Rule 11UA / Angel Tax Defense',
      'Section 56(2)(viib) Equity Issuance',
      'Form PAS-3 MCA Filing',
      'FEMA / RBI Foreign Investment (FDI/ODI)',
      'ESOP Scheme Allotment',
      'M&A / Slump Sale Restructuring',
    ],
    'PROPERTY_VALUATION': [
      'Capital Gains Rebuttal (Section 50C)',
      'Baseline FMV as of 2001 (Section 55A)',
      'Deemed Gift Protection (Section 56(2)(x))',
      'Bank Mortgage & Credit Underwriting',
      'Family Partition / Dispute Resolution',
      'Stamp Duty Adjudication Appeal',
    ],
    'VISA_VALUATION': [
      'Student Visa (US F-1, UK Tier-4, Canada, AU)',
      'Permanent Residency / Express Entry',
      'Investor / Business Visa (EB-5, Subclass 188)',
      'Family Sponsorship & Visitor Solvency',
    ],
    'BANK_COLLATERAL': [
      'Commercial Term Loan Advance',
      'Loan Against Property (LAP)',
      'Working Capital Limit Renewal',
      'Consortium Exposure > ₹50 Crore',
      'SARFAESI Reserve Price Valuation',
    ],
    'NCLT_IBC': [
      'CIRP Corporate Debtor Appraisal (Reg 35)',
      'Liquidation Value Reserve Determination',
      'Section 66 Avoidance Action Recovery',
      'Pre-Packaged Insolvency Process (PPIRP)',
    ],
    'PLANT_AND_MACHINERY': [
      'Depreciated Replacement Cost (DRC) for Banks',
      'Customs Duty Exemption (EPCG Scheme)',
      'Insurance Reinstatement Value (RVC)',
      'Remaining Useful Life (RUL) Certification',
      'Ind AS 16 / Ind AS 36 Impairment Audit',
    ],
  };

  final Map<String, List<String>> _serviceRequiredDocs = {
    'SHARE_VALUATION': [
      'Audited Financial Statements (Last 3 Years)',
      'Projected P&L and Balance Sheet (3–5 Years)',
      'Current Shareholding / Cap Table',
    ],
    'PROPERTY_VALUATION': [
      'Registered Title Deed / Sale Deed Copy',
      'Encumbrance Certificate (13–30 Years)',
      'Approved Building Sanction / Layout Plan',
    ],
    'VISA_VALUATION': [
      'Title Deeds of Residential / Commercial Property',
      'Passport Copy of Visa Applicant',
      'Relationship Proof (if parent/sponsor)',
    ],
    'BANK_COLLATERAL': [
      'Primary Title Deed & Non-Encumbrance Report',
      'Sanctioned Municipal Building Plan',
      'Property Tax Receipts (Latest)',
    ],
    'NCLT_IBC': [
      'NCLT Admission Order (Form 1/2)',
      'Fixed Asset Register (FAR)',
      'Audited Balance Sheets (Latest)',
    ],
    'PLANT_AND_MACHINERY': [
      'Capital Equipment Invoices & Bills of Entry',
      'Fixed Asset Register with Acquisition Dates',
      'Technical Specification & Maintenance Logs',
    ],
  };

  @override
  void initState() {
    super.initState();
    _selectedService = widget.initialService ?? 'PROPERTY_VALUATION';
    final purposes = _servicePurposes[_selectedService];
    if (purposes != null && purposes.isNotEmpty) {
      _selectedPurpose = purposes.first;
    }
  }

  @override
  void dispose() {
    _assetNameCtrl.dispose();
    _assetLocationCtrl.dispose();
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onServiceSelected(String service) {
    setState(() {
      _selectedService = service;
      final purposes = _servicePurposes[service];
      _selectedPurpose = (purposes != null && purposes.isNotEmpty) ? purposes.first : '';
    });
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'xlsx', 'xls', 'zip', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null) {
        setState(() {
          _pickedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not select files: $e';
      });
    }
  }

  Future<void> _submitLead() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiService().dio;

      final payload = {
        'serviceVertical': _selectedService,
        'mandatePurpose': _selectedPurpose,
        'assetName': _assetNameCtrl.text.trim().isNotEmpty ? _assetNameCtrl.text.trim() : 'Asset Under Appraisal',
        'assetLocation': _assetLocationCtrl.text.trim(),
        'valueBracket': _selectedValueBracket,
        'urgencySla': _selectedUrgencySla,
        'contactName': _nameCtrl.text.trim(),
        'contactRole': _roleCtrl.text.trim(),
        'companyName': _companyCtrl.text.trim(),
        'contactEmail': _emailCtrl.text.trim(),
        'contactPhone': _phoneCtrl.text.trim(),
        'preferredChannel': _preferredChannel,
        'documentCount': _pickedFiles.length,
      };

      final res = await dio.post('/api/leads', data: payload);
      final leadId = res.data['id'];
      final refCode = res.data['referenceCode'] ?? 'REQ-2026-PENDING';

      // Upload files if attached
      if (_pickedFiles.isNotEmpty && leadId != null) {
        final formData = FormData();
        for (final file in _pickedFiles) {
          if (file.bytes != null) {
            formData.files.add(MapEntry(
              'files',
              MultipartFile.fromBytes(file.bytes!, filename: file.name),
            ));
          }
        }
        try {
          await dio.post('/api/leads/$leadId/upload', data: formData);
        } catch (uploadErr) {
          debugPrint('Document upload warning: $uploadErr');
        }
      }

      setState(() {
        _referenceCode = refCode;
        _currentStep = 6;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Submission failed. Please check details or consult via WhatsApp.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 650;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 28,
      ),
      child: Center(
        child: Container(
          width: 720,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildProgressBar(),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 18 : 28),
                  child: _buildCurrentStepContent(isMobile),
                ),
              ),
              if (_currentStep < 6) _buildFooterActions(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A), // Dark slate
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt_rounded, color: LandingTheme.primaryAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMERCIAL VALUATION INTAKE',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  'Statutory Quotation & Document Appraisal Desk',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepIndicator(1, 'Service'),
          _stepDivider(),
          _stepIndicator(2, 'Purpose'),
          _stepDivider(),
          _stepIndicator(3, 'Asset'),
          _stepDivider(),
          _stepIndicator(4, 'Documents'),
          _stepDivider(),
          _stepIndicator(5, 'Contact'),
          _stepDivider(),
          _stepIndicator(6, 'Complete'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String title) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? const Color(0xFF10B981)
                : (isActive ? LandingTheme.primaryAccent : const Color(0xFF334155)),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : Text(
                    '$step',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive ? const Color(0xFF0F172A) : Colors.white70,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _stepDivider() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: const Color(0xFF334155),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isMobile) {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF87171)),
        ),
        child: Text(
          _errorMessage!,
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFB91C1C)),
        ),
      );
    }

    switch (_currentStep) {
      case 1:
        return _step1ServiceSelection();
      case 2:
        return _step2PurposeSelection();
      case 3:
        return _step3AssetDetails();
      case 4:
        return _step4DocumentUpload();
      case 5:
        return _step5ContactDetails();
      case 6:
        return _step6Confirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _step1ServiceSelection() {
    final services = [
      {'key': 'SHARE_VALUATION', 'name': 'Share & Equity Valuation', 'sub': 'Rule 11UA · Sec 56(2)(viib) · DCF', 'icon': Icons.insights_rounded},
      {'key': 'PROPERTY_VALUATION', 'name': 'Real Estate & Land Valuation', 'sub': 'Sec 34AB · Income Tax · Capital Gains', 'icon': Icons.apartment_rounded},
      {'key': 'VISA_VALUATION', 'name': 'Visa & Net Worth Solvency', 'sub': 'Form O-1 · Embassies · Consular Net Worth', 'icon': Icons.public_rounded},
      {'key': 'BANK_COLLATERAL', 'name': 'Bank Collateral & Mortgage', 'sub': 'RBI Guidelines · FMV / RV / DSV', 'icon': Icons.account_balance_rounded},
      {'key': 'NCLT_IBC', 'name': 'NCLT & IBC Insolvency', 'sub': 'CIRP Reg 27/35 · Liquidation Value', 'icon': Icons.gavel_rounded},
      {'key': 'PLANT_AND_MACHINERY', 'name': 'Plant & Machinery Appraisals', 'sub': 'Depreciated Replacement Cost · MEA', 'icon': Icons.precision_manufacturing_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Select Valuation Practice Area',
          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose the specific statutory domain for your appraisal dossier.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        ...services.map((s) {
          final isSelected = _selectedService == s['key'];
          return InkWell(
            onTap: () => _onServiceSelected(s['key'] as String),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, color: isSelected ? const Color(0xFF059669) : const Color(0xFF64748B), size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'] as String,
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          s['sub'] as String,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _step2PurposeSelection() {
    final purposes = _servicePurposes[_selectedService] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2: Statutory Mandate & Purpose',
          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the legal or commercial objective requiring this valuation report.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        ...purposes.map((p) {
          final isSelected = _selectedPurpose == p;
          return InkWell(
            onTap: () => setState(() => _selectedPurpose = p),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF8FAFC) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: p,
                    groupValue: _selectedPurpose,
                    onChanged: (v) => setState(() => _selectedPurpose = v!),
                    activeColor: const Color(0xFF0F172A),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      p,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _step3AssetDetails() {
    final brackets = ['< ₹1 Crore', '₹1 Cr – ₹5 Cr', '₹5 Cr – ₹25 Cr', '₹25 Cr – ₹100 Cr', 'Above ₹100 Crore'];
    final slas = [
      {'key': 'EXPRESS_24H', 'label': '⚡ Express (24–48 Hours)', 'desc': 'Emergency tribunal or visa biometrics deadline'},
      {'key': 'STANDARD_3D', 'label': '⏱ Standard (3–5 Business Days)', 'desc': 'Standard banking or corporate audit timeline'},
      {'key': 'COMPREHENSIVE_7D', 'label': '📅 Comprehensive (7–10 Days)', 'desc': 'Complex multi-unit industrial or consortium review'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Asset Scale & Turnaround SLA',
          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Provide high-level parameters to determine valuer empanelment category.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _assetNameCtrl,
          decoration: InputDecoration(
            labelText: 'Asset Name / Company Name / Facility *',
            hintText: 'e.g. Commercial Office Suite, Tech Private Limited, Manufacturing Yard',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _assetLocationCtrl,
          decoration: InputDecoration(
            labelText: 'Location / City / Destination Country',
            hintText: 'e.g. Kokapet, Hyderabad / USA Embassy',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Estimated Asset Value Bracket:',
          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: brackets.map((b) {
            final isSel = _selectedValueBracket == b;
            return ChoiceChip(
              label: Text(b),
              selected: isSel,
              selectedColor: const Color(0xFF0F172A),
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : const Color(0xFF334155),
              ),
              onSelected: (val) => setState(() => _selectedValueBracket = b),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Required Turnaround Urgency:',
          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        ...slas.map((s) {
          final isSel = _selectedUrgencySla == s['key'];
          return InkWell(
            onTap: () => setState(() => _selectedUrgencySla = s['key']!),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFF8FAFC) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSel ? const Color(0xFF10B981) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: s['key']!,
                    groupValue: _selectedUrgencySla,
                    onChanged: (v) => setState(() => _selectedUrgencySla = v!),
                    activeColor: const Color(0xFF10B981),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['label']!, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        Text(s['desc']!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _step4DocumentUpload() {
    final reqDocs = _serviceRequiredDocs[_selectedService] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 4: Statutory Document Upload',
          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Upload relevant deeds, financials, or orders to expedite technical review.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statutory Checklist for this Service:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF334155))),
              const SizedBox(height: 6),
              ...reqDocs.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(d, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF475569)))),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _pickFiles,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, size: 36, color: Color(0xFF475569)),
                const SizedBox(height: 10),
                Text('Click to Browse or Attach Documents', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                Text('PDF, DOCX, XLSX, ZIP, JPG (Max 50MB)', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        if (_pickedFiles.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('${_pickedFiles.length} File(s) Selected:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 6),
          ..._pickedFiles.map((f) => Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 16, color: Color(0xFF0F172A)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.name, style: GoogleFonts.inter(fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Text('${(f.size / 1024).toStringAsFixed(0)} KB', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => setState(() => _pickedFiles.remove(f)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _step5ContactDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 5: Professional Contact Details',
          style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Text(
          'Our Senior Valuation Partner will respond within the selected SLA.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _roleCtrl,
                decoration: InputDecoration(
                  labelText: 'Designation / Role',
                  hintText: 'e.g. CFO, Advocate, RP, Owner',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _companyCtrl,
                decoration: InputDecoration(
                  labelText: 'Company / Organization',
                  hintText: 'e.g. ABC Tech Ltd',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailCtrl,
          decoration: InputDecoration(
            labelText: 'Corporate / Official Email *',
            hintText: 'name@company.com or personal email',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phoneCtrl,
          decoration: InputDecoration(
            labelText: 'Mobile Phone *',
            hintText: '+91 98765 43210',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Preferred Response Channel:',
          style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          children: [
            _channelRadio('EMAIL', 'Official Email'),
            _channelRadio('PHONE', 'Phone Call'),
            _channelRadio('WHATSAPP', 'WhatsApp Desk'),
          ],
        ),
      ],
    );
  }

  Widget _channelRadio(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: key,
          groupValue: _preferredChannel,
          onChanged: (v) => setState(() => _preferredChannel = v!),
          activeColor: const Color(0xFF0F172A),
        ),
        Text(label, style: GoogleFonts.inter(fontSize: 12.5)),
      ],
    );
  }

  Widget _step6Confirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Valuation Mandate Received',
          style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 8),
        Text(
          'Reference Code: ${_referenceCode ?? "REQ-2026-XXXX"}',
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF059669),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What happens next:', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
              const SizedBox(height: 8),
              _nextStepItem('1', 'Automated acknowledgment sent to ${_emailCtrl.text}'),
              _nextStepItem('2', 'Senior Valuer assigned to review uploaded documents'),
              _nextStepItem('3', 'Formal proforma quotation dispatched within ${_selectedUrgencySla == "EXPRESS_24H" ? "2 hours" : "4 hours"}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close Desk'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final url = Uri.parse('https://wa.me/918500019091?text=${Uri.encodeComponent("Hello, I submitted mandate ${_referenceCode}. Requesting immediate confirmation.")}');
                if (await canLaunchUrl(url)) await launchUrl(url);
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF10B981)),
              label: const Text('Direct WhatsApp Chat', style: TextStyle(color: Color(0xFF10B981))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _nextStepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
            child: Center(child: Text(num, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF475569)))),
        ],
      ),
    );
  }

  Widget _buildFooterActions(bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 1)
            OutlinedButton(
              onPressed: _isSubmitting ? null : () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_currentStep == 5) {
                      if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
                        setState(() => _errorMessage = 'Please provide Name, Email, and Phone.');
                        return;
                      }
                      _submitLead();
                    } else {
                      setState(() {
                        _errorMessage = null;
                        _currentStep++;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_currentStep == 5 ? '⚡ Submit Mandate' : 'Continue →'),
          ),
        ],
      ),
    );
  }
}
