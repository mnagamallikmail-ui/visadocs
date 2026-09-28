import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';
import '../../features/landing/widgets/commercial_intake_modal.dart';

/// Plant and Machinery Valuation in India — Commercial Practice Hub
class PlantMachineryValuationScreen extends StatefulWidget {
  const PlantMachineryValuationScreen({super.key});

  @override
  State<PlantMachineryValuationScreen> createState() => _PlantMachineryValuationScreenState();
}

class _PlantMachineryValuationScreenState extends State<PlantMachineryValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  final Set<int> _expandedFaqIndices = {0};

  static const String _primaryPhone = '+918500019091';
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _lightBg = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(String message) async {
    final url = Uri.parse('https://wa.me/918500019091?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makePhoneCall() async {
    final url = Uri.parse('tel:$_primaryPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _openQuoteModal() {
    CommercialIntakeModal.show(context, initialService: 'PLANT_AND_MACHINERY');
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1100;
    final bool isTablet = screenW >= 700 && screenW < 1100;

    return Scaffold(
      backgroundColor: _pureWhite,
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100),
                _buildHeroSection(screenW, isDesktop),
                _buildStatutoryFrameworkSection(screenW, isDesktop),
                _buildObsolescenceFrameworkSection(screenW, isDesktop, isTablet),
                _buildAssetCoverageSection(screenW, isDesktop, isTablet),
                _buildMethodologySection(screenW, isDesktop),
                _buildDocumentChecklistSection(screenW, isDesktop),
                _buildFaqSection(screenW, isDesktop),
                _buildFinalConversionBlock(screenW, isDesktop),
                _buildInstitutionalFooter(screenW, isDesktop),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildServiceFloatingHeader(isDesktop),
          ),
          Positioned(
            bottom: 30,
            right: 30,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _launchWhatsApp(
                  'Hello ProValuer Commercial, I require a certified Plant & Machinery valuation report from an IBBI Registered Valuer / Chartered Engineer.',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'WhatsApp Valuer',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. HERO SECTION WITH 3-TIER CTA
  Widget _buildHeroSection(double screenW, bool isDesktop) {
    return Container(
      color: const Color(0xFF090D16),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 80 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: LandingTheme.primaryAccent),
                    const SizedBox(width: 8),
                    Text(
                      'CHARTERED ENGINEERS (IEI) • IBBI REGISTERED VALUERS (P&M) • IVS 300',
                      style: GoogleFonts.montserrat(
                        fontSize: isDesktop ? 10.5 : 9.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Plant & Machinery Valuation in India',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 44 : 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.0,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Text(
                  'Defense-grade engineering appraisals, Depreciated Replacement Cost (DRC) modeling, and Remaining Useful Life (RUL) certifications under Section 247 of Companies Act, IBC CIRP Regulation 35, and RBI Bank Panel Standards.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : 14,
                    color: const Color(0xFFCBD5E1),
                    height: 1.65,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // ── 3-TIER CTA HIERARCHY ──────────────────────────────────────────
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openQuoteModal,
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: Text(
                      '⚡ Request Valuation Quote',
                      style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingTheme.primaryAccent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 4,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone_in_talk, size: 18),
                    label: Text(
                      '📞 Speak With A Senior Valuer',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launchWhatsApp('Hello, I require a Plant & Machinery valuation quote.'),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 17, color: Color(0xFF25D366)),
                    label: Text(
                      '💬 WhatsApp Desk',
                      style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF25D366)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. STATUTORY FRAMEWORK SECTION
  Widget _buildStatutoryFrameworkSection(double screenW, bool isDesktop) {
    final mandates = [
      {
        'title': 'Section 247, Companies Act 2013',
        'sub': 'Ministry of Corporate Affairs (MCA)',
        'desc': 'Mandatory IBBI Registered Valuer (P&M) jurisdiction for slump sales, asset disposals, merger swap ratios, and corporate balance sheet audits.',
      },
      {
        'title': 'Regulations 27 & 35, IBBI CIRP 2016',
        'sub': 'Insolvency & Bankruptcy Code',
        'desc': 'Statutory computation of Fair Value and Liquidation Value for Resolution Professionals, Liquidators, and Committee of Creditors before NCLT Benches.',
      },
      {
        'title': 'Section 64UM, Insurance Act 1938',
        'sub': 'Insurance Reinstatement Value (RVC)',
        'desc': 'Reinstatement Value Clause asset modeling to prevent condition-of-average penalties during catastrophic industrial loss claims.',
      },
      {
        'title': 'Ind AS 16 & Ind AS 36 Compliance',
        'sub': 'Property, Plant & Equipment (PPE)',
        'desc': 'Defensible revaluation modeling and annual cash-generating unit (CGU) impairment testing for statutory financial reporting.',
      },
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'STATUTORY MANDATES & REGULATORY JURISDICTION',
                style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'Where Plant & Machinery Appraisals Are Legally Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: isDesktop ? 30 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(builder: (context, constraints) {
                final int cols = isDesktop ? 2 : 1;
                final double w = (constraints.maxWidth - (cols - 1) * 20) / cols;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: mandates.map((m) => Container(
                    width: w,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['title']!, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(m['sub']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: LandingTheme.brandGreen)),
                        const SizedBox(height: 10),
                        Text(m['desc']!, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.55)),
                      ],
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 3. THE 4 FORMS OF OBSOLESCENCE PANEL
  Widget _buildObsolescenceFrameworkSection(double screenW, bool isDesktop, bool isTablet) {
    final obs = [
      {'title': '1. Physical Deterioration', 'sub': 'Curable & Incurable Wear', 'desc': 'Thermodynamic fatigue, corrosion, metallurgy wear, mechanical vibration degradation, and running hours analysis.'},
      {'title': '2. Functional Obsolescence', 'sub': 'Excess Operating Cost', 'desc': 'Design deficiencies, excessive energy consumption, higher labor requirements compared to Modern Equivalent Assets (MEA).'},
      {'title': '3. Technological Obsolescence', 'sub': 'Automation & Cycle Times', 'desc': 'Superior CNC precision, higher throughput metallurgy, PLC automation advances rendering legacy equipment uncompetitive.'},
      {'title': '4. Economic / External Obsolescence', 'sub': 'Market & Regulatory Shifts', 'desc': 'Emission bans, raw material shortages, industry overcapacity, tariff changes eroding asset earning potential.'},
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TECHNICAL ENGINEERING RIGOR',
                style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Text(
                'The 4 Forms of Obsolescence Quantification',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: isDesktop ? 30 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Text(
                  'Unlike generic accounting depreciation, our Chartered Engineers apply forensic mechanical engineering protocols to decouple real-world value degradation.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B), height: 1.55),
                ),
              ),
              const SizedBox(height: 40),
              LayoutBuilder(builder: (context, constraints) {
                final int cols = isDesktop ? 4 : (isTablet ? 2 : 1);
                final double w = (constraints.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: obs.map((o) => Container(
                    width: w,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o['title']!, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text(o['sub']!, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: LandingTheme.primaryAccent)),
                        const SizedBox(height: 10),
                        Text(o['desc']!, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF475569), height: 1.5)),
                      ],
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 4. ASSET COVERAGE SECTION
  Widget _buildAssetCoverageSection(double screenW, bool isDesktop, bool isTablet) {
    final assets = [
      'Chemical & Pharmaceutical Continuous Process Lines',
      'CNC Machining Centers, Tooling & Heavy Press Yards',
      'Thermal, Gas, and Renewable Solar / Wind Utilities',
      'Industrial Boilers, Turbines & Pressure Vessels',
      'Automated Warehousing, Conveyors & Cranes',
      'Heavy Earthmoving & Construction Fleets',
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('MULTI-SECTOR INDUSTRIAL REACH', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text('Industrial Assets Valued Across India', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: isDesktop ? 30 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 36),
              LayoutBuilder(builder: (context, constraints) {
                final int cols = isDesktop ? 3 : (isTablet ? 2 : 1);
                final double w = (constraints.maxWidth - (cols - 1) * 16) / cols;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: assets.map((a) => Container(
                    width: w,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 12),
                        Expanded(child: Text(a, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))),
                      ],
                    ),
                  )).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 5. METHODOLOGY
  Widget _buildMethodologySection(double screenW, bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('INTERNATIONAL VALUATION STANDARDS', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text('Depreciated Replacement Cost (DRC) Formula', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: isDesktop ? 28 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'DRC = Replacement Cost New (RCN) - Physical Deterioration - Functional Obsolescence - Economic Obsolescence',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(fontSize: isDesktop ? 13.5 : 11.5, fontWeight: FontWeight.w700, color: LandingTheme.primaryAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. DOCUMENT CHECKLIST
  Widget _buildDocumentChecklistSection(double screenW, bool isDesktop) {
    final docs = [
      'Fixed Asset Register (FAR) with original capitalized cost and purchase dates',
      'Original purchase invoices, custom clearance documents, and Bill of Entry (BOE)',
      'Technical specification manuals, P&IDs, and single-line diagrams (SLD)',
      'Operational logbooks, maintenance overhauls, and running hour meters',
      'OEM replacement quotations for equivalent modern technology',
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('FAST-TRACK TECHNICAL REVIEW', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text('Documents Required for Machinery Valuation', textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: isDesktop ? 28 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 30),
              ...docs.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: Color(0xFF0F172A), size: 18),
                    const SizedBox(width: 12),
                    Expanded(child: Text(d, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF334155)))),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  // 7. FAQS
  Widget _buildFaqSection(double screenW, bool isDesktop) {
    final faqs = [
      {
        'q': 'Who is legally authorized to value Plant and Machinery for banks and NCLT in India?',
        'a': 'Under Section 247 of the Companies Act, 2013 and CIRP Regulation 35, only an IBBI Registered Valuer in the Plant and Machinery asset class holds statutory authority. In addition, physical technical audits and remaining life certifications are conducted by Chartered Engineers empanelled with the Institution of Engineers (India).'
      },
      {
        'q': 'What is the difference between Fair Value and Liquidation Value for industrial equipment?',
        'a': 'Fair Value reflects the estimated price received in an orderly transaction between market participants at the measurement date. Liquidation Value estimates the net gross realizable amount assuming forced disposal within a limited marketing window under distress conditions.'
      },
      {
        'q': 'What is the turnaround time for an industrial site inspection and report?',
        'a': 'For standalone manufacturing units, preliminary reports are delivered within 3 to 5 business days following physical site inspection. For emergency tribunal deadlines or express banking needs, a 48-hour fast-track SLA is available.'
      },
    ];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Text('INSTITUTIONAL FAQS', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: LandingTheme.primaryAccent, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Text('Frequently Asked Technical Questions', style: GoogleFonts.montserrat(fontSize: isDesktop ? 28 : 22, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
              const SizedBox(height: 30),
              ...List.generate(faqs.length, (idx) {
                final isExpanded = _expandedFaqIndices.contains(idx);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: _lightBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                  child: ExpansionTile(
                    title: Text(faqs[idx]['q']!, style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (val) {
                      setState(() {
                        if (val) {
                          _expandedFaqIndices.add(idx);
                        } else {
                          _expandedFaqIndices.remove(idx);
                        }
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(faqs[idx]['a']!, style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF475569), height: 1.6)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // 8. FINAL CONVERSION BLOCK WITH 3-TIER CTA
  Widget _buildFinalConversionBlock(double screenW, bool isDesktop) {
    return Container(
      color: const Color(0xFF090D16),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                child: Text('COMMERCIAL INTAKE DESK', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: LandingTheme.brandGreen, letterSpacing: 1)),
              ),
              const SizedBox(height: 18),
              Text(
                'Commission Your Plant & Machinery Valuation Today',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: isDesktop ? 32 : 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 14),
              Text(
                'Official, court-admissible reports by Chartered Engineers and IBBI Registered Valuers. Guaranteed delivery with strict NDA compliance.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFCBD5E1), height: 1.65),
              ),
              const SizedBox(height: 32),

              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _openQuoteModal,
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: Text('⚡ Request Valuation Quote', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingTheme.primaryAccent,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone_in_talk, size: 18),
                    label: Text('📞 Speak With A Senior Valuer', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launchWhatsApp('Hello, I require a Plant & Machinery valuation quote.'),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 17, color: Color(0xFF25D366)),
                    label: Text('💬 WhatsApp Desk', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF25D366))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 9. INSTITUTIONAL FOOTER
  Widget _buildInstitutionalFooter(double screenW, bool isDesktop) {
    return Container(
      color: const Color(0xFF04060A),
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 24, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2026 ProValuer Commercial. All statutory rights reserved.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
              InkWell(
                onTap: () => context.go('/'),
                child: Text(
                  'Back to Home',
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // FLOATING HEADER
  Widget _buildServiceFloatingHeader(bool isDesktop) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.go('/'),
            child: Text(
              'PROVALUER COMMERCIAL',
              style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
            ),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _openQuoteModal,
                icon: const Icon(Icons.bolt_rounded, size: 16),
                label: const Text('⚡ Request Quote'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LandingTheme.primaryAccent,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
