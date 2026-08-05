import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../features/landing/landing_sections.dart';

/// LandingPage — Clay Enterprise PropTech redesign
///
/// Warm cream editorial layout with scroll-aware header.
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
    final isDesktop = w >= 1024;
    final isTablet = w >= 768 && w < 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvas,
      endDrawer: isDesktop ? null : MobileMenuDrawer(launchWhatsApp: _launchWhatsApp),
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero — editorial cream layout (no dark background)
                HeroSection(
                  isDesktop: isDesktop,
                  launchWhatsApp: _launchWhatsApp,
                ),
                const TrustBar(),
                ServicesGrid(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  launchWhatsApp: _launchWhatsApp,
                ),
                WhyChooseUsSection(isDesktop: isDesktop),
                ValuationWorkflowSection(isDesktop: isDesktop),
                WhoWeServeSection(isDesktop: isDesktop),
                StatsSection(isDesktop: isDesktop),
                TestimonialsSection(isDesktop: isDesktop),
                FaqSection(isDesktop: isDesktop),
                CtaBanner(launchWhatsApp: _launchWhatsApp),
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
