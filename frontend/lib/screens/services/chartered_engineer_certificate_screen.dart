import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../features/landing/landing_theme.dart';
import '../../features/landing/widgets/commercial_intake_modal.dart';
import '../../services/analytics_service.dart';

/// Chartered Engineer Certificate in India — Commercial Practice Hub
/// Canonical URL: https://www.provaluer.in/chartered-engineer-certificate
class CharteredEngineerCertificateScreen extends StatefulWidget {
  const CharteredEngineerCertificateScreen({super.key});

  @override
  State<CharteredEngineerCertificateScreen> createState() => _CharteredEngineerCertificateScreenState();
}

class _CharteredEngineerCertificateScreenState extends State<CharteredEngineerCertificateScreen> {
  final ScrollController _scrollController = ScrollController();

  static const String _primaryPhone = '+918500880333';
  static const Color _pureWhite = Color(0xFFFFFFFF);
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _slateText = Color(0xFF475569);
  static const Color _obsidian = Color(0xFF0F172A);
  static const Color _borderSubtle = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    AnalyticsService.logServicePageOpen(
      serviceTitle: 'Chartered Engineer Certificate',
      route: '/chartered-engineer-certificate',
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchCall() async {
    AnalyticsService.logLeadCallClick(
      serviceType: 'CHARTERED_ENGINEER',
      phoneNumber: _primaryPhone,
    );
    final uri = Uri.parse('tel:$_primaryPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String message) async {
    AnalyticsService.logLeadWhatsAppClick(
      serviceType: 'CHARTERED_ENGINEER',
      target: 'https://wa.me/918500880333',
    );
    final uri = Uri.parse('https://wa.me/918500880333?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openIntakeModal() {
    AnalyticsService.logProposalRequestClick(
      source: 'chartered_engineer_screen',
      serviceType: 'CHARTERED_ENGINEER',
    );
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const CommercialIntakeModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1024;
    final bool isTablet = screenW >= 768 && screenW < 1024;

    return Scaffold(
      backgroundColor: _pureWhite,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : (isTablet ? 32 : 20),
                    vertical: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => context.go('/'),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: LandingTheme.primaryAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                  child: Text('PV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PRO VALUER', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: _obsidian, letterSpacing: -0.4)),
                                  Text('CHARTERED ENGINEERS & VALUERS', style: GoogleFonts.montserrat(fontSize: 9, fontWeight: FontWeight.w700, color: LandingTheme.primaryAccent, letterSpacing: 0.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/'),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text('Back to Home'),
                            style: TextButton.styleFrom(foregroundColor: _slateText),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _openIntakeModal,
                            icon: const Icon(Icons.request_quote_rounded, size: 16),
                            label: const Text('Request Certificate'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LandingTheme.primaryAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Banner
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  color: _lightBg,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : (isTablet ? 32 : 20),
                    vertical: isDesktop ? 60 : 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: LandingTheme.accentSubtle,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: LandingTheme.primaryAccent.withOpacity(0.3)),
                            ),
                            child: Text(
                              'STATUTORY CHARTERED ENGINEERING PRACTICE • THE INSTITUTION OF ENGINEERS (INDIA)',
                              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: LandingTheme.primaryAccent),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Chartered Engineer Certificate in Hyderabad & Across India',
                            style: GoogleFonts.montserrat(
                              fontSize: isDesktop ? 38 : (isTablet ? 28 : 24),
                              fontWeight: FontWeight.w800,
                              color: _obsidian,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Empanelled Chartered Engineers issuing court-admissible and customs-cleared technical certificates for EPCG Scheme closures, second-hand plant & machinery import, customs duty exemption, industrial structural stability, and visa financial solvency.',
                            style: GoogleFonts.inter(fontSize: isDesktop ? 16 : 14, color: _slateText, height: 1.6),
                          ),
                          const SizedBox(height: 28),
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _launchWhatsApp('Hello, I require a Chartered Engineer Certificate.'),
                                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 16, color: Colors.white),
                                label: const Text('WhatsApp Chartered Engineer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: _launchCall,
                                icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                                label: const Text('Call +91 85008 80333'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _obsidian,
                                  side: const BorderSide(color: _borderSubtle, width: 1.5),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Statutory Use Cases
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : (isTablet ? 32 : 20),
                    vertical: 60,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Primary Statutory Use Cases', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: _obsidian)),
                          const SizedBox(height: 8),
                          Text('Independent technical certification recognized by DGFT, Indian Customs, Banking Consortia, and International Consulates.', style: GoogleFonts.inter(fontSize: 14, color: _slateText)),
                          const SizedBox(height: 32),
                          GridView.count(
                            crossAxisCount: isDesktop ? 3 : (isTablet ? 2 : 1),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: isDesktop ? 1.4 : 1.6,
                            children: [
                              _buildFeatureCard(
                                icon: Icons.precision_manufacturing_rounded,
                                title: 'EPCG Scheme & Machinery Imports',
                                desc: 'Verification of capital goods installation, residual life, and market valuation for Directorate General of Foreign Trade (DGFT) export obligation compliance.',
                              ),
                              _buildFeatureCard(
                                icon: Icons.shield_rounded,
                                title: 'Factory Structural & Stability Audits',
                                desc: 'Statutory structural stability certificates mandated under the Factories Act for industrial sheds, chemical process units, and warehouse facilities.',
                              ),
                              _buildFeatureCard(
                                icon: Icons.flight_takeoff_rounded,
                                title: 'Visa Net Worth & Immovable Solvency',
                                desc: 'Chartered Engineer property valuation dossiers accepted by US, UK, Canada, Australia, and Schengen consulates for financial capability proof.',
                              ),
                              _buildFeatureCard(
                                icon: Icons.account_balance_rounded,
                                title: "Lender's Independent Engineer (LIE)",
                                desc: 'Milestone-based construction monitoring, technical drawdown sign-offs, and bill of quantities audits for commercial banking consortia.',
                              ),
                              _buildFeatureCard(
                                icon: Icons.verified_user_rounded,
                                title: 'Customs Duty & Circular Valuation',
                                desc: 'Valuation of imported second-hand machinery establishing depreciated replacement cost under Central Board of Indirect Taxes and Customs (CBIC).',
                              ),
                              _buildFeatureCard(
                                icon: Icons.handshake_rounded,
                                title: 'Insurance & Asset Capitalization',
                                desc: 'Remaining useful life (RUL) certifications and replacement cost schedules for company balance sheet audits and industrial insurance policies.',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Related Services Cross-Linking (Phase 4)
              SliverToBoxAdapter(
                child: Container(
                  color: _lightBg,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : (isTablet ? 32 : 20),
                    vertical: 48,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Related Valuation & Advisory Practices', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: _obsidian)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildRelatedChip(context, 'Plant & Machinery Valuation', '/services/plant-and-machinery-valuation'),
                              _buildRelatedChip(context, 'Bank Collateral Valuation', '/services/bank-collateral-valuation'),
                              _buildRelatedChip(context, 'Visa & Immigration Valuation', '/services/visa-and-immigration-valuations'),
                              _buildRelatedChip(context, 'Property Valuation in Hyderabad', '/services/property-valuation'),
                              _buildRelatedChip(context, 'Government Approved Valuers', '/government-approved-valuers'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderSubtle),
        boxShadow: const [BoxShadow(color: Color(0x080F172A), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: LandingTheme.accentSubtle, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: LandingTheme.primaryAccent, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: _obsidian)),
          const SizedBox(height: 8),
          Expanded(child: Text(desc, style: GoogleFonts.inter(fontSize: 12.5, color: _slateText, height: 1.5))),
        ],
      ),
    );
  }

  Widget _buildRelatedChip(BuildContext context, String title, String route) {
    return ActionChip(
      backgroundColor: _pureWhite,
      side: const BorderSide(color: _borderSubtle),
      avatar: const Icon(Icons.arrow_forward_rounded, size: 14, color: LandingTheme.primaryAccent),
      label: Text(title, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600, color: _obsidian)),
      onPressed: () {
        AnalyticsService.logServiceCardClick(serviceTitle: title, targetRoute: route, source: 'chartered_engineer_screen');
        context.go(route);
      },
    );
  }
}
