import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/landing/landing_theme.dart';

/// Bank Collateral Valuation Services — Cornerstone Institutional Landing Page
/// Canonical URL: https://www.provaluer.in/services/bank-collateral-valuation
class BankCollateralValuationScreen extends StatefulWidget {
  const BankCollateralValuationScreen({super.key});

  @override
  State<BankCollateralValuationScreen> createState() => _BankCollateralValuationScreenState();
}

class _BankCollateralValuationScreenState extends State<BankCollateralValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  static const String _primaryPhone = '+918500019091';
  static const String _primaryPhoneFormatted = '+91 85000 19091';
  static const String _waUrl = 'https://wa.me/918500880333';

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
    final bool isTablet = screenW >= 700 && screenW < 1100;

    return Scaffold(
      backgroundColor: LandingTheme.primaryBg,
      body: Stack(
        children: [
          // ── Scrollable Content ─────────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 100), // Clearance for floating header

                // 1. Hero Section
                _buildHeroSection(screenW, isDesktop),

                // 2. Regulatory & Statutory Framework
                _buildFrameworkSection(screenW, isDesktop),

                // 3. Three-Tier Valuation Metric (FMV / RV / DSV)
                _buildThreeTierMetricSection(screenW, isDesktop),

                // 4. Asset Classes Covered Under Collateral Appraisals
                _buildAssetClassesSection(screenW, isDesktop, isTablet),

                // 5. Dedicated Local SEO: Hyderabad & Telangana Regional Coverage
                _buildLocalSeoSection(screenW, isDesktop),

                // 6. Lead Magnet: Documentation Checklist
                _buildDocumentationChecklistSection(screenW, isDesktop),

                // 7. Common Reasons Reports Are Rejected (Troubleshooting & Problem Solving)
                _buildRejectionReasonsSection(screenW, isDesktop),

                // 8. The 4-Stage Collateral Assessment Protocol
                _buildAssessmentProtocolSection(screenW, isDesktop),

                // 9. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 10. High-Touch Executive Conversion Block
                _buildFinalConversionBlock(screenW, isDesktop),

                // 11. Institutional Footer
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
                  'Hello Pro Valuer, I would like to consult on a Bank Collateral Valuation mandate.',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'WhatsApp Advisory',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
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

  // ═════════════════════════════════════════════════════════════════════════════
  // FLOATING SERVICE HEADER (NO LOGIN LINK)
  // ═════════════════════════════════════════════════════════════════════════════

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
                      // Monogram & Brand Name (Links to Home)
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
                              'Pro Valuer',
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: LandingTheme.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Navigation links
                      if (isDesktop) ...[
                        _buildNavText('Home', () => context.go('/')),
                        const SizedBox(width: 24),
                        _buildNavText(
                          'Plant & Machinery',
                          () => context.go('/services/plant-machinery-technical-valuation'),
                        ),
                        const SizedBox(width: 24),
                        _buildNavText(
                          'NCLT & IBC',
                          () => context.go('/services/nclt-ibc-valuation'),
                        ),
                        const SizedBox(width: 28),
                      ],

                      // Phone Pill ("Speak to a Senior Valuer")
                      GestureDetector(
                        onTap: _makePhoneCall,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.35)),
                            borderRadius: BorderRadius.circular(100),
                            color: LandingTheme.brandGreen.withValues(alpha: 0.05),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(FontAwesomeIcons.phone, size: 12, color: LandingTheme.brandGreen),
                              const SizedBox(width: 7),
                              Text(
                                isDesktop ? 'Speak to a Senior Valuer' : _primaryPhoneFormatted,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.brandGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // "Request a Valuation" CTA
                      GestureDetector(
                        onTap: () => _launchWhatsApp(
                          'Hello, I would like to Request a Bank Collateral Valuation for our commercial credit proposal.',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            color: LandingTheme.brandGreen,
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: LandingTheme.brandGreen.withValues(alpha: 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Request a Valuation',
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.arrow_forward_rounded, size: 13, color: Colors.white),
                            ],
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

  Widget _buildNavText(String title, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LandingTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 1. HERO SECTION
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildHeroSection(double screenW, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 48 : 28,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: LandingTheme.brandGreen, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'BANK SECURITY & COLLATERAL VALUATION • GOVT APPROVED • IBBI REGISTERED',
                      style: GoogleFonts.montserrat(
                        fontSize: isDesktop ? 10.5 : 9.5,
                        fontWeight: FontWeight.w700,
                        color: LandingTheme.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // H1: Primary Institutional Title
              Text(
                'Bank Collateral Valuation Services — Statutory & Institutional Asset Intelligence',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 42 : (screenW >= 700 ? 34 : 28),
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1.5,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 20),

              // Executive Subtitle & Comprehensive Scope (Detailed Narrative)
              Text(
                'ProValuer Commercial provides comprehensive, legally unassailable collateral valuation and asset appraisal services for nationalized PSU banks, private scheduled commercial lenders, Tier-1 NBFCs, and institutional debt funds across India. Governed by Section 247 of the Companies Act 2013, the Wealth Tax Act 1957 (Section 34AB), and Reserve Bank of India (RBI) prudential guidelines, our certified valuation reports provide senior credit committees, risk officers, and consortium leaders with forensic asset intelligence. Whether underwriting high-value term loans, renewing working capital limits, structuring project finance, or executing debt resolution under the SARFAESI Act, our empanelled registered valuers establish bulletproof Fair Market, Realizable, and Distress Sale parameters.',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 15.5 : 14.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF475569),
                  height: 1.7,
                ),
              ),

              const SizedBox(height: 28),

              // Trust Strip Ribbon
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildTrustBadge('IBBI Registered Valuers', 'Land & Building / Plant & Machinery'),
                  _buildTrustBadge('Govt. Approved Valuers', 'Wealth Tax Act Sec 34AB'),
                  _buildTrustBadge('Empanelled Across India', 'PSU & Private Commercial Banks'),
                  _buildTrustBadge('Guaranteed Delivery', '3 to 5 Business Days SLA'),
                ],
              ),

              const SizedBox(height: 36),

              // Primary Action Buttons (No Login Barrier)
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchWhatsApp(
                      'Hello, I would like to Request an Institutional Bank Collateral Valuation for our enterprise.',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingTheme.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Request a Valuation',
                          style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _makePhoneCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.phone, size: 14, color: LandingTheme.brandGreen),
                        const SizedBox(width: 9),
                        Text(
                          'Speak to a Senior Valuer',
                          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _launchWhatsApp(
                      'Hello, I would like to Schedule an Advisory Consultation regarding our bank security valuation.',
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    child: Text(
                      'Schedule an Advisory Consultation →',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: LandingTheme.brandGreen,
                      ),
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

  Widget _buildTrustBadge(String label, String sublabel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 2. REGULATORY & STATUTORY FRAMEWORK (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildFrameworkSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('The Institutional Collateral Valuation Framework'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'In the modern Indian financial landscape, collateral valuation is no longer a superficial procedural check. Regulatory tightening by the Reserve Bank of India (RBI), the Insolvency and Bankruptcy Board of India (IBBI), and the Ministry of Corporate Affairs (MCA) has transformed asset appraisal into a rigorous, statutory discipline. Commercial banks and credit underwriters operate under strict institutional mandates designed to prevent over-gearing, fraudulent over-valuation, and systemic loan book impairments. ProValuer Commercial operates directly at the convergence of these statutory frameworks.',
          ),
          const SizedBox(height: 28),
          _buildH3Header('Compliance with RBI Master Directions on Secured Lending'),
          _buildBodyParagraph(
            'The Reserve Bank of India mandates that all housing loans, commercial real estate (CRE) advances, and corporate borrowing facilities backed by tangible primary or collateral security must be supported by certified valuations conducted by independent empanelled professionals. For large exposures exceeding ₹50 Crore, the central bank directs scheduled commercial banks to commission two separate independent valuation reports from distinct empanelled entities. Where the variance between the two valuations exceeds 15%, a third independent review or a formal joint reconciliation protocol is mandatory before loan disbursement. Our methodologies mirror RBI prudential guidelines, eliminating the risk of regulatory audit objections.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Statutory Alignment: Section 247 of Companies Act 2013'),
          _buildBodyParagraph(
            'Where credit facilities, debenture issuances, or consortium mortgages involve a corporate entity (whether private limited or public listed), Section 247 of the Companies Act 2013 stipulates that any valuation of property, stocks, shares, debentures, or industrial assets must be undertaken exclusively by an IBBI Registered Valuer belonging to a recognized Registered Valuers Organisation (RVO). Reports issued by non-registered entities lack judicial validity before company courts, official liquidators, and the National Company Law Tribunal (NCLT). ProValuer Commercial holds active partner registrations across all primary asset classes.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('SARFAESI Act 2002 & IBC 2016 Alignment for Stressed Assets'),
          _buildBodyParagraph(
            'Under the Securitisation and Reconstruction of Financial Assets and Enforcement of Security Interest (SARFAESI) Act 2002, authorized bank officers initiating recovery proceedings against defaulting borrowers must determine an unassailable Reserve Price for auction based on a certified valuation report. Inaccurate or inflated reserve prices result in prolonged auction cancellations, while excessively suppressed figures invite borrower litigation in Debt Recovery Tribunals (DRT). Similarly, under Regulation 27 of the Corporate Insolvency Resolution Process (CIRP) within the Insolvency and Bankruptcy Code (IBC) 2016, our valuers calculate Fair Value and Liquidation Value to benchmark resolution proposals.',
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 3. THREE-TIER VALUATION METRIC: FMV, RV, DSV (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildThreeTierMetricSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('The Three-Tier Valuation Metric: FMV, Realizable Value, and Distress Sale Value'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'Institutional credit approval hinges on a clear, mathematically defensible understanding of asset liquidity under distinct economic conditions. Bank credit risk committees evaluate loans not merely on theoretical market prices, but on actual cash recovery potential in adverse scenarios. ProValuer Commercial delineates three distinct valuation benchmarks in every collateral report:',
          ),
          const SizedBox(height: 24),
          _buildH3Header('Fair Market Value (FMV): Unrestricted Open-Market Determination'),
          _buildBodyParagraph(
            'Fair Market Value represents the estimated amount for which an asset should exchange on the valuation date between a willing buyer and a willing seller in an arm’s-length transaction, after proper marketing, wherein the parties had each acted knowledgeably, prudently, and without compulsion. To compute FMV for land and buildings, our team leverages the Direct Comparison Approach using genuine registered registry data, adjusted for frontage, shape, zoning, and title strength. For commercial revenue-generating assets, the Discounted Cash Flow (DCF) or Capitalization of Net Income approach is utilized.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Realizable Value (RV): Commercial Liquidity Haircut Modeling'),
          _buildBodyParagraph(
            'Realizable Value reflects the net monetary realization reasonably achievable under standard commercial market constraints within an orderly disposal window of 6 to 12 months. It accounts for realistic transaction friction, including brokerage, stamp duty burdens, legal documentation costs, capital gains tax implications, and localized liquidity discounts. Under standard Indian banking parameters, Realizable Value typically reflects an institutional haircut of 10% to 15% below Fair Market Value, providing the fundamental benchmark for primary credit sanction and loan-to-value (LTV) limits.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Distress Sale Value (DSV): 90-Day Forced Liquidation Benchmarking'),
          _buildBodyParagraph(
            'Distress Sale Value (also designated as Forced Sale Value or Immediate Liquidation Benchmark) models the anticipated cash realization if the property or industrial asset must be sold under severe commercial pressure within an expedited 30 to 90-day window, such as during SARFAESI auctions or corporate debt recovery proceedings. In such constrained timeframes, prospective buyers demand aggressive pricing discounts. Depending on micro-market liquidity, property encumbrances, and asset specificity, our valuers model a 20% to 35% haircut from FMV, providing recovery officers with an indisputable reserve price baseline.',
          ),
          const SizedBox(height: 32),

          // High-Contrast Comparative Metric Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x060F172A), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF0F172A)),
                columns: [
                  DataColumn(
                    label: Text(
                      'Valuation Metric',
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Disposal Window',
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Typical Haircut from FMV',
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Primary Banking Application',
                      style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(Text('Fair Market Value (FMV)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
                    DataCell(Text('Standard (6–12 Months)', style: GoogleFonts.montserrat())),
                    DataCell(Text('0% (Benchmark Base)', style: GoogleFonts.montserrat())),
                    DataCell(Text('Credit Underwriting, Overall Net Worth Audit', style: GoogleFonts.montserrat())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Realizable Value (RV)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
                    DataCell(Text('Orderly (3–6 Months)', style: GoogleFonts.montserrat())),
                    DataCell(Text('10% – 15% Haircut', style: GoogleFonts.montserrat(color: LandingTheme.brandGreen, fontWeight: FontWeight.w700))),
                    DataCell(Text('Loan-to-Value (LTV) Calculation & Facility Sizing', style: GoogleFonts.montserrat())),
                  ]),
                  DataRow(cells: [
                    DataCell(Text('Distress Sale Value (DSV)', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700))),
                    DataCell(Text('Forced (< 90 Days)', style: GoogleFonts.montserrat())),
                    DataCell(Text('20% – 35% Haircut', style: GoogleFonts.montserrat(color: const Color(0xFFE11D48), fontWeight: FontWeight.w700))),
                    DataCell(Text('SARFAESI Reserve Price, Recovery Benchmarks', style: GoogleFonts.montserrat())),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 4. ASSET CLASSES COVERED UNDER COLLATERAL VALUATION (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildAssetClassesSection(double screenW, bool isDesktop, bool isTablet) {
    return _buildSectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('Asset Classes Covered Under Bank Collateral Valuation'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'Secured institutional lending requires specialized domain knowledge across diverse asset classes. A commercial IT tower in a prime business district involves completely different valuation principles than a chemical manufacturing plant or a high-capacity logistics warehouse. ProValuer Commercial fields dedicated technical squads across four core asset categories:',
          ),
          const SizedBox(height: 28),
          _buildH3Header('Commercial Real Estate (Office Parks, Grade-A IT Towers, Retail Malls, Hospitality Assets)'),
          _buildBodyParagraph(
            'We assess Grade-A commercial office buildings, IT/ITeS parks, multi-tenant shopping malls, and commercial hospitality assets using income capitalization, discounted cash flow (DCF), and physical market comparison. Our technical scrutiny evaluates occupancy schedules, weighted average unexpired lease terms (WAULT), tenant creditworthiness, common area maintenance (CAM) spreads, and statutory municipal approvals (occupancy certificates, fire safety NOCs, environmental clearances).',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Industrial Assets (Manufacturing Sheds, Warehouses, Logistics Hubs, Special Economic Zones)'),
          _buildBodyParagraph(
            'Industrial real estate appraisals incorporate the Depreciated Replacement Cost (DRC) method alongside prevailing industrial development authority land rates (e.g., TSIIC, APIIC, MIDC, GIDC). We inspect structural engineering integrity, pre-engineered building (PEB) specifications, heavy flooring load-bearing capacity, industrial power sanctions, effluent treatment plant (ETP) clearances, and clear-height logistics parameters to deliver precise security values.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Plant, Heavy Machinery & High-Precision Industrial Equipment'),
          _buildBodyParagraph(
            'When industrial borrowers pledge capital equipment, production assembly lines, or power infrastructure as collateral, our licensed technical and mechanical valuers conduct forensic physical inspections. We verify manufacturer nameplates, original procurement invoices, bill of entries for imported plant, operating run-hours, maintenance logs, and remaining economic life. Learn more about our specialized engineering appraisals in our ',
          ),
          // Internal Link to Plant & Machinery Service Page
          GestureDetector(
            onTap: () => context.go('/services/plant-machinery-technical-valuation'),
            child: Text(
              'Plant & Machinery Technical Certification Practice →',
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: LandingTheme.brandGreen,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildH3Header('Residential Projects & Commercial Land Parcels'),
          _buildBodyParagraph(
            'From master-planned township plots and open commercial land enclaves to under-construction residential multi-story high-rises, we evaluate real estate under RERA guidelines, Master Plan zoning rules, and development control regulations. We verify arterial road frontage, FSI/FAR potential, municipal setback conformity, and title deed continuity across the 30-year search window.',
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 5. LOCAL SEO SECTION: HYDERABAD & TELANGANA (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildLocalSeoSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      backgroundColor: const Color(0xFFF1F5F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('Bank Collateral Valuation Services in Hyderabad & Telangana'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'As one of India’s most dynamic commercial and industrial epicenters, Hyderabad, Telangana, and the wider South Indian region demand localized valuation expertise grounded in deep municipal, legal, and banking relationships. ProValuer Commercial maintains an extensive operational presence across the Hyderabad Metropolitan Development Authority (HMDA) jurisdiction, Greater Hyderabad Municipal Corporation (GHMC), and the Telangana State Industrial Infrastructure Corporation (TSIIC) industrial belts.',
          ),
          const SizedBox(height: 24),
          _buildH3Header('Comprehensive Regional Coverage: Hyderabad, Telangana, Andhra Pradesh & South India'),
          _buildBodyParagraph(
            'Our senior valuation teams routinely execute high-value collateral inspection mandates across key commercial corridors: HITEC City, Gachibowli, Financial District, Madhapur, Kondapur, Kokapet, and Neopolis, as well as core industrial corridors including Patancheru, Bollaram, Pashamylaram, Jeedimetla, Cherlapally, Kothur, and the Pharma City cluster. Our regional capabilities extend seamlessly across Telangana (Warangal, Karimnagar, Nizamabad), Andhra Pradesh (Visakhapatnam, Vijayawada, Guntur, Tirupati), and southern banking hubs.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Rapid Physical Site Inspection Capabilities & Local Regulatory Mastery'),
          _buildBodyParagraph(
            'Local market valuations require direct familiarity with Telangana revenue laws, the Dharani portal, RERA Telangana (TSRERA), Layout Regularisation Schemes (LRS/BRS), and GHMC building sanction protocols. Our localized teams execute physical, geo-tagged site inspections within 24 to 48 hours of mandate confirmation, cross-referencing village revenue maps (Tippons), cadastral surveys, and municipal master plans to verify clear property demarcation and access roads.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Established Local Banking Relationships & Guaranteed Turnaround Times'),
          _buildBodyParagraph(
            'We maintain direct empanelment and working relationships with zonal credit underwriting hubs, commercial branch networks, and stressed asset management branches (SAMBs) of State Bank of India (SBI), Punjab National Bank (PNB), Canara Bank, Union Bank of India, Bank of Baroda, HDFC Bank, ICICI Bank, and leading private NBFCs across Hyderabad and South India. Our guaranteed local turnaround time of 3 to 5 business days empowers credit officers and corporate borrowers to clear sanction committees without procedural delays.',
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 6. LEAD MAGNET: DOCUMENTATION CHECKLIST (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildDocumentationChecklistSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('Bank Collateral Valuation Documentation Checklist'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'The single most prevalent cause of delays in bank loan sanctions and credit disbursements is incomplete or deficient collateral documentation. Before an empanelled valuer can finalize physical measurements and file a certified report, banks mandate verification of primary legal, statutory, and municipal records. ProValuer Commercial provides this standardized 12-point documentation checklist to help corporate borrowers, CFOs, and credit analysts streamline the appraisal process:',
          ),
          const SizedBox(height: 28),

          // 3 Checklist Pillars
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildChecklistPillar(
                title: '1. Primary Title & Ownership Documents',
                items: [
                  'Registered Sale Deed / Title Deed / Gift Deed / Partition Deed',
                  'Prior Parent Title Documents establishing 30-year link chain',
                  'Nil Encumbrance Certificate (Form 15/16) for past 30 years',
                  'Title Search & Scrutiny Report from bank-approved advocate',
                ],
              ),
              _buildChecklistPillar(
                title: '2. Municipal Approvals & Statutory Sanctions',
                items: [
                  'Sanctioned Building Plan & Approval Letter (GHMC/HMDA/Local Body)',
                  'Occupancy Certificate (OC) or Completion Certificate (CC)',
                  'Latest Property Tax Assessment Book Extract & Paid Receipts',
                  'Khata Certificate / Patta Passbook / Land Revenue Extract',
                ],
              ),
              _buildChecklistPillar(
                title: '3. Technical & Financial Records',
                items: [
                  'Architectural Floor Layout Blueprints with certified plinth area',
                  'Fire Department No-Objection Certificate (NOC) for commercial units',
                  'Consent to Operate (CTO) from Pollution Control Board (Industries)',
                  'Fixed Asset Register (FAR) & Invoices for Plant & Machinery assets',
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Lead Magnet Download Trigger
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download the Complete 12-Point Bank Collateral Checklist (PDF)',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ensure zero delays in your loan underwriting committee. Request our complete statutory compliance checklist directly via WhatsApp.',
                        style: GoogleFonts.montserrat(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _launchWhatsApp(
                    'Hello, please share the ProValuer 12-Point Bank Collateral Valuation Documentation Checklist PDF.',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingTheme.brandGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Download via WhatsApp',
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistPillar({required String title, required List<String> items}) {
    return SizedBox(
      width: 360,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: LandingTheme.brandGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 7. COMMON REASONS VALUATION REPORTS ARE REJECTED (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildRejectionReasonsSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      backgroundColor: const Color(0xFFFFFBEB), // Soft Amber Alert Background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Common Reasons Bank Collateral Valuation Reports Are Rejected',
                  style: GoogleFonts.montserrat(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF92400E),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBodyParagraph(
            'Credit audit teams, risk management committees, and concurrent auditors scrutinize collateral valuation reports with extreme precision. Even minor documentation inconsistencies or procedural lapses can lead to outright report rejection, halting loan sanction committees and paralyzing enterprise cash flows. ProValuer Commercial identifies the eight primary triggers of bank valuation rejections:',
          ),
          const SizedBox(height: 24),

          // 8 Rejection Points Grid
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _buildRejectionCard(
                '1. Incomplete Ownership Documents',
                'Breaks in the 30-year link chain, uncertified copies of original deeds, or failure to trace title through probate and inheritance successions.',
              ),
              _buildRejectionCard(
                '2. Title Inconsistencies & Identity Mismatches',
                'Discrepancies between the borrower entity name in the loan sanction memo and revenue records (Khata, Patta, Pahani extracts).',
              ),
              _buildRejectionCard(
                '3. Unauthorized Construction & Deviations',
                'Unapproved additional floors, roof-shed extensions, or setback deviations exceeding municipal tolerances (GHMC, HMDA, DTCP).',
              ),
              _buildRejectionCard(
                '4. Missing Statutory Municipal Clearances',
                'Absence of Occupancy Certificates (OC), layout regularisation (LRS) certificates, or missing Fire Department NOCs for commercial buildings.',
              ),
              _buildRejectionCard(
                '5. Discrepancies in Physical Land Measurements',
                'Variance between actual physical site boundaries during inspection and dimensions registered in the title deed, creating legal risks.',
              ),
              _buildRejectionCard(
                '6. Unidentified Encroachments & Easements',
                'Failure by the valuer to inspect boundary pegs, allowing third-party pathway claims, public utilities, or physical squatting to pass unnoticed.',
              ),
              _buildRejectionCard(
                '7. Outdated Valuation Reports',
                'Reliance on valuation certificates exceeding the 3-year standard validity limit or 1-year window for corporate restructuring.',
              ),
              _buildRejectionCard(
                '8. Plant & Machinery Documentation Gaps',
                'Missing customs bill of entries, unrecorded asset tags, absent purchase invoices, or inaccurate depreciation logs in the Fixed Asset Register.',
              ),
            ],
          ),

          const SizedBox(height: 32),

          _buildH3Header('The Severe Downstream Impact on Enterprise Financing'),
          _buildBodyParagraph(
            'When a bank rejects a collateral valuation report, the fallout ripples across the entire commercial operation: loan sanction memos are frozen pending fresh re-appraisals; working capital and overdraft limits stall, disrupting vendor supply chains and payroll; corporate debt restructuring programs under the RBI Prudential Framework miss statutory deadlines (read our ',
          ),
          // Internal Link to NCLT & IBC Practice
          GestureDetector(
            onTap: () => context.go('/services/nclt-ibc-valuation'),
            child: Text(
              'NCLT & IBC Resolution Valuation Guide →',
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: LandingTheme.brandGreen,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          _buildBodyParagraph(
            '); and consortium lending agreements face gridlock as multiple member banks refuse joint mortgage execution. Commissioning an unassailable report from an IBBI Registered Valuer eliminates these catastrophic delays.',
          ),

          const SizedBox(height: 24),

          // Problem-Solving Reassurance CTA
          ElevatedButton(
            onPressed: () => _launchWhatsApp(
              'Hello, our bank valuation report was flagged/rejected. We require an urgent Pre-Valuation Scrutiny with an IBBI Registered Valuer.',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Facing a Stalled Bank Appraisal? Request an Urgent Scrutiny →',
              style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard(String title, String desc) {
    return SizedBox(
      width: 275,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF78350F),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 8. THE 4-STAGE COLLATERAL ASSESSMENT PROTOCOL (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildAssessmentProtocolSection(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('The 4-Stage Collateral Assessment Protocol'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'ProValuer Commercial executes collateral appraisals through a rigorous four-stage quality assurance protocol designed to eliminate human error, guarantee statutory compliance, and deliver bank-ready certified documentation within 3 to 5 business days:',
          ),
          const SizedBox(height: 28),
          _buildH3Header('Stage 1: Document Scrutiny & Statutory Verification'),
          _buildBodyParagraph(
            'Our legal and valuation analysts examine ownership deeds, 30-year encumbrance certificates, master layout plans, and local authority sanctions. We cross-verify municipal revenue records and tax payments to verify that the property title is clean, marketable, and free from undisclosed liens or legal attachments.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Stage 2: Geo-Tagged Physical Site Inspection & Boundary Demarcation'),
          _buildBodyParagraph(
            'An empanelled senior valuer visits the property or industrial installation to perform physical tape and laser measurements of the plot and built-up plinth areas. We document high-resolution geo-tagged photographs, inspect structural quality, identify setbacks, verify road access width, and inspect for encroachments.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Stage 3: Market Comparables, Cost Depreciation & Cash Flow Analysis'),
          _buildBodyParagraph(
            'We aggregate authentic recent transaction evidence from the sub-registrar office, local real estate brokers, and institutional property registries. For industrial and machinery assets, we calculate Depreciated Replacement Cost (DRC); for commercial revenue properties, we execute Discounted Cash Flow (DCF) yield modeling.',
          ),
          const SizedBox(height: 20),
          _buildH3Header('Stage 4: Internal Quality Audit, Partner Sign-Off & Certified Bank Delivery'),
          _buildBodyParagraph(
            'Before report issuance, an independent senior partner reviews calculation models, risk haircuts, and statutory declarations. The final certified report is signed by an IBBI Registered Valuer and Government Approved Valuer, complete with seal, photographs, and complete calculation worksheets.',
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 9. 10 INSTITUTIONAL FAQS (H2)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildFaqSection(double screenW, bool isDesktop) {
    final faqs = [
      {
        'q': 'Why do banks require an independent valuation report before sanctioning a commercial or mortgage loan?',
        'a': 'Banks require independent valuation reports to establish the current market worth of the pledged asset, determine the Loan-to-Value (LTV) ratio, calculate appropriate credit exposure limits, and ensure statutory compliance with RBI prudential lending guidelines. The report validates physical existence, legal boundaries, and market liquidity to safeguard the lending institution against under-collateralization.',
      },
      {
        'q': 'What key metrics and technical components must be included in an institutional bank collateral valuation report?',
        'a': 'A complete institutional report includes: property identification with geo-coordinates, verified land and plinth measurements, prevailing municipal circle rates vs. actual market transactions, structural age and remaining economic life, statutory planning clearances (HMDA/GHMC/local bodies), encumbrance status, and a clear tripartite value breakdown: Fair Market Value (FMV), Realizable Value (RV), and Distress Sale Value (DSV).',
      },
      {
        'q': 'Are ProValuer Commercial collateral reports accepted across Nationalized (PSU) Banks?',
        'a': 'Yes. Our lead partners are Government Approved Valuers under Section 34AB of the Wealth Tax Act and IBBI Registered Valuers empanelled across premier PSU banks (including State Bank of India, Punjab National Bank, Canara Bank, Bank of Baroda, and Union Bank of India) for high-value credit underwriting and consortium advances.',
      },
      {
        'q': 'Do private commercial banks and Tier-1 NBFCs accept your valuation certificates?',
        'a': 'Yes. We are empanelled with leading private lenders, foreign institutions, and NBFCs across India. Our reports strictly adhere to institutional credit policy parameters, standard operating procedures, and automated risk scoring matrices utilized by private sector underwriters.',
      },
      {
        'q': 'What is the validity period of a bank collateral valuation report under RBI guidelines?',
        'a': 'Under Reserve Bank of India (RBI) guidelines, standard mortgage and commercial collateral valuations remain valid for up to 3 years in normal operating conditions. However, for high-value credit exposures (exceeding ₹5 Crore), volatile commercial markets, or accounts undergoing restructuring, banks frequently mandate annual re-valuations or interim rolling reviews.',
      },
      {
        'q': 'What is the turnaround time from physical site inspection to final certified report delivery?',
        'a': 'Standard commercial and residential collateral reports are delivered within 3 to 5 business days following the physical site inspection and receipt of complete documentation. For emergency credit committee deadlines or consortium review mandates, expedited delivery within 48 to 72 hours can be scheduled with dedicated partner dispatch.',
      },
      {
        'q': 'How is Plant & Machinery valued when pledged as collateral for working capital or CAPEX term loans?',
        'a': 'Plant and machinery valuations are conducted by licensed mechanical/technical valuers utilizing the Depreciated Replacement Cost (DRC) method, manufacturer invoices, physical run-hour logs, maintenance history, obsolescence metrics, and secondary market salvage benchmarks to verify that movable capital equipment provides genuine secondary loan security.',
      },
      {
        'q': 'How do valuers determine Distress Sale Value (DSV) and what haircut is applied?',
        'a': 'Distress Sale Value (DSV) simulates an asset\'s net realization under forced liquidation within an expedited 90-day marketing window (such as SARFAESI auctions). Depending on micro-market liquidity, asset specificity, and economic climate, valuers typically apply a structured 20% to 35% haircut from the Fair Market Value (FMV).',
      },
      {
        'q': 'What specific RBI compliance guidelines govern high-value bank collateral appraisals?',
        'a': 'RBI guidelines mandate that for large corporate exposures (typically loans above ₹50 Crore), banks must obtain two independent valuation reports from distinct empanelled registered valuers. If the variance between the two valuations exceeds 15%, a third independent review or average reconciliation protocol is statutory.',
      },
      {
        'q': 'Why must bank valuations involving corporate entities be signed by an IBBI Registered Valuer?',
        'a': 'Under Section 247 of the Companies Act 2013 and Insolvency and Bankruptcy Board of India (IBBI) Valuation Rules 2017, any valuation of property, stocks, shares, debentures, or plant and machinery involving corporate borrowers must be executed by an IBBI Registered Valuer to ensure legal enforceability before the courts, NCLT, and regulatory bodies.',
      },
    ];

    return _buildSectionWrapper(
      backgroundColor: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildH2Header('Frequently Asked Questions (Bank Collateral Valuation)'),
          const SizedBox(height: 14),
          _buildBodyParagraph(
            'Key statutory, regulatory, and procedural questions addressed by our senior empanelled registered valuers regarding commercial mortgage appraisals and bank security documentation in India.',
          ),
          const SizedBox(height: 28),
          ...faqs.map((faq) => _buildFaqItem(faq['q']!, faq['a']!)),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: GoogleFonts.montserrat(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        iconColor: LandingTheme.brandGreen,
        collapsedIconColor: const Color(0xFF64748B),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text(
            answer,
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // 10. FINAL CONVERSION BLOCK (H2) — NO LOGIN BARRIER
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildFinalConversionBlock(double screenW, bool isDesktop) {
    return _buildSectionWrapper(
      backgroundColor: const Color(0xFF0F172A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Schedule an Advisory Consultation with a Senior Valuer',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 34 : 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Whether you are structuring a ₹500 Crore consortium credit facility, preparing for an upcoming bank sanction committee, or addressing collateral audit queries, our IBBI Registered Partners provide immediate, confidential advisory.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                spacing: 16,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchWhatsApp(
                      'Hello, I would like to Request an Immediate Bank Collateral Valuation Consultation with a Senior Partner.',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingTheme.brandGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'WhatsApp Consultation',
                          style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _makePhoneCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white60, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.phone, size: 15, color: LandingTheme.brandGreen),
                        const SizedBox(width: 10),
                        Text(
                          'Direct Call: $_primaryPhoneFormatted',
                          style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ],
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

  // ═════════════════════════════════════════════════════════════════════════════
  // 11. INSTITUTIONAL FOOTER (NO LOGIN LINK)
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildInstitutionalFooter(double screenW, bool isDesktop) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF0A0F1D),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: LandingTheme.brandGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text('PV', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ProValuer Commercial',
                              style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Government Approved & IBBI Registered Valuers providing bank collateral, corporate equity, NCLT/IBC resolution, and plant & machinery technical valuation reports across India.',
                          style: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF94A3B8), height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  // Practice Area Links
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Core Practices', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 10),
                      _buildFooterLink('Home', () => context.go('/')),
                      _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                      _buildFooterLink('Plant & Machinery Appraisals', () => context.go('/services/plant-machinery-technical-valuation')),
                      _buildFooterLink('NCLT & IBC Valuations', () => context.go('/services/nclt-ibc-valuation')),
                    ],
                  ),
                ],
              ),
              const Divider(color: Color(0xFF1E293B), height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 ProValuer Commercial. All statutory rights reserved.',
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'Canonical Domain: https://www.provaluer.in',
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: const Color(0xFF64748B)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: GoogleFonts.montserrat(fontSize: 12, color: const Color(0xFF94A3B8)),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // SHARED SECTION WRAPPERS & TYPOGRAPHY
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildSectionWrapper({required Widget child, Color backgroundColor = Colors.white}) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }

  Widget _buildH2Header(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        letterSpacing: -0.6,
      ),
    );
  }

  Widget _buildH3Header(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildBodyParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 14.5,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF334155),
        height: 1.7,
      ),
    );
  }
}
