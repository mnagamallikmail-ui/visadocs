import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/landing_theme.dart';

/// Professional Service Page: Property Valuation for Probate, Inheritance & Estate Succession
/// Canonical URL: https://www.provaluer.in/services/probate-inheritance-valuation
/// Target Word Count: 5,350 - 6,500 words of dense, institutional, court-admissible testamentary legal prose.
class ProbateInheritanceValuationScreen extends StatefulWidget {
  const ProbateInheritanceValuationScreen({super.key});

  @override
  State<ProbateInheritanceValuationScreen> createState() => _ProbateInheritanceValuationScreenState();
}

class _ProbateInheritanceValuationScreenState extends State<ProbateInheritanceValuationScreen> {
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

              // 1. STATUTORY TESTAMENTARY HERO SECTION
              SliverToBoxAdapter(
                child: _buildHeroSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 2. STATUTORY LEGAL FRAMEWORK
              SliverToBoxAdapter(
                child: _buildStatutoryFrameworkSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 3. PROBATE VS LETTERS OF ADMINISTRATION VS SUCCESSION CERTIFICATE
              SliverToBoxAdapter(
                child: _buildComparisonSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 4. WHY ESTATE VALUATIONS ARE LEGALLY MANDATORY
              SliverToBoxAdapter(
                child: _buildWhyValuationsRequiredSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 5. HOW IS AN ESTATE VALUED? NET DISTRIBUTABLE ESTATE FORMULATION
              SliverToBoxAdapter(
                child: _buildHowEstateValuedSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 6. MULTI-ASSET ESTATE VALUATION COVERAGE
              SliverToBoxAdapter(
                child: _buildMultiAssetCoverageSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 7. COMPREHENSIVE DOCUMENTATION CHECKLIST & 6 FATAL DEFICIENCIES
              SliverToBoxAdapter(
                child: _buildDocumentationSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 8. HYDERABAD & TELANGANA REGIONAL TESTAMENTARY PRACTICE
              SliverToBoxAdapter(
                child: _buildHyderabadTelanganaSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 9. THE PROVALUER 4-STAGE ESTATE VALUATION PROTOCOL
              SliverToBoxAdapter(
                child: _buildFourStageProtocolSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 10. INSTITUTIONAL TESTAMENTARY & PROBATE FAQS
              SliverToBoxAdapter(
                child: _buildFaqSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 11. CONFIDENTIAL ESTATE CONSULTATION CTA
              SliverToBoxAdapter(
                child: _buildCtaSection(context, isDesktop, isTablet, contentPadding),
              ),

              // 12. INSTITUTIONAL FOOTER
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
                          'COMMERCIAL & TESTAMENTARY',
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
                    const SizedBox(width: 24),
                    _buildNavAction('Property Valuation', () => context.go('/services/property-valuation')),
                    const SizedBox(width: 24),
                    _buildNavAction('Matrimonial Valuation', () => context.go('/services/divorce-matrimonial-valuation')),
                    const SizedBox(width: 24),
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
                      'Hello ProValuer Commercial, I require a certified estate valuation report for a High Court probate / succession petition.',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                    label: Text(
                      isDesktop ? 'Probate Advisory' : 'Inquire',
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _slateText,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. STATUTORY TESTAMENTARY HERO SECTION
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
                    'Probate, Inheritance & Estate Valuation',
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
                  _buildComplianceBadge('Wealth Tax Act § 34AB Registered Valuers'),
                  _buildComplianceBadge('Companies Act § 247 IBBI Registered'),
                  _buildComplianceBadge('Indian Evidence Act § 45 Expert Testimony'),
                  _buildComplianceBadge('Indian Succession Act 1925 Compliant'),
                  _buildComplianceBadge('High Court Admissible Schedule of Assets'),
                ],
              ),
              const SizedBox(height: 20),

              // H1 Heading
              Text(
                'Certified Property & Estate Valuation for Probate, Succession & Family Settlements in India',
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
                'Court-admissible, independent forensic appraisals of residential estates, commercial office portfolios, multi-tenant retail complexes, agricultural acreage, unlisted business shareholdings, private family trusts, and ancestral jewellery. Prepared by Government Approved Valuers under Section 34AB of the Wealth Tax Act, 1957 and Registered Valuers under Section 247 of the Companies Act, 2013. Designed strictly to satisfy Section 276 of the Indian Succession Act, 1925, Section 45 of the Indian Evidence Act, 1872, and State Court Fees Acts. Providing High Court testamentary registries, civil judges, testamentary executors, and legal heirs with unassailable asset inventories to compute exact ad valorem court fees, substantiate Letters of Administration, execute equitable family partition deeds, and eliminate bitter coparcenary litigation with absolute statutory confidentiality.',
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
                        '100% Admissible',
                        'High Court & District Civil Court',
                        'Conforming strictly to Section 45 Indian Evidence Act and Section 276 Indian Succession Act standards.',
                        Icons.balance,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        'Ad Valorem Precision',
                        'Court Fee & Audit Defense',
                        'Eliminating District Collector under-valuation queries and registry caveats with empirical valuation benchmarks.',
                        Icons.account_balance,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        'Multi-Asset Scope',
                        'Real Estate, Shares, Trust & Gold',
                        'Comprehensive appraisal of immovable properties, corporate holdings, unlisted equity, and certified Stridhan.',
                        Icons.domain,
                        cardW,
                      ),
                      _buildHeroStatCard(
                        '24–48 Hours SLA',
                        'Expedited Legal Delivery',
                        'Rapid preliminary title vetting and expedited certified issuance across Hyderabad, Telangana, and Pan-India.',
                        Icons.timer,
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
              fontSize: 18,
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
  // 2. STATUTORY LEGAL FRAMEWORK
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
                'STATUTORY TESTAMENTARY FRAMEWORK',
                'Statutory Legal Framework: Probate, Testamentary Succession & Judicial Appraisals',
                'Estate administration in India is governed by rigorous personal laws, testamentary statutes, civil evidentiary mandates, and state revenue regulations. A property valuation report submitted to a High Court or Civil Court must withstand scrutiny under the following primary enactments:',
              ),
              const SizedBox(height: 32),

              _buildLawCard(
                '1. Indian Succession Act, 1925: Sections 276, 278, and the Mandatory Schedule of Assets',
                'Section 276 of the Indian Succession Act, 1925 provides that every petition for the probate of a will must annex a comprehensive, verified Schedule of Assets itemizing all movable and immovable properties of the deceased. Under Section 278, an identical sworn inventory is mandatory when applying for Letters of Administration in intestate estates. Under Sections 317 and 318, an executor or administrator must exhibit a full and true inventory within six months, containing an accurate estimate of the estate’s value. If an executor relies on informal broker estimates or circle rates that deviate from fair market realities, they become personally vulnerable to accusations of devastavit (mismanagement or waste of estate assets) by aggrieved beneficiaries. ProValuer Commercial provides court-admissible valuations that establish definitive market baselines, protecting executors from personal surcharge actions.',
                Icons.gavel,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '2. Hindu Succession Act, 1956: Coparcenary Rights, Section 6 Devolution & Class-I Heirs',
                'Under Section 6 of the Hindu Succession Act, 1956 (amended by the 2005 Amendment Act and conclusively interpreted by the Supreme Court of India in Vineeta Sharma v. Rakesh Sharma (2020) 9 SCC 1), daughters possess coparcenary rights by birth on equal footing with sons. When valuing estates involving Hindu Joint Family holdings, a fundamental distinction must be drawn between coparcenary property (which is subject to a deemed notional partition immediately prior to the deceased coparcener\'s demise) and the deceased\'s self-acquired property, which devolves exclusively upon Class-I legal heirs under Section 8. An erroneous appraisal that conflates coparcenary land with self-acquired estate invites immediate caveats and partitions suits. ProValuer\'s multi-layered audits isolate ancestral shares from absolute testamentary bequests.',
                Icons.diversity_3,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '3. Indian Evidence Act, 1872 (Section 45): Admissibility of Certified Valuers as Expert Witnesses',
                'Under Section 45 of the Indian Evidence Act, 1872, the opinion of an expert upon a point of science, art, or specialized technical subject matter is admissible as certified evidence before all courts of law. High Court testamentary benches and District Civil Judges consistently set aside real estate broker estimates, uncertified chartered accountant net worth certificates, or informal family assertions as legally inadmissible hearsay. Reports prepared by our Government Approved Valuers (registered under Section 34AB of the Wealth Tax Act, 1957) and IBBI Registered Valuers (under Section 247 of the Companies Act, 2013) carry statutory authority, establishing empirical methodology, depreciation schedules, and comparable sale registries that withstand hostile cross-examination.',
                Icons.verified,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '4. The Court Fees Act, 1870 & State Court Fee Amendments: Avoiding Deficit Penalties',
                'In all probate and succession proceedings, court fees are levied ad valorem based on the net value of the estate under the relevant State Court Fees and Suits Valuation Act (e.g., Article 6, Schedule I of the Telangana Court Fees and Suits Valuation Act, 1956). High Court registries routinely issue references under Section 19H of the Court Fees Act to the District Collector / Chief Controlling Revenue Authority (CCRA) to inspect the schedule of assets. If an applicant arbitrarily undervalues the property using outdated circle rates, the Collector issues severe deficit court fee notices alongside penalty interest, freezing the grant of probate. Conversely, unverified portal estimates lead to catastrophic overpayment of non-refundable court fees. ProValuer delivers precise, defensible market assessments that pass Collector scrutiny cleanly.',
                Icons.account_balance_wallet,
              ),
              const SizedBox(height: 16),

              _buildLawCard(
                '5. Order XXVI Rule 9 of the Code of Civil Procedure, 1908: Court-Appointed Local Commissioner Inquiries',
                'In high-stakes, contested probate disputes and partition suits, civil courts frequently exercise power under Order XXVI Rule 9 of the Code of Civil Procedure (CPC) to appoint an independent Local Commissioner or valuation expert to inspect the suit property, establish physical boundaries, verify ongoing possession, and assess rental yields. ProValuer Commercial regularly acts as court-appointed commissioners and expert technical witnesses, submitting impartial, empirical local investigation reports complete with geo-coordinates, architectural plinth verifications, and encumbrance audits.',
                Icons.apartment,
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
  // 3. PROBATE VS LETTERS OF ADMINISTRATION VS SUCCESSION CERTIFICATE
  // =========================================================================
  Widget _buildComparisonSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
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
                'TESTAMENTARY DISAMBIGUATION & JURISDICTION',
                'What Is the Difference Between Probate, Letters of Administration, and Succession Certificate?',
                'When administering a deceased individual\'s estate under the Indian Succession Act, 1925, legal heirs, executors, and advocates must distinguish between Probate, Letters of Administration (LoA), and Succession Certificates. While each emanates from judicial authority, their scope, applicant eligibility, and valuation requirements differ substantially.',
              ),
              const SizedBox(height: 24),

              Text(
                'Under Section 2(f) and Section 222 of the Indian Succession Act, a Probate is granted strictly to the named executor under a valid will to conclusively prove its authenticity and execute bequests. It is mandatory for wills executed within the Presidency towns of Mumbai, Kolkata, and Chennai, or concerning real estate situated therein under Sections 57 and 213. Conversely, under Sections 218 and 278, Letters of Administration are granted when an individual dies intestate (without a will), or where a will exists but no executor was appointed, the named executor renounces probate, or dies prior to proving the will. LoA can be granted to universal legatees or legal heirs, empowering them to manage the entire estate (movable and immovable). Finally, under Part X (Sections 370–390), a Succession Certificate is a specialized judicial decree granted by a civil court solely to realize movable debts, securities, provident funds, shares, and bank balances. Crucially, a Succession Certificate cannot be granted for immovable property. In all three proceedings, certified asset valuation is a statutory bottleneck: for Probate and LoA, it establishes the mandatory Schedule of Assets and ad valorem court fees; for Succession Certificates, it ensures unlisted equity and debts are accurately quantified for court fee stamping.',
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
                      0: FixedColumnWidth(180),
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
                          _buildTableHeaderCell('Feature / Dimension'),
                          _buildTableHeaderCell('Probate'),
                          _buildTableHeaderCell('Letters of Administration (LoA)'),
                          _buildTableHeaderCell('Succession Certificate'),
                        ],
                      ),
                      _buildTableRow(
                        'Primary Legal Purpose',
                        'Conclusively proves validity of a will and establishes legal authority of the named executor.',
                        'Appoints an administrator to manage and distribute the entire estate (movable and immovable).',
                        'Establishes legal title to realize movable debts, bank accounts, securities, and dividends.',
                        false,
                      ),
                      _buildTableRow(
                        'Statutory Provisions',
                        'Indian Succession Act, 1925 (Sections 213, 222, 276).',
                        'Indian Succession Act, 1925 (Sections 218, 232, 278).',
                        'Indian Succession Act, 1925 (Part X, Sections 370–390).',
                        true,
                      ),
                      _buildTableRow(
                        'Who Applies?',
                        'Strictly the named executor(s) appointed under the valid will.',
                        'Legal heirs, universal legatees, or residuary beneficiaries.',
                        'Any Class-I or Class-II legal heir claiming entitlement to movable debts.',
                        false,
                      ),
                      _buildTableRow(
                        'When Required?',
                        'When a valid will exists; mandatory in Mumbai, Kolkata, Chennai, and for High Court asset transfers.',
                        'When the deceased dies intestate, or when the will appoints no executor, or the executor refuses to act.',
                        'When the deceased dies intestate leaving financial securities, shares, or bank accounts.',
                        true,
                      ),
                      _buildTableRow(
                        'Immovable Property Covered?',
                        'Yes — Fully covers residential, commercial, industrial, and agricultural real estate.',
                        'Yes — Authorizes the administrator to partition, sell, or transfer immovable properties.',
                        'No — Statutorily restricted to movable debts and securities only.',
                        false,
                      ),
                      _buildTableRow(
                        'Valuation Role',
                        'Mandatory Schedule of Assets to compute ad valorem court fees and defeat Collector audit notices.',
                        'Mandatory sworn appraisal to establish court jurisdiction, determine court fees, and calculate administrative bond.',
                        'Mandatory valuation of unlisted equity, company securities, and debt portfolios for court stamping.',
                        true,
                      ),
                      _buildTableRow(
                        'Court Jurisdiction',
                        'High Court (Testamentary Jurisdiction) or District Delegate / District Civil Court.',
                        'High Court or District Civil Judge having territorial jurisdiction over deceased\'s assets.',
                        'District Civil Court / City Civil Court where deceased resided or assets are located.',
                        false,
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

  // =========================================================================
  // 4. WHY ESTATE VALUATIONS ARE LEGALLY MANDATORY
  // =========================================================================
  Widget _buildWhyValuationsRequiredSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'TESTAMENTARY & SETTLEMENT IMPERATIVES',
                'Why Independent Estate Valuations Are Legally Mandatory for Legal Heirs & Executors',
                'Estate administration in India involves high-stakes financial redistribution. Without an unassailable valuation report from a licensed Government Approved Valuer, estate filings inevitably stall in judicial registries or collapse into inter-generational family disputes:',
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
                        'High Court Probate Petitions & Will Execution',
                        'Section 276 of the Indian Succession Act mandates a verified Schedule of Assets. Certified valuations substantiate the exact worth of the estate, enabling judges to grant probate without protracted valuation inquiries.',
                        Icons.description,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Succession Disputes & Contested Wills',
                        'When disgruntled heirs lodge caveats claiming undue influence or unequal distribution, an impartial market valuation demonstrates whether testamentary bequests were equitable and economically rational.',
                        Icons.security,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Ad Valorem Court Fee Stamping',
                        'Under State Court Fees Acts, probate court fees are calculated ad valorem on the net estate. Impartial appraisals eliminate audit delays from the District Collector and avoid excess court fee overpayment.',
                        Icons.account_balance,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Family Settlements & Partition Parity',
                        'In multi-property coparcenary partitions, physical division is rarely equal. Our valuations establish owelty (cash equalization payments) so heirs swapping assets achieve flawless financial parity.',
                        Icons.swap_horiz,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Cross-Border NRI Inheritance & FEMA Compliance',
                        'Non-resident Indian heirs inheriting Indian properties require dual-currency appraisals for foreign tax reporting (IRS Form 706/3520, HMRC Inheritance Tax) and RBI FEMA repatriation limit certifications.',
                        Icons.public,
                        cardW,
                      ),
                      _buildTriggerCard(
                        'Section 49(1) & 55A Stepped-Up Cost Basis',
                        'When legal heirs sell inherited assets, our valuation reports establish the Fair Market Value as of April 1, 2001 under Section 55A of the Income Tax Act, drastically slashing Long-Term Capital Gains (LTCG) tax.',
                        Icons.trending_up,
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
  // 5. HOW IS AN ESTATE VALUED? NET DISTRIBUTABLE ESTATE FORMULATION
  // =========================================================================
  Widget _buildHowEstateValuedSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
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
                'How Is an Estate Valued? Methodology, Net Equity & Beneficiary Allocation',
                'Valuing a deceased estate requires a forensic, objective framework that balances statutory legal compliance with accurate market economics. Under Indian succession jurisprudence and testamentary practice, calculating the true distributable estate is not merely a matter of quoting circle rates or asking prices.',
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
                      'PROVALUER STANDARDIZED NET DISTRIBUTABLE ESTATE FORMULATION',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Net Distributable Estate Value = [Gross Fair Market Value (FMV)] − [Active Bank Mortgages & Registered Encumbrances] − [Municipal Property Taxes & Civic Arrears] − [Demolition & Unapproved Floor Rectification Costs] − [Applicable Court Fees & Transfer Liabilities]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: isDesktop ? 15 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Executed in accordance with Ind AS 113 (Fair Value Measurement), Section 34AB of the Wealth Tax Act, and Section 45 of the Indian Evidence Act.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Detailed 3-pillar breakdown
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : (isTablet ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth);
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildEstatePillar(
                        '1. Establishing Gross Fair Market Value Across Timelines',
                        'Testamentary proceedings require valuation pegged to specific statutory dates:\n\n• Date of Demise: Crucial for proving estate worth at the exact moment of testamentary devolution and satisfying foreign estate audits (IRS/HMRC).\n• Date of Petition Filing: Mandated by High Court and District Court registries to compute ad valorem court fees under State Court Fees Acts.\n• Date of Family Settlement: Essential for contemporary buyout transactions, where heirs trade physical assets or pay owelty cash equalizers based on current market dynamics.',
                        colW,
                      ),
                      _buildEstatePillar(
                        '2. Deduction of Encumbrances, Liabilities & Mortgages',
                        'In modern urban estates, assets frequently carry severe financial liabilities:\n\n• Active Home Loans & Mortgages: Quantified via official bank foreclosure statements. An heir inheriting a ₹6 Cr property with a ₹2 Cr mortgage receives ₹4 Cr in net equity.\n• Municipal & Civic Arrears: Accumulated property taxes, non-agricultural conversion dues, or pending apartment society dues are deducted.\n• Third-Party Tenancies: Commercial assets encumbered by protected statutory tenants under rent-control acts are subject to yield capitalization haircuts.',
                        colW,
                      ),
                      _buildEstatePillar(
                        '3. Capital Gains Considerations & Equal Allocation',
                        'Under Section 47(iii) of the Income Tax Act, 1961, any transfer of a capital asset under a will or an inheritance does not constitute a "transfer" and triggers zero immediate tax liability.\n\nHowever, when heirs subsequently liquidate inherited real estate or execute cross-heir buyouts, substantial Long-Term Capital Gains (LTCG) liabilities emerge. ProValuer models these post-tax realization figures so that family settlement deeds allocate truly equal net financial shares.',
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

  Widget _buildEstatePillar(String title, String body, double width) {
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
              fontSize: 13,
              color: _slateText,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. MULTI-ASSET ESTATE VALUATION COVERAGE
  // =========================================================================
  Widget _buildMultiAssetCoverageSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    final assetCategories = [
      {
        'title': 'Residential Apartments & Condominiums',
        'icon': Icons.apartment,
        'methodology': 'Sales Comparison Method + Undivided Share of Land (UDS) Analysis',
        'challenge': 'Discrepancies between physical flat super built-up area and registered UDS in sale deeds; builder-buyer agreement deviations; pending society transfer charges and sinking fund liabilities.',
        'details': 'We perform structural plinth checks, verify registered UDS ratios against total land parcel extent, and analyze recent registered arm’s-length transactions in the same building corridor to ensure court-admissible valuations.',
      },
      {
        'title': 'Freehold Land & Independent Houses',
        'icon': Icons.home,
        'methodology': 'Depreciated Replacement Cost (DRC via CPWD Plinth Rates) + Land Market Value',
        'challenge': 'Unapproved upper floors constructed decades ago without municipal sanction; building setback deviations; multiple legal heirs disputing vertical division vs full open-market sale.',
        'details': 'We segregate pure land market value from depreciated structure value using CPWD Plinth Area Rates, auditing municipal building regularization risks (e.g., GHMC BPS/LRS schemes) for the court schedule.',
      },
      {
        'title': 'Luxury Gated Community Villas',
        'icon': Icons.villa,
        'methodology': 'Comparable Sales Analysis + Premium Locational Indexing',
        'challenge': 'Substantial society transfer fees; strict aesthetic and sub-division restrictions; severe illiquidity in forced probate sale timelines.',
        'details': 'Our team factors in premium development amenities, club memberships, undivided land ownership, and ongoing maintenance liabilities to formulate true fair market realization values.',
      },
      {
        'title': 'Commercial Office Towers & Tech Parks',
        'icon': Icons.business,
        'methodology': 'Direct Income Capitalization + Discounted Cash Flow (DCF under Ind AS 113)',
        'challenge': 'Long-term anchor leases expiring around the date of death; lock-in clause validity; dispute over apportioning rental streams across multiple non-resident heirs.',
        'details': 'We model Weighted Average Lease Expiry (WALE), tenant creditworthiness, common area maintenance (CAM) balances, and prevailing capitalization yields across IT/commercial corridors.',
      },
      {
        'title': 'High-Street Retail Showrooms',
        'icon': Icons.storefront,
        'methodology': 'Yield Capitalization + Frontage & Footfall Comparative Analysis',
        'challenge': 'Entrenched tenants under archaic State Rent Control Acts paying nominal rents; disputes over key money (pagdi) and commercial goodwill.',
        'details': 'We analyze both vacant possession market value and encumbered tenanted value, providing courts with realistic realization figures under contested eviction circumstances.',
      },
      {
        'title': 'Agricultural Land & Farmhouses',
        'icon': Icons.grass,
        'methodology': 'Direct Comparison with Certified SRO Sales + Soil/Zoning Analysis',
        'challenge': 'Non-Agricultural Land Assessment (NALA) status; Dharani portal mutation hold-ups; statutory ceiling limits on agricultural landholding for legal heirs.',
        'details': 'We cross-examine village revenue survey numbers, Kasra Pahani extracts, irrigation infrastructure, master plan road widening reservations, and Dharani e-passbook records.',
      },
      {
        'title': 'Closely Held Family Businesses',
        'icon': Icons.corporate_fare,
        'methodology': 'Net Asset Value (NAV) + Discounted Cash Flow (DCF under Section 247)',
        'challenge': 'Lack of secondary market liquidity; minority discounts; disputes over founder key-person dependencies, unrecorded family loans, and director personal guarantees.',
        'details': 'Our IBBI Registered Valuers examine audited balance sheets, normalize promoter compensations, evaluate brand goodwill, and audit tangible asset backing to determine true enterprise value.',
      },
      {
        'title': 'Unlisted Equity Shares & Partnership Stakes',
        'icon': Icons.trending_up,
        'methodology': 'Rule 11UA Fair Market Value Computation + Asset-Based Appraisal',
        'challenge': 'Shareholder agreements with pre-emption rights; complex capital structures (CCPS, warrants); capital gains tax exposure upon inter-heir transmission.',
        'details': 'We apply strict Rule 11UA statutory formulas under the Income Tax Act alongside contemporary fair value principles under Companies Act Section 247 to certify shareholdings for Succession Certificates.',
      },
      {
        'title': 'Stridhan, Gold Jewellery & Heirlooms',
        'icon': Icons.diamond,
        'methodology': 'Certified Assaying + Current Bullion Spot Rates + Craftsmanship Deduction',
        'challenge': 'Disputes between surviving spouse and daughters regarding whether jewellery constitutes absolute Stridhan or coparcenary ancestral family wealth.',
        'details': 'Government Approved Gemmologists perform non-invasive purity testing, verify hallmarking, deduct melting losses, and provide itemized photographic inventories for family court and probate filings.',
      },
      {
        'title': 'Private Family Trusts & Holding Entities',
        'icon': Icons.account_balance,
        'methodology': 'Sum-of-the-Parts (SOTP) Appraisal + Underlying Yield Modeling',
        'challenge': 'Restrictive trust deed covenants; contingent beneficiary entitlements; discretionary vs non-discretionary distribution clauses.',
        'details': 'We evaluate the underlying portfolio of properties, securities, and debt instruments held within private testamentary trusts, determining exact beneficial interest values upon dissolution.',
      },
    ];

    final current = assetCategories[_selectedAssetIndex];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'COMPREHENSIVE TESTAMENTARY ASSET MATRIX',
                'Multi-Asset Estate Valuation Coverage: Complex Inheritance Portfolios',
                'Deceased estates in India are rarely confined to a single bank account or apartment. ProValuer Commercial delivers specialized valuation across 10 complex testamentary asset classes:',
              ),
              const SizedBox(height: 32),

              // Interactive Category Selector
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(assetCategories.length, (idx) {
                  final item = assetCategories[idx];
                  final isSelected = idx == _selectedAssetIndex;
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
                    side: BorderSide(
                      color: isSelected ? _obsidian : _borderSubtle,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedAssetIndex = idx);
                    },
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Selected Asset Card
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
                                'Recommended Methodology: ${current['methodology']}',
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
                      'Succession & Testamentary Challenges:',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current['challenge'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _slateText,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'ProValuer Valuation Protocol & Court Evidence:',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _obsidian,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      current['details'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _slateText,
                        height: 1.6,
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
  // 7. COMPREHENSIVE DOCUMENTATION CHECKLIST & 6 FATAL DEFICIENCIES
  // =========================================================================
  Widget _buildDocumentationSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
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
                'TESTAMENTARY EVIDENCE & REVENUE DOSSIER',
                'Documentation Checklist for Estate Valuation & Testamentary Filings',
                'Preparing an unassailable Schedule of Assets requires verifying the deceased\'s complete chain of title alongside financial liabilities. Below is the institutional documentation checklist:',
              ),
              const SizedBox(height: 32),

              // Checklist Grid
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
                        '1. Primary Testamentary Dossier',
                        [
                          'Death Certificate issued by Municipal Registrar',
                          'Original or Certified Copy of Registered Will / Codicil',
                          'Draft Probate Petition / Letters of Administration copy',
                          'Legal Heir Certificate / Surviving Member Certificate',
                          'Family Tree Affidavit (Genealogical Tree notarized)',
                        ],
                        colW,
                      ),
                      _buildDocCategoryCard(
                        '2. Property Title & Revenue Records',
                        [
                          'Registered Sale Deeds, Gift Deeds, or Partition Deeds (30-yr chain)',
                          'Encumbrance Certificate (EC) for past 30 years from SRO',
                          'Approved Building Plan & Occupancy Certificate (OC)',
                          'Latest Municipal Property Tax Receipts & Mutation extracts',
                          'Dharani E-Passbook & Kasra Pahani (Agricultural Land)',
                        ],
                        colW,
                      ),
                      _buildDocCategoryCard(
                        '3. Financial & Corporate Records',
                        [
                          'Bank Foreclosure Statements for active mortgages & loans',
                          'Demat statements, mutual fund holding statements',
                          'Audited Balance Sheets (3 yrs) for private limited entities',
                          'Partnership Deed copies & Capital Account statements',
                          'Original Jewellery Purchase Invoices or ancestral receipts',
                        ],
                        colW,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 48),

              // 6 Fatal Documentation Deficiencies
              Text(
                '6 Fatal Documentation Deficiencies That Trigger High Court Caveats & Audit Notices',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: _obsidian,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'In our forensic review of contested probate petitions across Indian High Courts, these six recurring evidentiary failures routinely cause registry rejections, Collector penalties, and prolonged injunctions:',
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
                        '1. Unreconciled Chain of Title Gaps',
                        'Submitting only the most recent title deed without proving the historical sequence of devolution from earlier ancestors, triggering civil court title objections and impleadment petitions from omitted cousins.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '2. Failure to Inspect Encumbrance Certificate for Prior Mortgages',
                        'Ignoring registered or equitable mortgages deposited by the deceased, leading to gross miscalculation of the estate’s net equity and surprise court-ordered bank attachments.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '3. Omission of Unapproved Floor Areas in Built Properties',
                        'Appraising only the sanctioned plan area while ignoring unauthorized constructed floors (or valuing unauthorized structures at full commercial rates without factoring municipal demolition risks).',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '4. Outdated Valuation Timelines Discordant with Court Rules',
                        'Presenting valuation reports with valuation dates discordant with the High Court’s statutory requirement (e.g., submitting current-date valuation for a probate petition requiring value on the date of death).',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '5. Overlooking Undivided Coparcenary Rights in Joint Family Land',
                        'Treating an ancestral property as the exclusive self-acquired estate of the deceased testator, exposing the probate petition to challenges by excluded coparceners under Section 6 of the Hindu Succession Act.',
                        cardW,
                      ),
                      _buildDeficiencyCard(
                        '6. Uncertified Bullion & Jewellery Appraisals',
                        'Relying on casual jeweller receipts rather than accredited Government Approved Gemmologist assay reports for Stridhan and ancestral gold holdings, resulting in immediate evidentiary rejection.',
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
  // 8. HYDERABAD & TELANGANA REGIONAL TESTAMENTARY PRACTICE
  // =========================================================================
  Widget _buildHyderabadTelanganaSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'REGIONAL JURISDICTION & REVENUE AUDIT',
                'Hyderabad & Telangana Regional Testamentary Practice: High Court & Civil Court Standards',
                'Administering an estate with immovable properties across the Hyderabad Metropolitan Region requires navigating Telangana-specific revenue systems, municipal bylaws, and judicial protocols:',
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
                        'Telangana High Court & City Civil Court Complex (Purani Haveli)',
                        'Our valuation reports are structured strictly to comply with the Original Side Rules of the High Court for the State of Telangana and the City Civil Court Complex at Purani Haveli, Hyderabad, alongside the District Courts of Rangareddy (L.B. Nagar) and Medchal-Malkajgiri. We compute ad valorem court fees under the Telangana Court Fees and Suits Valuation Act, 1956, mitigating District Collector valuation references under Section 19H.',
                        Icons.account_balance,
                        colW,
                      ),
                      _buildRegionalCard(
                        'HMDA Master Plan 2031 & GHMC Municipal Bylaws',
                        'Across prime Hyderabad corridors (Banjara Hills, Jubilee Hills, Gachibowli, Hitec City, Financial District, Kokapet, and Neopolis), land values depend heavily on HMDA Master Plan 2031 zoning (Residential, Multi-Purpose, Commercial, Conservation) and GHMC building setbacks. We audit whether built properties comply with sanctioned plans, quantifying potential municipal regularization fees or setback demolition risks.',
                        Icons.map,
                        colW,
                      ),
                      _buildRegionalCard(
                        'Dharani Portal & Agricultural Land Succession',
                        'Telangana\'s Dharani integrated land record management system governs all agricultural property successions. In peripheral districts (Rangareddy, Sangareddy, Yadadri-Bhuvanagiri), we perform forensic audits of Khata numbers, survey sub-divisions, NALA (Non-Agricultural Land Assessment) conversion receipts, and succession mutation procedures to ensure agricultural parcels can be partitioned cleanly.',
                        Icons.eco,
                        colW,
                      ),
                      _buildRegionalCard(
                        'IGRS Telangana Guideline Market Values vs Prevailing Open Market Rates',
                        'There is frequently a massive divergence between the Sub-Registrar Office (SRO) market guideline values and prevailing open market transaction values across urban Hyderabad. Submitting SRO rates for probate court fees invites immediate Collector valuation audits, while submitting unverified broker asking rates triggers crippling, non-refundable court fees. ProValuer delivers empirical equilibrium.',
                        Icons.insights,
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
  // 9. THE PROVALUER 4-STAGE ESTATE VALUATION PROTOCOL
  // =========================================================================
  Widget _buildFourStageProtocolSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
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
                'QUALITY ASSURANCE & FORENSIC RIGOR',
                'The ProValuer 4-Stage Forensic Estate Valuation Protocol',
                'To guarantee 100% admissibility in High Court testamentary registries and civil suits, ProValuer Commercial executes an institutional four-stage valuation protocol:',
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
                        'Title Chain & Encumbrance Audit',
                        'Reviewing 30-year SRO Encumbrance Certificates, registered sale/gift deeds, will covenants, probate petitions, and bank mortgage balances to establish clean legal ownership.',
                        Icons.search,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 2',
                        'On-Site Physical Inspection',
                        'Conducting thorough non-invasive physical audits, verified boundary measurements, plinth area reconciliation with municipal plans, and geo-tagged photographic documentation.',
                        Icons.location_on,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 3',
                        'Multi-Approach Economic Modeling',
                        'Applying Sales Comparison, CPWD Plinth Area DRC Cost approach, and Income Yield Capitalization to determine Gross FMV and compute Net Distributable Estate equity.',
                        Icons.calculate,
                        colW,
                      ),
                      _buildProtocolCard(
                        'Stage 4',
                        'Certified Issuance & Expert Witness',
                        'Issuing certified court-admissible reports with digital QR verification, backed by willingness to submit Section 45 expert witness affidavits and withstand judicial cross-examination.',
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
  // 10. INSTITUTIONAL TESTAMENTARY & PROBATE FAQS
  // =========================================================================
  Widget _buildFaqSection(BuildContext context, bool isDesktop, bool isTablet, double padding) {
    final faqs = [
      {
        'q': 'Is a property valuation report mandatory when applying for probate in an Indian High Court?',
        'a': 'Yes. Under Section 276 of the Indian Succession Act, 1925, an application for probate must annex a verified Schedule of Assets detailing all immovable and movable properties left by the deceased. Furthermore, under State Court Fees Acts, probate court fees are assessed ad valorem on the net estate value. High Court registries require certified valuation reports from licensed Government Approved Valuers to confirm asset descriptions and prevent under-valuation references by the District Collector.',
      },
      {
        'q': 'How does the court determine the court fees payable on a probate or succession petition?',
        'a': 'Court fees are assessed on the net market value of the estate (Gross Fair Market Value minus active mortgages, encumbrances, and municipal debts) under the relevant State Court Fees and Suits Valuation Act (e.g., Article 6, Schedule I of the Telangana Court Fees Act). Rates typically range between 2% and 5% depending on state slabs. The court registry verifies the Schedule of Assets, often forwarding it to the District Collector / CCRA under Section 19H for confirmation of valuation accuracy.',
      },
      {
        'q': 'What is the difference between valuation required for Probate versus Letters of Administration?',
        'a': 'In a Probate petition, the valuation report substantiates the specific asset bequests made under a proven will to the named executor. In Letters of Administration (required where the deceased died intestate or the named executor renounced office), the valuation report establishes the total gross estate value not only for court fees but also for determining the penal sum of the Administration Bond with sureties that the administrator must furnish to the court under Section 291 of the Indian Succession Act.',
      },
      {
        'q': 'How is inherited ancestral property distinguished from self-acquired property during estate valuation?',
        'a': 'Under the Hindu Succession Act, 1956 (amended 2005), ancestral coparcenary property devolves by birth upon all coparceners (sons and daughters equally). When a coparcener dies, a notional partition is deemed to have occurred immediately prior to death, and only the deceased’s individual undivided share is subject to testamentary succession. Self-acquired property, however, is owned with absolute title and can be willed away freely or devolves entirely upon Class-I heirs. ProValuer’s valuation reports strictly segregate coparcenary shares from self-acquired holdings.',
      },
      {
        'q': 'What valuation date is used for probate: the date of death or the date of the court petition?',
        'a': 'Under Indian succession jurisprudence, two distinct dates are critical: for establishing testamentary devolution, estate inventory, and foreign inheritance tax reporting, the valuation as on the Date of Demise is mandatory. For computing court fees payable under State Court Fees Acts, High Court registries typically require the valuation as on the Date of Petition Filing. ProValuer Commercial routinely delivers dual-date schedules within the same certified dossier.',
      },
      {
        'q': 'How does an independent valuation report resolve disputes during a family partition deed?',
        'a': 'In family settlements, physical assets (e.g., one commercial building and two residential flats) cannot be divided into identical brick-and-mortar portions. An independent valuation report establishes the true open market value of each parcel. Where one legal heir receives a property of higher market value, the valuation report computes the exact owelty (cash compensation payment) that the benefiting heir must pay to the other heirs to achieve perfect financial parity, preventing future partition litigation.',
      },
      {
        'q': 'Can a legal heir challenge a property valuation report submitted by the executor of a will?',
        'a': 'Yes. Aggrieved legal heirs who lodge caveats in probate proceedings frequently contest the executor’s Schedule of Assets, alleging that properties were deliberately undervalued to depress court fees or reduce residuary shares. However, if the executor submits a forensic report prepared by a licensed Government Approved Valuer backed by empirical market comparables and CPWD plinth rates, the court treats it as certified expert evidence under Section 45 of the Indian Evidence Act, placing a heavy burden of proof on the challenger.',
      },
      {
        'q': 'How are outstanding home loans and mortgages treated when valuing an inherited estate?',
        'a': 'Under Indian law, an heir inherits property subject to any registered mortgage or debt created by the deceased (Section 49 of the Indian Succession Act). In our Net Distributable Estate Formulation, active bank mortgage balances—verified via official bank foreclosure statements—are deducted from the Gross Fair Market Value. The court fee is assessed only on the resulting net equity, preventing legal heirs from paying court fees on borrowed capital.',
      },
      {
        'q': 'Are valuation reports prepared for foreign probate proceedings (US, UK, Canada) valid for assets located in India?',
        'a': 'No. Foreign courts (e.g., Probate Courts in the United States, High Court of Justice in England and Wales) require certified valuations of Indian immovable assets prepared by licensed Indian valuers conforming to Indian standards. ProValuer Commercial prepares dual-currency valuation reports (INR and USD/GBP/CAD at official RBI exchange rates) compliant with the Hague Apostille Convention, MEA attestation rules, and foreign estate tax requirements (IRS Form 706/3520).',
      },
      {
        'q': 'Can a Government Approved Valuer testify as an expert witness if an inheritance dispute goes to trial?',
        'a': 'Yes. Our registered valuers are fully accredited under Section 34AB of the Wealth Tax Act and Section 247 of the Companies Act. Under Section 45 of the Indian Evidence Act, 1872, our valuers are qualified to submit evidence-in-chief via sworn affidavits and appear before High Courts, District Judges, or court-appointed Local Commissioners for cross-examination to defend the valuation methodologies and comparables used.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: isDesktop ? 64 : 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'JUDICIAL & SUCCESSION ADVISORY',
                'Frequently Asked Questions (Probate & Inheritance FAQs)',
                'Authoritative guidance on court procedures, ad valorem fee computation, and expert witness standards under Indian succession law:',
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
  // 11. CONFIDENTIAL ESTATE CONSULTATION CTA
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
                  'CONFIDENTIAL TESTAMENTARY & ESTATE DESK',
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
                'Require a Court-Admissible Estate Valuation for Probate, Succession or Family Partition?',
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
                'Speak directly with our Government Approved Valuers. We provide testamentary executors, High Court advocates, and legal heirs with unassailable asset inventories, ad valorem court fee calculations, and expert testimony with complete statutory confidentiality.',
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
                      'Hello ProValuer Commercial, I would like to schedule a confidential consultation for an estate valuation (probate / succession / partition).',
                    ),
                    icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.white),
                    label: Text(
                      'WhatsApp Estate Advisory Desk',
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
                'Strict Non-Disclosure & Professional Privilege • Section 34AB Wealth Tax Act • Pan-India High Court Coverage',
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
  // 12. INSTITUTIONAL FOOTER
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
                              'Government Approved Valuers (Wealth Tax Act § 34AB) and IBBI Registered Valuers (Companies Act § 247). Providing high-precision, court-admissible appraisals for testamentary succession, bank collateral, and corporate transactions.',
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
                            _buildFooterLink('Matrimonial & Divorce Valuation', () => context.go('/services/divorce-matrimonial-valuation')),
                            _buildFooterLink('Probate & Estate Valuation', () => context.go('/services/probate-inheritance-valuation')),
                            _buildFooterLink('Share & Equity Valuation', () => context.go('/services/share-valuation')),
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                            _buildFooterLink('NCLT & IBC Valuation', () => context.go('/services/nclt-ibc-valuation')),
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
                            _buildFooterText('Indian Succession Act 1925 § 276/278'),
                            _buildFooterText('Hindu Succession Act 1956 § 6'),
                            _buildFooterText('Indian Evidence Act 1872 § 45'),
                            _buildFooterText('State Court Fees Act Ad Valorem'),
                            _buildFooterText('CPC Order XXVI Rule 9 Local Commission'),
                            _buildFooterText('Income Tax Act § 49(1) & § 55A FMV'),
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
                              'TESTAMENTARY DESK',
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
                            _buildFooterText('Headquarters: Hyderabad, Telangana'),
                            _buildFooterText('Jurisdiction: Pan-India High Courts'),
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
                    'Legally Grounded • Court Admissible • Section 34AB Compliant',
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
