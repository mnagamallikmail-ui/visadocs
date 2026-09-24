import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';

/// Professional Service Page: Certified Property Valuation Services
/// Canonical URL: https://www.provaluer.in/services/property-valuation
/// Target Word Count: 5,050 - 6,150 words of dense, institutional, statutory property valuation prose.
class PropertyValuationScreen extends StatefulWidget {
  const PropertyValuationScreen({super.key});

  @override
  State<PropertyValuationScreen> createState() => _PropertyValuationScreenState();
}

class _PropertyValuationScreenState extends State<PropertyValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedPropertyTypeIndex = 0;
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

                // 2. Statutory Authority & Credentials
                _buildStatutoryAuthoritySection(screenW, isDesktop),

                // 3. Why Do You Need a Property Valuation Report?
                _buildWhyYouNeedSection(screenW, isDesktop),

                // 4. Complete Property-Type Coverage Matrix (Interactive)
                _buildPropertyTypeMatrixSection(screenW, isDesktop),

                // 5. How Is Property Value Calculated in India? (5 Methods + H3)
                _buildMethodologySection(screenW, isDesktop),

                // 6. Statutory & Regulatory Framework (Sec 50C, 55A, 56(2)(x), Evid. Act 45)
                _buildRegulatoryFrameworkSection(screenW, isDesktop),

                // 7. Documents Required for Property Valuation & 6 Fatal Mistakes
                _buildDocumentationSection(screenW, isDesktop),

                // 8. Hyderabad / Telangana Property Valuation Practice
                _buildRegionalPracticeSection(screenW, isDesktop),

                // 9. The ProValuer 4-Stage Forensic Valuation Protocol
                _buildProtocolSection(screenW, isDesktop),

                // 10. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 11. High-Touch Executive Consultation CTA
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
                  'Hello ProValuer Commercial, I require a certified property valuation report from a Government Approved Valuer.',
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
                        'Property Advisory Desk',
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
                        _buildNavAction('Visa Valuations', () => context.go('/services/visa-and-immigration-valuations')),
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
                          'Hello ProValuer Commercial, I need an official property valuation report from a Government Approved Valuer.',
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
                      'GOVERNMENT APPROVED VALUERS · WEALTH TAX ACT SEC 34AB · IBBI REGISTERED',
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
                'Certified Property Valuation Reports by Government Approved Valuers in India',
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
                'Institutional-grade property appraisals and certified valuation certificates for Capital Gains Tax (Section 50C & 55A), Visa Financial Solvency, Commercial Bank Collateral, High Court Probate, Family Settlements, and Corporate Transactions. Issued by Government Approved Valuers registered under Section 34AB of the Wealth Tax Act, 1957 and Registered Valuers under Section 247 of the Companies Act, 2013. Admissible as expert technical testimony under Section 45 of the Indian Evidence Act, 1872 across all Indian judicial benches, revenue tribunals, nationalized banks, and foreign consular posts. Complete on-site forensic survey, GPS-stamped documentation, dual-approach algorithmic modeling, and instant tamper-evident QR code verification delivered within 24 to 48 hours.',
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
                  _buildTrustBadge('Sec 34AB & IBBI Registered', 'CBDT & MCA Empanelled Valuers'),
                  _buildTrustBadge('Court Admissible (Sec 45)', 'Indian Evidence Act Expert Testimony'),
                  _buildTrustBadge('Dual-Method DRC Modeling', 'CPWD Plinth Area & Market Sales'),
                  _buildTrustBadge('24–48 Hr Turnaround', 'Express Hyderabad & South India Delivery'),
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
      {'val': '₹18,500+ Cr', 'label': 'Real Estate Valued', 'sub': 'Residential, Commercial, Industrial'},
      {'val': '25,000+', 'label': 'Certified Appraisals', 'sub': 'Tax, Visa, Bank, Court & Corporate'},
      {'val': '100% Admissible', 'label': 'Legal Standing', 'sub': 'High Courts, ITAT, DRT, NCLT'},
      {'val': '24–48 Hrs', 'label': 'Standard Issuance', 'sub': 'Physical Hardcopy + Secure QR PDF'},
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
  // 2. STATUTORY AUTHORITY & CREDENTIALS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatutoryAuthoritySection(double screenW, bool isDesktop) {
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
                'REGULATORY ACCREDITATION & LEGAL POWERS',
                'Statutory Authority & Credentials of a Government Approved Property Valuer',
                'The Legal Distinctions Separating Certified Section 34AB Valuers from Real Estate Brokers and Chartered Engineers',
              ),
              const SizedBox(height: 24),

              Text(
                'In the Indian legal and commercial architecture, property valuation is not an informal estimate or commercial brokerage opinion; it is a regulated statutory discipline with strict legal consequences. Under Indian jurisprudence, an appraisal report carries legal weight only when executed by a professional holding formal accreditation under the Wealth Tax Act, 1957 or the Companies Act, 2013. When commercial banks sanction mortgage credit, when the Income Tax Department assesses capital gains, or when civil courts adjudicate partition suits, uncertified estimates from local property dealers or building contractors are rejected outright as legally inadmissible hearsay.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'ProValuer Commercial operates under the highest tiers of statutory recognition in India, ensuring our property valuation certificates withstand rigorous scrutiny across all regulatory bodies, revenue departments, and judicial benches:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 3 Credentials Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildAuthorityCard(
                        colW,
                        'Wealth Tax Act Section 34AB (CBDT)',
                        'Empanelled and registered by the Chief Commissioner of Income Tax / Central Board of Direct Taxes. Section 34AB valuers hold exclusive legal authority under the Income Tax Act to determine Fair Market Value (FMV) for Section 50C circle rate rebuttals, Section 55A capital gains baseline determinations as of April 1, 2001, and Section 56(2)(x) deemed gift protections.',
                        Icons.account_balance,
                      ),
                      _buildAuthorityCard(
                        colW,
                        'Companies Act Section 247 & IBBI',
                        'Registered Valuers governed by the Insolvency and Bankruptcy Board of India (IBBI) for the asset class of Land & Building. Empowered to certify corporate real estate under Companies Act 2013, NCLT corporate insolvency resolution (CIRP), mergers & acquisitions, and cross-border transactions under FEMA.',
                        Icons.verified_user,
                      ),
                      _buildAuthorityCard(
                        colW,
                        'Indian Evidence Act Section 45',
                        'Under Section 45, opinions of expert registered valuers are admissible in civil, criminal, and revenue courts as authoritative expert testimony. Our certified reports provide binding evidentiary proof in Family Court matrimonial divisions, High Court probate petitions, and Debt Recovery Tribunals (DRT).',
                        Icons.gavel,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),

              Text(
                'Our valuers maintain Fellow Memberships with the Institution of Valuers (FIV) and the Royal Institution of Chartered Surveyors (RICS), adhering strictly to International Valuation Standards (IVS) and the CPWD Manual of Standard Plinth Area Rates.',
                style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthorityCard(double width, String title, String body, IconData icon) {
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
  // 3. WHY DO YOU NEED A PROPERTY VALUATION REPORT?
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWhyYouNeedSection(double screenW, bool isDesktop) {
    final useCases = [
      {
        'title': 'Capital Gains Tax Planning (Sec 50C & 55A)',
        'who': 'Property Sellers, Taxpayers & Chartered Accountants',
        'desc': 'Defending against inflated Sub-Registrar circle rates under Section 50C or establishing historical Fair Market Value (FMV) as of April 1, 2001 under Section 55A to maximize indexed acquisition costs and legally minimize Long-Term Capital Gains (LTCG) tax.',
        'icon': Icons.calculate,
      },
      {
        'title': 'Visa & Global Immigration Solvency',
        'who': 'Students, Overseas Immigrants & Family Sponsors',
        'desc': 'Proving financial net worth, unencumbered family assets, and strong home-country ties under INA Section 214(b) for US F-1/B1/B2, Canada Study Permits/PNP, UKVI CAS maintenance, and Australia Subclass 500/188 visas.',
        'icon': Icons.flight_takeoff,
      },
      {
        'title': 'Bank Mortgage Financing & LAP Collateral',
        'who': 'Borrowers, Commercial Banks, HFCs & NBFCs',
        'desc': 'Required under RBI Master Directions for sanctioning home loans, Loan Against Property (LAP), and corporate working capital limits, establishing Fair Market Value, Realizable Value, and Distress Sale Value.',
        'icon': Icons.account_balance,
      },
      {
        'title': 'Divorce & Matrimonial Asset Division',
        'who': 'Spouses, Family Court Advocates & Mediators',
        'desc': 'Providing Family Courts with impartial, court-admissible property valuations under the Family Courts Act, 1984 to ensure equitable distribution of joint and self-acquired matrimonial assets.',
        'icon': Icons.balance,
      },
      {
        'title': 'Probate, Succession & Letters of Administration',
        'who': 'Heirs, Testamentary Petitioners & High Court Advocates',
        'desc': 'Mandated by High Courts and District Courts under the Indian Succession Act, 1925 to compute court filing fees and establish the exact estate value in contested or uncontested will probate petitions.',
        'icon': Icons.history_edu,
      },
      {
        'title': 'Family Partition Deeds & Coparcenary Settlements',
        'who': 'Joint Hindu Families, Coparceners & Family Offices',
        'desc': 'Establishing transparent valuation parity for dividing ancestral properties, commercial holdings, and agricultural estates under the Hindu Succession Act, preventing bitter intra-family litigation.',
        'icon': Icons.diversity_3,
      },
      {
        'title': 'Gift Deeds & Deemed Gifts (Sec 56(2)(x))',
        'who': 'Property Donors, Donees & Buyers',
        'desc': 'Shielding buyers and donees from arbitrary income additions under Section 56(2)(x) by proving that transaction discounts reflect genuine physical defects, easements, or market realities.',
        'icon': Icons.card_giftcard,
      },
      {
        'title': 'Prudent Sale & Purchase Due Diligence',
        'who': 'High-Net-Worth Individuals, NRIs & Corporate Buyers',
        'desc': 'Protecting buyers from overpaying in overheated micro-markets and shielding sellers from disposing of prime land parcels below fair realizable potential, backed by registered transaction comparables.',
        'icon': Icons.real_estate_agent,
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
                'STATUTORY USE CASES & COMMERCIAL TRIGGERS',
                'Why Do You Need a Property Valuation Report?',
                'An Exhaustive Breakdown of Legal, Tax, Financial, and Judicial Circumstances Requiring Certified Appraisals',
              ),
              const SizedBox(height: 24),

              Text(
                'Property owners rarely seek a certified valuation report out of idle curiosity; appraisals are commissioned to satisfy strict statutory, banking, or judicial mandates. In each scenario, an uncertified estimate is legally void. A report executed by a Section 34AB Government Approved Valuer serves as a legally binding shield, defending taxpayers against scrutiny assessments, proving credit solvency to nationalized lenders, and establishing indisputable market value before judicial benches.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 8 Use Case Cards in 2 Columns
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: useCases.map((uc) {
                      return Container(
                        width: colW,
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
                                  child: Icon(uc['icon'] as IconData, color: LandingTheme.brandGreen, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        uc['title'] as String,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: _obsidian,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Requisite for: ${uc['who']}',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: LandingTheme.brandGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              uc['desc'] as String,
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
  // 4. COMPLETE PROPERTY-TYPE COVERAGE MATRIX
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPropertyTypeMatrixSection(double screenW, bool isDesktop) {
    final propertyTypes = [
      {
        'title': 'Residential Apartments & Flats',
        'icon': Icons.apartment,
        'method': 'Sales Comparison Method + Undivided Share of Land (UDS) Calculation',
        'useCases': 'Home Loans, Visa Financial Solvency, Capital Gains Tax, Wealth Statements',
        'legal':
            'Reconciling Super Built-up Area against RERA Carpet Area. Verifying registered Undivided Share of Land (UDS) percentage against master deed schedule. Confirming municipal Occupancy Certificate (OC) validity to eliminate demolition or unapproved construction risks.',
        'details':
            'Apartments represent the most common urban residential asset. Our valuers analyze recent registered sale deeds in the same tower or immediate micro-market (within 500 meters), adjusting for floor-rise premiums, corner views, clubhouse amenity loading, and car park allocations.',
      },
      {
        'title': 'Independent Freehold Houses & Bungalows',
        'icon': Icons.home,
        'method': 'Land Comparison Method + Depreciated Replacement Cost (DRC) for Building',
        'useCases': 'Bank Mortgages, Probate & Estate Succession, Family Partition, Sec 55A FMV',
        'legal':
            'Checking municipal setback compliance, floor space index (FSI) utilization, and building sanction regularity. In older structures, checking for unauthorized vertical floor additions lacking municipal sanction permits.',
        'details':
            'Independent houses combine two distinct asset classes: the underlying freehold land parcel and the physical building structure. We value the land on current market transaction comparables and value the structure using CPWD plinth area rates less structural age depreciation.',
      },
      {
        'title': 'Luxury Villas & Gated Communities',
        'icon': Icons.villa,
        'method': 'Hedonic Market Comparison + Infrastructure Factor Loading',
        'useCases': 'High-Net-Worth Visa Filings, Corporate Solvency, Family Settlement, Mortgage',
        'legal':
            'Auditing common undivided land rights (access roads, central clubhouses, parks). Checking layout approval sanction numbers (e.g. HMDA / DTCP layout sanction) to confirm community infrastructure legality.',
        'details':
            'Villas demand nuanced appraisal because construction specifications (imported marble, private pools, smart automation) significantly exceed standard plinth area baselines. We apply hedonic pricing to isolate premium finishes from baseline land indices.',
      },
      {
        'title': 'Commercial Office Space & IT Parks',
        'icon': Icons.business,
        'method': 'Income Capitalization Method (Yield Capitalization) + DCF Modeling',
        'useCases': 'Corporate Balance Sheets, REIT Ingestion, Bank Security, NCLT Resolution',
        'legal':
            'Scrutinizing commercial lease agreements, lock-in periods, security deposit covenants, triple-net lease obligations, and municipal trade license clearances.',
        'details':
            'Valued based on net operating income (NOI) capitalization using prevailing commercial yield rates (7.5%–9.5% in Indian Tier-1 tech corridors like HITEC City and Gachibowli). In multi-tenant Grade-A assets, DCF modeling captures scheduled rental escalations.',
      },
      {
        'title': 'High-Street Retail Showrooms & Shops',
        'icon': Icons.storefront,
        'method': 'Rental Multiplier Method + Footfall Hedonic Pricing',
        'useCases': 'Commercial Mortgages, Partnership Dissolutions, SRO Circle Rate Defense',
        'legal':
            'Auditing municipal commercial property tax assessments, frontage road-width bylaws, fire safety clearances, and customer parking allocation compliance.',
        'details':
            'Retail property values are dictated by visibility, frontage width, and pedestrian/vehicular footfall. A corner showroom command substantial capital premiums over identical interior retail units.',
      },
      {
        'title': 'Logistics Warehouses & Cold Storage',
        'icon': Icons.warehouse,
        'method': 'Lease Rental Capitalization + Structural Replacement Cost',
        'useCases': 'PE Acquisitions, Industrial Bank Collateral, Capital Gains Reinvestment',
        'legal':
            'Verifying industrial land use zoning (TSIIC / RIICO), hazardous material approvals, fire safety NOCs, and floor load-bearing capacity certifications.',
        'details':
            'Appraising modern PEB (Pre-Engineered Building) sheds, clear height clearances (9m to 12m), dock leveler counts, and national highway corridor connectivity.',
      },
      {
        'title': 'Industrial Manufacturing Units & Plants',
        'icon': Icons.factory,
        'method': 'Depreciated Replacement Cost (DRC) + Heavy Yard Specialization',
        'useCases': 'SARFAESI Enforcement, Bank Collateral, Insolvency & Bankruptcy (CIRP)',
        'legal':
            'Verifying industrial master lease terms from state industrial corporations (e.g. TSIIC), pollution control board (PCB) consent to operate, and factory inspectorate approvals.',
        'details':
            'Industrial valuation isolates heavy foundation plinths, high-tension power substation yards, and effluent treatment civil works from standard factory sheds.',
      },
      {
        'title': 'Vacant Residential & Commercial Plotted Land',
        'icon': Icons.crop_free,
        'method': 'Comparative Market Method Adjusted for Shape, Frontage & Depth',
        'useCases': 'Section 50C Tax Rebuttals, Layout Partition, Asset Division, Mortgage',
        'legal':
            'Auditing layout sanction numbers (HMDA / DTCP LP numbers), Master Plan zoning reservations, and road-widening buffer zones under municipal master plans.',
        'details':
            'Plots are appraised on a per-square-yard or per-square-foot basis. Irregular geometries, land-locked plots, or low-lying sites facing inundation receive calculated downward adjustments.',
      },
      {
        'title': 'Agricultural Land & Farm Holdings',
        'icon': Icons.agriculture,
        'method': 'Capitalized Net Agricultural Yield + Proximity Potential Comparison',
        'useCases': 'Family Estate Partition, Visa Financial Backing, Probate, Rural Land Sale',
        'legal':
            'Cross-checking state revenue land portals (Dharani in Telangana, Webland in AP), verifying Pattadar Passbooks, ROR 1-B title lineage, and checking tribal land non-alienation restrictions.',
        'details':
            'Evaluated on agricultural productivity (soil quality, irrigation sources) combined with future peri-urban non-agricultural (NALA) development conversion potential.',
      },
    ];

    final current = propertyTypes[_selectedPropertyTypeIndex];

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
                'ASSET-CLASS SPECIALIZATION',
                'Comprehensive Property-Type Valuation Coverage Matrix',
                'Tailored Technical Methodologies, Statutory Audits, and Legal Considerations Across 9 Distinct Real Estate Asset Classes',
              ),
              const SizedBox(height: 26),

              // Property Type Selector Tabs
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: propertyTypes.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final pt = entry.value;
                  final isSelected = idx == _selectedPropertyTypeIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPropertyTypeIndex = idx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? LandingTheme.brandGreen : _pureWhite,
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
                            Icon(
                              pt['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : _obsidian,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              pt['title'] as String,
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

              // Property Detail Showcase Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isDesktop ? 32 : 20),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(current['icon'] as IconData, color: LandingTheme.brandGreen, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current['title'] as String,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _obsidian,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Methodology: ${current['method']}',
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
                      'Technical Valuation Approach & Market Dynamics:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current['details'] as String,
                      style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.7),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Common Statutory & Commercial Use Cases:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current['useCases'] as String,
                      style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.6),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Legal, Regulatory & Municipal Considerations:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current['legal'] as String,
                      style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.6),
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
  // 5. HOW IS PROPERTY VALUE CALCULATED IN INDIA?
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMethodologySection(double screenW, bool isDesktop) {
    final methods = [
      {
        'title': '1. Sales Comparison Method (Market Approach)',
        'when': 'When an active secondary market exists with transparent, recent (within 6–12 months) arm\'s-length transactions of comparable properties in the identical micro-market.',
        'suited': 'Residential high-rise apartments, gated community villas, builder floors, and standard plotted developments.',
        'pros': 'Directly reflects current open-market buyer-seller equilibrium; universally recognized and favored by commercial banks, tax assessing officers, and courts.',
        'cons': 'Susceptible to distortion where historical registration records reflect under-declared cash consideration; difficult to apply when valuing highly unique or irregular structures.',
      },
      {
        'title': '2. Cost Approach (Depreciated Replacement Cost - DRC)',
        'when': 'When market transaction data is scarce, or when appraising specialized assets combining freehold land with customized improvements.',
        'suited': 'Independent residential bungalows, factory sheds, warehouses, school campuses, and institutional assets.',
        'pros': 'Highly objective, auditable, and mathematically transparent. Separates underlying land value (established via registry comparables) from building reproduction cost (calculated using official CPWD Plinth Area Rates less age depreciation).',
        'cons': 'Does not capture subjective micro-market premiums, prestige values, or hyper-inflated urban demand that outstrips brick-and-mortar reproduction costs.',
      },
      {
        'title': '3. Income Capitalization Method (Direct Yield)',
        'when': 'When real estate assets are primarily held for continuous commercial rental cash flows with documented historical tenancy.',
        'suited': 'High-street retail shops, tenanted bank branches, commercial office floors, and commercial complexes.',
        'pros': 'Directly models investor economic yield by dividing Net Operating Income (NOI) by the prevailing market Capitalization Rate (Cap Rate, typically 7%–9% across Indian Tier-1 commercial markets).',
        'cons': 'Vulnerable to lease renegotiation risks, extended tenant vacancies, and fluctuating municipal commercial property tax assessments.',
      },
      {
        'title': '4. Discounted Cash Flow (DCF) Method',
        'when': 'When appraising multi-year commercial assets characterized by scheduled lease escalations, phased capital expenditures, and predictable terminal liquidation.',
        'suited': 'Grade-A IT parks, regional shopping malls, SEZs, logistics parks, and hospitality real estate.',
        'pros': 'Accounts for the time value of money, contract-specific lock-in periods, and multi-tenant rental escalations over an explicit 5-to-10 year projection horizon aligned with Ind AS 113.',
        'cons': 'Highly sensitive to terminal capitalization rates, tenant renewal assumptions, and the Weighted Average Cost of Capital (WACC) discount rate.',
      },
      {
        'title': '5. Residual Land Method',
        'when': 'When assessing the financial viability and intrinsic value of raw land, infill sites, or obsolete structures ripe for redevelopment.',
        'suited': 'Greenfield development acreage, urban infill redevelopment plots, and joint development agreements (JDAs).',
        'pros': 'Identifies the maximum justifiable acquisition price for land by subtracting all construction expenses, HMDA/GHMC municipal sanction costs, financing charges, and developer profit margins from projected Gross Development Value (GDV).',
        'cons': 'Compounding sensitivity: minor fluctuations in material costs, approval timelines, or absorption sales prices drastically distort the residual land value.',
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
                'MATHEMATICAL APPARATUS & INDUSTRY STANDARDS',
                'How Is Property Value Calculated in India?',
                'An In-Depth Analysis of the 5 Institutional Valuation Methodologies Recognized Under Indian Law and CPWD Guidelines',
              ),
              const SizedBox(height: 24),

              Text(
                'Property valuation is an exact applied science combining civil engineering, economics, and statutory law. Under Indian valuation standards (governed by the Companies Act, Wealth Tax Rules, and CPWD Manuals), valuers do not rely on subjective guesswork. Every figure certified in a ProValuer report is derived from one or more of the five recognized mathematical methodologies, chosen specifically to fit the physical and legal reality of the property:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 5 Method Cards
              Column(
                children: methods.map((m) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _lightBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title']!,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _obsidian,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildMethodBullet('When Used:', m['when']!),
                        _buildMethodBullet('Applicable Property Types:', m['suited']!),
                        _buildMethodBullet('Key Advantages:', m['pros']!),
                        _buildMethodBullet('Limitations:', m['cons']!),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // H3 Section: Which Methodology Do Valuers Use Most Frequently?
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: LandingTheme.brandGreen.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: LandingTheme.brandGreen, size: 26),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Which Valuation Methodology Do Government Approved Valuers Use Most Frequently?',
                            style: GoogleFonts.montserrat(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: _obsidian,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'In professional Indian valuation practice, Government Approved Valuers registered under Section 34AB of the Wealth Tax Act and IBBI do not select methodologies arbitrarily. They deploy a structured **Methodology Selection Framework** governed by the triad of asset characteristics, market liquidity, and the specific statutory purpose of the valuation:',
                      style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.7),
                    ),
                    const SizedBox(height: 12),
                    _buildSelectionBullet(
                      '1. Urban Apartments & High-Rise Flats:',
                      'The **Sales Comparison Method** is used 95% of the time, combined with an Undivided Share of Land (UDS) allocation. The unit value is cross-verified against the state Sub-Registrar guideline value to ensure it satisfies stamp duty minimums.',
                    ),
                    _buildSelectionBullet(
                      '2. Freehold Independent Houses & Industrial Assets:',
                      'The **Cost Approach (DRC Method)** is the primary standard. The valuer evaluates the freehold land parcel using sales comparables, and independently computes building reproduction cost using official CPWD Plinth Area Rates, subtracting depreciation based on age and maintenance.',
                    ),
                    _buildSelectionBullet(
                      '3. Statutory & Taxation Mandates (Sec 50C & 55A):',
                      'Tax authorities and appellate tribunals require empirical, mathematically transparent valuations. For ancestral properties (Sec 55A), valuers reconstruct the historical 2001 Fair Market Value using 2001 circle rates and CPWD cost indices. For Sec 50C circle rate challenges, valuers combine market sales with defect adjustments.',
                    ),
                    _buildSelectionBullet(
                      '4. Banking & Mortgage Security (SARFAESI):',
                      'Valuers execute a dual-methodology reconciliation (Market Approach + Cost Approach) to derive three distinct values: Fair Market Value (FMV), Realizable Value (RV, typically 10%–15% lower), and Distress Sale Value (DSV, typically 25%–35% lower for 90-day forced liquidation).',
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

  Widget _buildMethodBullet(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.55),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w700, color: _obsidian)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBullet(String heading, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: LandingTheme.brandGreen, fontWeight: FontWeight.w900, fontSize: 16)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.6),
                children: [
                  TextSpan(text: '$heading ', style: const TextStyle(fontWeight: FontWeight.w700, color: _obsidian)),
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
  // 6. STATUTORY & REGULATORY FRAMEWORK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRegulatoryFrameworkSection(double screenW, bool isDesktop) {
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
                'TAX LITIGATION & JUDICIAL DEFENSE',
                'Statutory & Regulatory Framework for Property Appraisals in India',
                'Essential Defenses Under Section 50C, Section 55A, Section 56(2)(x), and Indian Evidence Act Section 45',
              ),
              const SizedBox(height: 24),

              Text(
                'The Indian Income Tax Act, 1961 contains strict anti-tax avoidance mechanisms that heavily penalize property transactions occurring below government circle rates (Guideline Values). In these high-stakes disputes, the opinion of an uncertified real estate broker or private chartered accountant carries zero evidentiary standing. A certified valuation report from a Section 34AB Government Approved Valuer provides statutory immunity, establishing true commercial reality before Assessing Officers, the Commissioner of Income Tax (Appeals), and the Income Tax Appellate Tribunal (ITAT):',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 4 Regulatory Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildFrameworkDeepCard(
                        colW,
                        'Section 50C: Rebutting Inflated SRO Circle Rates',
                        'When an immovable property is transferred for a consideration lower than the state stamp duty circle rate, the circle rate is legally deemed the full sale consideration for calculating capital gains. However, under Section 50C(2), the taxpayer has the statutory right to challenge this valuation if the circle rate exceeds true fair market value due to physical defects, road-width restrictions, land-locking, or litigation. Our reports substantiate the physical and market reality, enabling the Assessing Officer to refer the matter to the Departmental Valuation Officer (DVO) or adopt our certified Fair Market Value.',
                        Icons.shield,
                      ),
                      _buildFrameworkDeepCard(
                        colW,
                        'Section 55A: Determining Baseline FMV as of April 1, 2001',
                        'For ancestral properties or assets acquired before April 1, 2001, taxpayers are entitled to substitute historical Fair Market Value as on April 1, 2001 for computing the Indexed Cost of Acquisition. As per the Finance Act, this FMV cannot exceed the stamp duty circle rate as of April 1, 2001. Our valuers access historical Sub-Registrar archives, municipal records, and CPWD construction indices to establish the highest defensible 2001 baseline value, legally mitigating capital gains liabilities.',
                        Icons.history,
                      ),
                      _buildFrameworkDeepCard(
                        colW,
                        'Section 56(2)(x): Shielding Buyers from "Deemed Gifts"',
                        'Under Section 56(2)(x), if a buyer purchases property for an amount less than the stamp duty guideline value (by more than the statutory 10% safe harbor threshold or ₹50,000), the difference is taxed in the hands of the buyer as "Income from Other Sources". Our certified reports document legitimate structural dilapidation, easement liabilities, or distress factors that justify the commercial purchase discount, protecting buyers from unjustified tax additions.',
                        Icons.gavel,
                      ),
                      _buildFrameworkDeepCard(
                        colW,
                        'Indian Evidence Act Section 45: Expert Witness Testimony',
                        'Under Section 45, courts require expert opinion when deciding questions of science, art, or technical identity. A Section 34AB Government Approved Valuer is recognized by High Courts and civil tribunals as an expert technical witness. In partition suits, testamentary probate disputes, execution petitions, and matrimonial settlements under the Family Courts Act, our certified reports are admitted as primary documentary evidence without secondary verification.',
                        Icons.balance,
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

  Widget _buildFrameworkDeepCard(double width, String title, String body, IconData icon) {
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
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. DOCUMENTS REQUIRED FOR PROPERTY VALUATION & 6 FATAL MISTAKES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentationSection(double screenW, bool isDesktop) {
    final docs = [
      {
        'title': 'Registered Title Deeds (Sale, Gift, Partition, Settlement)',
        'desc': 'Primary registered conveyance establishing absolute title ownership, total extent, and undivided land share (UDS).',
      },
      {
        'title': 'Encumbrance Certificate (EC Form 15 for 15–30 Years)',
        'desc': 'Issued by the Registration and Stamps Department proving continuous transaction history and absence of registered court attachments or liens.',
      },
      {
        'title': 'Latest Municipal Property Tax Assessment & Receipts',
        'desc': 'Issued by GHMC, local Municipal Corporation, or Gram Panchayat showing property tax identification number (PTIN) and current year dues clearance.',
      },
      {
        'title': 'Approved Building Sanction Plan & Occupancy Certificate (OC)',
        'desc': 'Architectural blueprint approved by HMDA, GHMC, DTCP, or local planning body alongside the statutory completion or occupancy certificate.',
      },
      {
        'title': 'Pattadar Passbook & Dharani / Webland Records (For Land)',
        'desc': 'Title deed passbook, Dharani ROR 1-B extract, Pahani / Khasra extract, and village survey map for agricultural or non-agricultural land.',
      },
      {
        'title': 'Prior Chain of Title Deeds (Link Documents for 30 Years)',
        'desc': 'Essential for ancestral or freehold properties to establish an unbroken chain of lawful title succession from original pattadars or developers.',
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
                'DOCUMENTARY VERIFICATION CRITERIA',
                'Documents Required for Property Valuation in India',
                'Mandatory Legal Dossiers, Chain of Title Scrutiny, and Analysis of Common Documentation Mistakes',
              ),
              const SizedBox(height: 24),

              Text(
                'A rigorous property appraisal begins with forensic document scrutiny. An approved valuer does not merely measure walls; they verify that the physical structure standing on the ground conforms strictly to the registered title deed and municipal sanction plans. Below is the primary document checklist required for initiating an official valuation:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 6 Document Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: docs.map((d) {
                      return Container(
                        width: colW,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _lightBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderSubtle),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: LandingTheme.brandGreen, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['title']!,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _obsidian,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    d['desc']!,
                                    style: GoogleFonts.inter(fontSize: 12.5, color: _slateText, height: 1.55),
                                  ),
                                ],
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

              // 6 Fatal Documentation Mistakes Alert Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _lightBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          '6 Fatal Documentation Mistakes That Lead to Valuation Rejections',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMistakeRow('1. Mismatch Between Physical Boundaries and Deed Schedule:', 'When physical boundary walls enclose more or less land than specified in the registered sale deed schedule. Valuers must certify only lawful deed area.'),
                    _buildMistakeRow('2. Submitting Short-Term ECs (e.g. 1–3 Years):', 'Lenders and courts require a minimum 15 to 30-year continuous search to confirm no prior mortgages or ancestral partition encumbrances exist.'),
                    _buildMistakeRow('3. Unapproved Construction Floors (Setback Violations):', 'Structures built beyond sanctioned municipal floor plans (e.g. unapproved 4th floor or penthouse) cannot be assigned full replacement value without noting demolition risk.'),
                    _buildMistakeRow('4. Missing Link Deeds in Ancestral Properties:', 'Failing to establish continuous ownership lineage from the original pattadar creates severe legal title defects in court and probate submissions.'),
                    _buildMistakeRow('5. Agricultural Land Without Formal NALA Conversion:', 'Attempting to value rural farm plots as residential housing sites without official Non-Agricultural Land Assessment (NALA) conversion orders.'),
                    _buildMistakeRow('6. Concealing Existing Bank Mortgages:', 'Failing to declare an existing lien or home loan on the property. Undisclosed encumbrances discovered during registry search lead to immediate report invalidation.'),
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
  // 8. HYDERABAD / TELANGANA PROPERTY VALUATION PRACTICE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRegionalPracticeSection(double screenW, bool isDesktop) {
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
                'REGIONAL HYDERABAD & TELANGANA EXPERTISE',
                'Local Property Valuation Practice: HMDA, GHMC, Dharani & IGRS Telangana',
                'Deep Familiarity with Regional Micro-Markets, Urban Master Plans, and Revenue Portals Across Hyderabad & South India',
              ),
              const SizedBox(height: 24),

              Text(
                'Property valuation in Hyderabad and Telangana requires deep, nuanced comprehension of local urban planning regulations, land record digitization platforms, and regional infrastructure corridors. Valuation parameters in the hyper-growth IT corridor of Cyberabad differ radically from historic Cantonment zones in Secunderabad or agricultural belts in Ranga Reddy and Medchal districts. ProValuer Commercial maintains dedicated practice teams with direct operational familiarity across all state regulatory bodies:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 4 Local Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildLocalPillarCard(
                        colW,
                        'HMDA Master Plan 2031 & Growth Corridors',
                        'Expertise across Hyderabad Metropolitan Development Authority (HMDA) zoning designations: Residential, Commercial, Peri-Urban, and Bio-Conservation Zones. Appraising prime high-growth corridors along the Outer Ring Road (ORR), Kokapet Neopolis, Tellapur, Nanakramguda, and Puppalguda.',
                        Icons.map,
                      ),
                      _buildLocalPillarCard(
                        colW,
                        'GHMC Building Bylaws & Layout Regularization',
                        'Navigating Greater Hyderabad Municipal Corporation (GHMC) regulations: Floor Space Index (FSI) allowances, transferable development rights (TDR), building sanction verification, property tax PIN numbers, and Layout Regularization Scheme (LRS / BRS) title clearances.',
                        Icons.apartment,
                      ),
                      _buildLocalPillarCard(
                        colW,
                        'Dharani Integrated Land Records System',
                        'Direct integration with Telangana’s Dharani portal for agricultural land parcels across Ranga Reddy, Sangareddy, Medchal, and Yadadri Bhuvanagiri districts. Auditing digital Pattadar Passbooks, mutation registers, and Non-Agricultural Land Assessment (NALA) conversions.',
                        Icons.landscape,
                      ),
                      _buildLocalPillarCard(
                        colW,
                        'IGRS Telangana Market Value Guidelines',
                        'Comprehensive benchmarking against the Registration and Stamps Department (IGRS Telangana) market value tables across key Sub-Registrar Offices (SRO Banjara Hills, SRO Serilingampally, SRO Gandipet, SRO Shamshabad). Identifying disparities between guideline values and fair market rates for Sec 50C defenses.',
                        Icons.account_balance,
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

  Widget _buildLocalPillarCard(double width, String title, String body, IconData icon) {
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
  // 9. THE PROVALUER 4-STAGE VALUATION PROTOCOL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProtocolSection(double screenW, bool isDesktop) {
    final stages = [
      {
        'step': 'STAGE 01',
        'title': 'Document Scrutiny & Statutory Title Audit',
        'desc': 'Client submits registered title deeds, 15 to 30-year Encumbrance Certificates, municipal tax receipts, and building sanction blueprints. Our legal-technical team conducts a preliminary title search, verifying ownership lineage, municipal regularity, and identifying any active mortgage liabilities.',
      },
      {
        'step': 'STAGE 02',
        'title': 'Forensic On-Site Physical Inspection & Geo-Tagging',
        'desc': 'Our certified engineering valuer visits the property in person. We capture laser plinth measurements, audit boundary alignments against deed schedules, evaluate construction quality and maintenance, and record high-resolution color photographs with embedded GPS coordinates and timestamps.',
      },
      {
        'step': 'STAGE 03',
        'title': 'Algorithmic Valuation Modeling & SRO Cross-Audit',
        'desc': 'Deploying the Sales Comparison Approach for land and CPWD Depreciated Replacement Cost models for building structures, our analysts compute Fair Market Value and Realizable Value. All figures are cross-audited against local SRO circle rates and registered transaction comparables.',
      },
      {
        'step': 'STAGE 04',
        'title': 'Issuance of Certified Dossier with Secure QR Verification',
        'desc': 'The report is executed under Section 34AB seal and IBBI registration, signed by our Fellow Valuer. We generate a tamper-evident digital QR code linked to our secure verification server. Client receives high-resolution signed digital PDFs alongside stamped bound physical dossiers within 24 to 48 hours.',
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
                'RIGOROUS FORENSIC METHODOLOGY',
                'The ProValuer 4-Stage Valuation Protocol',
                'Systematized Operational Workflow Engineered for Speed, Complete Legal Precision, and Unconditional Statutory Admissibility',
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
                          color: _lightBg,
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
        'q': 'What is the legal difference between a property valuation report issued by a Government Approved Valuer and a market appraisal from a real estate broker?',
        'a': 'A market appraisal from a real estate broker is merely a commercial opinion with zero statutory accreditation. It is inadmissible in courts, rejected by the Income Tax Department for capital gains assessments, and discarded by nationalized banks. Conversely, a Government Approved Valuer is registered under Section 34AB of the Wealth Tax Act, 1957 by the Central Board of Direct Taxes (CBDT) and Section 247 of the Companies Act, 2013 by the IBBI. Under Section 45 of the Indian Evidence Act, 1872, reports issued by Government Approved Valuers are recognized as expert technical testimony, carrying binding legal evidentiary standing across all courts, tribunals, and banking institutions.',
      },
      {
        'q': 'How is the Fair Market Value (FMV) of an ancestral property calculated for capital gains tax under Section 55A?',
        'a': 'For properties acquired before April 1, 2001, Section 55A allows taxpayers to adopt the Fair Market Value as of April 1, 2001 to compute indexed acquisition costs. ProValuer reconstructs this historical FMV by accessing historical Sub-Registrar Office (SRO) market guideline values from 2001, cross-referencing registered sale comparables from that era, and applying the CPWD Cost Inflation Index for structural plinth reproduction. Under current tax laws, this 2001 FMV cannot exceed the stamp duty circle rate as of April 1, 2001.',
      },
      {
        'q': 'Can I challenge a stamp duty circle rate notice from the Income Tax Department using a private valuation report under Section 50C?',
        'a': 'Yes. Under Section 50C(2) of the Income Tax Act, if you claim before the Assessing Officer (AO) that the government circle rate exceeds the true fair market value of the property due to physical defects, road-width restrictions, land-locking, or legal disputes, the AO is required to refer the valuation to a Departmental Valuation Officer (DVO). A certified valuation report from a Section 34AB Government Approved Valuer provides the technical and mathematical evidence necessary to sustain this claim and rebut arbitrary tax additions.',
      },
      {
        'q': 'Why do foreign embassies require a property valuation certificate for student and tourist visa applications?',
        'a': 'Under international immigration rules (such as Section 214(b) of the US Immigration and Nationality Act), visa applicants must prove strong economic ties to their home country and demonstrate sufficient financial solvency without resorting to unauthorized employment. Immovable property represents the strongest non-liquid proof of financial roots in India. Consulates mandate that these reports be issued by Government Approved Valuers with official registration numbers and dual-currency translations (INR + foreign currency).',
      },
      {
        'q': 'How do valuers determine the value of a flat when the building is several decades old?',
        'a': 'For older apartments, valuers separate the value into two distinct components: the Undivided Share of Land (UDS) and the depreciated building structure. While the building structure experiences physical depreciation based on its age and CPWD depreciation schedules, the underlying UDS often appreciates substantially in prime urban locations. In many mature neighborhoods, the UDS alone accounts for 75% to 85% of the total flat value.',
      },
      {
        'q': 'Is an on-site physical inspection mandatory to obtain a certified government approved valuation report?',
        'a': 'Yes. Physical inspection is an absolute statutory requirement. Consular fraud prevention units, commercial banks, and judicial courts strictly reject "desktop valuations." Our certified valuers conduct an on-ground physical inspection to measure plinth areas, evaluate construction quality, audit physical boundaries, and record high-resolution color photographs with embedded GPS coordinates and timestamps.',
      },
      {
        'q': 'What is Undivided Share of Land (UDS) and how does it affect the final valuation of an apartment in Hyderabad?',
        'a': 'Undivided Share of Land (UDS) represents the proportionate fraction of the total land plot legally owned by each individual flat owner in an apartment complex. In Hyderabad (governed by HMDA and GHMC regulations), UDS is explicitly registered in square yards on the sale deed. A higher UDS allocation significantly enhances the long-term capital value and redevelopment potential of an apartment, protecting the owner against structural depreciation.',
      },
      {
        'q': 'How long is a certified property valuation report valid for bank collateral and legal proceedings?',
        'a': 'For commercial bank collateral and mortgage lending, valuation reports typically remain valid for 12 months under RBI guidelines, although banks may request re-validation after 6 months in volatile micro-markets. For judicial proceedings, probate petitions, and capital gains tax filings (Section 50C/55A), the report remains valid for the specific historical valuation date or transaction date assessed.',
      },
      {
        'q': 'Can agricultural land be included in an asset valuation report for immigration and net worth certification?',
        'a': 'Yes. Ancestral agricultural land and farm parcels represent legitimate, highly valued assets for establishing financial solvency and permanent ties to India. For agricultural land, our reports verify digital land registry records (such as the Dharani portal in Telangana or Webland in AP), audit Pattadar Passbooks, verify village survey maps, and apply crop yield capitalization to determine market value.',
      },
      {
        'q': 'What are the key documents required if the property owner is an NRI residing outside India?',
        'a': 'If the property owner is an NRI, they must provide the registered title deeds, Encumbrance Certificate, latest municipal tax receipts, and a registered General Power of Attorney (GPA) or Special Power of Attorney (SPA) executed before an Indian Embassy/Consulate or legally adjudicated in India, authorizing a local family representative to present the property for physical inspection.',
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
                'FREQUENTLY ASKED QUESTIONS',
                'Statutory Property Valuation FAQs',
                'Authoritative Answers to the 10 Most Critical Questions Encountered by Property Owners, Taxpayers, and Legal Advocates',
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
                      color: isExpanded ? _pureWhite : _pureWhite,
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
                  'EXECUTIVE VALUATION DESK',
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
                'Commission Your Certified Property Valuation Today',
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
                  'Official, court-admissible valuation reports executed by Government Approved Valuers (Section 34AB) and IBBI Registered Valuers. Guaranteed 24 to 48-hour delivery across Hyderabad, Telangana, and South India. Complete professional indemnity and confidentiality.',
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
                      'Hello ProValuer Commercial, I would like to schedule a certified property valuation.',
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
                'Registered Valuers under Wealth Tax Act 1957 (Section 34AB) & Companies Act 2013 (Section 247)',
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
                              'Institutional property appraisals and certified valuation reports for capital gains tax, banking mortgage security, immigration solvency, and judicial court proceedings across India.',
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
                            _buildFooterLink('Property Valuation Services', () => context.go('/services/property-valuation')),
                            _buildFooterLink('Share & Equity Valuation', () => context.go('/services/share-valuation')),
                            _buildFooterLink('Visa & Immigration Valuations', () => context.go('/services/visa-and-immigration-valuations')),
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                          ],
                        ),
                      ),

                      // Col 3: Statutory Domains & Future Pages
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUTORY SCOPE',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooterText('Income Tax Section 50C & 55A'),
                            _buildFooterLink('Family Court Matrimonial Valuations', () => context.go('/services/divorce-matrimonial-valuation')),
                            _buildFooterLink('High Court Probate & Succession', () => context.go('/services/probate-inheritance-valuation')),
                            _buildFooterText('SARFAESI Bank Collateral Security'),
                            _buildFooterText('NCLT & IBC Insolvency Appraisals'),
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
