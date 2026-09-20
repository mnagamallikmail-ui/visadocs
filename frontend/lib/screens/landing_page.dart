import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/landing/landing_theme.dart';
import '../features/landing/landing_sections.dart';

/// LandingPage — Luxury Enterprise SaaS Redesign
/// Pure white & soft white glassmorphism aesthetic with scroll-aware floating header.
/// Business logic preserved: WhatsApp URL, scroll detection, mobile drawer.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isScrolled = false;

  static const String _waUrl = "https://wa.me/918500880333";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 60;
    if (scrolled != _isScrolled) setState(() => _isScrolled = scrolled);
  }

  Future<void> _launchWhatsApp(String message) async {
    final url = Uri.parse("$_waUrl?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 1200;
    final isTablet = w >= 768 && w < 1200;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: LandingTheme.primaryBg,
      endDrawer: isDesktop ? null : MobileMenuDrawer(launchWhatsApp: _launchWhatsApp),
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // 1. Hero Section with Palantir asset intelligence visual & dual CTAs
                HeroSection(
                  isDesktop: isDesktop,
                  launchWhatsApp: _launchWhatsApp,
                ),
                // 2. Prominent Trust Layer — Why Financial Institutions Work With Pro Valuer
                WhyFinancialInstitutionsWorkWithProValuerSection(isDesktop: isDesktop),
                // 3. Trust Bar — Regulatory Standards & Institutional Lending Framework
                const TrustBar(),
                // 4. Executive Authority Section — Institutional Expertise Backed By Qualified Professionals
                ExecutiveAuthoritySection(isDesktop: isDesktop),
                // 5. 8 Institutional Service Cards
                ServicesSection(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  launchWhatsApp: _launchWhatsApp,
                ),
                // 4. Ecosystem Coverage — 10 Institutional Sectors
                IndustriesSection(isDesktop: isDesktop),
                // 5. Institutional Advantage Matrix (Pro Valuer vs Traditional)
                WhyProValuerSection(isDesktop: isDesktop),
                // 5B. Why Reports Get Accepted (Dedicated Institutional Scrutiny Section)
                WhyReportsGetAcceptedSection(isDesktop: isDesktop),
                // 6. Interactive Institutional Valuation Workflow (6 Stages)
                ProcessSection(isDesktop: isDesktop),
                // 7. ₹100+ Crore Case Studies Showcase
                CaseStudiesSection(isDesktop: isDesktop),
                // 8. C-Suite & Risk Committee Endorsements
                TestimonialsSection(isDesktop: isDesktop),
                // 9. Statutory Licensure & Empanelments
                EmpanelmentsSection(isDesktop: isDesktop),
                // 10. Final Institutional CTA Banner
                CtaBanner(launchWhatsApp: _launchWhatsApp),
                // 11. Executive Dark Navy Footer
                LandingFooter(isDesktop: isDesktop),
              ],
            ),
          ),
          // ── Fixed sticky header ─────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LandingHeader(
              isDesktop: isDesktop,
              isScrolled: _isScrolled,
              launchWhatsApp: _launchWhatsApp,
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}
