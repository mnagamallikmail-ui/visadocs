import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../features/landing/landing_theme.dart';
import '../features/landing/landing_sections.dart';
import '../services/analytics_service.dart';

/// LandingPage — Apple Vision Pro Luxury Modern Redesign
/// Pure white background, liquid crystal glassmorphism, 50/50 hero layout,
/// massive whitespace, and minimal editorial sections.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _isScrolledNotifier = ValueNotifier<bool>(false);

  static const String _waUrl = "https://wa.me/918500880333";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 40;
    if (scrolled != _isScrolledNotifier.value) {
      _isScrolledNotifier.value = scrolled;
    }
  }

  Future<void> _launchWhatsApp(String message) async {
    final target = "$_waUrl?text=${Uri.encodeComponent(message)}";
    AnalyticsService.logWhatsAppClicked(
      whatsappTarget: target,
      serviceType: 'LANDING_PAGE',
      pageUrl: Uri.base.toString(),
    );
    final url = Uri.parse(target);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isScrolledNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = LandingTheme.isDesktop(context);
    final isTablet = LandingTheme.isTablet(context);

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
                const SizedBox(height: 16), // Minimized clearance for floating header (elevating Hero higher above fold)
                // 1. Hero Section (Balanced Layout with Fluid Viewport Sizing)
                HeroSection(
                  isDesktop: isDesktop,
                  launchWhatsApp: _launchWhatsApp,
                ),
                // 2. Authority Metrics — Verified Track Record (₹ Valued, Assignments, Years, Cities)
                //    Immediately below hero to anchor social proof before service listings.
                //    DEPLOYMENT NOTE: Confirm all metric values before going live.
                AuthorityMetricsSection(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                // 3. Services Section (6 Luxury Glass Cards)
                ServicesSection(
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                  launchWhatsApp: _launchWhatsApp,
                ),
                // 4. Why Pro Valuer (4 Spatial Glass Pillars)
                WhyProValuerSection(isDesktop: isDesktop),
                // 5. Process (4-Stage Crystal Flow)
                ProcessSection(isDesktop: isDesktop),
                // 6. Credentials (Licensure & Bank Recognition)
                CredentialsSection(isDesktop: isDesktop),
                // 7. Final Consultation Section (Luxury Glass CTA)
                CtaBanner(launchWhatsApp: _launchWhatsApp),
                // 8. Luxury Minimal Footer
                LandingFooter(isDesktop: isDesktop),
              ],
            ),
          ),
          // ── Fixed Floating Glass Navbar ───────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isScrolledNotifier,
              builder: (context, isScrolled, _) {
                return LandingHeader(
                  isDesktop: isDesktop,
                  isScrolled: isScrolled,
                  launchWhatsApp: _launchWhatsApp,
                  onMenuTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                );
              },
            ),
          ),
          // ── Persistent Sticky Floating Action Button ──────────────────────
          Positioned(
            bottom: 32,
            right: 32,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  AnalyticsService.logWhatsAppClicked(
                    whatsappTarget: 'https://wa.me/918500019091',
                    serviceType: 'STICKY_FAB',
                    pageUrl: Uri.base.toString(),
                  );
                  final uri = Uri.parse('https://wa.me/918500019091');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366), // Standard WhatsApp Green
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
