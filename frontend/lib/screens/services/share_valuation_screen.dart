import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';

/// Professional Service Page: Certified Share Valuation & Equity Intelligence
/// Canonical URL: https://www.provaluer.in/services/share-valuation
/// Target Word Count: 5,600 - 7,000 words of dense, institutional corporate-finance & regulatory prose.
class ShareValuationScreen extends StatefulWidget {
  const ShareValuationScreen({super.key});

  @override
  State<ShareValuationScreen> createState() => _ShareValuationScreenState();
}

class _ShareValuationScreenState extends State<ShareValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _selectedMethodologyIndex = 0;
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

  Future<void> _launchDialer(String number) async {
    final url = Uri.parse('tel:$number');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _toggleFaq(int index) {
    setState(() {
      if (_expandedFaqIndices.contains(index)) {
        _expandedFaqIndices.remove(index);
      } else {
        _expandedFaqIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isDesktop = screenW >= 1024;
    final isTablet = screenW >= 640 && screenW < 1024;
    final contentPadding = isDesktop ? 48.0 : (isTablet ? 24.0 : 16.0);

    return Scaffold(
      backgroundColor: _pureWhite,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: isDesktop ? 96 : 80),
              ),

              // 1. STATUTORY CORPORATE FINANCE HERO SECTION
              SliverToBoxAdapter(
                child: _buildHeroSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 2. STATUTORY & REGULATORY FRAMEWORK
              SliverToBoxAdapter(
                child: _buildStatutoryFrameworkSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 3. REGISTERED VALUER VS SEBI MERCHANT BANKER
              SliverToBoxAdapter(
                child: _buildValuerVsMerchantBankerSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 4. WHAT IS THE DIFFERENCE BETWEEN NAV AND DCF VALUATION?
              SliverToBoxAdapter(
                child: _buildNavVsDcfSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 5. EQUITY VALUATION METHODOLOGIES & CAPITAL INSTRUMENTS
              SliverToBoxAdapter(
                child: _buildMethodologiesSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 6. STRATEGIC VALUATION TRIGGERS ACROSS CORPORATE LIFE-CYCLE
              SliverToBoxAdapter(
                child: _buildStrategicTriggersSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 7. HOW IS AN UNLISTED COMPANY VALUED? ECONOMIC MODELING
              SliverToBoxAdapter(
                child: _buildHowUnlistedCompanyValuedSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 8. DOCUMENTATION CHECKLIST & 6 CRITICAL DOCUMENTATION MISTAKES
              SliverToBoxAdapter(
                child: _buildDocumentationSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 9. HYDERABAD & TELANGANA STARTUP INNOVATION ECOSYSTEM
              SliverToBoxAdapter(
                child: _buildHyderabadStartupSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 10. THE PROVALUER 4-STAGE FORENSIC SHARE VALUATION PROTOCOL
              SliverToBoxAdapter(
                child: _buildFourStageProtocolSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 11. INSTITUTIONAL SHARE VALUATION FAQS
              SliverToBoxAdapter(
                child: _buildFaqSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 12. EXECUTIVE CONSULTATION & PRIVATE EQUITY CTA
              SliverToBoxAdapter(
                child: _buildCtaSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 13. INSTITUTIONAL FOOTER
              SliverToBoxAdapter(
                child: _buildFooterSection(context, isDesktop, isTablet, contentPadding),
              ),
            ],
          ),

          // FLOATING GLASS NAVIGATION BAR
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildFloatingHeader(context, isDesktop),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // FLOATING GLASS HEADER
  // =========================================================================
  Widget _buildFloatingHeader(BuildContext context, bool isDesktop) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isDesktop ? 80 : 68,
          decoration: BoxDecoration(
            color: _isScrolled ? _pureWhite.withAlpha(240) : _pureWhite.withAlpha(200),
            border: Border(
              bottom: BorderSide(
                color: _isScrolled ? _borderSubtle : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 48 : 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brand Logo
              InkWell(
                onTap: () => context.go('/'),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LandingTheme.brandGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'PV',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROVALUER',
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _obsidian,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'CORPORATE & EQUITY INTELLIGENCE',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: LandingTheme.brandGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Navigation Links (Desktop)
              if (isDesktop)
                Row(
                  children: [
                    _buildNavAction('Practice Hub', () => context.go('/government-approved-valuers')),
                    const SizedBox(width: 20),
                    _buildNavAction('Property Valuation', () => context.go('/services/property-valuation')),
                    const SizedBox(width: 20),
                    _buildNavAction('Matrimonial Valuation', () => context.go('/services/divorce-matrimonial-valuation')),
                    const SizedBox(width: 20),
                    _buildNavAction('Probate Valuation', () => context.go('/services/probate-inheritance-valuation')),
                    const SizedBox(width: 20),
                    _buildNavAction('Bank Collateral', () => context.go('/services/bank-collateral-valuation')),
                  ],
                ),

              // Direct WhatsApp Advisory Button
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _launchDialer(_primaryPhone),
                    icon: const Icon(Icons.phone_in_talk, size: 16, color: _obsidian),
                    label: Text(
                      isDesktop ? _primaryPhoneFormatted : 'Call Desk',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _obsidian,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _borderSubtle),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(
                      'Hello ProValuer Commercial, I require a certified share valuation report for startup fundraising / Section 247 / Rule 11UA tax compliance.',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                    label: Text(
                      isDesktop ? 'Equity Advisory' : 'Inquire',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
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

  Widget _buildNavAction(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _slateText,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. STATUTORY CORPORATE FINANCE HERO SECTION
  // =========================================================================
  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border(bottom: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumbs
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  InkWell(
                    onTap: () => context.go('/'),
                    child: Text('Home', style: GoogleFonts.inter(fontSize: 12, color: _slateText)),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: _slateText),
                  InkWell(
                    onTap: () => context.go('/government-approved-valuers'),
                    child: Text('Government Approved Valuers', style: GoogleFonts.inter(fontSize: 12, color: _slateText)),
                  ),
                  const Icon(Icons.chevron_right, size: 14, color: _slateText),
                  Text(
                    'Share Valuation & Equity Advisory',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _obsidian),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Statutory Compliance Pill Badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildComplianceBadge('Companies Act 2013 § 247 IBBI Registered Valuers'),
                  _buildComplianceBadge('Income Tax Act § 56(2)(viib) & Rule 11UA Compliant'),
                  _buildComplianceBadge('FEMA Non-Debt Instruments (NDI) Arm\'s-Length Pricing'),
                  _buildComplianceBadge('Section 50CA & 56(2)(x) Capital Gains Defense'),
                  _buildComplianceBadge('Ind AS 113 / IFRS 13 Fair Value Measurement'),
                ],
              ),
              const SizedBox(height: 20),

              // H1 Heading
              Text(
                'Certified Share Valuation & Equity Intelligence for Startups, Corporates & Cross-Border FEMA in India',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 38 : (isTablet ? 30 : 25),
                  fontWeight: FontWeight.w800,
                  color: _obsidian,
                  height: 1.25,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),

              // Hero Sub-Narrative
              Text(
                'Institutional, court-admissible equity and enterprise appraisals for seed rounds, angel investments, Series A/B venture capital infusions, preferential allotments under Section 62, rights issues, sweat equity, employee stock option plans (ESOPs), and cross-border M&A transactions. Executed by IBBI Registered Valuers in the asset class of Securities or Financial Assets under Section 247 of the Companies Act, 2013 and licensed Government Approved Valuers under Section 34AB of the Wealth Tax Act, 1957. Conforming strictly to Rule 11UA of the Income Tax Rules, 1962, the Foreign Exchange Management (Non-Debt Instruments) Rules, 2019, and Ind AS 113 Fair Value Measurement standards. Providing startup founders, Chief Financial Officers, venture capital funds, and corporate boards with unassailable DCF financial models, net asset value certificates, and Form PAS-3 documentation to defeat Angel Tax assessments under Section 56(2)(viib), execute seamless ROC filings, and ensure 100% regulatory immunity with complete professional confidentiality.',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 16 : 14.5,
                  fontWeight: FontWeight.w400,
                  color: _slateText,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 36),

              // 4 Stat Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = isDesktop
                      ? (constraints.maxWidth - 48) / 4
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildHeroStatCard(
                        '100% ROC & Tax Admissible',
                        'Section 247 & Rule 11UA',
                        'Signed by IBBI Registered Valuers (Securities/Financial Assets) satisfying ROC Form PAS-3 and Section 56(2)(viib) mandates.',
                        Icons.verified,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        'FEMA Cross-Border Defense',
                        'Inbound FDI & Outbound ODI',
                        'Internationally accepted pricing methodologies satisfying RBI arm\'s-length rules and Form FC-GPR / FC-TRS filings.',
                        Icons.public,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        'Multi-Instrument Modeling',
                        'Equity, CCPS, CCDs & ESOPs',
                        'Sophisticated Black-Scholes, binomial tree, and liquidation preference waterfall modeling for multi-tier cap tables.',
                        Icons.account_tree,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        '24–48 Hours SLA',
                        'Funding Closing Express',
                        'Expedited corporate financial modeling and certified issuance to close investment rounds and term sheet deadlines.',
                        Icons.bolt,
                        cardW,
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

  Widget _buildComplianceBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF334155),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildHeroStatCard(String title, String subtitle, String desc, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: _slateText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. STATUTORY & REGULATORY FRAMEWORK
  // =========================================================================
  Widget _buildStatutoryFrameworkSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'STATUTORY & REGULATORY MANDATES',
                'Statutory Framework Governing Unlisted Share Valuation in India',
                'Issuing, transferring, or restructuring private corporate shares in India triggers overlapping compliance under company law, direct taxation, foreign exchange regulations, and accounting standards. A valuation report must withstand multi-agency regulatory scrutiny:',
              ),
              const SizedBox(height: 32),

              _buildLawCard(
                '1. Companies Act, 2013 (Section 247, Section 42 & Section 62): Mandatory IBBI Valuer Appraisals',
                'Section 247 of the Companies Act, 2013 strictly stipulates that where any valuation is required in respect of stocks, shares, debentures, securities, or goodwill under the Act, it shall be valued solely by a person registered as a valuer with the Insolvency and Bankruptcy Board of India (IBBI). Under Section 62(1)(c) (Preferential Allotment) and Section 42 (Private Placement), every unlisted company issuing shares to non-members or investors must obtain an IBBI Registered Valuer\'s report justifying the issue price and attach it to Form PAS-3 filed with the Registrar of Companies (ROC). Issuing shares without an IBBI Section 247 report invalidates the allotment, rendering directors liable to severe monetary penalties and compounding proceedings. Furthermore, Section 54 (Sweat Equity) and Section 68 (Share Buyback) mandate registered valuations to protect minority equity holders from unlawful dilution.',
                Icons.gavel,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '2. Income Tax Act, 1961: Section 56(2)(viib) & Rule 11UA (Angel Tax Defense)',
                'Under Section 56(2)(viib) of the Income Tax Act, 1961, where a closely held company receives consideration for the issue of shares exceeding the face value, the aggregate consideration exceeding the Fair Market Value (FMV) is treated as taxable "Income from Other Sources" and taxed at prevailing corporate rates. To establish statutory FMV under Rule 11UA(2), companies may adopt either the Net Asset Value (NAV) book-value method under Sub-rule (2)(a) or the Discounted Free Cash Flow (DCF) method under Sub-rule (2)(b). Following CBDT Notification 68/2023, the scope was expanded to non-resident investors, while adding 5 internationally accepted methods (CCM, PWERM, Option Pricing, Milestone Analysis, Replacement Cost) and a 10% price tolerance safe harbor. ProValuer delivers robust DCF models backed by documented board approvals that shield companies during National Faceless Assessment Centre (NFAC) scrutiny.',
                Icons.account_balance,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '3. Foreign Exchange Management Act (FEMA): RBI Non-Debt Instruments (NDI) Rules',
                'Under the Foreign Exchange Management (Non-Debt Instruments) Rules, 2019, cross-border equity transactions must satisfy strict arm\'s-length pricing caps and floors:\n• Inbound FDI: Equity shares, CCPS, or CCDs issued or transferred to non-residents cannot be priced lower than the Fair Market Value worked out as per any internationally accepted pricing methodology on an arm\'s-length basis, certified by a SEBI Registered Merchant Banker, Chartered Accountant, or IBBI Registered Valuer.\n• Outbound ODI: When an Indian resident acquires equity in an overseas enterprise, the purchase price cannot exceed certified FMV.\nValuation certificates are mandatory attachments for Form FC-GPR (allotments) and Form FC-TRS (transfers) on the RBI FIRMS portal.',
                Icons.public,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '4. Section 50CA & Section 56(2)(x): Anti-Abuse Transfer Pricing on Unlisted Equity',
                'When unlisted shares are transferred between existing shareholders or new buyers, Section 50CA of the Income Tax Act dictates that if the transfer price is lower than the Rule 11UAA Fair Market Value, the FMV is deemed to be the full value of consideration for computing the seller\'s capital gains tax. Concurrently, under Section 56(2)(x), the buyer is taxed on the discount (the difference between FMV and the lower purchase price) as deemed income from other sources. A certified Rule 11UAA valuation report eliminates double taxation jeopardy for both parties.',
                Icons.security,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '5. Ind AS 113 / IFRS 13: Fair Value Measurement Standards for Financial Instruments',
                'Indian Accounting Standard (Ind AS) 113 defines fair value as the price that would be received to sell an asset or paid to transfer a liability in an orderly transaction between market participants at the measurement date. When accounting for share-based payments (Ind AS 102), convertible instruments with embedded derivatives (Ind AS 109), or impairment reviews (Ind AS 36), companies must establish Level 1, Level 2, or Level 3 valuation inputs. ProValuer provides audit-ready valuation models conforming to international accounting scrutiny.',
                Icons.insights,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLawCard(String title, String body, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderSubtle),
            ),
            child: Icon(icon, size: 24, color: _obsidian),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _slateText,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. REGISTERED VALUER VS SEBI MERCHANT BANKER
  // =========================================================================
  Widget _buildValuerVsMerchantBankerSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border.symmetric(horizontal: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'REGULATORY DISAMBIGUATION & LICENSING MATRIX',
                'Registered Valuer vs. SEBI Merchant Banker: Who Can Legally Value Your Shares?',
                'One of the most persistent bottlenecks in corporate equity transactions is confusing the statutory jurisdiction of an IBBI Registered Valuer with that of a SEBI Registered Merchant Banker. Appointing the wrong professional invalidates regulatory filings:',
              ),
              const SizedBox(height: 24),

              Text(
                'Under the Companies Act, 2013, an IBBI Registered Valuer (registered under Section 247 in the asset class of Securities or Financial Assets) has exclusive, mandatory jurisdiction over all corporate transactions including preferential allotment under Section 62(1)(c), private placement under Section 42, sweat equity under Section 54, buybacks under Section 68, and NCLT mergers under Section 232. A Merchant Banker cannot sign these reports unless they are also registered with the IBBI. Conversely, under Income Tax Rule 11UA(2)(b) for DCF valuation under Section 56(2)(viib), the statute historically recognized SEBI Registered Category-I Merchant Bankers. For venture capital fundraising involving Indian resident and non-resident investors, companies frequently require dual-certification or a harmonized report. ProValuer Commercial bridges this divide with complete statutory accreditation.',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _slateText,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 32),

              // Responsive Comparison Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: BoxConstraints(minWidth: isDesktop ? 1140 : 800),
                  decoration: BoxDecoration(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(200),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                      3: FlexColumnWidth(1.2),
                    },
                    border: const TableBorder.symmetric(
                      inside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                    children: [
                      // Header Row
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        children: [
                          _buildTableHeaderCell('Regulatory Transaction'),
                          _buildTableHeaderCell('IBBI Registered Valuer (§ 247)'),
                          _buildTableHeaderCell('SEBI Merchant Banker (Cat-I)'),
                          _buildTableHeaderCell('Chartered Accountant (FCA)'),
                        ],
                      ),
                      _buildTableRow(
                        'Preferential Allotment (§ 62 / § 42)',
                        'Mandatory by Law — Required for ROC Form PAS-3 filing.',
                        'Not Legally Eligible unless also an IBBI Registered Valuer.',
                        'Not Eligible under Companies Act 2013 Section 247.',
                        false,
                      ),
                      _buildTableRow(
                        'Income Tax § 56(2)(viib) DCF (Rule 11UA)',
                        'Eligible under updated parity framework for corporate filings.',
                        'Statutorily Recognized under Rule 11UA(2)(b) DCF method.',
                        'Eligible only for Rule 11UA NAV book-value method.',
                        true,
                      ),
                      _buildTableRow(
                        'FEMA Cross-Border FDI / ODI Pricing',
                        'Fully Recognized by RBI under NDI Rules 2019.',
                        'Fully Recognized by RBI under NDI Rules 2019.',
                        'Eligible for issuing pricing certificate under FEMA.',
                        false,
                      ),
                      _buildTableRow(
                        'NCLT Merger / Swap Ratio (§ 232)',
                        'Mandatory — Must be prepared by IBBI Registered Valuer.',
                        'Issues Fairness Opinion on the Registered Valuer report.',
                        'Cannot sign statutory swap ratio report under Section 247.',
                        true,
                      ),
                      _buildTableRow(
                        'Share Buyback & Capital Reduction',
                        'Mandatory under Section 68 and Section 66 of Companies Act.',
                        'Manages public offer process; relies on RV report.',
                        'Internal accounting support only.',
                        false,
                      ),
                      _buildTableRow(
                        'Sweat Equity & ESOP Perquisite',
                        'Mandatory for Sweat Equity (§ 54); highly recommended for ESOPs.',
                        'Eligible for ESOP fair market value under Income Tax Rules.',
                        'Eligible for perquisite tax certification under Rule 40C.',
                        true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. WHAT IS THE DIFFERENCE BETWEEN NAV AND DCF VALUATION?
  // =========================================================================
  Widget _buildNavVsDcfSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'METHODOLOGY COMPARISON & TAX SCRUTINY',
                'What Is the Difference Between NAV Valuation and DCF Valuation?',
                'When pricing unlisted shares under Rule 11UA of the Income Tax Rules, corporate entities face a critical fork in the road: should they adopt the Net Asset Value (NAV) method or the Discounted Cash Flow (DCF) method? The choice fundamentally impacts the share premium, investor equity dilution, and tax audit vulnerability.',
              ),
              const SizedBox(height: 24),

              Text(
                'The Net Asset Value (NAV) method under Rule 11UA(1)(c) is a backward-looking, asset-based formula. It calculates the book value of all assets on the balance sheet (with statutory adjustments for immovable property circle rates, listed shares, and jewellery), deducts total liabilities, and divides by total equity. It reflects historical accounting cost rather than ongoing commercial vitality. In contrast, the Discounted Cash Flow (DCF) method under Rule 11UA(2)(b) is a forward-looking, income-based approach. It forecasts the company\'s free cash flows over a 3 to 5-year discrete projection period, discounts them to present value using the Weighted Average Cost of Capital (WACC), and adds a perpetual Terminal Value. For technology startups and high-growth enterprises that possess substantial intangible intellectual property, software algorithms, and market traction but negligible historical physical assets, the NAV method yields an artificially depressed value (often near zero or face value). The DCF method is the only methodology that captures the true economic premium justified by venture capital investors.',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  color: _slateText,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 32),

              // NAV vs DCF Comparison Table
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: BoxConstraints(minWidth: isDesktop ? 1140 : 800),
                  decoration: BoxDecoration(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(6),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(180),
                      1: FlexColumnWidth(1.2),
                      2: FlexColumnWidth(1.2),
                    },
                    border: const TableBorder.symmetric(
                      inside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    ),
                    children: [
                      // Header Row
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        children: [
                          _buildTableHeaderCell('Comparison Dimension'),
                          _buildTableHeaderCell('Net Asset Value (NAV) Method'),
                          _buildTableHeaderCell('Discounted Cash Flow (DCF) Method'),
                        ],
                      ),
                      _buildTableRowTwoCol(
                        'Core Philosophy',
                        'Historical, backward-looking asset liquidation value derived from audited balance sheet.',
                        'Forward-looking economic earning power based on projected future cash generation.',
                        false,
                      ),
                      _buildTableRowTwoCol(
                        'Rule 11UA Formula',
                        'Rigid formula: (A − L) × (PV / PE). Adjusted for real estate circle rates and quoted securities.',
                        'Free Cash Flow to Firm (FCFF) discounted at WACC plus Gordon Growth Terminal Value.',
                        true,
                      ),
                      _buildTableRowTwoCol(
                        'Intangible Assets / IP',
                        'Completely ignored unless explicitly capitalized as acquired intangibles on the balance sheet.',
                        'Fully captured through high gross margins, operating leverage, and revenue expansion.',
                        false,
                      ),
                      _buildTableRowTwoCol(
                        'Startup Suitability',
                        'Severely unsuitable for tech startups; yields nominal or near-zero valuations.',
                        'Highly preferred for startups; justifies high valuations and protects share premium.',
                        true,
                      ),
                      _buildTableRowTwoCol(
                        'Tax Scrutiny Vulnerability',
                        'Low scrutiny risk because numbers are drawn directly from audited historical balance sheets.',
                        'High scrutiny risk; tax officers examine projection reasonableness, revenue pipelines, and WACC.',
                        false,
                      ),
                      _buildTableRowTwoCol(
                        'Certifying Authority',
                        'Can be certified by any practicing Chartered Accountant (CA) or Registered Valuer.',
                        'Must be certified by a SEBI Registered Merchant Banker or IBBI Registered Valuer.',
                        true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Tax Scrutiny Guidance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield, color: Color(0xFFD97706), size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Tax Scrutiny Considerations: Defending DCF Projections under Section 56(2)(viib)',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Following the landmark Supreme Court decision in Commissioner of Income Tax v. Vodafone Idea Ltd and numerous ITAT rulings (e.g., Flutura Business Solutions, DQ Entertainment), the Income Tax Assessing Officer cannot arbitrarily reject a taxpayer\'s choice of DCF method in favor of NAV. However, the AO retains the legal power to verify whether the management projections were prepared on a reasonable, bona fide basis. If a startup projects ₹100 Crore in revenue but achieves only ₹1 Crore without documented commercial justification, tax authorities may attempt to recompute the share price. ProValuer mitigates this risk by grounding every DCF in board-approved business plans, market research comparables, and macroeconomic sensitivity bands.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xFF78350F),
                        height: 1.65,
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

  TableRow _buildTableRowTwoCol(String col1, String col2, String col3, bool isAlt) {
    return TableRow(
      decoration: BoxDecoration(
        color: isAlt ? const Color(0xFFF8FAFC) : _pureWhite,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col1,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _obsidian),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col2,
            style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.5),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col3,
            style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.5),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 5. EQUITY VALUATION METHODOLOGIES & CAPITAL INSTRUMENTS
  // =========================================================================
  Widget _buildMethodologiesSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    final methodologies = [
      {
        'title': 'Discounted Cash Flow (DCF) Method',
        'icon': Icons.trending_up,
        'summary': 'The gold standard for high-growth tech startups, SaaS firms, and growth-stage enterprises.',
        'details': 'Under DCF, future cash flows available to capital providers (FCFF or FCFE) are projected over a discrete horizon (3 to 5 years) and discounted to present value using the Weighted Average Cost of Capital (WACC). Terminal Value is modeled using the Gordon Growth Model with a conservative growth rate aligned with Indian long-term inflation/GDP.',
        'instruments': 'Common Equity, Pre-Money Startup Rounds, Series A/B Valuations, Section 56(2)(viib) Defense.',
      },
      {
        'title': 'Net Asset Value (NAV) & Adjusted Book Value',
        'icon': Icons.account_balance_wallet,
        'summary': 'Statutory asset-based methodology under Rule 11UA(1)(c) and Section 50CA.',
        'details': 'Evaluates the fair market value of all underlying assets on the balance sheet minus all outstanding debt and liabilities. Under updated Rule 11UA rules, market adjustments are mandated for immovable property (SRO guideline circle rates), listed shares, and precious metals.',
        'instruments': 'Holding Companies, Real Estate SPVs, Capital Gains Audits (§ 50CA), Distressed Equity Liquidation.',
      },
      {
        'title': 'Comparable Company Multiple (CCM)',
        'icon': Icons.domain,
        'summary': 'Market approach benchmarking company multiples against publicly traded listed peers.',
        'details': 'Identifies listed peers with comparable business models, margins, and growth profiles. Derives enterprise multiples such as EV/Revenue, EV/EBITDA, or P/E, applying a Discount for Lack of Marketability (DLOM) to adjust for the illiquidity of unlisted private stock.',
        'instruments': 'E-Commerce, FinTech, Consumer Brands, Non-Resident Rule 11UA Allotments, M&A Fairness Opinions.',
      },
      {
        'title': 'Precedent Transaction Multiple (PTM)',
        'icon': Icons.handshake,
        'summary': 'Market approach evaluating recent arm\'s-length acquisition prices in the same industry.',
        'details': 'Analyzes the transaction multiples paid by strategic acquirers or private equity buyouts for controlling or minority stakes in similar unlisted entities. Reflects real-world transaction control premiums and competitive bidding dynamics.',
        'instruments': 'Trade Sales, Majority Buyouts, Strategic Investor Inbound FDI, Restructuring Schemes.',
      },
      {
        'title': 'Profit Earning Capacity Value (PECV)',
        'icon': Icons.pie_chart,
        'summary': 'Income approach based on historical weighted average normalized profits.',
        'details': 'Established under historical judicial guidelines (Hindustan Lever v. Employees Union) and RBI guidelines for mature operating companies. Capitalizes a 3 to 5-year weighted average of normalized Profit After Tax (PAT) by an industry capitalization rate.',
        'instruments': 'Traditional Family Businesses, Mature Manufacturing, Court-Appointed Partition Schemes.',
      },
      {
        'title': 'Complex Convertible Instruments & Waterfalls',
        'icon': Icons.account_tree,
        'summary': 'Advanced financial engineering for multi-tier venture capital capitalizations.',
        'details': 'Startups rarely issue pure common stock to institutional investors. We utilize Black-Scholes option pricing models, Monte Carlo simulations, and liquidation preference waterfall models to value Compulsorily Convertible Preference Shares (CCPS), Compulsorily Convertible Debentures (CCDs), Warrants, and SAFE notes factoring in senior liquidation preferences, 1x non-participating caps, conversion ratchets, and anti-dilution adjustments.',
        'instruments': 'Institutional VC Rounds (Series A to D), Mezzanine Debt, Down-Round Protection Audits.',
      },
    ];

    final current = methodologies[_selectedMethodologyIndex];

    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border.symmetric(horizontal: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'VALUATION METHODOLOGIES & CAPITAL INSTRUMENTS',
                'Comprehensive Equity Valuation Methodologies & Complex Instruments',
                'ProValuer Commercial applies internationally accepted valuation approaches recognized under Ind AS 113, International Valuation Standards (IVS), and Indian direct tax enactments:',
              ),
              const SizedBox(height: 32),

              // Selector Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(methodologies.length, (idx) {
                  final item = methodologies[idx];
                  final isSelected = idx == _selectedMethodologyIndex;
                  return ChoiceChip(
                    label: Text(
                      item['title'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : _obsidian,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: _obsidian,
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: BorderSide(color: isSelected ? _obsidian : _borderSubtle),
                    onSelected: (val) {
                      if (val) setState(() => _selectedMethodologyIndex = idx);
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(current['icon'] as IconData, size: 28, color: const Color(0xFF1E40AF)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                current['title'] as String,
                                style: GoogleFonts.montserrat(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: _obsidian,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                current['summary'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2563EB),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, color: _borderSubtle),
                    const SizedBox(height: 20),

                    Text(
                      'Technical Valuation Mechanics:',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current['details'] as String,
                      style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.65),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'Applicable Instruments & Statutory Use Cases:',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderSubtle),
                      ),
                      child: Text(
                        current['instruments'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
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

  // =========================================================================
  // 6. STRATEGIC VALUATION TRIGGERS ACROSS CORPORATE LIFE-CYCLE
  // =========================================================================
  Widget _buildStrategicTriggersSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'TRANSACTION TRIGGERS ACROSS CORPORATE LIFE-CYCLE',
                'Strategic Valuation Triggers: From Seed Stage to Public Listing',
                'Every equity transaction in an unlisted company requires a tailored valuation framework conforming to statutory mandates. ProValuer covers all critical corporate milestones:',
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildTriggerCard(
                        'Startup Fundraising (Seed, Angel & Series A/B)',
                        'DCF modeling to justify pre-money and post-money valuations. Certifying compliance with Section 56(2)(viib) to eliminate Angel Tax liabilities and issuing Form PAS-3 documentation.',
                        Icons.rocket_launch,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Preferential Allotment & Private Placement (§ 62 / § 42)',
                        'Mandatory Section 247 valuation report by an IBBI Registered Valuer specifying the basis of issue price, conversion ratios, and fairness justification for filing with ROC.',
                        Icons.verified,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Cross-Border FEMA Inbound FDI & Outbound ODI',
                        'Certifying RBI arm\'s-length pricing compliance under Non-Debt Instrument Rules for Form FC-GPR / FC-TRS reporting, eliminating foreign exchange compounding risks.',
                        Icons.public,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'ESOPs & Sweat Equity Allotments (§ 54)',
                        'Establishing grant price and exercise price for employee stock option plans; calculating taxable perquisite value under Section 17(2)(vi) and Sweat Equity fair value under Section 54.',
                        Icons.people,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Mergers, Demergers & NCLT Share Swaps (§ 232)',
                        'Formulating equitable Share Entitlement and Swap Ratios for court schemes of amalgamation, supported by fairness opinions and valuation methodology defense before NCLT benches.',
                        Icons.swap_calls,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Share Buybacks (§ 68) & Capital Reduction (§ 66)',
                        'Determining maximum buyback pricing under Section 68 and establishing equitable share redemption values in court-approved capital reduction schemes to protect creditors.',
                        Icons.remove_circle_outline,
                        cardW,
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

  Widget _buildTriggerCard(String title, String desc, IconData icon, double width) {
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
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

  // =========================================================================
  // 7. HOW IS AN UNLISTED COMPANY VALUED? ECONOMIC MODELING
  // =========================================================================
  Widget _buildHowUnlistedCompanyValuedSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border.symmetric(horizontal: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'MATHEMATICAL MODELING & FINANCIAL AUDIT',
                'How Is an Unlisted Company Valued? Step-by-Step Economic Modeling',
                'Valuing private unlisted equity demands mathematical rigor combining corporate financial economics with strict regulatory safe harbors:',
              ),
              const SizedBox(height: 24),

              // Mathematical Formula Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROVALUER DISCOUNTED CASH FLOW (DCF) ENTERPRISE FORMULATION',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Enterprise Value (EV) = ∑ [FCFF_t / (1 + WACC)^t] + [Terminal Value_n / (1 + WACC)^n]\n\nEquity Value = Enterprise Value + Cash & Non-Operating Assets − Total Debt & Debt-Like Instruments\n\nFair Market Value Per Share = Equity Value / Fully Diluted Number of Shares',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isDesktop ? 14 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Calculated strictly under Ind AS 113, International Valuation Standards (IVS), and Income Tax Rule 11UA(2)(b).',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4 Detailed Pillars
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 24) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildPillarCard(
                        '1. Free Cash Flow to Firm (FCFF) Normalization',
                        'We normalize historical and projected financials: FCFF = Operating EBIT × (1 − Tax Rate) + Depreciation & Amortization − Capital Expenditures (CapEx) − Change in Non-Cash Working Capital. We audit promoter compensation, remove non-recurring extraordinary gains/losses, and verify commercial sales pipeline contracts.',
                        colW,
                      ),
                      _buildPillarCard(
                        '2. Deriving Weighted Average Cost of Capital (WACC)',
                        'WACC = (E/V × Ke) + (D/V × Kd × (1 − T)). We determine the Cost of Equity (Ke) using the Capital Asset Pricing Model (CAPM): Ke = Rf + β × (Rm − Rf) + Size Premium + Company Specific Risk Premium (CSRP). We unlever and relever raw industry betas from listed peers using Hamada\'s equation.',
                        colW,
                      ),
                      _buildPillarCard(
                        '3. Terminal Value Quantification (Gordon Growth)',
                        'Because private companies operate in perpetuity, 60%–75% of total value resides in the Terminal Value: TV = [FCFF_(n+1)] / (WACC − g). ProValuer caps the terminal growth rate (g) strictly below India\'s long-term sovereign GDP expansion (typically 4.0%–5.0%), preventing tax authorities from challenging terminal values as speculative.',
                        colW,
                      ),
                      _buildPillarCard(
                        '4. Discounts for Lack of Marketability & Control (DLOM & DLOC)',
                        'Private unlisted shares cannot be liquidated instantly on an exchange. Where appropriate (e.g., secondary minority transfers, family partitions), we quantify empirical DLOM haircuts (15%–30%) using Chaffe and Finnerty option-pricing models and apply DLOC for non-voting equity.',
                        colW,
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

  Widget _buildPillarCard(String title, String body, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: _slateText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 8. DOCUMENTATION CHECKLIST & 6 CRITICAL DOCUMENTATION MISTAKES
  // =========================================================================
  Widget _buildDocumentationSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'DUE DILIGENCE & REGULATORY DOSSIER',
                'Documentation Checklist for Certified Share Valuation',
                'To prepare an unassailable equity valuation report compliant with ROC, Income Tax, and FEMA standards, the following corporate dossier is required:',
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildDocCategoryCard(
                        '1. Corporate Governance & Charters',
                        [
                          'Certificate of Incorporation (CIN)',
                          'Updated Memorandum & Articles of Association (MOA & AOA)',
                          'Fully Diluted Capitalization Table (Cap Table)',
                          'Board Resolutions approving the proposed allotment/transfer',
                          'Shareholders\' Agreement & Subscription Agreements (SHA/SSA)',
                        ],
                        colW,
                      ),
                      _buildDocCategoryCard(
                        '2. Historical & Provisional Financials',
                        [
                          'Audited Financial Statements (Last 3–5 Fiscal Years)',
                          'Statutory Audit Reports, CARO reports & Tax Audit Notes',
                          'Provisional Financial Statements as on the valuation cutoff date',
                          'Asset Depreciation Schedules & Intangible Capitalization records',
                          'Income Tax Returns (ITR-6) and Form 3CD for past 3 years',
                        ],
                        colW,
                      ),
                      _buildDocCategoryCard(
                        '3. Projections & Business Model',
                        [
                          'Detailed 3–5 Year Financial Model approved by the Board',
                          'Revenue driver assumptions, CAC, LTV & unit economics',
                          'CapEx schedules, hiring plans & working capital cycles',
                          'Debt sanction letters & loan amortization schedules',
                          'Customer pipeline contracts & LOIs supporting revenue growth',
                        ],
                        colW,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),

              // 6 Critical Documentation Mistakes
              Text(
                '6 Critical Valuation Documentation Mistakes That Provoke Income Tax Scrutiny Notices',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: _obsidian,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In our forensic review of Section 56(2)(viib) assessments and ROC inquiries, these six fatal mistakes systematically trigger reassessments and share premium additions:',
                style: GoogleFonts.inter(fontSize: 14, color: _slateText),
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = isDesktop
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildDeficiencyCard(
                        '1. Unsubstantiated Hockey-Stick Revenue Projections',
                        'Submitting aggressive DCF projections without pipeline contracts or market comparables, enabling Assessing Officers to reject the DCF model entirely as speculative.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '2. Discordant Valuation Cutoff Dates',
                        'Issuing valuation reports dated months prior to or after the Board resolution for share allotment, violating strict Rule 11UA contemporaneous valuation mandates.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '3. Ignoring Fully Diluted Capitalization Structures',
                        'Valuing equity on an undiluted basis while ignoring in-the-money CCPS, CCDs, or ESOP pools, drastically distorting per-share fair market value.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '4. Generic Beta Assumptions Without Listed Peer Unlevering',
                        'Copying conglomerate betas rather than calculating unlevered industry asset betas, destroying discount rate credibility during scrutiny.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '5. Failure to Secure Formal Board Approval for Projections',
                        'Submitting management projections that were never formally approved by the company\'s Board of Directors through a documented resolution.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '6. Engaging Unregistered Valuers for Companies Act Filings',
                        'Filing Form PAS-3 using reports from chartered accountants lacking IBBI Section 247 registration, leading to automatic ROC rejection and penalties.',
                        cardW,
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

  Widget _buildDocCategoryCard(String title, List<String> items, double width) {
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
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        it,
                        style: GoogleFonts.inter(fontSize: 12.5, color: _slateText, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildDeficiencyCard(String title, String desc, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 22, color: Color(0xFFE11D48)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF9F1239),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4C0519), height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 9. HYDERABAD & TELANGANA STARTUP INNOVATION ECOSYSTEM
  // =========================================================================
  Widget _buildHyderabadStartupSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border.symmetric(horizontal: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'REGIONAL INNOVATION & CORPORATE HUBS',
                'Hyderabad & Telangana Startup Innovation Ecosystem: T-Hub, HITEC City & Genome Valley',
                'Hyderabad is one of India\'s most vibrant venture capital and technology hubs. ProValuer Commercial delivers specialized valuation advisory tailored to regional corporate regulators and tech corridors:',
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 24) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildRegionalCard(
                        'T-Hub 2.0, T-Works & HITEC City Tech Corridors',
                        'We work extensively with SaaS, AI, DeepTech, and FinTech startups incubated across T-Hub 2.0, IIT Hyderabad, and HITEC City tech parks. From early-stage SAFE notes and angel rounds to Series A venture capital closings, our certified reports provide founders with ironclad defense against Angel Tax assessments while satisfying institutional VC term sheets.',
                        Icons.rocket_launch,
                        colW,
                      ),
                      _buildRegionalCard(
                        'Genome Valley & Pharma / Life Sciences Intellectual Property',
                        'Genome Valley houses India\'s premier biotechnology, pharmaceutical, and vaccine manufacturing enterprises. Valuing life sciences companies requires specialized multi-phase clinical trial pipeline modeling, patent exclusivity duration audits, and risk-adjusted Net Present Value (rNPV) modeling recognized by global life science investors.',
                        Icons.biotech,
                        colW,
                      ),
                      _buildRegionalCard(
                        'Registrar of Companies (ROC) Hyderabad Bench Standards',
                        'Our IBBI Registered Valuers prepare valuation dossiers specifically formatted to comply with the stringent scrutiny requirements of the Registrar of Companies (ROC), Hyderabad. We ensure zero delays or re-submission requisitions when filing Form PAS-3, MGT-14, and SH-7 on the MCA21 portal.',
                        Icons.business,
                        colW,
                      ),
                      _buildRegionalCard(
                        'NCLT Hyderabad Bench: Mergers, Swaps & Resolution Plans',
                        'For corporate restructurings, amalgamations under Section 232, and CIRP fair value determinations under IBC, our team submits court-admissible share swap ratios and liquidation value determinations directly to the National Company Law Tribunal (NCLT) Hyderabad Bench.',
                        Icons.balance,
                        colW,
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

  Widget _buildRegionalCard(String title, String desc, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: _obsidian),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            desc,
            style: GoogleFonts.inter(fontSize: 13.5, color: _slateText, height: 1.65),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 10. THE PROVALUER 4-STAGE FORENSIC SHARE VALUATION PROTOCOL
  // =========================================================================
  Widget _buildFourStageProtocolSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'INSTITUTIONAL EXECUTION & FORENSIC RIGOR',
                'The ProValuer 4-Stage Forensic Share Valuation Protocol',
                'To guarantee 100% regulatory acceptance across ROC, Income Tax, and FEMA portals, ProValuer Commercial executes an institutional four-stage protocol:',
              ),
              const SizedBox(height: 32),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 48) / 4
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildProtocolCard(
                        'Stage 1',
                        'Cap Table & Governance Audit',
                        'Reviewing MOA, AOA, SHAs, voting covenants, fully diluted equity structures, CCPS conversion terms, and board resolutions to establish the legal baseline.',
                        Icons.search,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 2',
                        'Financial Normalization & Interviews',
                        'Analyzing 3–5 year audited financials, normalizing promoter compensation, validating sales pipelines, and interviewing leadership on unit economics and CapEx cycles.',
                        Icons.analytics,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 3',
                        'Multi-Approach Financial Modeling',
                        'Building empirical DCF models, WACC derivations via CAPM, peer multiple benchmarking, and sensitivity analyses compliant with Rule 11UA and Ind AS 113.',
                        Icons.calculate,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 4',
                        'Certified Issuance & Tax Defense',
                        'Issuing signed, tamper-evident IBBI Registered Valuer reports for Form PAS-3 / FEMA filings, backed by full technical support during income tax scrutiny proceedings.',
                        Icons.verified_user,
                        colW,
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

  Widget _buildProtocolCard(String stage, String title, String desc, IconData icon, double width) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              stage,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E40AF),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Icon(icon, size: 28, color: _obsidian),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slateText,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 11. INSTITUTIONAL SHARE VALUATION FAQS
  // =========================================================================
  Widget _buildFaqSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    final faqs = [
      {
        'q': 'Who is legally authorized to issue a share valuation report for a private limited company in India?',
        'a': 'Under Section 247 of the Companies Act, 2013, all share valuations for preferential allotments (Section 62), private placements (Section 42), sweat equity (Section 54), buybacks (Section 68), and NCLT mergers must be conducted exclusively by a Registered Valuer registered with the Insolvency and Bankruptcy Board of India (IBBI) in the asset class of Securities or Financial Assets. For Income Tax Rule 11UA(2)(b) DCF valuation under Section 56(2)(viib), SEBI Registered Merchant Bankers are recognized. For FEMA FDI transactions, reports from IBBI Registered Valuers, Merchant Bankers, or Chartered Accountants are acceptable to the RBI.',
      },
      {
        'q': 'What is the difference between a Registered Valuer under the Companies Act and a SEBI Merchant Banker under Income Tax?',
        'a': 'An IBBI Registered Valuer holds a personal statutory license under Section 247 of the Companies Act, 2013, with exclusive authority over corporate MCA/ROC filings (such as Form PAS-3). A SEBI Registered Merchant Banker holds an entity-level license under SEBI regulations and has historical recognition under Rule 11UA(2)(b) of the Income Tax Act for certifying DCF reports. For comprehensive startup rounds involving both ROC allotments and direct tax scrutiny, companies frequently obtain dual-certified or harmonized valuation dossiers.',
      },
      {
        'q': 'How is the Fair Market Value (FMV) of unlisted shares calculated under Rule 11UA?',
        'a': 'Under Rule 11UA, FMV is calculated using either the Net Asset Value (NAV) method under Sub-rule (1)(c)/(2)(a) or the Discounted Cash Flow (DCF) method under Sub-rule (2)(b). The NAV formula takes the book value of assets minus liabilities, adjusted for the market/circle value of immovable properties, listed shares, and jewellery. The DCF method forecasts 3–5 year free cash flows discounted at the company\'s WACC plus Terminal Value. Following CBDT amendments, 5 additional internationally accepted methods (CCM, PWERM, Option Pricing, Milestone Analysis, Replacement Cost) are recognized for non-resident investments alongside a 10% safe harbor band.',
      },
      {
        'q': 'What is Section 56(2)(viib) "Angel Tax", and how does a DCF valuation report provide legal immunity?',
        'a': 'Section 56(2)(viib) taxes any excess premium received on the issue of unlisted shares above their Fair Market Value as taxable "Income from Other Sources". A DCF valuation report prepared by an accredited valuer contemporaneously with the board resolution establishes statutory FMV under Rule 11UA(2)(b). Judicial precedents confirm that Assessing Officers cannot arbitrarily replace the taxpayer\'s DCF method with NAV if the underlying financial model was prepared on a bona fide basis backed by board-approved business plans.',
      },
      {
        'q': 'What are the mandatory valuation requirements for foreign direct investment (FDI) under RBI FEMA regulations?',
        'a': 'Under the Foreign Exchange Management (Non-Debt Instruments) Rules, 2019, any shares, CCPS, or CCDs issued or transferred to a non-resident must comply with arm\'s-length pricing caps and floors: the issue or transfer price cannot be less than the Fair Market Value worked out as per any internationally accepted pricing methodology, certified by an IBBI Registered Valuer, SEBI Merchant Banker, or Chartered Accountant. This certificate must be submitted on the RBI FIRMS portal alongside Form FC-GPR or Form FC-TRS within 30 days.',
      },
      {
        'q': 'Can a private company issue shares at a premium above the Fair Market Value determined by a valuer?',
        'a': 'Under the Companies Act, 2013, a company can issue shares at any price determined by an IBBI Registered Valuer\'s report under Section 62(1)(c). However, under Income Tax Section 56(2)(viib), if shares are issued to resident investors at a price higher than the certified Rule 11UA Fair Market Value, the excess premium is taxed as income in the company\'s hands. Therefore, the valuation report should accurately reflect the full commercial enterprise value to avoid tax leakage.',
      },
      {
        'q': 'How are Compulsorily Convertible Preference Shares (CCPS) valued during startup fundraising rounds?',
        'a': 'CCPS are valued on a fully diluted conversion basis using Black-Scholes option pricing models, probability-weighted expected returns (PWERM), or conversion ratio analysis. The valuer evaluates the coupon dividend rate, conversion price, seniority of liquidation preferences (e.g., 1x non-participating), anti-dilution adjustments, and expected exit horizon to certify the fair value per preference share for ROC Form PAS-3 and FEMA FC-GPR compliance.',
      },
      {
        'q': 'What is the validity period of a share valuation report for ROC and Income Tax filings?',
        'a': 'Under Rule 11UA of the Income Tax Rules, the valuation date can be the date on which the consideration is received or a date not earlier than 90 days prior to the date of allotment. Under the Companies Act, ROC norms generally expect the valuation report to be contemporaneous with the Board resolution approving the private placement offer letter (Form PAS-4), typically within 30 to 60 days of issue.',
      },
      {
        'q': 'How is the exercise price of Employee Stock Options (ESOPs) determined for corporate tax compliance?',
        'a': 'Under Section 17(2)(vi) of the Income Tax Act read with Rule 40C, the perquisite value of ESOPs is taxable in the employee\'s hands on the date of exercise. The perquisite value equals the Fair Market Value of the shares on the exercise date minus the exercise price paid by the employee. For unlisted companies, this FMV must be certified by an accredited valuer using the DCF or NAV method.',
      },
      {
        'q': 'What penalties apply if shares of an unlisted company are transferred below Fair Market Value under Section 50CA?',
        'a': 'If unlisted shares are transferred below the Rule 11UAA Fair Market Value, Section 50CA deems the FMV to be the full sale consideration, triggering heavy capital gains tax and interest for the seller. Concurrently, under Section 56(2)(x), the buyer is taxed on the difference as deemed gift income at regular slab rates. Both parties face substantial penalties under Section 270A for under-reporting of income.',
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _lightBg,
        border: Border.symmetric(horizontal: BorderSide(color: _borderSubtle)),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'REGULATORY & CORPORATE FINANCE ADVISORY',
                'Frequently Asked Questions (Share & Equity Valuation FAQs)',
                'Authoritative guidance on statutory compliance, Angel Tax immunity, and FEMA pricing under Indian corporate and direct tax laws:',
              ),
              const SizedBox(height: 32),

              ...List.generate(faqs.length, (idx) {
                final faq = faqs[idx];
                final isExpanded = _expandedFaqIndices.contains(idx);
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _pureWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isExpanded ? _obsidian : _borderSubtle),
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: isExpanded,
                    onExpansionChanged: (_) => _toggleFaq(idx),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    title: Text(
                      faq['q']!,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    children: [
                      Text(
                        faq['a']!,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: _slateText,
                          height: 1.65,
                        ),
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

  // =========================================================================
  // 12. EXECUTIVE CONSULTATION & PRIVATE EQUITY CTA
  // =========================================================================
  Widget _buildCtaSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      decoration: const BoxDecoration(
        color: _obsidian,
      ),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 72 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  'CONFIDENTIAL EQUITY & VENTURE CAPITAL ADVISORY DESK',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Planning an Investment Round, Preferential Allotment or Cross-Border FEMA Transaction?',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 32 : (isTablet ? 26 : 22),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Consult our IBBI Registered Valuers (Securities or Financial Assets). We provide tech startups, corporate boards, and investment funds with unassailable DCF financial models, Form PAS-3 certifications, and FEMA compliance dossiers with complete corporate confidentiality.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 15 : 13.5,
                  color: const Color(0xFF94A3B8),
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 36),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _launchWhatsApp(
                      'Hello ProValuer Commercial, I would like to schedule an equity valuation consultation for a funding round / Section 247 report.',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.white),
                    label: Text(
                      'WhatsApp Equity Advisory Desk',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _launchDialer(_primaryPhone),
                    icon: const Icon(Icons.phone_in_talk, size: 18, color: Colors.white),
                    label: Text(
                      'Direct Line: $_primaryPhoneFormatted',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF475569)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Strict Non-Disclosure (NDA) Protocol • Section 247 Companies Act • Pan-India Regulatory Coverage',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 13. INSTITUTIONAL FOOTER
  // =========================================================================
  Widget _buildFooterSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      color: const Color(0xFF0A0F1D),
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 48) / 4
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 24,
                    children: [
                      // Col 1: Brand & Credentials
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'PROVALUER',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'IBBI Registered Valuers (Securities or Financial Assets) and Government Approved Valuers (Wealth Tax Act § 34AB). Delivering high-precision equity modeling for startups, corporates, and cross-border transactions.',
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
                              'VALUATION SERVICES',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFooterLink('Government Approved Valuers', () => context.go('/government-approved-valuers')),
                            _buildFooterLink('Property Valuation Services', () => context.go('/services/property-valuation')),
                            _buildFooterLink('Share & Equity Valuation', () => context.go('/services/share-valuation')),
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                            _buildFooterLink('NCLT & IBC Valuation', () => context.go('/services/nclt-ibc-valuation')),
                            _buildFooterLink('Divorce Matrimonial Valuation', () => context.go('/services/divorce-matrimonial-valuation')),
                            _buildFooterLink('Probate & Estate Valuation', () => context.go('/services/probate-inheritance-valuation')),
                          ],
                        ),
                      ),

                      // Col 3: Statutory Domains
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STATUTORY DOMAINS',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFooterText('Companies Act 2013 § 247 / § 62 / § 42'),
                            _buildFooterText('Income Tax Act § 56(2)(viib) & Rule 11UA'),
                            _buildFooterText('FEMA Non-Debt Instruments (NDI) Rules'),
                            _buildFooterText('Section 50CA & 56(2)(x) Capital Gains'),
                            _buildFooterText('Ind AS 113 / IFRS 13 Fair Value'),
                            _buildFooterText('Insolvency & Bankruptcy Code Regulation 35'),
                          ],
                        ),
                      ),

                      // Col 4: Contact & Confidentiality
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EQUITY ADVISORY DESK',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFooterText('Confidential Advisory Desk'),
                            _buildFooterText('Phone: $_primaryPhoneFormatted'),
                            _buildFooterText('WhatsApp: +91 85008 80333'),
                            _buildFooterText('Hub: Hyderabad, Telangana (T-Hub / HITEC)'),
                            _buildFooterText('Jurisdiction: Pan-India ROC & MCA21'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
              const Divider(color: Color(0xFF1E293B)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 ProValuer Commercial. All Rights Reserved.',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                  ),
                  Text(
                    'Legally Grounded • Section 247 Compliant • Rule 11UA Stamped',
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

  Widget _buildFooterLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF94A3B8),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF334155),
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
          fontSize: 12,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3, String col4, bool isAlt) {
    return TableRow(
      decoration: BoxDecoration(
        color: isAlt ? const Color(0xFFF8FAFC) : _pureWhite,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col1,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col2,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _slateText,
              height: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col3,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _slateText,
              height: 1.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            col4,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _slateText,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String badge, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _borderSubtle),
          ),
          child: Text(
            badge,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _obsidian,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            color: _slateText,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}
