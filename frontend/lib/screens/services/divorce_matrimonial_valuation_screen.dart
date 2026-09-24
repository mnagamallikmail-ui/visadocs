import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';

/// Professional Service Page: Property Valuation for Divorce & Matrimonial Asset Division
/// Canonical URL: https://www.provaluer.in/services/divorce-matrimonial-valuation
/// Target Word Count: 4,900 - 6,000 words of dense, institutional, court-admissible legal prose.
class DivorceMatrimonialValuationScreen extends StatefulWidget {
  const DivorceMatrimonialValuationScreen({super.key});

  @override
  State<DivorceMatrimonialValuationScreen> createState() => _DivorceMatrimonialValuationScreenState();
}

class _DivorceMatrimonialValuationScreenState extends State<DivorceMatrimonialValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedAssetIndex = 0;
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

                // 2. Statutory Legal Framework & Court Admissibility
                _buildStatutoryFrameworkSection(screenW, isDesktop),

                // 3. How Is Property Divided During Divorce in India?
                _buildPropertyDivisionRulesSection(screenW, isDesktop),

                // 4. Multi-Asset Matrimonial Valuation Coverage (Interactive)
                _buildAssetCoverageSection(screenW, isDesktop),

                // 5. Forensic Asset Tracing & Concealment Detection
                _buildForensicTracingSection(screenW, isDesktop),

                // 6. Net Equity Formulation: Balancing Assets Against Debts
                _buildNetEquitySection(screenW, isDesktop),

                // 7. Documents Required for Matrimonial Valuation & Deficiencies
                _buildDocumentationSection(screenW, isDesktop),

                // 8. Regional Practice: Hyderabad, Telangana & South India Courts
                _buildRegionalPracticeSection(screenW, isDesktop),

                // 9. The ProValuer 4-Stage Matrimonial Valuation Protocol
                _buildProtocolSection(screenW, isDesktop),

                // 10. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 11. High-Touch Executive Consultation Block
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
                  'Hello ProValuer Commercial, I require a confidential, court-admissible matrimonial property valuation report.',
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
                        'Family Advisory Desk',
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
                        _buildNavAction('Property Valuation', () => context.go('/services/property-valuation')),
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
                          'Hello ProValuer Commercial, I need an official property valuation report for a family court divorce proceeding.',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: LandingTheme.brandGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confidential Consultation',
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
                      'FAMILY COURTS ACT 1984 · INDIAN EVIDENCE ACT SEC 45 · IBBI REGISTERED VALUERS',
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
                'Certified Matrimonial Property & Asset Valuation Reports for Divorce Settlements in India',
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
                'Court-admissible, independent forensic appraisals of residential real estate, commercial holdings, closely held family businesses, unlisted equity, agricultural acreage, and Stridhan for divorce proceedings and mutual settlements. Executed by Government Approved Valuers under Section 34AB of the Wealth Tax Act, 1957 and Registered Valuers under Section 247 of the Companies Act, 2013. Designed strictly in conformity with Section 45 of the Indian Evidence Act, 1872 and landmark Supreme Court mandates (Rajnesh v. Neha). Providing Family Court judges, legal advocates, and mediators with indisputable, impartial Net Equity Formulations to resolve spousal buyout equity, permanent alimony, and maintenance disputes with complete professional confidentiality.',
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
                  _buildTrustBadge('Court Admissible (Sec 45)', 'Admissible Before Family & High Courts'),
                  _buildTrustBadge('Strict NDA & Privilege', '100% Confidential Spousal Dossiers'),
                  _buildTrustBadge('Net Distributable Equity', 'Deducting Active Mortgages & Debts'),
                  _buildTrustBadge('Supreme Court Mandate', 'Fully Compliant with Rajnesh v. Neha'),
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
      {'val': '3,500+', 'label': 'Matrimonial Appraisals', 'sub': 'Mutual Settlements & Contested Suits'},
      {'val': '100% Admissible', 'label': 'Family Court Standing', 'sub': 'Evidence Act Sec 45 Expert Reports'},
      {'val': 'Multi-Asset', 'label': 'Comprehensive Audits', 'sub': 'Property, Equity, Stridhan & Land'},
      {'val': '24–48 Hrs', 'label': 'Confidential Issuance', 'sub': 'Digital QR Dossier + Bound Stamp'},
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
  // 2. STATUTORY LEGAL FRAMEWORK & COURT ADMISSIBILITY
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
                'JUDICIAL STATUTES & EVIDENTIARY PRINCIPLES',
                'Statutory Legal Framework & Court Admissibility of Valuation Reports',
                'Legal Grounding Under the Family Courts Act 1984, Indian Evidence Act Section 45, and Hindu Marriage Act Sections 25 & 27',
              ),
              const SizedBox(height: 24),

              Text(
                'In Indian matrimonial litigation, property disputes are adjudicated under a sophisticated matrix of procedural and personal laws. Family Courts operate under a statutory mandate to promote amicable conciliation while ensuring equitable financial justice. When divorcing spouses present wildly divergent estimates of marital property, the court cannot rely on subjective affidavits or informal real estate broker quotes. Under Indian evidentiary jurisprudence, only certified technical reports executed by qualified independent experts carry formal evidentiary weight.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'ProValuer Commercial structures its matrimonial valuation reports in strict compliance with the statutory anchors governing Indian family law:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 4 Framework Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildFrameworkCard(
                        colW,
                        'Family Courts Act, 1984 (Sections 9, 10 & 14)',
                        'Section 9 mandates Family Courts to make proactive efforts for settlement and conciliation. A neutral, certified valuation report serves as an impartial factual baseline for mediators and judges. Under Section 14, Family Courts are empowered to receive any technical report or expert statement that assists in effectively resolving the dispute, giving certified valuation dossiers primary consideration.',
                        Icons.gavel,
                      ),
                      _buildFrameworkCard(
                        colW,
                        'Indian Evidence Act, 1872 (Section 45)',
                        'Section 45 establishes that opinions of skilled technical experts regarding science, art, or asset identification are relevant facts admissible in evidence. A Section 34AB Government Approved Valuer acts as an independent expert witness. Our reports are accompanied by expert affidavits and are thoroughly fortified to withstand cross-examination by opposing counsel.',
                        Icons.verified,
                      ),
                      _buildFrameworkCard(
                        colW,
                        'Hindu Marriage Act, 1955 (Sections 25 & 27)',
                        'Section 27 empowers the court to make just provisions regarding property presented at or about the time of marriage belonging jointly to both spouses. Under Section 25, the court determines permanent alimony and maintenance having regard to the respondent’s own income and other property, mandating accurate asset appraisal to prevent spousal under-declaration.',
                        Icons.balance,
                      ),
                      _buildFrameworkCard(
                        colW,
                        'Supreme Court Mandate (Rajnesh v. Neha, 2020)',
                        'The Supreme Court of India established compulsory filing of Affidavits of Assets and Liabilities by both parties in matrimonial disputes. False asset declarations or failure to disclose fair market values attract perjury and contempt proceedings. ProValuer reports provide the certified documentary evidence required to populate Part C (Immovable Assets) and Part D (Investments & Movables).',
                        Icons.account_balance,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 26),

              Text(
                'Similar equitable principles govern matrimonial property settlement under Section 37 of the Special Marriage Act, 1954 and Section 39/40 of the Indian Divorce Act, 1869, ensuring universal court admissibility across all religious and civil jurisdictions in India.',
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
  // 3. HOW IS PROPERTY DIVIDED DURING DIVORCE IN INDIA?
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPropertyDivisionRulesSection(double screenW, bool isDesktop) {
    final rules = [
      {
        'title': '1. Self-Acquired Property (Separate Ownership vs Maintenance)',
        'legal': 'Under Indian law (unlike Western community property regimes), property acquired by one spouse in their sole name using their own funds remains their absolute separate property under Section 14 of the Hindu Succession Act. The other spouse possesses no automatic legal claim to the title.',
        'dispute': 'The non-titled spouse routinely claims indirect economic contributions—such as unpaid domestic labor, funding household expenses, or financing renovations—demanding a financial share.',
        'valuation': 'While courts cannot forcibly transfer sole title, an independent valuation establishes the owner\'s true capital base, enabling judges to award substantial lump-sum permanent alimony or maintenance under Section 25 HMA.',
      },
      {
        'title': '2. Jointly Owned Property (Co-Ownership & Buyout Equity)',
        'legal': 'Property purchased jointly in both spouses\' names is co-owned. The legal presumption is equal 50:50 ownership unless the registered deed specifies explicit unequal fractions or bank statements prove disparate contribution.',
        'dispute': 'Severe deadlocks arise when one spouse contributed 90% of the funds while the other contributed 10%, leading to disputes over whether division should follow legal deed title (50:50) or financial contribution equity.',
        'valuation': 'An impartial valuation determines the precise Spousal Buyout Equity (the exact cash consideration one spouse must pay to extinguish the other’s registered share) or sets the auction reserve price if sold.',
      },
      {
        'title': '3. Stridhan (Absolute Female Ownership & Section 27 HMA)',
        'legal': 'Under Section 14 of the Hindu Succession Act and Supreme Court jurisprudence (Pratibha Rani v. Suraj Kumar), Stridhan—including gold jewellery, silver, cash gifts, and assets presented at or about marriage—is the woman\'s absolute personal property. Refusing to return it constitutes criminal breach of trust under Section 406 IPC.',
        'dispute': 'Husbands or in-laws denying possession, claiming items were sold to fund joint living expenses, or disputing gold weight, purity, and authenticity.',
        'valuation': 'Certified assay valuation of gold bullion and precious stones using current hallmark rates establishes an indisputable financial recovery claim under Section 27 of the Hindu Marriage Act.',
      },
      {
        'title': '4. Ancestral Property (Coparcenary Rights vs Alimony)',
        'legal': 'Ancestral property inherited across four generations of male lineage belongs to the Hindu Coparcenary. An estranged spouse holds zero direct coparcenary claim over their husband’s or wife’s ancestral family holdings.',
        'dispute': 'Spouses attempting to attach ancestral family estates; husbands attempting to conceal self-acquired real estate by falsely labeling it as Hindu Undivided Family (HUF) or ancestral property.',
        'valuation': 'Independent title audits trace the chain of acquisition to separate genuine ancestral estates from self-acquired assets, isolating the husband\'s undivided coparcenary share to gauge financial capacity for alimony.',
      },
      {
        'title': '5. Loan-Backed Assets (Mortgaged Properties & Net Equity)',
        'legal': 'Real estate backed by an active joint bank mortgage represents gross asset value offset by secured debt. Legal title cannot be cleanly transferred or partitioned without the lending bank\'s written consent, discharge of charge, or loan refinancing.',
        'dispute': 'One spouse abandoning EMI payments while demanding 50% market value; disputes over credit score contamination; disagreements on how to divide future appreciation against past debt service.',
        'valuation': 'Valuers formulate Net Distributable Equity by deducting the certified outstanding principal loan balance, accrued interest, and prepayment penalties from the Gross Fair Market Value, preventing unfair windfalls.',
      },
      {
        'title': '6. Why Independent Valuation Matters (Overcoming Subjective Distortions)',
        'legal': 'In contested divorces, spousal valuation claims are intrinsically distorted: husbands routinely undervalue properties by 40%–60% citing outdated circle rates to depress maintenance, while wives frequently cite inflated speculative portal listings.',
        'dispute': 'Protracted negotiation deadlocks during court-ordered mediation (Section 9 Family Courts Act) and Lok Adalat proceedings.',
        'valuation': 'A certified appraisal by a Section 34AB Government Approved Valuer establishes an indisputable, evidence-backed benchmark admissible under Section 45 of the Indian Evidence Act, breaking deadlocks and enabling amicable Section 13B mutual consent settlements.',
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
                'PROPERTY DIVISION JURISPRUDENCE',
                'How Is Property Divided During Divorce in India?',
                'Legal Principles, Common Disputes, and Valuation Implications Across 6 Core Property Classifications',
              ),
              const SizedBox(height: 24),

              Text(
                'India does not operate under a statutory community property system. Dividing marital wealth requires navigating a complex interplay between registered title deeds, personal succession acts, financial contribution records, and judicial precedents. Below is an authoritative breakdown of how Indian courts treat different property categories and how independent valuation resolves disputes:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // 6 Property Division Cards
              Column(
                children: rules.map((r) {
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
                          r['title']!,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _obsidian,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRuleBullet('Legal Principles:', r['legal']!),
                        _buildRuleBullet('Common Disputes:', r['dispute']!),
                        _buildRuleBullet('Valuation Implications:', r['valuation']!),
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

  Widget _buildRuleBullet(String label, String value) {
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. MULTI-ASSET MATRIMONIAL VALUATION COVERAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAssetCoverageSection(double screenW, bool isDesktop) {
    final assetClasses = [
      {
        'title': 'Residential Apartments & Condos',
        'icon': Icons.apartment,
        'method': 'Sales Comparison Method + Undivided Share of Land (UDS) Audit',
        'challenges':
            'Disputes over whether to partition physical space or execute a spousal buyout; assessing value of high-end interior woodwork; factoring active joint home loans.',
        'scope':
            'Auditing registered deed UDS percentage, verifying RERA carpet area, analyzing recent tower sales, and determining the exact net equity for title release deeds.',
      },
      {
        'title': 'Independent Freehold Houses & Bungalows',
        'icon': Icons.home,
        'method': 'Land Market Comparables + CPWD Depreciated Replacement Cost (DRC)',
        'challenges':
            'Determining structural divisibility (can the bungalow be physically split between spouses vs sold); setback violations; unapproved upper floors.',
        'scope':
            'Separating freehold land market value from building structure. In ancestral bungalows, tracing chain of title to isolate coparcenary claims from marital investments.',
      },
      {
        'title': 'Luxury Gated Villas',
        'icon': Icons.villa,
        'method': 'Hedonic Pricing + Clubhouse/Amenity Loading',
        'challenges':
            'Exorbitant personal customization costs; high ongoing society maintenance liabilities; illiquidity of ultra-luxury real estate in divorce timelines.',
        'scope':
            'Isolating baseline villa construction costs from luxury interior embellishments, verifying layout sanction approvals, and calculating fair spousal exit consideration.',
      },
      {
        'title': 'Commercial Real Estate & Showrooms',
        'icon': Icons.storefront,
        'method': 'Income Capitalization Method (Yield) + DCF Modeling',
        'challenges':
            'Spouses concealing cash rental yields; informal tenancy agreements; tenant lock-in clauses; evaluating non-compete commercial goodwill.',
        'scope':
            'Capitalizing net operating rental income (NOI) using prevailing commercial capitalization rates (7.5%–9.5%), checking GST lease invoices, and auditing lease renewals.',
      },
      {
        'title': 'Closely Held Family Businesses (Pvt Ltd & LLPs)',
        'icon': Icons.business,
        'method': 'Net Asset Value (NAV) + Price-to-Earnings Multipliers / DCF',
        'challenges':
            'Spouses artificially deflating business profitability, siphoning company funds into personal accounts, or inflating family salaries to suppress marital net worth.',
        'scope':
            'Forensic financial statement analysis under Section 247 of Companies Act, normalizing director compensation, auditing fixed asset registers, and valuing company equity.',
      },
      {
        'title': 'Unlisted Shares & Start-Up ESOPs',
        'icon': Icons.trending_up,
        'method': 'Rule 11UA (Income Tax) & Fair Value under Ind AS 113',
        'challenges':
            'Vesting schedules of tech startup ESOPs; illiquidity discounts; post-separation valuation increases vs marital efforts; minority shareholder discounts.',
        'scope':
            'Appraising unlisted securities, convertible debentures, and vested stock options, balancing pre-decree equity rights against contingent future liquidations.',
      },
      {
        'title': 'Stridhan Gold Jewellery & Diamonds',
        'icon': Icons.diamond,
        'method': 'Assay Hallmark Certification + Contemporary Bullion Benchmarks',
        'challenges':
            'Missing original purchase invoices; disputes over gold purity (22K vs 18K vs 14K); factoring making charges and gemstone depreciation against raw bullion value.',
        'scope':
            'Itemized physical inventory, BIS hallmark assay verification, certified gemological weight auditing, and conversion into court-admissible recovery schedules under Section 27 HMA.',
      },
      {
        'title': 'Agricultural Land & Peri-Urban Farmhouses',
        'icon': Icons.agriculture,
        'method': 'Capitalized Crop Yield + Proximity Development Potential',
        'challenges':
            'State revenue portal complexities (Dharani/Webland); joint coparcenary ancestral ownership; unmutated succession entries; non-agricultural (NALA) conversion potential.',
        'scope':
            'Verifying Pattadar Passbooks, survey boundary maps, soil productivity, and valuing peri-urban road-facing land at fair developmental potential.',
      },
      {
        'title': 'Joint Assets Held with In-Laws',
        'icon': Icons.group,
        'method': 'Proportionate Equity Partition & Contribution Tracing',
        'challenges':
            'Properties registered jointly among husband, wife, and parents-in-law; tracing bank down-payment contributions vs registered title deed percentages.',
        'scope':
            'Forensically auditing bank statement trails to separate the marital couple’s true beneficial equity from extended family shares, preventing asset dissipation.',
      },
    ];

    final current = assetClasses[_selectedAssetIndex];

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
                'MULTI-ASSET APPRAISAL ARCHITECTURE',
                'Multi-Asset Matrimonial Valuation Coverage & Appraisal Challenges',
                'Comprehensive Forensic Valuation Framework Across Real Estate, Private Equity, ESOPs, Stridhan Jewellery, and Agricultural Holdings',
              ),
              const SizedBox(height: 26),

              // Asset Selector Tabs
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: assetClasses.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final ac = entry.value;
                  final isSelected = idx == _selectedAssetIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedAssetIndex = idx),
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
                              ac['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : _obsidian,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ac['title'] as String,
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

              // Asset Detail Card
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
                      'Specific Matrimonial Valuation Challenge:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current['challenges'] as String,
                      style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.7),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'ProValuer Valuation & Forensic Audit Scope:',
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current['scope'] as String,
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
  // 5. FORENSIC ASSET TRACING & CONCEALMENT DETECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildForensicTracingSection(double screenW, bool isDesktop) {
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
                'FORENSIC INVESTIGATION & ASSET DISCOVERY',
                'Forensic Matrimonial Asset Tracing & Concealment Detection',
                'Uncovering Hidden Wealth, Benami Property Holdings, Undisclosed Corporate Entities, and Siphoned Cash Flows',
              ),
              const SizedBox(height: 24),

              Text(
                'In high-stakes matrimonial litigation, one of the most pervasive challenges is the deliberate concealment, transfer, or undervaluation of marital wealth. Anticipating divorce or maintenance claims, high-earning spouses frequently transfer immovable properties to trusted relatives, register corporate assets under opaque shell companies, or declare artificial business losses. A standard valuation that only appraises disclosed properties is fundamentally inadequate.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'ProValuer Commercial deploys forensic valuation protocols combining MCA corporate registry audits, Sub-Registrar transaction mapping, and bank liability reconciliations:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 3 Forensic Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 32) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildForensicCard(
                        colW,
                        'Benami Property & Shell Entity Tracing',
                        'Investigating immovable properties purchased in the names of domestic staff, trusted relatives, or newly incorporated LLPs shortly before or during matrimonial disputes. We cross-reference DIN (Director Identification Numbers), corporate shareholding patterns, and registered address links to establish beneficial spousal ownership.',
                        Icons.search,
                      ),
                      _buildForensicCard(
                        colW,
                        'Siphoned Rental Incomes & Cash Concealment',
                        'Commercial properties frequently generate undeclared cash flows or lease payments redirected to offshore or secondary family accounts. We audit GST lease invoices, tenant occupancy agreements, and prevailing micro-market commercial yields to reconstruct true net rental cash flows.',
                        Icons.monetization_on,
                      ),
                      _buildForensicCard(
                        colW,
                        'Sham Encumbrances & Fictitious Debt Audits',
                        'Spouses often create fictitious mortgages or unregistered loans from relatives to artificially depress net property equity. Our forensic team audits bank loan sanction letters, registered charge filings (MCA Form CHG-1), and Sub-Registrar encumbrance certificates to eliminate sham liabilities.',
                        Icons.rule,
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

  Widget _buildForensicCard(double width, String title, String body, IconData icon) {
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
  // 6. NET EQUITY FORMULATION: BALANCING ASSETS AGAINST DEBTS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildNetEquitySection(double screenW, bool isDesktop) {
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
                'MATRIMONIAL BALANCE SHEET BALANCING',
                'Net Equity Formulation: Balancing Marital Assets Against Debt Liabilities',
                'Mathematical Formulation of Net Realizable Spousal Equity to Guide Court Buyouts and Settlement Terms',
              ),
              const SizedBox(height: 24),

              Text(
                'In modern urban divorces, properties are rarely owned debt-free. High-value apartments in metropolitan tech corridors often carry substantial outstanding home loans, personal lines of credit, or municipal tax dues. If a court divides property based purely on Gross Fair Market Value, the spouse who assumes the property alongside the mortgage is severely disadvantaged. ProValuer Commercial applies a standardized **Net Equity Formulation** to compute true distributable spousal wealth:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 26),

              // Net Equity Equation Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: LandingTheme.brandGreen.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The ProValuer Net Distributable Equity Formula:',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lightBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderSubtle),
                      ),
                      child: Text(
                        'Net Distributable Spousal Equity = [Gross Fair Market Value (FMV)] - [Certified Principal Loan Outstanding] - [Prepayment & Bank Discharge Charges] - [Unpaid Municipal Tax & Society Dues] ± [Past Financial Contribution Adjustments]',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _obsidian,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Capital Gains Tax & Stamp Duty Factoring in Spousal Transfers:',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Under Section 47 of the Income Tax Act, 1961, any transfer of a capital asset between spouses under an agreement in contemplation of divorce or pursuant to a court decree does not constitute a "transfer" for capital gains tax purposes. However, if the settlement terms require selling the property to a third party on the open market, substantial Long-Term Capital Gains (LTCG) tax will arise. Our valuation reports model these net after-tax realization figures so parties negotiate based on real cash proceeds.',
                      style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.65),
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
  // 7. DOCUMENTS REQUIRED FOR MATRIMONIAL VALUATION & DEFICIENCIES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentationSection(double screenW, bool isDesktop) {
    final docs = [
      {
        'title': 'Registered Real Estate Title Deeds & Link Documents',
        'desc': 'Sale Deed, Gift Deed, Partition Deed, and historical link documents establishing title lineage for a minimum of 30 years.',
      },
      {
        'title': 'Encumbrance Certificate (EC Form 15 for 15–30 Years)',
        'desc': 'Certified search from the Sub-Registrar Office proving ownership continuity and confirming absence of third-party attachments.',
      },
      {
        'title': 'Active Home Loan Foreclosure Statements & Sanction Letters',
        'desc': 'Formal statement from lending bank showing principal loan balance, EMI payment history, and loan co-borrower details.',
      },
      {
        'title': '3 Years Audited Financial Statements & ITR-V (For Businesses)',
        'desc': 'Profit & loss accounts, balance sheets, MCA master data, and tax filings for private limited companies, partnerships, or LLPs.',
      },
      {
        'title': 'Itemized Stridhan Inventory & Hallmark Assay Certificates',
        'desc': 'Detailed lists of gold jewellery, silver, and precious stones with BIS hallmark certification, purchase invoices, and wedding photos.',
      },
      {
        'title': 'Revenue Land Records (Pattadar Passbooks & Dharani Extracts)',
        'desc': 'Digital revenue records, ROR 1-B, Khasra Pahani, village survey maps, and NALA non-agricultural conversion documentation.',
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
                'Documents Required for Matrimonial Valuation & Common Deficiencies',
                'Essential Legal Records, Financial Ledgers, and Analysis of the 6 Most Damaging Document Deficiencies in Family Court Filings',
              ),
              const SizedBox(height: 24),

              Text(
                'To produce an impartial, court-admissible matrimonial valuation report that withstands judicial scrutiny and cross-examination, valuers require verified documentary evidence. Below is the primary documentation checklist required for initiating an appraisal:',
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

              // 6 Common Deficiencies Box
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
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          '6 Fatal Documentation Deficiencies That Weaken Family Court Claims',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDeficiencyRow('1. Failure to Deduct Outstanding Mortgage Liabilities:', 'Presenting a property at gross market value without deducting the active joint home loan, misleading the court on net distributable equity.'),
                    _buildDeficiencyRow('2. Submitting Circle Rates (Guideline Values) Instead of FMV:', 'Circle rates in prime urban tech corridors are frequently 40%–60% below true open market values, resulting in artificially depressed maintenance claims.'),
                    _buildDeficiencyRow('3. Inability to Trace Financial Contribution Trails:', 'Failing to produce bank statements proving who paid the down payment, stamp duty, and monthly EMIs on jointly registered flats, creating ownership deadlocks.'),
                    _buildDeficiencyRow('4. Missing Historical Link Deeds in Ancestral Claims:', 'Failing to establish continuous title succession from the original pattadar creates severe legal defects when defending ancestral properties.'),
                    _buildDeficiencyRow('5. Unverified Handwritten Stridhan Lists:', 'Submitting informal self-declared lists of wedding jewellery without certified hallmark assay reports or purchase invoices, leading to immediate dismissal in court.'),
                    _buildDeficiencyRow('6. Relying on Stale or Outdated Valuations:', 'Presenting valuation reports conducted two to three years prior, ignoring severe micro-market price shifts and structural depreciation.'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeficiencyRow(String title, String body) {
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
  // 8. REGIONAL PRACTICE: HYDERABAD, TELANGANA & SOUTH INDIA
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
                'LOCAL JUDICIAL & MEDIATION EXCELLENCE',
                'Hyderabad, Telangana & South India Family Court Practice',
                'Direct Alignment with City Civil Family Courts (Purani Haveli), Secunderabad, L.B. Nagar, and the High Court Mediation Centre',
              ),
              const SizedBox(height: 24),

              Text(
                'Hyderabad represents one of India’s most dynamic economic and tech hubs, where matrimonial disputes frequently feature complex combinations of high-rise IT corridor real estate, dual-salaried joint home loans, unlisted tech startup equity, and multi-generational ancestral assets. ProValuer Commercial operates with dedicated practice teams appearing as independent experts across all local judicial forums:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // 4 Local Focus Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildLocalCourtCard(
                        colW,
                        'City Civil Family Courts (Purani Haveli & Secunderabad)',
                        'Regularly preparing court-commissioned and party-appointed valuation reports for proceedings before the Principal Family Court at Purani Haveli and the Additional Family Court at Secunderabad, formatted precisely to satisfy judicial bench rules.',
                        Icons.account_balance,
                      ),
                      _buildLocalCourtCard(
                        colW,
                        'Ranga Reddy & Medchal District Family Courts',
                        'Handling high-volume IT corridor spousal disputes originating from Cyberabad (Gachibowli, HITEC City, Kondapur, Miyapur, and Tellapur) before the District Family Courts at L.B. Nagar and Malkajgiri.',
                        Icons.apartment,
                      ),
                      _buildLocalCourtCard(
                        colW,
                        'Telangana High Court Mediation Centre Alignment',
                        'Serving as certified independent valuation experts for matrimonial mediation panels under Nyaya Seva Sadan (TSLSA) and the High Court Mediation and Arbitration Centre, providing neutral financial baselines that break settlement deadlocks.',
                        Icons.handshake,
                      ),
                      _buildLocalCourtCard(
                        colW,
                        'Dharani Agricultural Land Division across Telangana',
                        'Navigating complex ancestral land partitions across Ranga Reddy, Sangareddy, Medchal, and Yadadri districts, verifying Dharani portal land records, Pattadar Passbooks, and peri-urban NALA conversion values.',
                        Icons.landscape,
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

  Widget _buildLocalCourtCard(double width, String title, String body, IconData icon) {
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
  // 9. THE PROVALUER 4-STAGE MATRIMONIAL PROTOCOL
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildProtocolSection(double screenW, bool isDesktop) {
    final stages = [
      {
        'step': 'STAGE 01',
        'title': 'Confidential Inventory Audit & Non-Disclosure Protocol',
        'desc': 'Parties or counsel submit registered title deeds, bank loan foreclosure statements, and asset inventories under a strict Non-Disclosure Agreement (NDA). Our legal team conducts a preliminary title search, isolating separate property from joint marital assets.',
      },
      {
        'step': 'STAGE 02',
        'title': 'Forensic On-Site Physical Inspection & Multi-Asset Tagging',
        'desc': 'Our certified engineering valuers visit the properties in person. We capture laser plinth measurements, verify physical boundaries, evaluate structural maintenance, inspect Stridhan jewellery assay stamps, and record GPS-tagged color photographs.',
      },
      {
        'step': 'STAGE 03',
        'title': 'Algorithmic Tripartite Modeling & Debt Reconciliation',
        'desc': 'Deploying the Sales Comparison Approach and CPWD Depreciated Replacement Cost models, our valuation analysts calculate Fair Market Value, deduct active principal mortgage balances, and formulate Net Distributable Equity.',
      },
      {
        'step': 'STAGE 04',
        'title': 'Issuance of Court-Admissible Dossier with QR Verification',
        'desc': 'The report is executed under Section 34AB seal and IBBI registration, signed by our Fellow Valuer, and accompanied by an Expert Witness Affidavit under Section 45 Evidence Act. An encrypted digital QR code ensures instant judicial authenticity.',
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
                'The ProValuer 4-Stage Matrimonial Valuation Protocol',
                'Systematized Operational Workflow Engineered for Speed, Complete Confidentiality, and Unconditional Court Admissibility',
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
        'q': 'Is a property valuation report issued by a Government Approved Valuer legally binding in an Indian Family Court?',
        'a': 'Under Section 45 of the Indian Evidence Act, 1872, reports issued by Government Approved Valuers (registered under Section 34AB of the Wealth Tax Act and Section 247 of the Companies Act) constitute expert technical testimony admissible in evidence. While Family Court judges retain judicial discretion to evaluate all facts, a certified valuation accompanied by an expert witness affidavit carries the highest evidentiary weight, serving as an authoritative factual benchmark that opposing counsel cannot dismiss as informal opinion.',
      },
      {
        'q': 'How is property divided if it is registered jointly in the names of both husband and wife?',
        'a': 'By legal presumption under Indian property law, jointly registered property is owned in equal 50:50 shares unless the registered sale deed explicitly defines different ownership proportions. However, in contested divorces, courts examine financial contribution trails (who paid the down payment, stamp duty, and monthly EMIs). ProValuer’s valuation report calculates the Gross Fair Market Value, deducts any active bank mortgage balance, and determines the exact net cash buyout figure required for one spouse to acquire the other’s share.',
      },
      {
        'q': 'What happens if one spouse refuses to allow physical inspection of the house for matrimonial valuation?',
        'a': 'If an estranged spouse refuses entry, your legal advocate can file an interim application under Section 151 of the Code of Civil Procedure (CPC) or Section 14 of the Family Courts Act requesting the court to appoint a Court Commissioner or direct the opposing party to permit on-site inspection. Alternatively, if access is impossible, our valuers can execute an external dimensional inspection cross-referenced with approved municipal blueprints, Sub-Registrar deed schedules, and identical unit comparables, noting the inspection limitations for the court.',
      },
      {
        'q': 'How is the value of a spouse\'s private business or startup shareholding determined during a divorce?',
        'a': 'Valuation of closely held private limited companies, partnerships, or startup equity is executed under Section 247 of the Companies Act, 2013 using the Net Asset Value (NAV) method, Discounted Cash Flow (DCF), or comparable company market multiples. We audit audited financial statements, normalize director remuneration, identify unrecorded perks, and determine fair spousal equity to guide lump-sum alimony awards.',
      },
      {
        'q': 'Can ancestral property owned by the husband\'s family be valued and claimed for divorce maintenance?',
        'a': 'An estranged wife cannot claim direct ownership or partition of ancestral property belonging to the husband\'s coparcenary under the Hindu Succession Act. However, the husband\'s undivided coparcenary interest in ancestral property represents a legitimate financial resource. Courts evaluate the fair market value of his ancestral share under Section 25 of the Hindu Marriage Act when determining the quantum of permanent alimony and child maintenance.',
      },
      {
        'q': 'How does the valuer compute spousal buyout equity when an active bank home loan exists?',
        'a': 'We apply our Net Distributable Equity Formula: Gross Fair Market Value minus Certified Principal Loan Balance minus Prepayment Penalties minus Unpaid Municipal Dues. For example, if a joint flat is valued at ₹2 Crores with an active bank loan of ₹80 Lakhs, the net equity is ₹1.2 Crores. In an equal 50:50 co-ownership, the buyout consideration is ₹60 Lakhs, with the purchasing spouse formally refinancing the mortgage to release the exiting spouse from bank liability.',
      },
      {
        'q': 'What is the process for valuing Stridhan gold jewellery and wedding gifts for recovery under Section 27?',
        'a': 'Our approved jewellery valuers conduct physical assay testing of gold articles, verifying Bureau of Indian Standards (BIS) hallmark stamps, measuring exact gram weights, and appraising precious gemstone quality. We prepare an itemized court recovery schedule applying contemporary bullion market rates, enabling Family Courts to order the physical return of jewellery or mandate equivalent financial restitution under Section 27 HMA.',
      },
      {
        'q': 'How does ProValuer identify and value hidden or undervalued properties during matrimonial litigation?',
        'a': 'Our forensic practice cross-checks MCA corporate records (DIN numbers) to uncover undisclosed company shareholdings, audits Sub-Registrar transaction archives to trace properties transferred to third parties shortly before separation, and reconciles bank statement trails to identify undisclosed rental incomes or mortgage drawdowns, presenting a consolidated evidence dossier to the court.',
      },
      {
        'q': 'Are property valuation reports prepared for foreign divorce proceedings (US, UK, Canada, Australia) accepted in Indian courts?',
        'a': 'Yes. When non-resident Indian (NRI) couples divorce abroad, foreign courts require certified valuation of properties located in India to finalize global asset distribution. ProValuer prepares dual-currency valuation reports compliant with Indian legal standards and foreign court evidentiary rules under the Hague Apostille Convention and Section 13 CPC.',
      },
      {
        'q': 'How long does an emergency matrimonial property valuation report take to be delivered for an urgent court hearing?',
        'a': 'ProValuer maintains an emergency family court valuation desk across Hyderabad, Telangana, and South India. Upon receipt of digital property records before 12:00 PM, on-site physical inspection is scheduled immediately, and the certified, QR-coded dossier accompanied by an expert witness affidavit is delivered within 24 to 48 hours for urgent court hearings or mediation sessions.',
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
                'Matrimonial & Divorce Valuation FAQs',
                'Authoritative Answers to the 10 Most Critical Judicial and Financial Questions Encountered by Litigants and Legal Counsel',
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
                  'CONFIDENTIAL FAMILY LAW ADVISORY DESK',
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
                'Schedule Your Court-Admissible Matrimonial Valuation',
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
                  'Impartial, evidence-backed valuation reports executed by Government Approved Valuers under Section 34AB of the Wealth Tax Act and Section 247 of the Companies Act. Guaranteed 24 to 48-hour delivery across Hyderabad, Telangana, and South India. Complete advocate-client privilege and strict professional confidentiality.',
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
                      'Hello ProValuer Commercial, I would like to schedule a confidential matrimonial property valuation.',
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
                              'Court-admissible matrimonial appraisals, financial solvency affidavits, and expert witness valuation reports under the Family Courts Act 1984 and Indian Evidence Act Section 45.',
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
                            _buildFooterLink('Divorce Matrimonial Valuation', () => context.go('/services/divorce-matrimonial-valuation')),
                            _buildFooterLink('Share & Equity Valuation', () => context.go('/services/share-valuation')),
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
                            _buildFooterText('Family Courts Act 1984'),
                            _buildFooterText('Indian Evidence Act Section 45'),
                            _buildFooterText('Hindu Marriage Act Sections 25 & 27'),
                            _buildFooterLink('High Court Probate & Succession', () => context.go('/services/probate-inheritance-valuation')),
                            _buildFooterText('Insolvency & Bankruptcy (NCLT)'),
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
