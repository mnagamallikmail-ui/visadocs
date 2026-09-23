import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/landing/landing_theme.dart';

/// Statutory NCLT & IBC Valuation Services — Institutional Landing Page
/// Canonical URL: https://www.provaluer.in/services/nclt-ibc-valuation
class NcltIbcValuationScreen extends StatefulWidget {
  const NcltIbcValuationScreen({super.key});

  @override
  State<NcltIbcValuationScreen> createState() => _NcltIbcValuationScreenState();
}

class _NcltIbcValuationScreenState extends State<NcltIbcValuationScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  static const String _primaryPhone = '+918500019091';
  static const String _primaryPhoneFormatted = '+91 85000 19091';
  static const String _waUrl = 'https://wa.me/918500880333';

  // Institutional Design Tokens
  static const Color _obsidian = Color(0xFF0F172A);
  static const Color _slateText = Color(0xFF475569);
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _borderSubtle = Color(0xFFE2E8F0);
  static const Color _accentGold = Color(0xFFB45309);
  static const Color _goldLight = Color(0xFFFEF3C7);
  static const Color _navyCard = Color(0xFF1E293B);

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

                // 2. Statutory Insolvency Framework
                _buildFrameworkSection(screenW, isDesktop),

                // 3. Fair Value vs. Liquidation Value Benchmark
                _buildDualMetricSection(screenW, isDesktop),

                // 4. CIRP Valuation Timeline (Admission to Resolution)
                _buildTimelineSection(screenW, isDesktop),

                // 5. Multi-Disciplinary Asset Class Coverage
                _buildAssetClassesSection(screenW, isDesktop, isTablet),

                // 6. Regional NCLT Bench Capabilities (Hyderabad & South India)
                _buildRegionalSection(screenW, isDesktop),

                // 7. Comprehensive CIRP Documentation Checklist
                _buildDocumentationChecklistSection(screenW, isDesktop),

                // 8. Common Reasons Reports Are Challenged or Rejected
                _buildDisputeAndRejectionSection(screenW, isDesktop),

                // 9. The ProValuer 4-Stage Forensic Valuation Protocol
                _buildProtocolSection(screenW, isDesktop),

                // 10. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 11. High-Touch Executive Conversion Block
                _buildConversionSection(screenW, isDesktop),

                // 12. Institutional Footer
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
                  'Hello ProValuer Commercial, I would like to consult on a statutory NCLT / CIRP Valuation mandate under IBC 2016.',
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
                        'CIRP Advisory Desk',
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
  // FLOATING SERVICE HEADER
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
                                color: _obsidian,
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
                        _buildNavText('Bank Collateral', () => context.go('/services/bank-collateral-valuation')),
                        const SizedBox(width: 24),
                        _buildNavText('NCLT & IBC', () => context.go('/services/nclt-ibc-valuation'), isActive: true),
                        const SizedBox(width: 24),
                        _buildNavText('Plant & Machinery', () => context.go('/services/plant-machinery-technical-valuation')),
                        const SizedBox(width: 32),
                      ],

                      // Action Buttons (Zero Login Links)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _makePhoneCall,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: _borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_in_talk, size: 14, color: _obsidian),
                                const SizedBox(width: 6),
                                Text(
                                  isDesktop ? _primaryPhoneFormatted : 'Call',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _obsidian,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _launchWhatsApp(
                            'Hello ProValuer Commercial, I need statutory valuation support for an ongoing CIRP / NCLT matter under Regulation 27.',
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                                  'Appoint Valuer',
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

  Widget _buildNavText(String title, VoidCallback onTap, {bool isActive = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive ? LandingTheme.brandGreen : _obsidian,
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
      width: double.infinity,
      color: _pureWhite,
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
              // Eyebrow Badges
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildPillBadge(
                    Icons.gavel,
                    'STATUTORY INSOLVENCY & BANKRUPTCY PRACTICE',
                    _obsidian,
                  ),
                  _buildPillBadge(
                    Icons.verified_user,
                    'IBBI REGISTERED VALUERS (SECTION 247 COMPANIES ACT)',
                    LandingTheme.brandGreen,
                  ),
                  _buildPillBadge(
                    Icons.shield_outlined,
                    'REGULATION 27 & 35 CIRP COMPLIANCE',
                    _accentGold,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // H1 Heading
              Text(
                'Statutory NCLT & IBC Valuation Services: CIRP Fair Value & Liquidation Value Appraisals by IBBI Registered Valuers',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 40 : (screenW >= 700 ? 32 : 26),
                  fontWeight: FontWeight.w900,
                  color: _obsidian,
                  letterSpacing: -1.2,
                  height: 1.18,
                ),
              ),
              const SizedBox(height: 22),

              // Lead Executive Narrative
              Text(
                'Under the Insolvency and Bankruptcy Code, 2016 (IBC), independent statutory valuation is the legal foundation upon which equitable corporate resolution, creditor distribution waterfalls, and forensic asset accountability depend. ProValuer Commercial delivers defense-grade, court-admissible Fair Value and Liquidation Value appraisals strictly under Regulation 27 and Regulation 35 of the IBBI (Insolvency Resolution Process for Corporate Persons) Regulations, 2016. Our empanelled IBBI Registered Valuers and multi-disciplinary technical specialists support Resolution Professionals (RPs), Liquidators, and Committees of Creditors (CoC) across NCLT Benches nationwide with unimpeachable, methodologically defensible valuation reports engineered to withstand hostile appellate challenges before the NCLT and NCLAT.',
                style: GoogleFonts.montserrat(
                  fontSize: isDesktop ? 15.5 : 14.5,
                  fontWeight: FontWeight.w400,
                  color: _slateText,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 30),

              // Trust Strip Ribbon
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildTrustBadge('IBBI Registered Valuers', 'Land & Building / Plant & Machinery / SFA'),
                  _buildTrustBadge('Regulation 27 Compliance', 'Mandatory Independent Twin Valuer Teams'),
                  _buildTrustBadge('Section 30(2)(b) Protection', 'Ironclad Statutory Creditor Floor Benchmarking'),
                  _buildTrustBadge('30–45 Day Execution SLA', 'Strict Adherence to 180 / 330-Day CIRP Windows'),
                ],
              ),
              const SizedBox(height: 36),

              // Primary Action Buttons
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchWhatsApp(
                      'Hello ProValuer Commercial, we require an IBBI Registered Valuer appointment under Regulation 27 of the CIRP Regulations.',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LandingTheme.brandGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Consult Senior Insolvency Valuer',
                          style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _makePhoneCall,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _borderSubtle, width: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_in_talk, size: 18, color: _obsidian),
                        const SizedBox(width: 10),
                        Text(
                          'Direct Advisory: $_primaryPhoneFormatted',
                          style: GoogleFonts.montserrat(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _obsidian,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Quick Metric Badges
              _buildHeroKpiGrid(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _obsidian,
              letterSpacing: 0.6,
            ),
          ),
        ],
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
      {'val': '100% IBBI', 'label': 'Registered Valuers Under Sec 247', 'icon': Icons.verified_rounded},
      {'val': 'Reg 27 & 35', 'label': 'Dual Valuer Forensic Alignment', 'icon': Icons.account_balance_rounded},
      {'val': '30–45 Days', 'label': 'Guaranteed CIRP Reporting SLA', 'icon': Icons.timer_outlined},
      {'val': 'Pan-India', 'label': 'Active Across All Regional Benches', 'icon': Icons.map_outlined},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = isDesktop ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 2.1 : 1.6,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, idx) {
            final item = kpis[idx];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _lightBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'] as IconData, color: LandingTheme.brandGreen, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    item['val'] as String,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _obsidian,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item['label'] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _slateText,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. STATUTORY INSOLVENCY FRAMEWORK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFrameworkSection(double screenW, bool isDesktop) {
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
                'STATUTORY INSOLVENCY FRAMEWORK',
                'IBC 2016, Regulation 27 & Companies Act Section 247 Compliance',
                'The Statutory Foundation Governing Corporate Insolvency Appraisals Across India',
              ),
              const SizedBox(height: 26),

              Text(
                'The enactment of the Insolvency and Bankruptcy Code, 2016 fundamentally transformed India’s corporate distress resolution ecosystem from a debtor-in-possession system to a creditor-in-control paradigm. Under this rigorous legal architecture, asset valuation ceases to be a discretionary commercial estimate; it becomes a statutory condition precedent that dictates the rights, recovery thresholds, and voting protocols of secured financial creditors, unsecured financial creditors, and operational creditors alike.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Pursuant to Regulation 27 of the IBBI (Insolvency Resolution Process for Corporate Persons) Regulations, 2016, the Resolution Professional (RP) is statutorily mandated within forty-seven (47) days of the insolvency commencement date to appoint two Registered Valuers for each class of assets owned by the Corporate Debtor. These valuers must be registered with the Insolvency and Bankruptcy Board of India (IBBI) under Section 247 of the Companies Act, 2013, read alongside the Companies (Registered Valuers and Valuation) Rules, 2017. Any appraisal conducted by non-registered entities, unregulated accounting firms, or chartered engineering panels lacking IBBI individual and entity credentials is void ab initio before the Adjudicating Authority (National Company Law Tribunal).',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 28),

              // 3 Framework Pillar Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildFrameworkCard(
                        constraints.maxWidth,
                        isDesktop,
                        'Regulation 27: Dual Valuer Mandate',
                        'Strict statutory requirement compelling the RP to appoint two distinct Registered Valuers per asset class. Both valuers operate under sealed, non-disclosure confidentiality covenants to independently calculate Fair Value and Liquidation Value without mutual consultation.',
                        Icons.security,
                      ),
                      _buildFrameworkCard(
                        constraints.maxWidth,
                        isDesktop,
                        'Section 247 Companies Act Governance',
                        'Mandatory professional accreditation under IBBI and recognized Registered Valuers Organisations (RVOs). Strict conflict-of-interest prohibitions ensure complete independence from the Corporate Debtor, financial creditors, and prospective resolution applicants.',
                        Icons.assignment_turned_in_outlined,
                      ),
                      _buildFrameworkCard(
                        constraints.maxWidth,
                        isDesktop,
                        'Section 30(2)(b) Distribution Floor',
                        'Liquidation Value calculated under Regulation 35 establishes the statutory minimum recovery floor. Dissenting financial creditors and operational creditors cannot receive less than the liquidation value they would have been entitled to under Section 53 waterfall priorities.',
                        Icons.account_balance_wallet_outlined,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              Text(
                'Insolvency Professionals bear personal fiduciary liability for the integrity of the CIRP timeline and resolution filings. By engaging ProValuer Commercial’s credentialed Registered Valuers, RPs and CoC members secure ironclad methodological transparency, comprehensive on-site geo-spatial audit trails, and defensible econometric models that effectively eliminate legal vulnerability before the NCLT and the National Company Law Appellate Tribunal (NCLAT).',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrameworkCard(double maxWidth, bool isDesktop, String title, String body, IconData icon) {
    final width = isDesktop ? (maxWidth - 40) / 3 : maxWidth;
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: LandingTheme.brandGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
  // 3. FAIR VALUE VS. LIQUIDATION VALUE BENCHMARK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDualMetricSection(double screenW, bool isDesktop) {
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
                'DUAL VALUATION BENCHMARK UNDER IBC',
                'Fair Value vs. Liquidation Value: Statutory Definitions & Mechanics',
                'Comprehensive Analysis of Regulation 2(1)(hb) and Regulation 2(1)(k) Metrics',
              ),
              const SizedBox(height: 26),

              Text(
                'Regulation 35 of the CIRP Regulations establishes two distinct valuation benchmarks that the Registered Valuers must independently compute. Confusing these two metrics or applying non-statutory methodologies represents one of the most frequent grounds for valuation reports being set aside by NCLT benches. Our valuation protocols strictly observe the regulatory demarcations defined under the Code.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 30),

              // Dual Cards Comparison
              LayoutBuilder(
                builder: (context, constraints) {
                  final colWidth = isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      // Fair Value Card
                      Container(
                        width: colWidth,
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: _lightBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.35), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.show_chart, color: Colors.blueAccent, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Fair Value (FV)',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _obsidian,
                                        ),
                                      ),
                                      Text(
                                        'CIRP Regulation 2(1)(hb)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Statutory Definition: "The estimated realizable value of the assets of the corporate debtor, if they were to be exchanged on the insolvency commencement date between a willing buyer and a willing seller in an arm’s length transaction, after proper marketing and where the parties had each acted knowledgeably, prudently and without compulsion."',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _slateText,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBulletItem('Premise of Value: Highest and Best Use (HABU) under orderly market circumstances.'),
                            _buildBulletItem('Valuation Horizon: Unconstrained exposure time reflecting normal commercial marketing cycles.'),
                            _buildBulletItem('Methodology: Discounted Cash Flow (DCF), Income Capitalization, and Market Comparable Sales Multiples.'),
                            _buildBulletItem('CoC Function: Serves as the analytical yardstick for evaluating whether Resolution Applicants offer adequate commercial enterprise value.'),
                          ],
                        ),
                      ),

                      // Liquidation Value Card
                      Container(
                        width: colWidth,
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: _lightBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accentGold.withValues(alpha: 0.45), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _goldLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.gavel, color: _accentGold, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Liquidation Value (LV)',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: _obsidian,
                                        ),
                                      ),
                                      Text(
                                        'CIRP Regulation 2(1)(k)',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _accentGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Statutory Definition: "The estimated realizable value of the assets of the corporate debtor if the corporate debtor were to be liquidated on the insolvency commencement date."',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: _slateText,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildBulletItem('Premise of Value: Forced liquidation, piecemeal asset surrender, or distressed slump sale.'),
                            _buildBulletItem('Valuation Horizon: Severely curtailed disposal window (typically 90 to 180 days under court auction constraints).'),
                            _buildBulletItem('Methodology: Depreciated Replacement Cost (DRC), Net Realizable Asset Value, and empirical distress haircutting.'),
                            _buildBulletItem('CoC Function: Establishes the mandatory statutory floor payout under Section 30(2)(b) for dissenting creditors.'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // Comparative Table Matrix
              _buildComparativeMatrix(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: LandingTheme.brandGreen, fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativeMatrix(bool isDesktop) {
    final rows = [
      ['Dimension', 'Fair Value (Regulation 2(1)(hb))', 'Liquidation Value (Regulation 2(1)(k))'],
      ['Standard of Value', 'Open Market Arm’s-Length Exchange', 'Orderly or Forced Liquidation Realization'],
      ['Marketing Window', 'Sufficient normal commercial period', 'Constrained statutory liquidation timeline (90-180 days)'],
      ['Corporate Condition', 'Preserved enterprise value as Going Concern', 'Dismantled, piecemeal, or stressed slump sale'],
      ['Disposal Costs', 'Standard brokerages & transaction costs', 'Auction fees, dismantling, transport, legal holding costs'],
      ['Statutory Role', 'Benchmarks Resolution Plan commercial viability', 'Determines Section 30(2)(b) & Section 53 priority payout floor'],
      ['Confidentiality', 'Strict sealed cover under Regulation 35(1)', 'Disclosed to CoC only after receipt of compliant plans'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderSubtle),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final idx = entry.key;
          final r = entry.value;
          final isHeader = idx == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isHeader ? LandingTheme.brandGreen.withValues(alpha: 0.08) : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: _borderSubtle.withValues(alpha: idx == rows.length - 1 ? 0 : 0.6),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    r[0],
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
                      color: isHeader ? LandingTheme.brandGreen : _obsidian,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    r[1],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                      color: isHeader ? _obsidian : _slateText,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    r[2],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400,
                      color: isHeader ? _obsidian : _slateText,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. CIRP VALUATION TIMELINE (ADMISSION TO RESOLUTION)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTimelineSection(double screenW, bool isDesktop) {
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
                'CIRP VALUATION TIMELINE',
                'From NCLT Admission to Final Resolution: The 10-Stage Process',
                'Comprehensive Chronological Workflow Across the 180 to 330-Day CIRP Window',
              ),
              const SizedBox(height: 24),

              Text(
                'The Corporate Insolvency Resolution Process operates under rigid statutory deadlines established under Section 12 of the IBC (180 days, extendable to 270 days, with a hard outer limit of 330 days inclusive of litigation). Asset valuation must be executed with extreme procedural discipline to prevent timeline collapse. Below is the sequential ten-stage workflow executed by ProValuer Commercial in strict alignment with IBBI regulations:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 30),

              // 10 Sequential Steps
              _buildTimelineStep(
                '01',
                'NCLT Admission & Moratorium Commencement',
                'The Adjudicating Authority admits the insolvency application under Section 7 (financial creditor), Section 9 (operational creditor), or Section 10 (corporate debtor). Moratorium under Section 14 takes immediate legal effect, freezing alienations and adverse claims.',
              ),
              _buildTimelineStep(
                '02',
                'IRP Appointment & Public Announcement',
                'The Interim Resolution Professional takes charge of the Corporate Debtor, makes the public announcement in Form A, collates creditor claims within 14 days, and constitutes the Committee of Creditors (CoC).',
              ),
              _buildTimelineStep(
                '03',
                'Regulation 27 Valuer Appointment',
                'Within 47 days of the Insolvency Commencement Date (ICD), the IRP or RP formally appoints two independent IBBI Registered Valuers for each asset class (Land & Building, Plant & Machinery, Securities & Financial Assets) under sealed NDA covenants.',
              ),
              _buildTimelineStep(
                '04',
                'Forensic On-Site Physical Inspections',
                'Registered Valuers mobilize multi-disciplinary engineering and surveying teams to conduct mandatory physical site audits, GPS boundary validations, machinery condition ratings, capacity verification, and title reconciliation.',
              ),
              _buildTimelineStep(
                '05',
                'Fair Value Econometric Modeling',
                'Valuers determine Fair Value under Regulation 2(1)(hb) using Highest and Best Use (HABU) principles, discounted cash flows (DCF), market comparables, and unconstrained transaction assumptions.',
              ),
              _buildTimelineStep(
                '06',
                'Liquidation Value Distress Calculation',
                'Valuers compute Liquidation Value under Regulation 2(1)(k), modeling asset realization under forced liquidation conditions, piecemeal dismantling, market liquidity absorption, and empirical statutory haircuts.',
              ),
              _buildTimelineStep(
                '07',
                'Confidential Submission to Resolution Professional',
                'Valuation reports are submitted to the RP in password-protected, encrypted formats under Regulation 35(1). The RP maintains absolute confidentiality under strict non-disclosure undertakings.',
              ),
              _buildTimelineStep(
                '08',
                'Committee of Creditors (CoC) Confidential Review',
                'Under Regulation 35(2), the RP discloses Fair Value and Liquidation Value to CoC members only after receiving compliant resolution plans and securing signed confidentiality undertakings from each member.',
              ),
              _buildTimelineStep(
                '09',
                'Resolution Plan Feasibility & Section 30(2) Compliance',
                'The CoC evaluates resolution applicants’ financial proposals against the Liquidation Value benchmark, verifying that dissenting financial creditors and operational creditors receive statutory priority payments under Section 30(2)(b).',
              ),
              _buildTimelineStep(
                '10',
                'Resolution Plan Approval or Liquidation Order',
                'Upon 66% CoC voting approval, the plan is submitted to the NCLT for approval under Section 31. If no viable plan emerges within the 330-day window, Section 33 triggers liquidation, and the established Liquidation Value serves as the reserve price benchmark for e-auction.',
              ),

              const SizedBox(height: 36),

              // Operational Bottlenecks & Third Valuer Situations
              _buildSubHeading('Operational Bottlenecks, Missing Documentation & Third Valuer Situations'),
              const SizedBox(height: 14),
              Text(
                'While the statutory timeline is clearly delineated, real-world CIRP valuations frequently encounter severe operational bottlenecks. Key delay drivers include uncooperative suspended management who conceal records or deny physical facility access (necessitating urgent Section 19(2) applications by the RP before NCLT), incomplete Fixed Asset Registers (FAR) where machinery purchases lack invoices or customs clearance files, and unregistered title deeds or encumbered leasehold land requiring extensive revenue record tracing across municipal and taluka offices.',
                style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.75),
              ),
              const SizedBox(height: 14),
              Text(
                'A critical procedural flashpoint under Regulation 35(1)(b) arises when the estimates of the two appointed Registered Valuers diverge significantly—statutorily interpreted as a variance exceeding 15% to 25%. In such events, the RP is required to appoint a Third Registered Valuer. The third valuer conducts an entirely independent appraisal, and the final Fair Value and Liquidation Value are derived by taking the mathematical average of the two closest estimates. ProValuer Commercial’s rigorous econometric calibration and extensive regional market transaction databases drastically minimize variance, safeguarding RPs against costly third-valuer delays and CoC litigation.',
                style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String stepNumber, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: LandingTheme.brandGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: LandingTheme.brandGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
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
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. MULTI-DISCIPLINARY ASSET CLASS COVERAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildAssetClassesSection(double screenW, bool isDesktop, bool isTablet) {
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
                'MULTI-DISCIPLINARY ASSET COVERAGE',
                'Comprehensive Asset Class Valuation Under Companies Act Section 247',
                'Specialized Valuation Practice Groups for Every Asset Class of the Corporate Debtor',
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 32,
                    runSpacing: 24,
                    children: [
                      // Land & Building
                      _buildAssetClassCard(
                        cardWidth,
                        'Land & Building (Real Estate & Infrastructure)',
                        'Industrial manufacturing campuses, SEZ commercial parks, corporate towers, warehousing hubs, township developments, encroached parcels, and leasehold lands under state industrial development corporations (TSIIC, APIIC, MIDC, GIDC, KIADB). We conduct physical boundary triangulation, verify FSI/FAR utilization, scrutinize master plan zoning, and model encumbered leasehold tenures.',
                        Icons.apartment,
                      ),

                      // Plant & Machinery
                      _buildAssetClassCard(
                        cardWidth,
                        'Plant & Machinery (Heavy Engineering & Industrial)',
                        'Continuous process chemical plants, steel rolling mills, thermal power facilities, pharmaceutical API manufacturing lines, cement plants, and specialized tooling. We calculate Depreciated Replacement Cost (DRC), examine remaining useful life (RUL), assess physical obsolescence, and model scrap versus secondary market salvage realizations.',
                        Icons.precision_manufacturing,
                      ),

                      // Securities & Financial Assets
                      _buildAssetClassCard(
                        cardWidth,
                        'Securities & Financial Assets (Equity & Debt)',
                        'Unlisted equity shares, preference capital, corporate guarantees, inter-corporate deposits (ICDs), structured debt instruments, derivative contracts, and subsidiary equity holdings. We deploy Discounted Cash Flow (DCF), Comparable Company Multiples (CCM), and Net Asset Value (NAV) models compliant with Ind AS 113.',
                        Icons.monetization_on_outlined,
                      ),

                      // Intangible Assets & PUFE Forensic Support
                      _buildAssetClassCard(
                        cardWidth,
                        'Intangible Assets & PUFE Forensic Valuation',
                        'Proprietary patents, pharmaceutical drug master files (DMFs), trademarks, brand equity, software architectures, and specialized mining concessions. Additionally, we provide economic valuation support for avoidance applications under Section 43 (Preferential), Section 45 (Undervalued), Section 50 (Extortionate), and Section 66 (Fraudulent Trading) transactions.',
                        Icons.fingerprint,
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

  Widget _buildAssetClassCard(double width, String title, String body, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: LandingTheme.brandGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slateText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. REGIONAL NCLT BENCH CAPABILITIES (HYDERABAD & SOUTH INDIA)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRegionalSection(double screenW, bool isDesktop) {
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
                'REGIONAL NCLT BENCH CAPABILITIES',
                'NCLT Hyderabad Bench & South India CIRP Valuation Coverage',
                'Deep Regional Jurisdictional Expertise Across Telangana, Andhra Pradesh, Karnataka & Tamil Nadu',
              ),
              const SizedBox(height: 26),

              Text(
                'ProValuer Commercial maintains dedicated insolvency valuation desks with localized operational reach across South India. With deep institutional familiarity with the NCLT Hyderabad Bench (having jurisdiction over Telangana and Andhra Pradesh), NCLT Bengaluru Bench, NCLT Chennai Bench, and NCLT Amaravati, our teams execute rapid on-ground forensic mobilization without jurisdictional friction.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 22),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colWidth = isDesktop ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildRegionalBenchCard(
                        colWidth,
                        'NCLT Hyderabad Bench',
                        'Telangana & Andhra Pradesh',
                        'Specialized coverage across HMDA, GHMC, and TSIIC industrial zones: Patancheru, Pashamylaram, Jeedimetla, Genome Valley, Jadcherla, and Pharma City. Deep expertise in heavy engineering, bulk drug pharma, and infrastructure debtors.',
                      ),
                      _buildRegionalBenchCard(
                        colWidth,
                        'South India Industrial Corridors',
                        'Cross-State Industrial Belts',
                        'Active valuation presence along the Visakhapatnam-Chennai Industrial Corridor (VCIC), Bangalore-Hyderabad Industrial Corridor, Sri City SEZ, Oragadam automotive corridor, and Hosur engineering clusters.',
                      ),
                      _buildRegionalBenchCard(
                        colWidth,
                        '30–45 Day Guaranteed SLA',
                        'Strict CIRP Timeline Adherence',
                        'Prompt on-site mobilization within 48 to 72 hours of mandate execution. Rigorous inspection workflows guarantee complete Fair Value and Liquidation Value delivery within 30 to 45 days, comfortably meeting Regulation 27 deadlines.',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Our regional valuers possess granular insights into local land revenue systems, including Dharani portal records in Telangana, Webland and Meebhoomi data in Andhra Pradesh, Kaveri portal encumbrances in Karnataka, and Patta/Chitta verifications in Tamil Nadu, eliminating legal vulnerability when tracing distressed real estate titles.',
                style: GoogleFonts.inter(fontSize: 14, color: _slateText, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionalBenchCard(double width, String title, String subtitle, String desc) {
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
              fontWeight: FontWeight.w800,
              color: LandingTheme.brandGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 12),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. COMPREHENSIVE CIRP DOCUMENTATION CHECKLIST
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentationChecklistSection(double screenW, bool isDesktop) {
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
                'CIRP DOCUMENTATION CHECKLIST',
                'Statutory Information Dossier for Resolution Professionals',
                'Essential Data Requirements to Initiate Regulation 27 Forensic Valuation',
              ),
              const SizedBox(height: 24),

              Text(
                'To ensure rapid mobilization and prevent procedural delays during the tight CIRP calendar, the Resolution Professional or Liquidator should collate the following evidentiary records prior to the on-site forensic inspection:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colWidth = isDesktop ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 32,
                    runSpacing: 24,
                    children: [
                      _buildChecklistGroup(
                        colWidth,
                        '1. Corporate & Statutory Insolvency Dossier',
                        [
                          'Certified Copy of NCLT Admission Order under Section 7, 9, or 10 of IBC.',
                          'Public Announcement Form A and details of Interim Resolution Professional appointment.',
                          'List of Financial Creditors, Operational Creditors, and CoC voting share allocations.',
                          'Provisional Financial Statements as of the Insolvency Commencement Date (ICD).',
                          'Audited Annual Reports and Tax Audit Reports for the preceding 3 to 5 financial years.',
                        ],
                      ),
                      _buildChecklistGroup(
                        colWidth,
                        '2. Real Estate, Land & Civil Infrastructure Dossier',
                        [
                          'Original or Certified Title Deeds, Sale Deeds, Lease Agreements, and Allotment Letters.',
                          '30-Year Encumbrance Certificates (EC) issued by the Sub-Registrar / Registration Department.',
                          'Non-Agricultural (NA) Land Conversion Orders and Master Layout Sanction Approvals.',
                          'Approved Building Architectural Plans, Factory Inspectorate Licenses, and CFO / Occupancy Certificates.',
                          'Property Tax Assessment Receipts, Water/Electricity Connection Invoices, and Ground Rent Receipts.',
                        ],
                      ),
                      _buildChecklistGroup(
                        colWidth,
                        '3. Plant, Machinery & Technical Equipment Dossier',
                        [
                          'Fixed Asset Register (FAR) detailing asset descriptions, serial numbers, date of commissioning, and historical cost.',
                          'Original Purchase Invoices, Commercial Contracts, and Customs Clearance / Bill of Entry records for imported machinery.',
                          'Preventive Maintenance Logs, Overhaul History, and Current Operational Condition Classification.',
                          'Vendor AMC Contracts, OEM Technical Handbooks, and Calibration / Certification Records.',
                          'List of Decommissioned, Obsolete, Scrapped, or Missing Machinery with write-off approvals.',
                        ],
                      ),
                      _buildChecklistGroup(
                        colWidth,
                        '4. Financial Assets, Working Capital & Intangibles Dossier',
                        [
                          'Certified Demat Account Statements, Share Certificates of Subsidiary and Joint Venture Companies.',
                          'Inter-Corporate Deposit (ICD) Loan Agreements, Corporate Guarantee Deeds, and Promissory Notes.',
                          'Trade Receivables Aging Schedule with details of disputed or litigated outstanding dues.',
                          'Inventory Valuation Statements as on ICD (Raw Materials, WIP, Finished Goods, Stores/Spares).',
                          'Intellectual Property Registration Certificates (Patents, Trademarks, Copyrights, Software Licenses).',
                        ],
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

  Widget _buildChecklistGroup(double width, String groupTitle, List<String> items) {
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
          Text(
            groupTitle,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: LandingTheme.brandGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: _slateText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. COMMON REASONS NCLT VALUATION REPORTS ARE CHALLENGED OR REJECTED
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDisputeAndRejectionSection(double screenW, bool isDesktop) {
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
                'LITIGATION & REJECTION TRIGGERS',
                'Common Reasons NCLT & IBC Valuation Reports Are Challenged Before Tribunals',
                'Forensic Analysis of Valuation Defects That Jeopardize CIRP Approvals Before NCLT & NCLAT',
              ),
              const SizedBox(height: 24),

              Text(
                'In high-stakes corporate insolvencies, unsuccessful resolution applicants, dissenting financial creditors, and suspended promoters routinely initiate aggressive litigation targeting valuation reports. Flawed appraisals lead to protracted appellate delays, setting aside of approved resolution plans, and disciplinary referrals against Resolution Professionals. ProValuer Commercial conducts exhaustive pre-issuance technical audits to safeguard against the eight most common valuation defects:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildRejectionCard(
                        cardWidth,
                        '1. Arbitrary Distress Haircuts Without Empirical Basis',
                        'Applying unsubstantiated blanket haircuts (e.g., deducting 60% without transaction comp evidence) directly violates IBBI guidelines. Tribunals require econometric substantiation explaining why distress discounts are warranted.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '2. Omission of Physical On-Site Asset Inspection',
                        'Relying exclusively on book entries or historical balance sheets without physical ground verification constitutes a fatal procedural breach. Physical verification is mandatory to establish actual existence and operational status.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '3. Misclassification of Encumbered vs Unencumbered Assets',
                        'Failing to verify first-charge versus subordinate hypothecations distorts the Section 53 waterfall analysis, causing secured creditors to challenge the fairness of creditor distribution models.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '4. Ignoring the 15% Variance Rule & Third Valuer Mandate',
                        'When two Registered Valuers submit divergent figures differing by over 15% to 25%, the RP must appoint a Third Valuer under Regulation 35(1)(b). Failure to do so invalidates the final valuation baseline.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '5. Methodological Inconsistency (Scrap vs Going Concern)',
                        'Valuing an operating manufacturing entity strictly on a scrap/piecemeal basis without evaluating going-concern intangibles suppresses Fair Value and undervalues the enterprise to the detriment of creditors.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '6. Disregarding Off-Balance Sheet & Intangible Assets',
                        'Ignoring high-value drug licenses, unexpired mining concessions, brand equity, or software source codes artificially deflates enterprise value, triggering challenges by aggrieved equity holders or CoC members.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '7. Deviating from Insolvency Commencement Date (ICD)',
                        'Under Regulation 35, the valuation date must strictly coincide with the Insolvency Commencement Date. Using subsequent dates without statutory justification leads to rejection by the Adjudicating Authority.',
                      ),
                      _buildRejectionCard(
                        cardWidth,
                        '8. Inadequate Disclosure of Environmental & Remediation Liabilities',
                        'Failing to quantify environmental remediation costs, decommissioning liabilities, or pending pollution control penalties distorts net realizable value upon asset surrender.',
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

  Widget _buildRejectionCard(double width, String title, String body) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.deepOrangeAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                'FORENSIC VALUATION PROTOCOL',
                'The ProValuer 4-Stage Defense-Grade CIRP Methodology',
                'Engineered to Eliminate Dispute Vulnerabilities and Ensure Unanimous CoC Confidence',
              ),
              const SizedBox(height: 28),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop ? (constraints.maxWidth - 32) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 32,
                    runSpacing: 24,
                    children: [
                      _buildProtocolCard(
                        cardWidth,
                        'Stage 1: Mandate Formalization & Pre-Audit Intelligence',
                        'Execution of comprehensive non-disclosure agreements (NDA) under Regulation 35. Complete reconciliation of Fixed Asset Registers against ICD balance sheets, examination of charge documents filed with MCA (Form CHG-1), and synthesis of creditor claim schedules.',
                        Icons.verified_user_outlined,
                      ),
                      _buildProtocolCard(
                        cardWidth,
                        'Stage 2: On-Site Forensic Field Inspection & Technical Audit',
                        'Deployment of certified chartered engineers and registered valuers for physical boundary surveying, GPS geo-tagging of equipment, operational testing of plant lines, verification of idle/mothballed machinery, and local municipal inquiries.',
                        Icons.travel_explore,
                      ),
                      _buildProtocolCard(
                        cardWidth,
                        'Stage 3: Dual Econometric Valuation Modeling',
                        'Parallel synthesis of Fair Value (Income/DCF and Market approaches reflecting highest and best use) and Liquidation Value (Depreciated Replacement Cost and empirical distress liquidation modeling). Rigorous sensitivity analysis across realization timelines.',
                        Icons.analytics_outlined,
                      ),
                      _buildProtocolCard(
                        cardWidth,
                        'Stage 4: Confidential Delivery & Court-Admissible Defense',
                        'Sealed, encrypted delivery of valuation reports directly to the Resolution Professional. Preparation of executive summary dossiers for confidential CoC evaluation, and comprehensive technical defense before NCLT benches in case of creditor challenges.',
                        Icons.gavel,
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

  Widget _buildProtocolCard(double width, String title, String body, IconData icon) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: LandingTheme.brandGreen, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _obsidian,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _slateText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. 10 INSTITUTIONAL FAQS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFaqSection(double screenW, bool isDesktop) {
    final faqs = [
      {
        'q': 'What is the statutory difference between Fair Value and Liquidation Value under the IBC?',
        'a': 'Under Regulation 2(1)(hb) of the CIRP Regulations, Fair Value represents the estimated realizable value if assets were exchanged on the insolvency commencement date between a willing buyer and willing seller in an arm’s-length transaction, assuming proper marketing and highest and best use. In contrast, Liquidation Value under Regulation 2(1)(k) is the estimated realizable value if the corporate debtor were to be liquidated on the commencement date, factoring in forced sale conditions, compressed realization timelines (typically 90 to 180 days), and piecemeal asset surrender.',
      },
      {
        'q': 'Why does the Insolvency and Bankruptcy Code mandate two registered valuers for each asset class?',
        'a': 'Regulation 27 of the CIRP Regulations mandates the appointment of two independent Registered Valuers to ensure cross-validation, procedural objectivity, and creditor protection. Because valuation fundamentally drives the distribution waterfall and minimum payouts under Section 30(2)(b), relying on a single valuer creates unacceptable systemic vulnerability. Both valuers prepare independent appraisals under sealed confidentiality without sharing findings.',
      },
      {
        'q': 'What protocol is triggered if there is a significant difference between the two valuation reports?',
        'a': 'Under Regulation 35(1)(b) of the CIRP Regulations, if the two Registered Valuers submit significantly divergent valuation estimates—statutorily interpreted as a variance exceeding 15% to 25%—the Resolution Professional is required to appoint a Third Registered Valuer. The third valuer conducts an independent appraisal, and the final Fair Value and Liquidation Value are calculated as the mathematical average of the two closest estimates.',
      },
      {
        'q': 'At what stage of the CIRP are valuation figures disclosed to the Committee of Creditors (CoC)?',
        'a': 'Under Regulation 35(2), Fair Value and Liquidation Value figures are strictly confidential and are NOT disclosed at the outset. The Resolution Professional shares the valuation numbers with CoC members only after the receipt of compliant resolution plans and after obtaining a formal confidentiality and non-disclosure undertaking from each creditor. This prevents resolution applicants from pegging bids artificially close to the liquidation floor.',
      },
      {
        'q': 'Can a resolution plan provide an amount lower than the Liquidation Value to operational creditors?',
        'a': 'No. Section 30(2)(b) of the IBC provides an absolute statutory floor. It mandates that operational creditors and dissenting financial creditors must receive an amount not less than what they would have received if the Corporate Debtor were liquidated under Section 53 waterfall priorities. A plan violating this statutory minimum cannot be approved by the Adjudicating Authority (NCLT).',
      },
      {
        'q': 'How is the valuation of continuous process plants and specialized machinery conducted during CIRP?',
        'a': 'Continuous process manufacturing facilities (such as chemical reactors, steel furnaces, and cement kilns) are evaluated using Depreciated Replacement Cost (DRC) and physical condition auditing. Our chartered engineering specialists assess remaining useful life (RUL), technological obsolescence, overhaul records, and replacement capital costs. For liquidation scenarios, we model the steep discounts associated with dismantling, rigging, specialized transport, and secondary equipment auction absorption.',
      },
      {
        'q': 'What is the role of registered valuers in assessing PUFE (Preferential, Undervalued, Extortionate, Fraudulent) transactions?',
        'a': 'While forensic auditors investigate transaction trails, Registered Valuers are engaged under Sections 43, 45, 50, and 66 of the IBC to quantify the economic loss and value differential of suspicious transactions. Valuers determine whether corporate assets were transferred at a gross undervaluation compared to fair market benchmarks during the relevant claw-back look-back periods (1 year for regular parties, 2 years for related parties).',
      },
      {
        'q': 'What is the typical timeline for completing an IBC valuation report under Regulation 27?',
        'a': 'Regulation 27 requires the valuer appointment within 47 days of the insolvency commencement date. Standard comprehensive multi-asset valuation reports require between 30 to 45 business days, including on-site physical inspection, data collation, econometric modeling, and pre-issuance quality review. In urgent fast-track CIRP matters, expedited turnaround can be accommodated through dedicated multi-team deployment.',
      },
      {
        'q': 'How are disputed, un-hypothecated, or unregistered assets treated in an IBC valuation report?',
        'a': 'All known physical and intangible assets belonging to the Corporate Debtor must be inventoried. Where assets are subject to title disputes, pending civil suits, or lack municipal registration, the valuer explicitly notes these legal impediments in the qualification notes. The Fair Value and Liquidation Value are adjusted using risk-adjusted discounting to reflect litigation risk, encumbrance clearing costs, or potential title defects.',
      },
      {
        'q': 'How does the Liquidation Value determined during CIRP impact subsequent liquidation proceedings?',
        'a': 'If the CoC votes for liquidation under Section 33 or if the 330-day resolution window expires without an approved plan, the Adjudicating Authority orders liquidation. Under Regulation 35 of the IBBI (Liquidation Process) Regulations, 2016, the Liquidator may rely on the CIRP valuation reports or commission fresh valuations. The Liquidation Value established during CIRP forms the statutory reserve price benchmark for subsequent public e-auctions of corporate debtor assets.',
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
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'FREQUENTLY ASKED QUESTIONS',
                'Statutory Guidance on CIRP & NCLT Valuations Under IBC 2016',
                'Comprehensive Legal, Procedural, and Methodological Clarifications for RPs and CoC Members',
              ),
              const SizedBox(height: 30),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return _buildFaqItem(faq['q']!, faq['a']!, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderSubtle),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: _obsidian,
          iconColor: LandingTheme.brandGreen,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          title: Text(
            '${index + 1}. $question',
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _obsidian,
            ),
          ),
          children: [
            Text(
              answer,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _slateText,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 11. HIGH-TOUCH EXECUTIVE CONVERSION BLOCK
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildConversionSection(double screenW, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 70 : 45,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 48 : 28),
            decoration: BoxDecoration(
              color: _navyCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  'Appoint an IBBI Registered Valuer for Your CIRP Mandate',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: isDesktop ? 28 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Text(
                    'Ensure strict compliance with Regulation 27 and eliminate dispute vulnerabilities before NCLT benches. Speak directly with our senior Registered Valuers under complete statutory confidentiality.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 15 : 13.5,
                      color: const Color(0xFFCBD5E1),
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _launchWhatsApp(
                        'Hello ProValuer Commercial, I am an Insolvency Professional and require an IBBI Registered Valuer appointment under Regulation 27.',
                      ),
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20, color: Colors.white),
                      label: Text(
                        'WhatsApp CIRP Advisory Desk',
                        style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _makePhoneCall,
                      icon: const Icon(Icons.phone_in_talk, size: 18, color: Colors.white),
                      label: Text(
                        'Call Direct: $_primaryPhoneFormatted',
                        style: GoogleFonts.montserrat(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF475569), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text(
                      'Strict Statutory Confidentiality · NDA Execution Prior to Data Review',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. INSTITUTIONAL FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInstitutionalFooter(double screenW, bool isDesktop) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Footer Nav Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 24,
                    children: [
                      // Col 1: Identity
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PROVALUER COMMERCIAL',
                              style: GoogleFonts.montserrat(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Insolvency & Bankruptcy Valuation Practice. Registered Valuers under IBBI and Section 247 of Companies Act, 2013.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Col 2: Core Practice Services
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
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                            _buildFooterLink('NCLT & IBC Valuation', () => context.go('/services/nclt-ibc-valuation')),
                            _buildFooterLink('Plant & Machinery Valuation', () => context.go('/services/plant-machinery-technical-valuation')),
                          ],
                        ),
                      ),

                      // Col 3: Statutory Jurisdictions
                      SizedBox(
                        width: colW,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NCLT BENCHES',
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFCBD5E1),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooterText('NCLT Hyderabad Bench'),
                            _buildFooterText('NCLT Bengaluru Bench'),
                            _buildFooterText('NCLT Chennai Bench'),
                            _buildFooterText('NCLT Amaravati & Cuttack'),
                          ],
                        ),
                      ),

                      // Col 4: Institutional Contact
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

              // Bottom bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© 2026 ProValuer Commercial. All Rights Reserved. Canonical: https://www.provaluer.in',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'Statutory Insolvency Practice · IBBI Regulated',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
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

  Widget _buildFooterLink(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              decoration: TextDecoration.underline,
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
          fontSize: 12,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String tag, String title, String subtitle) {
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
            tag,
            style: GoogleFonts.montserrat(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: _obsidian,
              letterSpacing: 0.8,
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
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _slateText,
          ),
        ),
      ],
    );
  }

  Widget _buildSubHeading(String title) {
    return Text(
      title,
      style: GoogleFonts.montserrat(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: _obsidian,
      ),
    );
  }
}
