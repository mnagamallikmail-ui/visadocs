import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/landing/landing_theme.dart';

/// Government Approved Valuers in India — Master Authority & Practice Hub
/// Canonical URL: https://www.provaluer.in/government-approved-valuers
class GovernmentApprovedValuersScreen extends StatefulWidget {
  const GovernmentApprovedValuersScreen({super.key});

  @override
  State<GovernmentApprovedValuersScreen> createState() => _GovernmentApprovedValuersScreenState();
}

class _GovernmentApprovedValuersScreenState extends State<GovernmentApprovedValuersScreen> {
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
  static const Color _navyCard = Color(0xFF1E293B);

  // Active index for "Why do you need a valuation?" interactive selector
  int _selectedReasonIndex = 0;

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

                // 2. Statutory Credentials & Regulatory Framework
                _buildFrameworkSection(screenW, isDesktop),

                // 3. When Do You Need a Government Approved Valuation Report?
                _buildWhenDoYouNeedSection(screenW, isDesktop),

                // 4. Interactive "Why do you need a valuation?" Selector
                _buildInteractiveSelectorSection(screenW, isDesktop),

                // 5. Property Valuation for Income Tax, Capital Gains & Stamp Duty (Sec 50C, 55A)
                _buildIncomeTaxSection(screenW, isDesktop),

                // 6. Certified Property Valuation for Visa & Global Immigration
                _buildVisaSection(screenW, isDesktop),

                // 7. Legal, Court & Matrimonial Valuations (Divorce & Inheritance)
                _buildLegalAndCourtSection(screenW, isDesktop),

                // 8. Comparative Matrix: Valuer vs Real Estate Agent vs Engineer
                _buildComparativeMatrixSection(screenW, isDesktop),

                // 9. Local Practice Focus: Hyderabad, Secunderabad & Telangana
                _buildLocalSeoSection(screenW, isDesktop),

                // 10. Comprehensive Documentation Checklist
                _buildDocumentationChecklistSection(screenW, isDesktop),

                // 11. The ProValuer 4-Stage Protocol
                _buildProtocolSection(screenW, isDesktop),

                // 12. 10 Institutional FAQs
                _buildFaqSection(screenW, isDesktop),

                // 13. High-Touch Executive Conversion Block
                _buildConversionSection(screenW, isDesktop),

                // 14. Institutional Footer
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
                  'Hello ProValuer Commercial, I require a certified valuation report from a Government Approved Valuer.',
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
                        'Valuer Advisory Desk',
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

                      // Desktop Navigation
                      if (isDesktop) ...[
                        _buildNavText('Home', () => context.go('/')),
                        const SizedBox(width: 22),
                        _buildNavText(
                          'Govt Valuers',
                          () => context.go('/government-approved-valuers'),
                          isActive: true,
                        ),
                        const SizedBox(width: 22),
                        _buildNavText(
                          'Bank Collateral',
                          () => context.go('/services/bank-collateral-valuation'),
                        ),
                        const SizedBox(width: 22),
                        _buildNavText(
                          'NCLT & IBC',
                          () => context.go('/services/nclt-ibc-valuation'),
                        ),
                        const SizedBox(width: 22),
                        _buildNavText(
                          'Plant & Machinery',
                          () => context.go('/services/plant-machinery-technical-valuation'),
                        ),
                        const SizedBox(width: 30),
                      ],

                      // Direct Phone Button
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

                      // WhatsApp Consultation Button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _launchWhatsApp(
                            'Hello ProValuer Commercial, I would like to consult a Government Approved Valuer regarding a certified property appraisal.',
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
                                  'Request Valuation',
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
                    Icons.account_balance,
                    'SECTION 34AB WEALTH TAX ACT 1957 (CBDT APPROVED)',
                    _obsidian,
                  ),
                  _buildPillBadge(
                    Icons.verified_user,
                    'SECTION 247 COMPANIES ACT 2013 (IBBI REGISTERED)',
                    LandingTheme.brandGreen,
                  ),
                  _buildPillBadge(
                    Icons.gavel,
                    'COURT-ADMISSIBLE EXPERT APPRAISALS (SEC 45 EVIDENCE ACT)',
                    _accentGold,
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // H1 Heading
              Text(
                'Government Approved Valuers in India: Statutory Property, Tax & Legal Valuations',
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
                'ProValuer Commercial provides defense-grade, legally unassailable valuation reports executed by Government Approved Valuers under Section 34AB of the Wealth Tax Act, 1957 and Registered Valuers under Section 247 of the Companies Act, 2013. Serving taxpayers, legal advocates, chartered accountants, property owners, and non-resident Indians (NRIs), our certified valuation reports are accepted without demur by the Income Tax Department, the Reserve Bank of India, Indian High Courts, Family Courts, Sub-Registrar Offices (SRO), and foreign diplomatic missions including US, UK, Canadian, and Australian consulates.',
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
                  _buildTrustBadge('Income Tax Approved', 'Wealth Tax Act Sec 34AB'),
                  _buildTrustBadge('IBBI Registered Valuers', 'Land & Building / Machinery / SFA'),
                  _buildTrustBadge('100% Embassy Acceptance', 'US, UK, Canada & Australia Visa'),
                  _buildTrustBadge('Fast Turnaround SLA', '24 to 48 Hours for Standard Appraisals'),
                ],
              ),
              const SizedBox(height: 36),

              // Action Buttons
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => _launchWhatsApp(
                      'Hello ProValuer Commercial, I would like to consult a Government Approved Valuer for a certified valuation report.',
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
                          'Speak to a Government Approved Valuer',
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
                          'Direct Consultation: $_primaryPhoneFormatted',
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

              // Metric Highlights Grid
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
      {'val': 'Sec 34AB', 'label': 'Wealth Tax Act CBDT Empanelled', 'icon': Icons.account_balance_outlined},
      {'val': 'Sec 247', 'label': 'Companies Act & IBBI Registered', 'icon': Icons.verified_user_rounded},
      {'val': 'Court Proof', 'label': 'Indian Evidence Act Sec 45 Admissible', 'icon': Icons.gavel_rounded},
      {'val': 'Pan-India', 'label': 'Hyderabad, Telangana & Nationwide Reach', 'icon': Icons.map_outlined},
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
  // 2. STATUTORY CREDENTIALS & REGULATORY FRAMEWORK
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
                'STATUTORY CREDENTIALS & REGULATORY MANDATES',
                'Dual Registration Under Wealth Tax Act Sec 34AB & Companies Act Sec 247',
                'The Statutory Foundations That Distinguish Government Approved Valuers in India',
              ),
              const SizedBox(height: 26),

              Text(
                'In the Indian legal and financial system, property valuation is not an unregulated commercial opinion. When assets are appraised for taxation, judicial adjudication, bank lending, or visa solvency, authorities strictly mandate that the valuer possess formal statutory registration granted by the Central Government. ProValuer Commercial operates across the two highest tiers of statutory recognition in India:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildFrameworkCard(
                        colW,
                        '1. Wealth Tax Act, 1957 (Section 34AB)',
                        'Registered directly by the Chief Commissioner of Income Tax / Principal Chief Commissioner under the Central Board of Direct Taxes (CBDT), Ministry of Finance, Government of India. Valuers registered under Section 34AB hold statutory jurisdiction for Capital Gains Tax (Section 50C, Section 54, Section 55A), Wealth Tax, Stamp Duty adjudications, High Court probate petitions, Family Court asset settlements, and foreign visa financial solvency certificates.',
                        Icons.account_balance,
                      ),
                      _buildFrameworkCard(
                        colW,
                        '2. Companies Act, 2013 (Section 247)',
                        'Registered Valuers governed by the Insolvency and Bankruptcy Board of India (IBBI) and recognized Registered Valuers Organisations (RVOs). Mandated for corporate collateral assessments, bank consortium borrowings, NCLT/IBC corporate insolvency resolution processes (CIRP), mergers & acquisitions, and Ind AS 113 fair value financial reporting.',
                        Icons.verified_user,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Under Section 45 of the Indian Evidence Act, 1872, reports issued by our Government Approved and IBBI Registered Valuers carry the evidentiary status of certified expert testimony. This eliminates the risk of reports being dismissed as self-serving claims during litigation, tax scrutiny, or consular visa audits.',
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
              fontSize: 13.5,
              color: _slateText,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. WHEN DO YOU NEED A GOVERNMENT APPROVED VALUATION REPORT?
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWhenDoYouNeedSection(double screenW, bool isDesktop) {
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
                'STATUTORY VALUATION TRIGGERS',
                'When Do You Need a Government Approved Valuation Report?',
                'An Essential Guide to the 8 Legal and Commercial Triggers Requiring Certified Appraisals',
              ),
              const SizedBox(height: 24),

              Text(
                'A valuation report issued by a Government Approved Valuer is a legally binding evidentiary document mandated by regulatory statutes, judicial tribunals, and institutional bodies. In India and across international jurisdictions, there are eight primary circumstances under which engaging a certified Government Approved Valuer is mandatory:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 28),

              // 8 Scenarios Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildTriggerCard(
                        cardW,
                        '1. Visa & Global Immigration',
                        'Requested by: US Embassy (USCIS), UKVI, IRCC Canada, Australian DHA, Schengen Consulates.\nWhy Required: To prove liquid financial solvency, family ties to India, and net worth backing student, investor, or immigrant visas. Reports must follow Wealth Tax Act Sec 34AB standards.',
                        Icons.flight_takeoff,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '2. Bank Finance & Mortgage Lending',
                        'Requested by: Nationalized PSU Banks, Scheduled Private Lenders, Housing Finance Companies, NBFCs.\nWhy Required: To benchmark Fair Market Value (FMV), Realizable Value, and Distress Sale Value for Loan Against Property (LAP), project finance, and SARFAESI reserve price enforcement.',
                        Icons.account_balance,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '3. Property Sale & Capital Gains Tax',
                        'Requested by: Income Tax Assessing Officers, CIT (Appeals), Chartered Accountants.\nWhy Required: To challenge inflated Sub-Registrar circle rates under Section 50C and Section 56(2)(x), or determine historical FMV as of April 1, 2001 under Section 55A for indexation benefits.',
                        Icons.trending_up,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '4. Divorce & Matrimonial Settlements',
                        'Requested by: Family Courts, Matrimonial Advocates, Arbitrators, Mediators.\nWhy Required: To establish an independent, neutral market value for joint marital real estate and commercial assets to ensure equitable distribution under the Family Courts Act, 1984.',
                        Icons.balance,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '5. Probate, Succession & Inheritance',
                        'Requested by: High Courts, District Civil Courts, Estate Executors, Legal Heirs.\nWhy Required: To quantify gross estate valuation for calculating court fees in probate petitions, letters of administration, and executing registered wills under the Indian Succession Act, 1925.',
                        Icons.history_edu,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '6. Family Settlements & Gift Deeds',
                        'Requested by: Sub-Registrar Offices (SRO), Family Offices, Partition Mediators.\nWhy Required: To arrive at mutually agreed market valuations for family partition deeds, settlement deeds, and gift registrations, preventing future title litigation and stamp duty penalties.',
                        Icons.diversity_3,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '7. Corporate Transactions & Mergers',
                        'Requested by: Boards of Directors, Statutory Auditors, Registrar of Companies (ROC), SEBI.\nWhy Required: Mandated under Section 247 of Companies Act 2013 for asset transfers, slump sales, FEMA cross-border equity pricing, and Ind AS 113 fair value financial statements.',
                        Icons.business,
                      ),
                      _buildTriggerCard(
                        cardW,
                        '8. NCLT & Insolvency Proceedings',
                        'Requested by: Resolution Professionals (RPs), Liquidators, Committee of Creditors (CoC).\nWhy Required: Statutorily required under Regulation 27 & 35 of the IBBI CIRP Regulations, 2016 to compute Fair Value and Liquidation Value during corporate distress resolution.',
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

  Widget _buildTriggerCard(double width, String title, String body, IconData icon) {
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
                    fontSize: 15,
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
  // 4. INTERACTIVE "WHY DO YOU NEED A VALUATION?" SELECTOR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildInteractiveSelectorSection(double screenW, bool isDesktop) {
    final options = [
      {
        'title': 'Visa & Immigration',
        'icon': Icons.flight_takeoff,
        'summary':
            'Foreign embassies (US, UK, Canada, Australia, Schengen) mandate wealth and property valuation reports signed by Section 34AB Government Approved Valuers to establish family financial solvency and satisfy Form I-134/I-864 or UKVI requirements.',
        'statutory': 'Wealth Tax Act 1957 Section 34AB · Consular Solvency Standards',
        'actionText': 'Consult Visa Valuation Desk',
        'waMessage':
            'Hello ProValuer Commercial, I need a certified Property Valuation Report for my Student / Immigration Visa application.',
        'linkRoute': '/services/visa-and-immigration-valuations',
        'linkText': 'View Dedicated Visa Valuation Page',
      },
      {
        'title': 'Bank Finance',
        'icon': Icons.account_balance,
        'summary':
            'Nationalized PSU banks and private lenders require Fair Market, Realizable, and Distress Sale values to sanction high-value Loan Against Property (LAP), working capital, and term loan facilities.',
        'statutory': 'Companies Act 2013 Section 247 · RBI Master Directions · SARFAESI Act',
        'actionText': 'Consult Banking Valuation Desk',
        'waMessage':
            'Hello ProValuer Commercial, I need a bank collateral valuation report for loan sanctioning / mortgage security.',
        'linkRoute': '/services/bank-collateral-valuation',
        'linkText': 'View Bank Collateral Valuation Page',
      },
      {
        'title': 'Capital Gains Tax',
        'icon': Icons.trending_up,
        'summary':
            'Rebut inflated circle rates under Section 50C/56(2)(x) before the Assessing Officer, or establish historical FMV as of April 1, 2001 under Section 55A to optimize indexed cost of acquisition.',
        'statutory': 'Income Tax Act 1961 Section 50C, 54, 55A, 56(2)(x)',
        'actionText': 'Consult Capital Gains Specialist',
        'waMessage':
            'Hello ProValuer Commercial, I need a Government Approved Valuation Report to respond to an Income Tax / Section 50C query.',
        'linkRoute': '',
        'linkText': '',
      },
      {
        'title': 'Property Sale',
        'icon': Icons.home_work,
        'summary':
            'Accurately establish true fair market value before listing or purchasing prime real estate. Avoid under-reporting penalties and verify stamp duty market rates across municipal corridors.',
        'statutory': 'State Stamp Acts · IGRS Market Valuation Guidelines',
        'actionText': 'Request Property Valuation',
        'waMessage':
            'Hello ProValuer Commercial, I would like to get an independent property valuation before executing a sale/purchase.',
        'linkRoute': '',
        'linkText': '',
      },
      {
        'title': 'Divorce & Matrimonial',
        'icon': Icons.balance,
        'summary':
            'Provide family courts and matrimonial advocates with an unassailable, neutral valuation of joint residential and commercial properties to ensure equitable marital asset division.',
        'statutory': 'Family Courts Act 1984 · Indian Evidence Act Section 45',
        'actionText': 'Confidential Matrimonial Advisory',
        'waMessage':
            'Hello ProValuer Commercial, I need an impartial, court-admissible valuation for a matrimonial property settlement.',
        'linkRoute': '',
        'linkText': '',
      },
      {
        'title': 'Inheritance & Probate',
        'icon': Icons.history_edu,
        'summary':
            'Determine exact asset values for High Court probate petitions, succession certificates, and registered family partition deeds under the Indian Succession Act, 1925.',
        'statutory': 'Indian Succession Act 1925 · Court Fees Act 1870',
        'actionText': 'Consult Succession Valuer',
        'waMessage':
            'Hello ProValuer Commercial, I need a valuation report for High Court probate / succession certificate filing.',
        'linkRoute': '',
        'linkText': '',
      },
      {
        'title': 'NCLT & Insolvency',
        'icon': Icons.gavel,
        'summary':
            'Statutory Fair Value and Liquidation Value appraisals under Regulation 27 & 35 of CIRP Regulations for Resolution Professionals, Liquidators, and Committees of Creditors.',
        'statutory': 'Insolvency and Bankruptcy Code 2016 · CIRP Regulations',
        'actionText': 'Consult Insolvency Valuer',
        'waMessage':
            'Hello ProValuer Commercial, I require statutory valuation under Regulation 27 of CIRP Regulations for an NCLT matter.',
        'linkRoute': '/services/nclt-ibc-valuation',
        'linkText': 'View NCLT & IBC Valuation Page',
      },
      {
        'title': 'Corporate Transactions',
        'icon': Icons.business,
        'summary':
            'Valuation of corporate assets, shares, and industrial plants under Section 247 of the Companies Act for M&A, capital restructuring, and Ind AS 113 financial reporting.',
        'statutory': 'Companies Act 2013 Section 247 · FEMA Equity Guidelines',
        'actionText': 'Consult Corporate Valuation Desk',
        'waMessage':
            'Hello ProValuer Commercial, I need a valuation report for a corporate transaction / Section 247 compliance.',
        'linkRoute': '',
        'linkText': '',
      },
    ];

    final currentOption = options[_selectedReasonIndex];

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
                'INTERACTIVE VALUATION ADVISORY SELECTOR',
                'Why Do You Need a Valuation? Select Your Specific Use Case',
                'Select your purpose below to review the statutory mandate, documentation criteria, and consultation path.',
              ),
              const SizedBox(height: 28),

              // Selector Tabs
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final opt = entry.value;
                  final isSelected = idx == _selectedReasonIndex;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedReasonIndex = idx),
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
                              opt['icon'] as IconData,
                              size: 15,
                              color: isSelected ? Colors.white : _obsidian,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              opt['title'] as String,
                              style: GoogleFonts.montserrat(
                                fontSize: 12.5,
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

              // Selected Option Detail Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            currentOption['icon'] as IconData,
                            color: LandingTheme.brandGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentOption['title'] as String,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: _obsidian,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                currentOption['statutory'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: LandingTheme.brandGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      currentOption['summary'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        color: _slateText,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _launchWhatsApp(currentOption['waMessage'] as String),
                          icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16),
                          label: Text(
                            currentOption['actionText'] as String,
                            style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LandingTheme.brandGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if ((currentOption['linkRoute'] as String).isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () {
                              final route = currentOption['linkRoute'] as String;
                              context.go(route);
                            },
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: _obsidian),
                            label: Text(
                              currentOption['linkText'] as String,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _obsidian,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _borderSubtle),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
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
  // 5. PROPERTY VALUATION FOR INCOME TAX, CAPITAL GAINS & STAMP DUTY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIncomeTaxSection(double screenW, bool isDesktop) {
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
                'TAXATION & STAMP DUTY APPRAISALS',
                'Property Valuation Reports for Income Tax, Capital Gains & Stamp Duty',
                'Statutory Defense Under Section 50C, Section 55A, and Section 56(2)(x) of the Income Tax Act, 1961',
              ),
              const SizedBox(height: 26),

              Text(
                'One of the most consequential functions of a Section 34AB Government Approved Valuer is safeguarding taxpayers against arbitrary capital gains tax additions and stamp duty disputes. The Income Tax Act, 1961 contains strict anti-abuse provisions where property valuations directly impact tax liabilities:',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 22),

              // 4 Deep Tax Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildIncomeTaxCard(
                        colW,
                        'Section 50C: Rebutting Inflated Circle Rates',
                        'Under Section 50C, if the sale consideration of land or building is less than the State Government circle rate / guideline value, the circle rate is deemed the full value of consideration. However, under Section 50C(2), the taxpayer has the statutory right to claim before the Assessing Officer that the circle rate exceeds true Fair Market Value due to physical defects, encumbrances, road-width restrictions, or litigation. A valuation report from a Government Approved Valuer establishes the true FMV, compelling the tax authority to adopt the realistic value.',
                        Icons.gavel,
                      ),
                      _buildIncomeTaxCard(
                        colW,
                        'Section 55A: Fair Market Value as of April 1, 2001',
                        'For ancestral properties or assets acquired before April 1, 2001, taxpayers can substitute historical Fair Market Value as of April 1, 2001 for indexation under Section 55. As per the Finance Act, this FMV cannot exceed the stamp duty value as on April 1, 2001. Our valuers trace historical registration archives, municipal records, and CPWD construction indices to provide Chartered Accountants with the certified valuation basis required to compute indexed acquisition costs and prevent scrutiny additions.',
                        Icons.calendar_month,
                      ),
                      _buildIncomeTaxCard(
                        colW,
                        'Section 56(2)(x): Defending Buyers Against Deemed Gifts',
                        'Under Section 56(2)(x), if a buyer purchases property for a price lower than the stamp duty guideline value (by more than 10% or ₹50,000), the difference is treated as taxable income under "Income from Other Sources". Our certified valuation reports establish why the actual market transaction price reflects genuine arm’s-length market reality, protecting buyers from unjustified tax additions.',
                        Icons.shield_outlined,
                      ),
                      _buildIncomeTaxCard(
                        colW,
                        'Challenging SRO Guideline Values & Stamp Duty Disputes',
                        'State Sub-Registrar Offices (SROs) frequently maintain outdated or blanket guideline values that do not account for land locking, high-tension wire encumbrances, water-body buffer zones, or municipal road-widening reservations. When registering sale deeds or gift deeds, our reports substantiate why lower stamp duty applies, enabling successful appeals under Section 47A of the Indian Stamp Act.',
                        Icons.receipt_long,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Chartered Accountants and tax advocates routinely engage ProValuer Commercial during faceless assessments under Section 143(3), appeals before the Commissioner of Income Tax (Appeals), and proceedings before the Income Tax Appellate Tribunal (ITAT). Our reports include extensive photographic evidence, title chain analysis, CPWD cost indices, and registered transaction comparables.',
                style: GoogleFonts.inter(fontSize: 14.5, color: _slateText, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeTaxCard(double width, String title, String body, IconData icon) {
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
                    fontSize: 15,
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
  // 6. CERTIFIED PROPERTY VALUATION FOR VISA & GLOBAL IMMIGRATION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVisaSection(double screenW, bool isDesktop) {
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
                'GLOBAL IMMIGRATION & CONSULAR SOLVENCY',
                'Certified Property Valuation for Visa & Financial Solvency',
                'Mandated Formats for US, UK, Canada, Australia, and European Schengen Embassies',
              ),
              const SizedBox(height: 26),

              Text(
                'When Indian students, working professionals, and families apply for overseas student visas (US F-1, UK Student Route, Canada Study Permit, Australia Subclass 500) or permanent residency/investor visas (EB-5, Golden Visas), foreign consular officers require proof of sufficient financial solvency and ties to India to ensure the applicant will not become a public charge.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Foreign consulates explicitly reject real estate broker letters, property portal estimates, or self-declared property valuations. Consular fraud prevention units mandate that property valuation certificates be executed by a Government Approved Valuer registered under Section 34AB of the Wealth Tax Act, complete with registration numbers, boundary descriptions, and municipal tax receipts.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              // Visa Gateway Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _pureWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LandingTheme.brandGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LandingTheme.brandGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.flight_takeoff, color: LandingTheme.brandGreen, size: 28),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need a Dedicated Visa Net Worth & Solvency Report?',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _obsidian,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Explore our dedicated service page for visa net worth statements, CA cross-verification, and embassy-specific formats with guaranteed 24 to 48-hour delivery.',
                            style: GoogleFonts.inter(fontSize: 13, color: _slateText, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/services/visa-and-immigration-valuations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LandingTheme.brandGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Visa Services →',
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. LEGAL, COURT & MATRIMONIAL VALUATIONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLegalAndCourtSection(double screenW, bool isDesktop) {
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
                'JUDICIAL & COURT-ADMISSIBLE VALUATIONS',
                'Divorce Settlements, Inheritance, Estate Succession & High Court Probate',
                'Unbiased Forensic Property Appraisals Under the Indian Evidence Act, 1872',
              ),
              const SizedBox(height: 26),

              Text(
                'When real estate becomes the subject of contentious litigation—whether in divorce proceedings before Family Courts or estate disputes under High Court probate jurisdictions—judicial officers require independent expert testimony. Reports by real estate brokers or interested parties are routinely set aside for bias. ProValuer Commercial’s registered valuers provide court-admissible appraisals backed by complete chain-of-title documentation and physical boundary audits.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 20) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _buildTriggerCard(
                        colW,
                        'Divorce & Matrimonial Asset Division',
                        'In matrimonial disputes, determining the exact fair market value of jointly owned apartments, ancestral properties, and benami investments is vital for permanent alimony and equitable property distribution. Our reports provide Family Court judges and advocates with objective market assessments that eliminate emotional distortion.',
                        Icons.balance,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Inheritance, Probate & High Court Petitions',
                        'Under the Indian Succession Act, 1925 and the Court Fees Act, 1870, obtaining a Letter of Administration or Probate of a Will requires accurate certified valuation of all immovable estate assets. Our Section 34AB valuation reports establish the precise value for probate court fee computation and prevent partition disputes among legal heirs.',
                        Icons.history_edu,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. COMPARATIVE MATRIX: VALUER VS BROKER VS ENGINEER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildComparativeMatrixSection(double screenW, bool isDesktop) {
    final rows = [
      ['Dimension', 'Govt Approved Valuer (Sec 34AB)', 'Real Estate Agent / Broker', 'Chartered Engineer (Non-Valuer)'],
      ['Statutory License', 'Central Board of Direct Taxes (CBDT)', 'None (State RERA Agent only)', 'Institution of Engineers (India)'],
      ['Income Tax Sec 50C/55A', 'Statutorily Binding Evidence', 'Rejected by Assessing Officers', 'Rejected without Sec 34AB license'],
      ['Court Admissibility', 'Expert Witness under Evidence Act Sec 45', 'Inadmissible Hearsay Opinion', 'Limited to civil engineering structure'],
      ['Foreign Visa Acceptance', '100% Recognized by Embassies', 'Strictly Rejected by Consulates', 'Not Accepted for financial solvency'],
      ['Bank Collateral & Lending', 'Empanelled with PSU/Private Banks', 'Zero Lending Validity', 'Limited to building cost certification'],
      ['Professional Liability', 'Statutory Fiduciary Accountability', 'Zero Legal Accountability', 'Engineering Certification Only'],
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
                'STATUTORY LOCUS STANDI',
                'Government Approved Valuer vs. Real Estate Agent vs. Chartered Engineer',
                'Understanding the Legal Differences That Prevent Rejection in Courts, Banks, and Consulates',
              ),
              const SizedBox(height: 26),

              Container(
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
                                fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
                                color: isHeader ? _obsidian : LandingTheme.brandGreen,
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
                          Expanded(
                            flex: 3,
                            child: Text(
                              r[3],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. LOCAL PRACTICE FOCUS: HYDERABAD & TELANGANA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildLocalSeoSection(double screenW, bool isDesktop) {
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
                'LOCAL REGIONAL PRACTICE',
                'Government Approved Valuer Services in Hyderabad, Secunderabad & Telangana',
                'Comprehensive HMDA, GHMC, and Dharani Revenue Knowledge Across Greater Hyderabad',
              ),
              const SizedBox(height: 26),

              Text(
                'Headquartered in Hyderabad, ProValuer Commercial maintains dedicated field inspection teams covering the entire Hyderabad Metropolitan Development Authority (HMDA) jurisdiction, Greater Hyderabad Municipal Corporation (GHMC), and the industrial corridors of Telangana state. We combine localized revenue expertise with statutory central licensing.',
                style: GoogleFonts.inter(fontSize: 15, color: _slateText, height: 1.8),
              ),
              const SizedBox(height: 22),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildTriggerCard(
                        colW,
                        'Commercial & Premium Hubs',
                        'Jubilee Hills, Banjara Hills, Hitec City, Gachibowli, Madhapur, Financial District, Kondapur, Kokapet, and Neopolis. Rapid valuation for high-value commercial IT spaces, luxury villas, and multi-story residential towers.',
                        Icons.business,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Industrial Corridors & SEZs',
                        'Patancheru, Pashamylaram, Jeedimetla, Genome Valley, Jadcherla, Shamshabad, and Cherlapally. Deep expertise in TSIIC industrial plot allotments, factory sheds, and heavy engineering plants.',
                        Icons.factory,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Dharani & IGRS Integration',
                        'Direct integration with Telangana Registration & Stamps Department (IGRS Telangana) market value tables and the Dharani portal for agricultural land conversion tracking and non-agricultural regularizations.',
                        Icons.lan,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 10. COMPREHENSIVE DOCUMENTATION CHECKLIST
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDocumentationChecklistSection(double screenW, bool isDesktop) {
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
                'DOCUMENTATION CHECKLIST',
                'Required Documents for a Government Approved Valuation Report',
                'Collate the Following Records to Ensure Rapid 24 to 48-Hour Report Delivery',
              ),
              const SizedBox(height: 24),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildChecklistCard(
                        colW,
                        '1. Real Estate & Land Title Dossier',
                        [
                          'Registered Sale Deed, Gift Deed, Partition Deed, or Allotment Letter.',
                          'Link Documents establishing 30-year ownership pedigree.',
                          'Encumbrance Certificate (EC) for the preceding 13 to 30 years.',
                          'Approved Building Plan and Layout Sanction copy from GHMC/HMDA/Municipality.',
                          'Latest Property Tax Assessment Receipt and Electricity / Water Bills.',
                        ],
                      ),
                      _buildChecklistCard(
                        colW,
                        '2. Applicant & Legal Mandate Dossier',
                        [
                          'Identity Proof (Aadhaar Card, PAN Card, Passport for Visa / NRI mandates).',
                          'Income Tax Scrutiny Notice / Assessment Order (for Section 50C / 55A appeals).',
                          'Court Petition copy (for Family Court divorce or High Court probate matters).',
                          'Bank Sanction Letter / Loan Application details (for collateral lending).',
                          'Power of Attorney (POA) if the owner is an NRI or unable to attend physical inspection.',
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

  Widget _buildChecklistCard(double width, String title, List<String> items) {
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
              color: LandingTheme.brandGreen,
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
  // 11. THE PROVALUER 4-STAGE PROTOCOL
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
                'VALUATION PROTOCOL',
                'The ProValuer 4-Stage Government Valuation Protocol',
                'Rigorous Execution Methodology Ensuring 100% Statutory and Consular Acceptance',
              ),
              const SizedBox(height: 26),

              LayoutBuilder(
                builder: (context, constraints) {
                  final colW = isDesktop ? (constraints.maxWidth - 24) / 2 : constraints.maxWidth;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 20,
                    children: [
                      _buildTriggerCard(
                        colW,
                        'Stage 1: Mandate & Title Pre-Audit',
                        'We review link documents, revenue entries, and municipal layout approvals to identify zoning, encumbrance, or title discrepancies prior to physical field mobilization.',
                        Icons.assignment_turned_in_outlined,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Stage 2: Physical Boundary & Condition Audit',
                        'A certified valuer inspects the property, verifies actual physical boundaries against sale deeds, takes geo-stamped photos, and evaluates construction quality and remaining useful life.',
                        Icons.pin_drop_outlined,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Stage 3: Multi-Methodological Modeling',
                        'We apply Market Approach (comparables), Cost Approach (CPWD Plinth Area Rates minus depreciation), and Income Approach to compute defensible Fair Market Value.',
                        Icons.analytics_outlined,
                      ),
                      _buildTriggerCard(
                        colW,
                        'Stage 4: Certified Report Issuance & Defense',
                        'We deliver sealed, digitally signed valuation reports with QR verification codes, Section 34AB credentials, and complete annexures accepted by tax officers, courts, and embassies.',
                        Icons.verified_outlined,
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

  // ═══════════════════════════════════════════════════════════════════════════
  // 12. 10 INSTITUTIONAL FAQS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFaqSection(double screenW, bool isDesktop) {
    final faqs = [
      {
        'q': 'Who is legally considered a "Government Approved Valuer" in India?',
        'a': 'In India, a Government Approved Valuer is a professional registered under Section 34AB of the Wealth Tax Act, 1957 by the Chief Commissioner of Income Tax / CBDT, Ministry of Finance, Government of India. For corporate matters under the Companies Act, 2013, valuers must be registered with the Insolvency and Bankruptcy Board of India (IBBI) under Section 247. ProValuer Commercial holds both statutory registrations.',
      },
      {
        'q': 'Is a property valuation report mandatory for student visa and immigration applications?',
        'a': 'Yes. Foreign embassies (including US, UK, Canada, Australia, and European Schengen consulates) mandate certified financial solvency evidence. A property valuation report prepared by a Section 34AB Government Approved Valuer proves that the applicant or sponsor possesses genuine immovable assets in India to finance education and retain strong ties to the home country.',
      },
      {
        'q': 'What is the difference between an IBBI Registered Valuer and a Wealth Tax Approved Valuer?',
        'a': 'Wealth Tax Act Section 34AB Government Approved Valuers are empanelled by the Income Tax Department to value assets for individuals, capital gains tax, stamp duty, family courts, and visa solvency. IBBI Registered Valuers under Section 247 of the Companies Act hold statutory jurisdiction over corporate debt, banking collateral, mergers, and NCLT/IBC insolvency proceedings.',
      },
      {
        'q': 'How does a Government Approved Valuer determine property value for Capital Gains Tax under Section 50C?',
        'a': 'Under Section 50C of the Income Tax Act, if the sale price is lower than the circle rate, the circle rate is treated as the sale value. However, the taxpayer can contest this under Section 50C(2) before the Assessing Officer. A Government Approved Valuer evaluates physical constraints, road width, topography, and municipal encumbrances to prove true Fair Market Value, protecting the taxpayer from arbitrary tax additions.',
      },
      {
        'q': 'Are your valuation reports accepted by Indian courts in divorce and property partition suits?',
        'a': 'Yes. Under Section 45 of the Indian Evidence Act, 1872, reports issued by our Government Approved Valuers serve as certified expert evidence. They are accepted by Family Courts in divorce settlements, Civil District Courts, and High Courts for probate, letters of administration, and partition suits.',
      },
      {
        'q': 'What documents are required to obtain a certified property valuation report?',
        'a': 'Key documents include: (1) Registered Sale Deed / Title Deed, (2) Link documents tracing ownership, (3) Encumbrance Certificate (EC), (4) Approved Building Plan / Layout Sanction, and (5) Latest Property Tax assessment receipt. For visa reports, applicant and sponsor identity proof is also required.',
      },
      {
        'q': 'What is the standard turnaround time for a Government Approved Valuation Report?',
        'a': 'For standard residential properties and visa net worth reports, certified reports are delivered within 24 to 48 hours following physical inspection and document receipt. For large commercial buildings, industrial factories, or agricultural land parcels, turnaround is typically 3 to 5 business days.',
      },
      {
        'q': 'Can a Government Approved Valuer provide valuation for NRI properties located in India?',
        'a': 'Yes. We frequently serve Non-Resident Indians (NRIs) residing in the US, UK, Gulf, Canada, and Australia. Physical site inspection is coordinated with local representatives or tenants, and certified digital reports bearing cryptographic digital signatures and QR verification are delivered securely overseas.',
      },
      {
        'q': 'How long is a Government Approved Valuation Report legally valid?',
        'a': 'For taxation purposes (Capital Gains), the report is tied to the specific transaction date or assessment year. For visa and immigration, foreign consulates typically require reports issued within the preceding 6 months. For bank lending, reports remain active for 1 to 3 years depending on institutional credit policies.',
      },
      {
        'q': 'Why can’t a real estate agent or property broker sign a legal valuation report?',
        'a': 'Real estate brokers and property agents do not possess statutory registration under Section 34AB of the Wealth Tax Act or Section 247 of the Companies Act. They have no locus standi under Indian law, and their estimates are strictly rejected by the Income Tax Department, courts, banks, and foreign embassies.',
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
                'Statutory Guidance on Government Approved Valuations in India',
                'Clear Answers to the Most Common Legal, Tax, Banking, and Visa Valuation Questions',
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
  // 13. HIGH-TOUCH EXECUTIVE CONVERSION BLOCK
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
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 20),
                Text(
                  'Consult a Government Approved Valuer Today',
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
                    'Ensure 100% acceptance before the Income Tax Department, Indian Courts, Banks, and Foreign Embassies. Connect directly with our Senior Valuers under complete professional confidentiality.',
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
                        'Hello ProValuer Commercial, I would like to consult a Government Approved Valuer for a certified valuation report.',
                      ),
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20, color: Colors.white),
                      label: Text(
                        'WhatsApp Advisory Desk',
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
                        'Direct Call: $_primaryPhoneFormatted',
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
                      'Strict Professional Confidentiality · Court-Admissible & Embassy-Approved Formats',
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
  // 14. INSTITUTIONAL FOOTER
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
                              'Government Approved Valuers under Wealth Tax Act Sec 34AB & IBBI Registered Valuers under Companies Act Sec 247.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Col 2: Services
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
                            _buildFooterLink('Government Approved Valuers', () => context.go('/government-approved-valuers')),
                            _buildFooterLink('Bank Collateral Valuation', () => context.go('/services/bank-collateral-valuation')),
                            _buildFooterLink('NCLT & IBC Valuation', () => context.go('/services/nclt-ibc-valuation')),
                            _buildFooterLink('Plant & Machinery Valuation', () => context.go('/services/plant-machinery-technical-valuation')),
                          ],
                        ),
                      ),

                      // Col 3: Legal & Statutory Scope
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
                            const SizedBox(height: 12),
                            _buildFooterText('Income Tax Section 50C & 55A'),
                            _buildFooterText('Visa Financial Solvency (US/UK/Canada)'),
                            _buildFooterText('Family Court Divorce Settlements'),
                            _buildFooterText('High Court Probate & Succession'),
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
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'CBDT Approved · IBBI Registered',
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
}
