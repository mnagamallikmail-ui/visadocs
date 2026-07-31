import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';
import '../features/landing/boomerang_hero_background.dart';
import '../features/landing/landing_sections.dart';

/// LandingPage — Boomerang Landing Page
///
/// The primary marketing landing page for ProValuer Commercial.
/// Features a full-viewport hero section with an animated "boomerang"
/// (ping-pong) canvas background, a scroll-aware transparent→solid header,
/// and content sections below with entrance animations.
///
/// All original content is preserved: services, trust bar, who-we-serve,
/// consultation WhatsApp links, footer, and login navigation.
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
    // Toggle header style after scrolling past 80px (roughly 1 header height)
    final scrolled = _scrollController.offset > 80;
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
    final heroHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.canvas,
      // Mobile navigation drawer — only on non-desktop
      endDrawer:
          isDesktop ? null : MobileMenuDrawer(launchWhatsApp: _launchWhatsApp),
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                // Hero: full viewport with boomerang background
                SizedBox(
                  height: heroHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Layer 1: Animated boomerang canvas
                      const BoomerangHeroBackground(),
                      // Layer 2: Dark scrim + bottom fade to canvas
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x33000000), // 20% black
                              Color(0x59000000), // 35% black
                              AppColors.canvas, // fade to page canvas
                            ],
                            stops: [0.0, 0.75, 1.0],
                          ),
                        ),
                      ),
                      // Layer 3: Hero text + consultation card
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 72),
                          child: HeroOverlayContent(
                            isDesktop: isDesktop,
                            launchWhatsApp: _launchWhatsApp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Sections below the hero
                const TrustBar(),
                ServicesGrid(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  launchWhatsApp: _launchWhatsApp,
                ),
                WhoWeServeSection(isDesktop: isDesktop),
                StatsSection(isDesktop: isDesktop),
                CtaBanner(launchWhatsApp: _launchWhatsApp),
                LandingFooter(isDesktop: isDesktop),
              ],
            ),
          ),
          // ── Fixed header (floating over scrollable content) ─────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LandingHeader(
              isDesktop: isDesktop,
              isTransparent: !_isScrolled,
              launchWhatsApp: _launchWhatsApp,
              onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }
}
