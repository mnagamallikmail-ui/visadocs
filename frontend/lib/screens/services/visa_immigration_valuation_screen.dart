import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';

/// Professional Service Page: Certified Property Valuation for Visa & Immigration
/// Canonical URL: https://www.provaluer.in/services/visa-and-immigration-valuations
/// Word Count Target: 4,850 - 5,450 words of dense, institutional, consular-grade prose.
class VisaImmigrationValuationScreen extends StatefulWidget {
  const VisaImmigrationValuationScreen({super.key});

  @override
  State<VisaImmigrationValuationScreen> createState() => _VisaImmigrationValuationScreenState();
}

class _VisaImmigrationValuationScreenState extends State<VisaImmigrationValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedCountryIndex = 0;
  final Set<int> _expandedFaqIndices = {0, 1};

  static const String _primaryPhone = '+918500019091';
  static const String _primaryPhoneFormatted = '+91 85000 19091';
  static const String _waUrl = 'https://wa.me/918500880333';

  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _obsidian = Color(0xFF0F172A);
  static const Color _slateText = Color(0xFF475569);
  static const Color _borderSubtle = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp(String message) async {
    final url = Uri.parse('$_waUrl?text=${Uri.encodeComponent(message)}');
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

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1100;

    return Scaffold(
      backgroundColor: _pureWhite,
      body: Stack(
        children: [
          // ── Main Scrollable Body ──────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100), // Clearance for floating header

                // 1. Hero Section
                _buildHeroSection(screenW, isDesktop),

                // 2. Statutory Consular Framework & Accreditation
                _buildStatutoryFrameworkSection(screenW, isDesktop),

                // 3. Country-Specific Embassy Requirements (Interactive Matrix)
                _buildCountryRequirementsSection(screenW, isDesktop),

                // 4. Property Valuation Report vs Net Worth vs CA Certificate (Master Comparative Table)
                _buildComparativeTableSection(screenW, isDesktop),

                // 5. Documents Required for Visa Property Valuation
                _buildDocumentationSection(screenW, isDesktop),

                // 6. Anatomy of an Embassy-Compliant Valuation Report
                _buildReportAnatomySection(screenW, isDesktop),

                // 7. Common Rejection Reasons by Consular Officers
                _buildRejectionReasonsSection(screenW, isDesktop),

                // 8. Regional Practice: Hyderabad, Telangana & South India
                _buildRegionalPracticeSection(screenW, isDesktop),

                // 9. The ProValuer 4-Stage Forensic Visa Protocol
                _buildProtocolSection(screenW, isDesktop),

                // 10. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 11. High-Touch Executive Conversion Block
                _buildConversionSection(screenW, isDesktop),

                // 12. Institutional Footer & Cross-Navigation
                _buildInstitutionalFooter(screenW, isDesktop),
              ],
            ),
          ),

          // ── Fixed Floating Glass Navbar (No Login Barrier) ─────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildServiceFloatingHeader(isDesktop),
          ),

          // ── Persistent WhatsApp Floating Pill ───────────────────────────────
          Positioned(
            bottom: 30,
            right: 30,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _launchWhatsApp(
                  'Hello ProValuer Commercial, I require a certified property valuation report for my visa application.',
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
                        'Visa Valuation Desk',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // FLOATING GLASS NAVBAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildServiceFloatingHeader(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 20,
        vertical: _isScrolled ? 12 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: _isScrolled ? const Color(0x0F0F172A) : const Color(0x080F172A),
                  blurRadius: _isScrolled ? 30 : 20,
                  offset: Offset(0, _isScrolled ? 10 : 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: _isScrolled ? const Color(0xEBFFFFFF) : const Color(0xC7FFFFFF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: const Color(0xF2FFFFFF), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      // Brand Logo & Link to Home
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: LandingTheme.brandGreen,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: Text(
                                  'PV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ProValuer',
                              style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _obsidian,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Practice Navigation Links (Desktop)
                      if (isDesktop) ...[
                        _buildNavAction('All Services', () => context.go('/')),
                        const SizedBox(width: 20),
                        _buildNavAction('Government Approved Valuers', () => context.go('/government-approved-valuers')),
                        const SizedBox(width: 20),
                        _buildNavAction('Bank Collateral', () => context.go('/services/bank-collateral-valuation')),
                        const SizedBox(width: 24),
                      ],

                      // Direct Phone Call
                      GestureDetector(
                        onTap: _makePhoneCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _lightBg,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: _borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_in_talk, size: 14, color: LandingTheme.brandGreen),
                              const SizedBox(width: 8),
                              Text(
                                _primaryPhoneFormatted,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _obsidian,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Direct WhatsApp CTA
                      ElevatedButton(
                        onPressed: () => _launchWhatsApp(
                          'Hello ProValuer Commercial, I need an official property valuation report for my visa financial solvency dossier.',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LandingTheme.brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Consult Valuer',
                          style: GoogleFonts.montserrat(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavAction(String title, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _slateText,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. HERO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeroSection(double screenW, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 48 : 32,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: LandingTheme.brandGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EMBASSY COMPLIANT · WEALTH TAX ACT SEC 34AB · IBBI REGISTERED VALUERS',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LandingTheme.brandGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // H1
              Text(
                'Certified Property Valuation Reports for Visa & Global Immigration',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 44 : 30,
                  fontWeight: FontWeight.w900,
                  color: _obsidian,
                  height: 1.15,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 18),

              // Lead Narrative
              Text(
                'Consular-grade property appraisals and financial solvency statements for foreign embassies, high commissions, and immigration authorities. ProValuer delivers court-admissible, dual-currency valuation reports compliant with USCIS (US F-1, B-1/B-2, EB-5), IRCC Canada (Study Permit, Express Entry, PNP), UKVI (Student & Skilled Worker), Australian Department of Home Affairs (Subclass 500, 189/190), and European Schengen visa mandates. Executed by Government Approved Valuers under Section 34AB of the Wealth Tax Act, 1957, guaranteed 100% acceptance, zero consular queries, and real-time QR-code verification.',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16.5 : 14.5,
                  color: _slateText,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 28),

              // Trust Badges Pill Grid
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildTrustBadge('24–48 Hr Turnaround', 'Emergency Express Available'),
                  _buildTrustBadge('Dual Currency Formats', 'INR + USD / CAD / GBP / AUD / EUR'),
                  _buildTrustBadge('Anti-Fraud QR Code', 'Instant Online Consular Verification'),
                  _buildTrustBadge('Apostille & MEA Compatible', 'Meets Hague Convention Standards'),
                ],
              ),
              const SizedBox(height: 36),

              // 4 Hero KPI Cards
              _buildHeroKpiGrid(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _slateText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroKpiGrid(bool isDesktop) {
    final kpis = [
      {'val': '15,000+', 'label': 'Visa Reports Issued', 'sub': 'Student, PR & Investor Filings'},
      {'val': '50+ Nations', 'label': 'Global Acceptance', 'sub': 'US, Canada, UK, Australia, EU'},
      {'val': '24–48 Hrs', 'label': 'Standard Delivery', 'sub': 'Physical Hardcopy + Digital PDF'},
      {'val': '100% Audit-Proof', 'label': 'Consular Track Record', 'sub': 'Zero Methodological Rejections'},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = isDesktop ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kpis.map((kpi) {
            return Container(
              width: cardW,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpi['val']!,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: LandingTheme.brandGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kpi['label']!,
                    style: GoogleFonts.montserrat(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _obsidian,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kpi['sub']!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _slateText,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. STATUTORY CONSULAR FRAMEWORK & ACCREDITATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatutoryFrameworkSection(double screenW, bool isDesktop) {
    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'STATUTORY REGISTRATION & EMBASSY ADMISSIBILITY',
                'Why Consulates Mandate Government Approved Valuation Reports',
                'Legal Grounding Under Section 34AB of the Wealth Tax Act and Indian Evidence Act Section 45',
              ),
              const SizedBox(height: 24),

              Text(
                'Foreign immigration departments and consular visa officers operate under stringent statutory mandates to verify that visa applicants and their financial sponsors possess authentic, unencumbered economic capacity. When evaluating applications for study permits, visitor visas, temporary work permits, or permanent residency, visa officers must satisfy two fundamental legal inquiries: First, does the applicant possess sufficient financial resources to pay tuition, housing, and living expenses without resorting to illegal unauthorized employment or public welfare funds? Second, does the applicant retain substantial socio-economic ties to their home country that compel their departure upon the conclusion of their authorized stay?',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Immovable property—encompassing residential apartments, independent freehold houses, commercial retail units, and ancestral agricultural landholdings—constitutes the single most powerful, non-liquid proof of financial standing and domestic roots in India. However, foreign embassies strictly discard informal price letters from local real estate brokers, unverified property tax receipts, or subjective self-evaluations. Consular Fraud Prevention Units (FPUs) routinely blacklist applications supported by questionable documentation.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 3 Framework Feature Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildFrameworkCard(
                        colW,
                        'Wealth Tax Act Section 34AB',
                        'Registration granted by the Chief Commissioner of Income Tax / Central Board of Direct Taxes (CBDT). Consular officers recognize Section 34AB valuers as the highest statutory authority in India empowered to certify immovable asset values for international legal scrutiny.',
                        Icons.account_balance,
                      ),
                      _buildFrameworkCard(
                        colW,
                        'Indian Evidence Act Section 45',
                        'Under Section 45, opinions of expert registered valuers are admissible in judicial and quasi-judicial proceedings. When visa officers verify sponsor affidavits of support, a Section 45 expert valuation provides unassailable legal proof of real estate wealth.',
                        Icons.gavel,
                      ),
                      _buildFrameworkCard(
                        colW,
                        'Hague Apostille & MEA Compliance',
                        'For European Schengen visas and jurisdictions requiring apostilled documents, ProValuer valuation reports are prepared in strict conformity with Ministry of External Affairs (MEA) attestation standards and Hague Apostille Convention guidelines.',
                        Icons.verified,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              Text(
                'Furthermore, ProValuer Commercial valuers maintain registration with the Insolvency and Bankruptcy Board of India (IBBI) under Section 247 of the Companies Act, 2013, and hold Fellow memberships with the Institution of Valuers (FIV). This multi-tier statutory standing guarantees that reports submitted to immigration authorities are recognized as institutional appraisals rather than commercial opinions.',
                style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameworkCard(double width, String title, String body, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LandingTheme.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: LandingTheme.brandGreen, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slateText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. COUNTRY-SPECIFIC EMBASSY REQUIREMENTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCountryRequirementsSection(double screenW, bool isDesktop) {
    final countries = [
      {
        'country': 'United States',
        'code': 'USCIS / US Consulates',
        'flag': '🇺🇸',
        'sub': 'F-1 Student Visa, B-1/B-2 Tourist, EB-5 Immigrant Investor',
        'mandate':
            'Under Section 214(b) of the Immigration and Nationality Act (INA), every applicant is presumed to have immigrant intent until they prove strong, enduring economic and family ties to their home country. A certified property valuation report demonstrating substantial immovable real estate holdings owned by the student or their parents serves as vital corroborative evidence to overcome Section 214(b) refusals during consular interviews. For EB-5 investors, certified property appraisals are legally required to establish the lawful "Source of Funds" (SOF) when capital is derived from property sales, equity release, or mortgage loans.',
        'deliverables': [
          'Form I-20 financial solvency backing',
          'Sponsor Affidavit of Support (Form I-134 / I-864) asset verification',
          'Dual currency schedule in INR and USD based on official RBI rates',
          'EB-5 lawful source of funds documentation and historical valuation tracing',
        ],
      },
      {
        'country': 'Canada',
        'code': 'IRCC (Immigration Canada)',
        'flag': '🇨🇦',
        'sub': 'Study Permit, Express Entry (FSW), Provincial Nominee Programs',
        'mandate':
            'Immigration, Refugees and Citizenship Canada (IRCC) mandates that applicants prove sufficient financial resources for tuition, living allowances, and return transportation. While liquid funds (such as Guaranteed Investment Certificates - GIC and bank deposits) cover first-year expenses, property valuation reports establish long-term parental financial stability for multi-year degrees. For Express Entry Federal Skilled Worker (FSW) and Provincial Nominee Programs (such as Ontario OINP, British Columbia BC PNP, and Saskatchewan SINP), provincial officers require comprehensive personal net worth statements backed by certified immovable asset valuations.',
        'deliverables': [
          'Study permit long-term financial capability portfolio',
          'Provincial Nominee Program (PNP) net worth audit dossiers',
          'Express Entry settlement funds proof of unencumbered equity',
          'CAD conversion schedule compliant with Bank of Canada reference rates',
        ],
      },
      {
        'country': 'United Kingdom',
        'code': 'UKVI (UK Visas & Immigration)',
        'flag': '🇬🇧',
        'sub': 'Student Route (Tier 4), Skilled Worker, Innovator Founder',
        'mandate':
            'Under UKVI Immigration Rules, applicants must demonstrate maintenance funds alongside accommodation suitability and overall sponsor solvency. For student visa applicants, an approved valuation certificate proves the family\'s enduring wealth backing the Confirmation of Acceptance for Studies (CAS). For family settlement and spouse visas under Appendix FM, consular officers require property inspection and valuation reports to verify that accommodation is adequate, legally owned, and not overcrowded.',
        'deliverables': [
          'Confirmation of Acceptance for Studies (CAS) parental financial backing',
          'Appendix FM adequate maintenance and accommodation compliance certificates',
          'Innovator Founder and Global Business Mobility net capital appraisals',
          'GBP currency conversion schedule aligned with OANDA / Bank of England benchmarks',
        ],
      },
      {
        'country': 'Australia',
        'code': 'Department of Home Affairs',
        'flag': '🇦🇺',
        'sub': 'Student Subclass 500, Skilled PR 189/190, Business Innovation 188',
        'mandate':
            'Australia\'s Department of Home Affairs rigorously evaluates applicants against the Genuine Student (GS) criteria. Applicants must provide documentary evidence that their parents or legal guardians have access to sufficient funds and unencumbered assets. For Business Innovation and Investment Program (BIIP Subclass 188/888) visas, applicants must submit exhaustive valuation reports proving net business and personal assets of at least AUD 1.25 million, executed by government-licensed valuers.',
        'deliverables': [
          'Subclass 500 Genuine Student (GS) financial capacity verification',
          'Subclass 188/888 Business Innovation asset audit reports',
          'Parental annual income and asset backing affidavits',
          'AUD currency conversion tables matching Reserve Bank of Australia rates',
        ],
      },
      {
        'country': 'European Schengen Area',
        'code': 'Germany, France, Italy, Spain, etc.',
        'flag': '🇪🇺',
        'sub': 'National Visa (Type D), Schengen Tourist (Type C), Golden Visas',
        'mandate':
            'European consulates enforce Article 14 of the Schengen Visa Code, requiring evidence of socio-economic roots in India to guarantee return prior to visa expiration. For Germany National Visas (Study / Jobseeker), property valuations supplement blocked accounts by demonstrating familial economic resilience. For European Golden Visas (Spain, Portugal, Greece), certified valuation reports establish real estate asset liquidity and capital export compliance.',
        'deliverables': [
          'Schengen Visa Code socio-economic tie verification',
          'German student visa blocked account supplementary asset documentation',
          'European residency and Golden Visa real estate wealth audits',
          'EUR currency conversion schedule compliant with European Central Bank rates',
        ],
      },
    ];

    final current = countries[_selectedCountryIndex];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'DESTINATION EMBASSY PROTOCOLS',
                'Country-Specific Embassy Financial Solvency Requirements',
                'Tailored Valuation Formats Engineered to Satisfy Exact Consular Criteria Across 5 Major Global Jurisdictions',
              ),
              const SizedBox(height: 26),

              // Country Switcher Tabs
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: countries.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final isSelected = idx == _selectedCountryIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCountryIndex = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? LandingTheme.brandGreen : _lightBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isSelected ? LandingTheme.brandGreen : _borderSubtle,
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: LandingTheme.brandGreen.withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c['flag'] as String, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              c['country'] as String,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? Colors.white : _obsidian,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Country Detail Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 32 : 20),
                decoration: BoxDecoration(
                  color: _lightBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(current['flag'] as String, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${current['country']} — ${current['code']}',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _obsidian,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                current['sub'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: LandingTheme.brandGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: _borderSubtle),
                    const SizedBox(height: 20),

                    Text(
                      'Statutory Embassy Mandate & Consular Focus:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current['mandate'] as String,
                      style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.75),
                    ),
                    const SizedBox(height: 22),

                    Text(
                      'ProValuer Certified Deliverables for this Jurisdiction:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      children: (current['deliverables'] as List<String>).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: LandingTheme.brandGreen),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    color: _slateText,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PROPERTY VALUATION vs NET WORTH vs CA CERTIFICATE (COMPARATIVE TABLE)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildComparativeTableSection(double screenW, bool isDesktop) {
    return Container(
      color: _pureWhite,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'STATUTORY INSTRUMENT COMPARISON',
                'Property Valuation Report vs. Net Worth Certificate vs. CA Certificate',
                'Understanding the Specific Legal Functions, Issuing Authorities, and Consular Acceptance of Visa Financial Proofs',
              ),
              const SizedBox(height: 24),

              Text(
                'One of the most widespread confusions among visa applicants and immigration consultants is the distinction between a Property Valuation Report issued by a Government Approved Valuer and a Net Worth Certificate issued by a Chartered Accountant. While both documents frequently appear within a complete visa financial dossier, they fulfill entirely distinct statutory functions under Indian law and international consular regulations. A Chartered Accountant is licensed to audit accounts and summarize financial instruments, but possesses no statutory jurisdiction or engineering competency to determine the Fair Market Value of real estate. Conversely, a Government Approved Valuer possesses exclusive statutory authority to physically inspect, survey, and certify the valuation of land and buildings.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // Comprehensive High-Contrast Comparison Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: isDesktop ? 1200 : 960,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderSubtle),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.4),
                        1: FlexColumnWidth(2.2),
                        2: FlexColumnWidth(2.2),
                        3: FlexColumnWidth(2.0),
                      },
                      border: TableBorder.all(color: _borderSubtle, width: 1),
                      children: [
                        // Table Header
                        TableRow(
                          decoration: const BoxDecoration(color: _obsidian),
                          children: [
                            _buildTableHeaderCell('Comparison Parameter'),
                            _buildTableHeaderCell('Property Valuation Report\n(Govt Approved Valuer)'),
                            _buildTableHeaderCell('CA Net Worth Certificate\n(Chartered Accountant)'),
                            _buildTableHeaderCell('CA Income Tax Computation\n(ITR Acknowledgement)'),
                          ],
                        ),
                        // Row 1: Primary Purpose
                        _buildTableRow(
                          'Primary Purpose',
                          'Statutory appraisal of immovable properties (flats, houses, land, commercial buildings) based on market transactions and physical condition.',
                          'Consolidated financial summary aggregating all assets (immovable real estate, bank deposits, mutual funds, gold) minus liabilities.',
                          'Verification of taxable annual income and tax payment history filed with the Income Tax Department.',
                          false,
                        ),
                        // Row 2: Issuing Authority
                        _buildTableRow(
                          'Issuing Authority & Licensure',
                          'Government Approved Valuer registered under Section 34AB of Wealth Tax Act, 1957 & IBBI (Companies Act Sec 247).',
                          'Practicing Chartered Accountant registered under the Institute of Chartered Accountants of India (ICAI).',
                          'Central Board of Direct Taxes (CBDT) e-filing portal & verified by practicing CA.',
                          true,
                        ),
                        // Row 3: Physical Site Inspection
                        _buildTableRow(
                          'Physical Site Inspection',
                          'Mandatory. Includes GPS coordinates, physical boundary audit, plinth measurements, and color photographs.',
                          'None. Relying entirely on documents presented by the client without on-ground property verification.',
                          'None. Purely accounting and tax calculation based on declared incomes.',
                          false,
                        ),
                        // Row 4: Real Estate Valuation Basis
                        _buildTableRow(
                          'Real Estate Valuation Basis',
                          'Depreciated Replacement Cost (DRC), Sales Comparison Method, and local Sub-Registrar guideline value benchmarks.',
                          'Adopts the exact valuation figure certified by the Government Approved Valuer into the net worth statement.',
                          'Historical cost or book value recorded in books of accounts, ignoring current fair market appreciation.',
                          true,
                        ),
                        // Row 5: Legal Strength & Evidentiary Standing
                        _buildTableRow(
                          'Legal Strength (Indian Courts & VFS)',
                          'High. Admissible under Section 45 of Indian Evidence Act as expert technical witness testimony.',
                          'High for financial liquidity and overall net worth aggregation, but legally invalid for standalone real estate appraisal.',
                          'Standard proof of past fiscal earnings; cannot substantiate current asset equity or liquidation capability.',
                          false,
                        ),
                        // Row 6: Consular Embassy Acceptance
                        _buildTableRow(
                          'Consular Embassy Acceptance',
                          'Universally mandated across US, UK, Canada, Australia, and Schengen embassies for immovable asset solvency.',
                          'Universally accepted as a high-level summary, provided real estate figures are corroborated by certified valuer reports.',
                          'Mandated for 3-year income trend verification, but insufficient to prove long-term capital backing.',
                          true,
                        ),
                        // Row 7: Standalone Validity
                        _buildTableRow(
                          'Can it be Used Alone?',
                          'Yes, as definitive proof of real estate wealth and home country ties under INA Section 214(b) or IRCC rules.',
                          'No. Consulates frequently issue procedural fairness letters if a CA bundles real estate without a certified valuer report.',
                          'No. High income alone does not demonstrate capital asset ownership or unencumbered wealth.',
                          false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // Master Synthesis Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _lightBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: LandingTheme.brandGreen, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Ideal Consular Financial Filing Architecture',
                            style: GoogleFonts.montserrat(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _obsidian,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Leading immigration lawyers and visa consultants recommend a synchronized three-tier financial dossier: (1) An authoritative Property Valuation Report from a Section 34AB Government Approved Valuer certifying all immovable assets; (2) An ICAI-registered Chartered Accountant Net Worth Statement that references and incorporates the valuer\'s certified real estate figures; and (3) The sponsor\'s 3-year Income Tax Returns (ITR-V) proving steady cash flow. Submitting a CA statement with uncorroborated real estate values is one of the leading causes of consular administrative delays.',
                            style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.65),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.3,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String param, String valuer, String caNetWorth, String caItr, bool isAlternate) {
    return TableRow(
      decoration: BoxDecoration(color: isAlternate ? _lightBg : _pureWhite),
      children: [
        _buildTableCell(param, isBold: true),
        _buildTableCell(valuer),
        _buildTableCell(caNetWorth),
        _buildTableCell(caItr),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: isBold
            ? GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _obsidian,
              )
            : GoogleFonts.inter(
                fontSize: 12.5,
                color: _slateText,
                height: 1.55,
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. DOCUMENTS REQUIRED FOR VISA PROPERTY VALUATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentationSection(double screenW, bool isDesktop) {
    final docList = [
      {
        'title': 'Registered Title Deeds (Sale, Gift, Partition or Settlement)',
        'req': 'Mandatory',
        'desc': 'Primary legal instrument registered with the Sub-Registrar proving lawful title, total site extent, and undivided land share (UDS).',
        'reason': 'Consulates require unassailable proof of absolute ownership without clouds on title.',
      },
      {
        'title': 'Encumbrance Certificate (EC Form 15)',
        'req': 'Mandatory (13 to 30 Years)',
        'desc': 'Issued by the Registration and Stamps Department demonstrating continuous transaction history and confirming zero third-party claims.',
        'reason': 'Proves the asset is free of registered mortgages, court attachments, or undisclosed sales.',
      },
      {
        'title': 'Latest Property Tax Assessment & Paid Receipts',
        'req': 'Mandatory',
        'desc': 'Issued by the local municipal body (e.g., GHMC, Municipal Corporation, or Gram Panchayat) showing property tax PIN and current year payment.',
        'reason': 'Validates continuous physical possession and compliance with municipal revenue laws.',
      },
      {
        'title': 'Approved Building Sanction Plan & Occupancy Certificate',
        'req': 'Mandatory for Buildings',
        'desc': 'Blueprint approved by the urban planning authority (e.g., HMDA, GHMC, DTCP) alongside the Occupancy Certificate (OC).',
        'reason': 'Ensures the building is structurally legal and does not face statutory municipal demolition orders.',
      },
      {
        'title': 'Sponsor Identity & Relationship Proof (Aadhaar, PAN, Passport)',
        'req': 'Mandatory',
        'desc': 'Aadhaar Card and PAN Card of the property owner alongside the visa applicant\'s Passport and Birth Certificate.',
        'reason': 'Establishes the unbroken familial lineage connecting the financial sponsor to the visa applicant.',
      },
      {
        'title': 'Agricultural Land Revenue Records (Pattadar Passbook / Dharani)',
        'req': 'Mandatory for Rural Land',
        'desc': 'Title deed passbook, Dharani ROR 1-B extract, Pahani / Khasra extract, and village revenue map showing survey numbers.',
        'reason': 'Substantiates lawful title to agricultural acreage, cropping patterns, and land classification.',
      },
      {
        'title': 'Registered General Power of Attorney (GPA / SPA)',
        'req': 'Required for NRI Cases',
        'desc': 'If the property owner resides abroad, a registered GPA executed before an Indian Embassy / Consulate or adjudicated in India.',
        'reason': 'Authorizes family representatives in India to present the property for physical inspection.',
      },
      {
        'title': 'Existing Bank Mortgage / Loan Outstanding Statement',
        'req': 'Conditional',
        'desc': 'If an active home loan exists, a formal statement from the lending bank showing the principal outstanding amount.',
        'reason': 'Enables the valuer to compute Net Equity Value (Fair Market Value minus Outstanding Liability).',
      },
      {
        'title': 'Link Documents / Historical Chain of Title (Minimum 30 Years)',
        'req': 'Mandatory for Ancestral Property',
        'desc': 'Prior conveyances and succession deeds demonstrating unbroken ownership lineage from the original pattadar or builder.',
        'reason': 'Prevents procedural fairness queries regarding disputed ancestral or coparcenary interests.',
      },
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'DOCUMENTATION ARCHITECTURE & AUDIT CRITERIA',
                'Documents Required for a Visa Property Valuation Report',
                'Comprehensive 9-Point Document Checklist, Verification Workflow, and Analysis of Common Delay Triggers',
              ),
              const SizedBox(height: 24),

              Text(
                'A certified property valuation report is only as robust as the legal documentation supporting it. Foreign visa officers and background investigation units subject submitted property documents to rigorous cross-referencing. Missing link deeds, expired encumbrance certificates, or discrepancies between registered deed measurements and municipal sanction drawings represent the most frequent triggers for consular delays. ProValuer enforces a stringent pre-audit document checklist before initiating physical site inspections:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 9 Document Cards in 3 Columns
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: docList.map((doc) {
                      return Container(
                        width: colW,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    doc['req']!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: LandingTheme.brandGreen,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.description_outlined, size: 18, color: _slateText),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              doc['title']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _obsidian,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              doc['desc']!,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: _slateText,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _lightBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Consular Reason: ${doc['reason']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: _obsidian,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Common Documentation Mistakes
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          '6 Fatal Documentation Mistakes That Trigger Visa Processing Delays',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMistakeRow('1. Name and Initial Mismatches:', 'Discrepancies in spelling between the property owner\'s name on ancient sale deeds and modern Aadhaar/Passport records. (Must be resolved via notarized one-and-the-same affidavits).'),
                    _buildMistakeRow('2. Short-Duration Encumbrance Certificates:', 'Submitting a 1-year or 3-year EC rather than a mandatory 15 to 30-year search, leading visa officers to suspect undisclosed encumbrances.'),
                    _buildMistakeRow('3. Unregistered Power of Attorney:', 'Using a simple notarized GPA for properties owned by overseas relatives; embassies require registered GPAs or direct consular attestations.'),
                    _buildMistakeRow('4. Concealing Active Bank Mortgages:', 'Presenting a property as 100% equity when an active home loan exists. If discovered, consular fraud units flag the file for fraudulent misrepresentation.'),
                    _buildMistakeRow('5. Unapproved Floor Violations:', 'Claiming value for penthouse or terrace floors constructed in direct violation of municipal sanction plans.'),
                    _buildMistakeRow('6. Agricultural Land without Dharani Passbooks:', 'Submitting unmutated revenue land records where succession remains pending in local tahsildar courts.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMistakeRow(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.55),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w700, color: _obsidian)),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. ANATOMY OF AN EMBASSY-COMPLIANT VALUATION REPORT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildReportAnatomySection(double screenW, bool isDesktop) {
    final sections = [
      {
        'part': 'Part A',
        'title': 'Official Statutory Covering Letter & Certificate of Value',
        'desc': 'Printed on official institutional letterhead detailing CBDT Section 34AB Registration Number, IBBI Registration Number, and Institution of Valuers Fellow credentials. Formally addresses the visa visa officer or consular post, declaring the final Fair Market Value (FMV) and Net Realizable Value in both Indian Rupees (INR) and the target destination currency (USD, CAD, GBP, AUD, EUR).',
      },
      {
        'part': 'Part B',
        'title': 'Legal Identification & Property Schedule',
        'desc': 'Exhaustive legal description encompassing Sub-Registrar jurisdiction, Registration District, Survey Number, Plot Number, Flat Number, Municipal Door Number, and Four-Side Boundaries (North, South, East, West). Explicitly matches the schedule of property recorded in registered title deeds.',
      },
      {
        'part': 'Part C',
        'title': 'Physical Inspection & Engineering Audit',
        'desc': 'Verifies exact date and time of physical on-ground inspection. Details structural specifications: Type of construction (RCC framed vs load-bearing), quality of interior finishes, age of structure, estimated remaining useful life (RUL), municipal plinth area measurements, and Undivided Share of Land (UDS).',
      },
      {
        'part': 'Part D',
        'title': 'Dual-Approach Valuation Methodology & Cost Calculations',
        'desc': 'Detailed algorithmic breakdown utilizing the Sales Comparison Method for land/UDS and the CPWD Depreciated Replacement Cost (DRC) method for building structures. Fully articulates plinth area rates, depreciation percentages based on structural age, and local market absorption indices.',
      },
      {
        'part': 'Part E',
        'title': 'Color Photographic Evidence with GPS Coordinates & Timestamp',
        'desc': 'High-resolution embedded photographs documenting the property: Front exterior facade, abutting access roadway, interior rooms, building elevation, and municipal house number plate. Every image features an embedded GPS coordinate watermark (Latitude & Longitude) and timestamp proving genuine on-site inspection.',
      },
      {
        'part': 'Part F',
        'title': 'Encumbrance & Mortgage Declaration',
        'desc': 'Statutory declaration certifying whether the property is free of all registered encumbrances, liens, court injunctions, and municipal attachments based on verified 15 to 30-year Encumbrance Certificates. Where bank loans exist, provides net equity computations.',
      },
      {
        'part': 'Part G',
        'title': 'Valuer Independence Declaration & Tamper-Evident QR Code',
        'desc': 'Statutory certification confirming the valuer retains zero personal, financial, or family interest in the property or visa applicant. Concludes with an ink seal, registered valuer signature, and a tamper-evident digital QR code linking directly to ProValuer\'s secure cloud authentication server for instant consular verification.',
      },
    ];

    return Container(
      color: _pureWhite,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'REPORT SPECIFICATION & STANDARDS',
                'Anatomy of an Embassy-Compliant Valuation Report',
                'The 7 Core Sections Engineered into Every ProValuer Consular Dossier to Guarantee Immediate Consular Approval',
              ),
              const SizedBox(height: 24),

              Text(
                'Foreign consulates and immigration visa officers handle thousands of student, tourist, and permanent residency dossiers every month. Reports that appear hastily drafted, lack physical verification evidence, or omit explicit statutory registration credentials are systematically flagged for secondary review or administrative processing under Section 221(g). Every property valuation report prepared by ProValuer Commercial follows a rigorous 7-part anatomy engineered to withstand the most demanding scrutiny of foreign visa officers:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 7 Vertical Parts List
              Column(
                children: sections.map((sec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderSubtle),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _obsidian,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sec['part']!,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sec['title']!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: _obsidian,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                sec['desc']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _slateText,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. COMMON REJECTION REASONS BY CONSULAR OFFICERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRejectionReasonsSection(double screenW, bool isDesktop) {
    final reasons = [
      {
        'title': 'Broker Letters & Non-Statutory Valuations',
        'desc': 'Submitting letters from real estate agents, property consultants, or construction contractors. Foreign embassies maintain strict blacklists of unofficial valuation sources that do not possess statutory registration under the Wealth Tax Act or Companies Act.',
      },
      {
        'title': 'Outdated Valuation Reports Older Than 6–12 Months',
        'desc': 'Consulates require contemporary financial solvency proof. Submitting property appraisals executed more than one year prior triggers immediate queries regarding whether the property was sold, mortgaged, or transferred in the interim.',
      },
      {
        'title': 'Unsubstantiated Hyper-Inflated Property Values',
        'desc': 'Valuation reports that quote exorbitant market rates disconnected from registered Sub-Registrar transaction comparables or government guideline values. Consular fraud units check online land registries and reject speculative numbers.',
      },
      {
        'title': 'Failure to Document Clear Family Sponsorship Lineage',
        'desc': 'Submitting property owned by extended relatives (e.g., uncles, cousins, distant family) without executing legally binding Deeds of Guarantee or Registered Affidavits of Support demonstrating why the asset is available for the applicant.',
      },
      {
        'title': 'Absence of Physical Inspection Evidence & Photos',
        'desc': 'Reports drafted as "desktop valuations" without on-site photographs, building measurements, or geo-coordinates. Consulates treat reports lacking visual evidence as fabricated documentation.',
      },
      {
        'title': 'Failure to Disclose Active Bank Encumbrances',
        'desc': 'Presenting a ₹2 Crore mortgaged flat as full equity without disclosing a ₹1.2 Crore outstanding home loan. If the embassy discovers an undeclared lien through EC verification, the applicant faces permanent visa bans for fraud.',
      },
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'CONSULAR RISK MITIGATION',
                'Common Consular Rejection Reasons & Red Flags in Property Valuations',
                'How Visa Officers and Fraud Prevention Units Evaluate Real Estate Proofs and How ProValuer Insulates Your Filing',
              ),
              const SizedBox(height: 24),

              Text(
                'Visa refusals under INA Section 214(b) (United States), Section 221(g) administrative processing, or IRCC procedural fairness letters are frequently rooted in preventable errors in financial documentation. When a visa officer suspects that a property valuation is exaggerated, fraudulent, or prepared by an unaccredited party, the credibility of the entire visa application collapses. ProValuer Commercial conducts rigorous forensic audits to eliminate all consular red flags before issuance:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 6 Rejection Cards (2 Columns)
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: reasons.map((r) {
                      return Container(
                        width: colW,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    r['title']!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: _obsidian,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              r['desc']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _slateText,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. REGIONAL PRACTICE: HYDERABAD, TELANGANA & SOUTH INDIA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRegionalPracticeSection(double screenW, bool isDesktop) {
    return Container(
      color: _pureWhite,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'LOCAL REGIONAL PRACTICE EXCELLENCE',
                'Hyderabad, Telangana & South India Visa Valuation Services',
                'Direct Alignment with the U.S. Consulate General Hyderabad, VFS Global Centres, and Telangana Real Estate Dynamics',
              ),
              const SizedBox(height: 24),

              Text(
                'Hyderabad represents one of the largest outbound immigration, student visa, and technology worker hubs in South Asia. With the establishment of the state-of-the-art U.S. Consulate General in Nanakramguda (Financial District, Gachibowli), as well as prominent Visa Application Centres (VFS Global) for the United Kingdom, Canada, Australia, and Schengen nations, local applicants require immediate, highly responsive valuation services that reflect nuanced regional real estate parameters.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'ProValuer Commercial maintains dedicated practice teams across Hyderabad, Cyberabad, Secunderabad, and greater Telangana districts. We possess exhaustive familiarity with regional statutory bodies, land registries, and planning frameworks, including:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 22),

              // 4 Local Focus Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildLocalFeatureCard(
                        colW,
                        'HMDA & GHMC High-Rise Real Estate',
                        'Expert valuation of premium gated community apartments, luxury villas, and commercial spaces across HITEC City, Gachibowli, Financial District, Kokapet Neopolis, Tellapur, Jubilee Hills, and Banjara Hills. Reconciling high-density super built-up areas with certified Undivided Share of Land (UDS) calculations.',
                        Icons.apartment,
                      ),
                      _buildLocalFeatureCard(
                        colW,
                        'Dharani Integrated Agricultural Portals',
                        'Telangana families frequently hold substantial wealth in agrarian land parcels across Ranga Reddy, Medchal-Malkajgiri, Sangareddy, Yadadri Bhuvanagiri, and Medak districts. We directly interface with Dharani portal records, verifying Pattadar Passbooks, ROR 1-B extracts, and NALA non-agricultural conversion feasibility.',
                        Icons.landscape,
                      ),
                      _buildLocalFeatureCard(
                        colW,
                        'Direct US Consulate & VFS Alignment',
                        'Our reports strictly mirror the documentary standards expected by consular officers at the U.S. Consulate General Hyderabad (Nanakramguda) and VFS Global Hyderabad. We provide identical hardcopy dossier binders alongside digitally certified PDFs for online portal uploads (CEAC, IRCC Portal, ImmiAccount).',
                        Icons.account_balance,
                      ),
                      _buildLocalFeatureCard(
                        colW,
                        'Emergency 24-Hour Express Issuance',
                        'Understanding the urgent deadlines of unexpected consular interview appointments or sudden 221(g) administrative deadlines, ProValuer operates an emergency express valuation desk providing guaranteed on-site inspection and certified dossier delivery within 24 to 48 hours across Hyderabad metro.',
                        Icons.bolt,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalFeatureCard(double width, String title, String body, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: LandingTheme.brandGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slateText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. THE PROVALUER 4-STAGE FORENSIC PROTOCOL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProtocolSection(double screenW, bool isDesktop) {
    final stages = [
      {
        'step': 'STAGE 01',
        'title': 'Document Scrutiny & Family Sponsorship Audit',
        'desc': 'Client submits registered title deeds, Encumbrance Certificates, municipal tax receipts, and family relationship documents via our secure portal. Our legal team conducts a preliminary forensic title review, verifying ownership lineage, identity matching, and identifying any active mortgage liabilities.',
      },
      {
        'step': 'STAGE 02',
        'title': 'Forensic On-Site Physical Inspection & Geo-Tagging',
        'desc': 'Our certified engineering valuer conducts a physical on-ground survey of the property. We verify physical boundaries, capture structural plinth measurements, evaluate construction specifications and quality, and record high-resolution color photographs with embedded GPS coordinates and timestamps.',
      },
      {
        'step': 'STAGE 03',
        'title': 'Algorithmic Valuation Modeling & Dual-Currency Translation',
        'desc': 'Deploying the Sales Comparison Approach and CPWD Depreciated Replacement Cost models, our valuation analysts calculate Fair Market Value and Realizable Value. All figures are translated into target foreign currencies (USD, CAD, GBP, AUD, EUR) using official RBI reference exchange rates.',
      },
      {
        'step': 'STAGE 04',
        'title': 'Issuance of Embassy-Compliant Dossier with QR Verification',
        'desc': 'Report is executed under Section 34AB seal and IBBI registration, signed by our Fellow Valuer. We generate a tamper-evident digital QR code linked to our live verification database. Client receives a high-resolution signed digital PDF alongside physical stamped bound hardcopies for consular submission.',
      },
    ];

    return Container(
      color: _lightBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'RIGOROUS FORENSIC METHODOLOGY',
                'The ProValuer 4-Stage Forensic Visa Valuation Protocol',
                'Systematized Operational Workflow Engineered for Speed, Complete Legal Precision, and Unconditional Consular Admissibility',
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = isDesktop ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stages.map((st) {
                      return Container(
                        width: cardW,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _pureWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: LandingTheme.brandGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                st['step']!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              st['title']!,
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: _obsidian,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              st['desc']!,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: _slateText,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. 10 INSTITUTIONAL FAQS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFaqSection(double screenW, bool isDesktop) {
    final faqs = [
      {
        'q': 'Why does the US Embassy or Canadian Consulate require a property valuation report from a Government Approved Valuer instead of a CA certificate?',
        'a': 'Under Indian law and international evidentiary rules, Chartered Accountants are licensed to audit financial accounts, tax filings, and bank balances; they possess no statutory jurisdiction or technical engineering expertise to determine the Fair Market Value (FMV) of real estate. Real estate appraisal requires physical site inspection, land boundary verification, construction quality analysis, and registration market comparable reconciliation. Consular Fraud Prevention Units (FPUs) mandate that immovable asset valuations be executed by a Government Approved Valuer registered under Section 34AB of the Wealth Tax Act, 1957. A CA then uses the valuer\'s certified figure to compile the overall Net Worth Certificate.',
      },
      {
        'q': 'Can my parents sponsor my student visa using ancestral agricultural land or vacant plots?',
        'a': 'Yes, absolutely. Ancestral agricultural land, rural farm holdings, and vacant residential/commercial plots represent legitimate, highly regarded assets for proving financial solvency and deep home-country ties. For agricultural land, the report incorporates Dharani portal extracts, Pattadar Passbooks, village revenue maps, and local agricultural yield capitalization to establish market worth. For vacant plots, comparative sales methods and layout approval verifications are applied.',
      },
      {
        'q': 'Does the property need to be free of bank mortgages or home loans to be shown for visa solvency?',
        'a': 'No, a property with an active home loan can still be utilized, provided there is positive net equity. In our valuation report, we clearly articulate the Gross Fair Market Value, deduct the certified outstanding bank loan balance (provided via the latest bank loan statement), and highlight the Net Realizable Equity. For example, if a flat is valued at ₹1.5 Crores and retains an outstanding mortgage of ₹30 Lakhs, the net equity of ₹1.2 Crores is legally recognized as genuine sponsor wealth.',
      },
      {
        'q': 'How is the property value converted into US Dollars, Canadian Dollars, British Pounds, or Euros?',
        'a': 'ProValuer reports incorporate a certified dual-currency valuation schedule. The primary appraisal is computed in Indian Rupees (INR) and translated into the target destination currency (USD, CAD, GBP, AUD, or EUR) using the official Reserve Bank of India (RBI) reference exchange rate or international banking reference rates prevailing on the inspection date. This enables foreign consular officers to immediately evaluate financial capacity without manual conversion.',
      },
      {
        'q': 'Is a physical inspection of the property mandatory for an embassy visa valuation report?',
        'a': 'Yes, physical inspection is an essential requirement. Consular fraud prevention protocols strictly reject "desktop valuations." Our certified valuers conduct an on-site inspection to measure plinth areas, evaluate physical condition, verify boundaries, and capture high-resolution color photographs with embedded GPS coordinates and timestamps. These photographs are permanently bound into the report as conclusive proof of existence.',
      },
      {
        'q': 'How recent should the property valuation report be when submitting to the visa consulate?',
        'a': 'Consulates universally expect valuation reports to be contemporary. As a general standard, valuation reports should not be older than 6 to 12 months at the time of visa filing or consular interview. If your report was executed more than one year ago, consular officers may request an updated appraisal to verify that the property was not liquidated, encumbered, or partitioned in the interim.',
      },
      {
        'q': 'Can property owned by extended family members (uncles, aunts, grandparents) be included in my visa financial dossier?',
        'a': 'Primary sponsors are conventionally immediate family members (parents, legal guardians, or the applicant). However, property owned by grandparents or maternal/paternal uncles can be included if accompanied by a registered Affidavit of Financial Sponsorship, proof of family relationship, and a legally binding declaration explaining their willingness to sponsor the applicant\'s education or stay.',
      },
      {
        'q': 'How does ProValuer\'s QR code verification prevent visa application fraud and embassy scrutiny?',
        'a': 'Every valuation report issued by ProValuer Commercial features an encrypted, tamper-evident digital QR code printed directly on the certificate. When scanned by a visa officer or consular investigator using any smartphone or scanner, the code redirects to our secure cloud verification server displaying a verified copy of the certificate, inspection timestamp, valuer registration credentials, and property summary. This eliminates the risk of unauthorized document tampering.',
      },
      {
        'q': 'What is the difference between a Property Valuation Report and a CA Net Worth Certificate for visa purposes?',
        'a': 'A Property Valuation Report evaluates only immovable real estate (land, apartments, houses, commercial buildings) based on physical inspection and technical valuation standards. A CA Net Worth Certificate is an accounting statement that aggregates all of the sponsor\'s assets—including real estate (taken directly from our valuation report), bank savings, fixed deposits, shares, and gold—and deducts liabilities. Consulates require both documents working in unison.',
      },
      {
        'q': 'Can I get an emergency visa property valuation report within 24 hours in Hyderabad or Telangana?',
        'a': 'Yes. ProValuer operates an emergency express consular valuation desk across Hyderabad, Cyberabad, Secunderabad, and surrounding districts. Upon receipt of digital property documents before 12:00 PM, we schedule same-day on-site physical inspection and deliver the fully executed, certified, and QR-coded digital valuation dossier within 24 to 48 hours, with hardcopies hand-delivered or dispatched via express courier.',
      },
    ];

    return Container(
      color: _pureWhite,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 60 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'FREQUENTLY ASKED QUESTIONS',
                'Statutory & Consular Property Valuation FAQs',
                'Authoritative Answers to the 10 Most Critical Questions Encountered by Students, Immigrants, and Family Sponsors',
              ),
              const SizedBox(height: 28),

              Column(
                children: faqs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final faq = entry.value;
                  final isExpanded = _expandedFaqIndices.contains(idx);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isExpanded ? _lightBg : _pureWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isExpanded ? LandingTheme.brandGreen.withValues(alpha: 0.3) : _borderSubtle,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedFaqIndices.remove(idx);
                                  } else {
                                    _expandedFaqIndices.add(idx);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                color: Colors.transparent,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        faq['q']!,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isExpanded ? LandingTheme.brandGreen : _obsidian,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      isExpanded ? Icons.remove_circle_outline : Icons.add_circle_outline,
                                      color: isExpanded ? LandingTheme.brandGreen : _slateText,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1, color: _borderSubtle),
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                faq['a']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  color: _slateText,
                                  height: 1.7,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. HIGH-TOUCH EXECUTIVE CONVERSION BLOCK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConversionSection(double screenW, bool isDesktop) {
    return Container(
      color: _obsidian,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 70 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'EXECUTIVE IMMIGRATION ADVISORY DESK',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: LandingTheme.brandGreen,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Schedule Your Embassy Property Valuation Today',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 34 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 750),
                child: Text(
                  'Guaranteed 24 to 48-hour delivery of certified, QR-coded, dual-currency valuation reports compliant with US, UK, Canada, Australia, and European Schengen visa mandates. Complete confidentiality assured.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    color: const Color(0xFFCBD5E1),
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(
                      'Hello ProValuer Commercial, I would like to schedule an embassy-compliant property valuation for a visa application.',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                    label: Text(
                      'Consult via WhatsApp',
                      style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone_in_talk, size: 18),
                    label: Text(
                      'Direct Line: $_primaryPhoneFormatted',
                      style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Registered Valuers under Section 34AB of Wealth Tax Act, 1957 & Section 247 of Companies Act, 2013',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. INSTITUTIONAL FOOTER & CROSS-NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInstitutionalFooter(double screenW, bool isDesktop) {
    return Container(
      color: const Color(0xFF090D16),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 60) / 4 : (constraints.maxWidth - 20) / 2;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 24,
                    children: [
                      // Col 1: Brand
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROVALUER COMMERCIAL',
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Institutional property appraisals and certified valuation reports for global immigration, consular solvency, bank lending, and statutory dispute defense.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Col 2: Practice Areas
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRACTICE AREAS',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooterLink('Home Page', () => context.go('/')),
                            _buildFooterLink('Government Approved Valuers', () => context.go('/government-approved-valuers')),
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                            _buildFooterLink('Visa & Immigration Valuations', () => context.go('/services/visa-and-immigration-valuations')),
                          ],
                        ),
                      ),

                      // Col 3: Consular Focus
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EMBASSY JURISDICTIONS',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooterText('United States (USCIS F-1 & EB-5)'),
                            _buildFooterText('Canada (IRCC Study Permit & PNP)'),
                            _buildFooterText('United Kingdom (UKVI CAS & Spouse)'),
                            _buildFooterText('Australia (DHA Subclass 500 & 188)'),
                            _buildFooterText('European Schengen Area (Type D)'),
                          ],
                        ),
                      ),

                      // Col 4: Contact
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONTACT DESK',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooterText('Advisory: $_primaryPhoneFormatted'),
                            _buildFooterText('WhatsApp: +91 85008 80333'),
                            _buildFooterText('Hyderabad, Telangana, India'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 ProValuer Commercial. Canonical: https://www.provaluer.in',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'Sec 34AB Wealth Tax Act · IBBI Registered',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12.5,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION HEADER HELPER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionHeader(String badge, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: LandingTheme.brandGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LandingTheme.brandGreen,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _obsidian,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: _slateText,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
