import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'landing_theme.dart';
import 'widgets/hero_video_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// APPLE VISION PRO / ARCHITECTURAL MONOCHROMATIC GLASS UTILITIES
// ═══════════════════════════════════════════════════════════════════════════════

/// Spatial Glass Panel with Apple Vision Pro physical glass properties:
/// - 45px backdrop blur
/// - Specular top edge highlight fading into subtle platinum refraction
/// - Layered ambient and contact shadows
/// - Physical crystal thickness feel
class VisionProGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? surfaceColor;
  final bool hasSpecularBorder;
  final List<BoxShadow>? customShadow;

  const VisionProGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 24,
    this.surfaceColor,
    this.hasSpecularBorder = true,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: customShadow ?? LandingTheme.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 45, sigmaY: 45),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: surfaceColor ?? LandingTheme.surfaceGlass,
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasSpecularBorder
                  ? Border.all(
                      color: const Color(0xF2FFFFFF),
                      width: 1.2,
                    )
                  : Border.all(
                      color: const Color(0x33CBD5E1),
                      width: 1.0,
                    ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small Glass Eyebrow Badge (Platinum / Pearl White)
class GlassEyebrowBadge extends StatelessWidget {
  final String label;
  final IconData? icon;

  const GlassEyebrowBadge({
    super.key,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: LandingTheme.pearlWhite,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xE2E8F0CC), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: LandingTheme.primaryAccent),
            const SizedBox(width: 7),
          ] else ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: LandingTheme.primaryAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: LandingTheme.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. FLOATING GLASS NAVIGATION BAR
// ═══════════════════════════════════════════════════════════════════════════════

class LandingHeader extends StatelessWidget {
  final bool isDesktop;
  final bool isScrolled;
  final Future<void> Function(String) launchWhatsApp;
  final VoidCallback? onMenuTap;

  const LandingHeader({
    super.key,
    required this.isDesktop,
    required this.isScrolled,
    required this.launchWhatsApp,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final double horizontalPadding = isDesktop ? 60 : 20;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isScrolled ? 12 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              boxShadow: isScrolled
                  ? const [
                      BoxShadow(
                        color: Color(0x0F0F172A),
                        blurRadius: 30,
                        offset: Offset(0, 10),
                      ),
                    ]
                  : const [
                      BoxShadow(
                        color: Color(0x080F172A),
                        blurRadius: 20,
                        offset: Offset(0, 4),
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
                    color: isScrolled
                        ? const Color(0xEBFFFFFF)
                        : const Color(0xC7FFFFFF),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: const Color(0xF2FFFFFF),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Brand Logo Monogram (Polished Obsidian & Platinum)
                      GestureDetector(
                        onTap: () => context.go('/'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: LandingTheme.platinumButtonGradient,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x200F172A),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'PV',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Pro Valuer',
                              style: GoogleFonts.plusJakartaSans(
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

                      // Desktop Navigation Items
                      if (isDesktop) ...[
                        _HeaderLink(label: 'Services', onTap: () => _scrollTo('services')),
                        const SizedBox(width: 28),
                        _HeaderLink(label: 'Why Pro Valuer', onTap: () => _scrollTo('why-pro-valuer')),
                        const SizedBox(width: 28),
                        _HeaderLink(label: 'Process', onTap: () => _scrollTo('process')),
                        const SizedBox(width: 28),
                        _HeaderLink(label: 'Case Studies', onTap: () => _scrollTo('case-studies')),
                        const SizedBox(width: 28),
                        _HeaderLink(label: 'Credentials', onTap: () => _scrollTo('credentials')),
                        const SizedBox(width: 32),

                        // Request Consultation Button (Obsidian & Platinum)
                        GestureDetector(
                          onTap: () => launchWhatsApp('Hello, I would like to request an institutional valuation consultation with Pro Valuer.'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              gradient: LandingTheme.platinumButtonGradient,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F0F172A),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Request Consultation',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Mobile Menu Icon
                        IconButton(
                          onPressed: onMenuTap,
                          icon: const Icon(Icons.menu_rounded, color: LandingTheme.textPrimary, size: 24),
                        ),
                      ],
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

  void _scrollTo(String id) {
    // Navigation anchor
  }
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeaderLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: LandingTheme.textSecondary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. HERO SECTION — FULL-WIDTH CINEMATIC VIDEO BACKGROUND (APPLE BUSINESS × STRIPE ENTERPRISE)
// ═══════════════════════════════════════════════════════════════════════════════

class HeroSection extends StatefulWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;

  const HeroSection({
    super.key,
    required this.isDesktop,
    required this.launchWhatsApp,
  });

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with TickerProviderStateMixin {
  // Ordered sequence of 8 institutional story videos
  static const List<String> _heroStoryVideos = [
    'assets/videos/hero_story/1.mp4',
    'assets/videos/hero_story/2.mp4',
    'assets/videos/hero_story/3.mp4',
    'assets/videos/hero_story/4.mp4',
    'assets/videos/hero_story/5.mp4',
    'assets/videos/hero_story/6.mp4',
    'assets/videos/hero_story/7.mp4',
    'assets/videos/hero_story/8.mp4',
  ];

  final List<String> _keywords = [
    'Institutional Assets',
    'Commercial Towers',
    'Industrial Facilities',
    'Infrastructure Portfolios',
    'Banking Collaterals',
    'Shopping Malls',
    'Net Worth Certificates',
  ];

  int _currentKeywordIndex = 0;

  // Keyword slide & fade animation
  late AnimationController _keywordAnimController;
  late Animation<double> _keywordSlideAnimation;
  late Animation<double> _keywordOpacityAnimation;
  Timer? _keywordTimer;

  // Video story cycle state
  int _currentVideoIndex = 0;
  bool _isVideoPlaying = false;
  bool _storyCompleted = false;

  // 500ms content fade controller (1.0 = reading mode, 0.0 = video mode)
  late AnimationController _contentFadeController;
  Timer? _storyTimer;

  @override
  void initState() {
    super.initState();

    // 1. Morphing keyword animator
    _keywordAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _keywordSlideAnimation = Tween<double>(begin: 18.0, end: 0.0).animate(
      CurvedAnimation(parent: _keywordAnimController, curve: Curves.easeOutCubic),
    );
    _keywordOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _keywordAnimController, curve: Curves.easeOut),
    );
    _keywordAnimController.forward();

    _keywordTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      _keywordAnimController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentKeywordIndex = (_currentKeywordIndex + 1) % _keywords.length;
        });
        _keywordAnimController.forward();
      });
    });

    // 2. Content fade controller (starts fully visible at 1.0)
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );

    // 3. Initial page load: Hero content shown normally for 3 seconds, then Video 1 starts
    _storyTimer = Timer(const Duration(seconds: 3), () {
      _startVideo(0);
    });
  }

  void _startVideo(int index) {
    if (!mounted || _storyCompleted) return;

    // Smoothly fade OUT all hero content (500ms):
    // Headline, rotating keywords, description, trust indicators, CTA buttons, and eyebrow badge
    _contentFadeController.reverse().then((_) {
      if (!mounted || _storyCompleted) return;
      // After fade completes: content is completely invisible (opacity 0.0).
      // Now activate video playback so user ONLY sees full-width video + dark overlay!
      setState(() {
        _currentVideoIndex = index;
        _isVideoPlaying = true;
      });
    });
  }

  void _onVideoCompleted(int completedIndex) {
    if (!mounted) return;

    // Immediately stop video playback
    setState(() {
      _isVideoPlaying = false;
    });

    // Smoothly fade IN all hero content (500ms)
    _contentFadeController.forward();

    // If Video 8 has finished, sequence finishes permanently
    if (completedIndex >= _heroStoryVideos.length - 1) {
      _storyCompleted = true;
      return;
    }

    // 10-second reading window where content is fully visible and interactive,
    // and NO video is playing.
    _storyTimer?.cancel();
    _storyTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _storyCompleted) return;
      _startVideo(completedIndex + 1);
    });
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _keywordTimer?.cancel();
    _keywordAnimController.dispose();
    _contentFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1024;
    final bool isTablet = screenW >= 768 && screenW < 1024;

    // Viewport-aware sizing: Fit inside browser viewport without scrolling
    // Top clearance above Hero is 80px (SizedBox(height: 80) in landing_page.dart).
    final double heroHeight = isDesktop
        ? (screenH - 80).clamp(420.0, 820.0)
        : isTablet
            ? (screenH - 80).clamp(480.0, 750.0)
            : (screenH * 0.82).clamp(480.0, 700.0);

    final bool isCompactLaptop = isDesktop && (screenH < 850 || screenW < 1440);

    return ClipRect(
      child: Container(
        width: double.infinity,
        height: isDesktop ? heroHeight : null,
        constraints: BoxConstraints(minHeight: heroHeight),
        decoration: const BoxDecoration(
          color: Colors.white,
          gradient: RadialGradient(
            center: Alignment(0.6, -0.4),
            radius: 1.2,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── LAYER 1: Full-Width Cinematic Video Background (SHARP & UNBLURRED) ──
            // ONLY rendered/visible during Video Mode. In Reading Mode, the video layer is
            // completely hidden so ZERO frozen frame, paused image, or static poster frame remains!
            if (!_storyCompleted)
              Positioned.fill(
                child: Visibility(
                  visible: _isVideoPlaying,
                  maintainState: true,
                  child: HeroVideoWidget(
                    videoAssets: _heroStoryVideos,
                    activeVideoIndex: _currentVideoIndex,
                    isPlaying: _isVideoPlaying,
                    onVideoCompleted: _onVideoCompleted,
                  ),
                ),
              ),

            // ── LAYER 2: Existing Dark Horizontal Gradient Overlay ───────────────────
            // ONLY present during Video Mode for cinematic contrast
            if (_isVideoPlaying)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isDesktop ? Alignment.centerLeft : Alignment.topCenter,
                      end: isDesktop ? Alignment.centerRight : Alignment.bottomCenter,
                      stops: const [0.0, 0.50, 1.0],
                      colors: const [
                        Color.fromRGBO(8, 14, 26, 0.82), // Left (or Top on mobile): 82%
                        Color.fromRGBO(8, 14, 26, 0.55), // Center: 55%
                        Color.fromRGBO(8, 14, 26, 0.20), // Right (or Bottom on mobile): 20%
                      ],
                    ),
                  ),
                ),
              ),

            // ── LAYER 3: Foreground Hero Content (Headline, Keyword, Description, CTAs, Trust) ──
            // Fades OUT completely during video playback (Opacity 1.0 -> 0.0 over 500ms)
            // Fades IN completely during reading window (Opacity 0.0 -> 1.0 over 500ms)
            FadeTransition(
              opacity: _contentFadeController,
              child: IgnorePointer(
                ignoring: _isVideoPlaying,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 24,
                    vertical: isDesktop ? (isCompactLaptop ? 16 : 24) : 20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1320),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildForegroundContent(screenW, screenH, isDesktop, isTablet),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForegroundContent(double screenW, double screenH, bool isDesktop, bool isTablet) {
    // Viewport-aware typography & spacing to guarantee zero scrolling on laptops (1366x768, 1440x900, 1536x864)
    final bool isCompactLaptop = isDesktop && (screenH < 850 || screenW < 1440);

    final double headlineSize = isCompactLaptop
        ? 44.0
        : (isDesktop ? 56.0 : (isTablet ? 38.0 : 32.0));

    final double keywordSize = isCompactLaptop
        ? 44.0
        : (isDesktop ? 56.0 : (isTablet ? 38.0 : 32.0));

    final double bodySize = isCompactLaptop
        ? 15.0
        : (isDesktop ? 17.5 : 14.5);

    final double badgeGap = isCompactLaptop ? 10.0 : 16.0;
    final double keywordGap = isCompactLaptop ? 4.0 : 6.0;
    final double descGap = isCompactLaptop ? 12.0 : 18.0;
    final double trustGap = isCompactLaptop ? 14.0 : 20.0;
    final double ctaGap = isCompactLaptop ? 18.0 : 26.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Eyebrow Badge (Pearl White Glass Pill)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompactLaptop ? 14 : 16,
            vertical: isCompactLaptop ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: LandingTheme.pearlWhite,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: const Color(0xE2E8F0CC), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_rounded, size: 14, color: LandingTheme.primaryAccent),
              const SizedBox(width: 8),
              Text(
                'IBBI REGISTERED VALUERS • ASSET INTELLIGENCE',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isCompactLaptop ? 11.0 : 11.5,
                  fontWeight: FontWeight.w700,
                  color: LandingTheme.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: badgeGap),

        // Hero Headline (High-Contrast Obsidian Charcoal Slate)
        Text(
          'Independent Valuation\nFor',
          style: GoogleFonts.plusJakartaSans(
            fontSize: headlineSize,
            fontWeight: FontWeight.w800,
            color: LandingTheme.textPrimary,
            letterSpacing: -1.8,
            height: 1.08,
          ),
        ),

        SizedBox(height: keywordGap),

        // Rotating Morphing Keyword (Platinum Obsidian Gradient)
        AnimatedBuilder(
          animation: _keywordAnimController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _keywordSlideAnimation.value),
              child: Opacity(
                opacity: _keywordOpacityAnimation.value,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return LandingTheme.textPlatinumGradient.createShader(bounds);
                  },
                  child: Text(
                    _keywords[_currentKeywordIndex],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: keywordSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white, // Masked with dark platinum gradient
                      letterSpacing: -1.8,
                      height: 1.08,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: descGap),

        // Description (Soft Architectural Graphite)
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompactLaptop ? 560 : 620),
          child: Text(
            'Independent statutory valuation and asset intelligence for leading banks, NBFCs, private equity funds, insolvency professionals, and public corporations.',
            style: GoogleFonts.inter(
              fontSize: bodySize,
              fontWeight: FontWeight.w400,
              color: LandingTheme.textSecondary,
              letterSpacing: -0.2,
              height: 1.55,
            ),
          ),
        ),

        SizedBox(height: trustGap),

        // Trust Indicators (Light Ambient Pills)
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _buildTrustBadge(Icons.verified_user_outlined, 'IBBI / Sec 247 Compliant', isCompactLaptop),
            _buildTrustBadge(Icons.account_balance_outlined, '₹15,000+ Cr Valued', isCompactLaptop),
            _buildTrustBadge(Icons.assured_workload_outlined, 'Bank Empanelled', isCompactLaptop),
          ],
        ),

        SizedBox(height: ctaGap),

        // CTA Buttons (Always Visible during Reading Mode & Immediately Clickable)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            // Primary CTA: Request Consultation (Obsidian Platinum Gradient)
            GestureDetector(
              onTap: () => widget.launchWhatsApp('Hello, I would like to request an institutional valuation consultation with Pro Valuer.'),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactLaptop ? 22 : 28,
                  vertical: isCompactLaptop ? 13 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: LandingTheme.platinumButtonGradient,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240F172A),
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Request Consultation',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompactLaptop ? 13.5 : 14.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
                  ],
                ),
              ),
            ),

            // Secondary CTA: Client Login (Midnight Navy Pill)
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactLaptop ? 20 : 24,
                  vertical: isCompactLaptop ? 13 : 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Midnight Navy
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0x33334155), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 15, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Client Login',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompactLaptop ? 13.5 : 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tertiary CTA: View Sample Report (Pearl White Pill)
            GestureDetector(
              onTap: () => widget.launchWhatsApp('Hello, please provide the sample institutional valuation report.'),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactLaptop ? 18 : 22,
                  vertical: isCompactLaptop ? 13 : 16,
                ),
                decoration: BoxDecoration(
                  color: LandingTheme.pearlWhite,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: const Color(0xE2E8F0CC), width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sample Report',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: isCompactLaptop ? 13.0 : 14.0,
                        fontWeight: FontWeight.w600,
                        color: LandingTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_outward_rounded, size: 14, color: LandingTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 11 : 14,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 13 : 14, color: LandingTheme.primaryAccent),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: isCompact ? 11.5 : 12.5,
              fontWeight: FontWeight.w600,
              color: LandingTheme.textPrimary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. SERVICES SECTION — 6 LUXURY MONOCHROMATIC ARCHITECTURAL CARDS
// ═══════════════════════════════════════════════════════════════════════════════

class ServicesSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final Future<void> Function(String) launchWhatsApp;

  const ServicesSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
    required this.launchWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final services = [
      {
        'title': 'Land & Real Estate Valuation',
        'desc': 'Valuation of commercial office towers, Grade-A IT parks, retail centers, residential townships, and master-planned land parcels under statutory DCF and yield capitalization models.',
        'icon': Icons.apartment_rounded,
      },
      {
        'title': 'Industrial & Manufacturing Plants',
        'desc': 'Depreciated Replacement Cost (DRC) and income-based appraisals for specialized manufacturing facilities, fabrication plants, warehousing logistics hubs, and heavy engineering yards.',
        'icon': Icons.factory_rounded,
      },
      {
        'title': 'Plant, Machinery & Equipment',
        'desc': 'Independent technical audits and Remaining Useful Life (RUL) assessments conducted by Chartered Engineers for capital asset verification, customs duty exemptions, and lending security.',
        'icon': Icons.precision_manufacturing_rounded,
      },
      {
        'title': 'Infrastructure & Concession Assets',
        'desc': 'Economic and technical appraisal of public-private partnership (PPP) infrastructure, maritime port berths, toll highway concessions, transmission grids, and renewable solar installations.',
        'icon': Icons.alt_route_rounded,
      },
      {
        'title': 'Insolvency & CIRP Statutory Reports',
        'desc': 'Section 247 registered appraisals under the Insolvency and Bankruptcy Code 2016 for Resolution Professionals, Liquidators, and Committee of Creditors with full NCLT defense.',
        'icon': Icons.gavel_rounded,
      },
      {
        'title': 'Net Worth & Statutory Certification',
        'desc': 'Comprehensive individual and corporate net worth documentation, financial standing certifications, and Chartered Engineer certificates for visa authorities, courts, and banks.',
        'icon': Icons.verified_user_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const GlassEyebrowBadge(label: 'Services', icon: Icons.auto_awesome_rounded),
              const SizedBox(height: 20),
              Text(
                'Institutional Asset Advisory',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  'Independent valuation methodologies executed under statutory regulations across all major asset categories.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 60),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 24;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: services.map((s) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisionProGlassPanel(
                          padding: const EdgeInsets.all(32),
                          borderRadius: 22,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: LandingTheme.accentSubtle,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: LandingTheme.platinumHighlight, width: 1),
                                ),
                                child: Icon(
                                  s['icon'] as IconData,
                                  color: LandingTheme.primaryAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                s['title'] as String,
                                style: LandingTheme.cardTitle,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                s['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: () => launchWhatsApp('Hello, I am interested in ${s['title']}.'),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Learn more',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: LandingTheme.primaryAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_rounded, size: 13, color: LandingTheme.primaryAccent),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 4. WHY PRO VALUER — 4 PILLARS OF AUTHORITY
// ═══════════════════════════════════════════════════════════════════════════════

class WhyProValuerSection extends StatelessWidget {
  final bool isDesktop;

  const WhyProValuerSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final pillars = [
      {
        'title': 'IBBI Registration',
        'sub': 'STATUTORY CREDENTIALS',
        'desc': 'Licensed under Section 247 of the Companies Act 2013 across Land & Building, Plant & Machinery, and Securities & Financial Assets.',
        'icon': Icons.verified_rounded,
      },
      {
        'title': 'Chartered Engineering',
        'sub': 'TECHNICAL RIGOR',
        'desc': 'Physical audits conducted by Corporate Members of The Institution of Engineers (India), ensuring verified ground truth.',
        'icon': Icons.engineering_rounded,
      },
      {
        'title': 'Independent Assessment',
        'sub': 'OBJECTIVE BENCHMARKS',
        'desc': 'Unbiased multi-model appraisals free from volume, borrower, or developer pressures, defending your credit decisions.',
        'icon': Icons.balance_rounded,
      },
      {
        'title': 'Audit-Ready Documentation',
        'sub': 'REGULATORY DEFENSE',
        'desc': 'Evidentiary dossiers cross-referenced with sub-registrar transaction data, designed to withstand credit committee and auditor scrutiny.',
        'icon': Icons.fact_check_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const GlassEyebrowBadge(label: 'Why Pro Valuer', icon: Icons.shield_rounded),
              const SizedBox(height: 20),
              Text(
                'Engineered for Absolute Credibility',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Text(
                  'Delivering the rigor required by credit committees, statutory auditors, and regulatory bodies.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 60),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 20;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: pillars.map((p) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisionProGlassPanel(
                          padding: const EdgeInsets.all(28),
                          borderRadius: 20,
                          surfaceColor: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: LandingTheme.accentSubtle,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  p['icon'] as IconData,
                                  color: LandingTheme.primaryAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                p['sub'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.primaryAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. PROCESS SECTION — 4-STAGE CRYSTAL WORKFLOW
// ═══════════════════════════════════════════════════════════════════════════════

class ProcessSection extends StatelessWidget {
  final bool isDesktop;

  const ProcessSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final steps = [
      {
        'step': '01',
        'title': 'Physical Inspection',
        'desc': 'On-site technical inspection by Chartered Engineers, verifying physical asset condition, boundaries, and municipal alignment.',
      },
      {
        'step': '02',
        'title': 'Analytical Modeling',
        'desc': 'Data extraction from title documents, registry records, micro-market transactions, and statutory zoning master plans.',
      },
      {
        'step': '03',
        'title': 'Independent Valuation',
        'desc': 'Multi-model valuation executing DCF yield analysis, depreciated replacement cost (DRC), and forced liquidation stress tests.',
      },
      {
        'step': '04',
        'title': 'Certified Delivery',
        'desc': 'Mandatory partner-level dual sign-off, IBBI digital signature, and tamper-evident digital dossier delivery.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const GlassEyebrowBadge(label: 'Process', icon: Icons.sync_rounded),
              const SizedBox(height: 20),
              Text(
                'The Institutional Workflow',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(
                  'A structured 4-stage methodology ensuring defensible deliverables for every engagement.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 60),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 20;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: steps.map((s) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisionProGlassPanel(
                          padding: const EdgeInsets.all(28),
                          borderRadius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['step']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: LandingTheme.primaryAccent,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s['desc']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.55,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 6. CASE STUDIES — MINIMAL OUTCOME-FOCUSED GLASS CARDS
// ═══════════════════════════════════════════════════════════════════════════════

class CaseStudiesSection extends StatelessWidget {
  final bool isDesktop;

  const CaseStudiesSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final studies = [
      {
        'tag': 'INFRASTRUCTURE & LOGISTICS',
        'title': 'Maritime Bulk Port & Container Terminal',
        'client': 'National Lending Consortium (7 Banks)',
        'challenge': 'Specialized waterfront rights, marine structures, and high-capital machinery requiring credit appraisal under stringent covenant timelines.',
        'outcome': 'Consortium credit committee sanction achieved with zero audit observations; report cleared independent scrutiny without caveat.',
      },
      {
        'tag': 'COMMERCIAL REAL ESTATE',
        'title': 'Grade-A Commercial IT Park Portfolio',
        'client': 'Global Private Equity & REIT Ingestion',
        'challenge': 'Multi-tenant commercial assets with complex lease escalations, vacancy underwriting, and institutional fair value certification.',
        'outcome': 'Fair value certified in compliance with Ind AS 16 & 36; successfully accepted by statutory Big 4 auditors and trustees.',
      },
      {
        'tag': 'INSOLVENCY & STRESSED ASSETS',
        'title': 'Integrated Steel & Manufacturing Complex',
        'client': 'Resolution Professional & Committee of Creditors',
        'challenge': 'Stressed heavy manufacturing complex requiring independent liquidation value and fair value under IBC 2016 regulations.',
        'outcome': 'Valuation defended before NCLT benches; resolution plan successfully approved by COC voting majority.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const GlassEyebrowBadge(label: 'Case Studies', icon: Icons.insights_rounded),
              const SizedBox(height: 20),
              Text(
                'Selected Engagements',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(
                  'Institutional advisory outcomes delivering clarity for complex asset decisions.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 60),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : 1;
                  const double spacing = 24;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: studies.map((cs) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisionProGlassPanel(
                          padding: const EdgeInsets.all(32),
                          borderRadius: 22,
                          surfaceColor: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cs['tag']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.primaryAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                cs['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cs['client']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: LandingTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Divider(height: 1, color: Color(0x29CBD5E1)),
                              const SizedBox(height: 18),
                              Text(
                                'Challenge',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cs['challenge']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Outcome',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.primaryAccent,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cs['outcome']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. CREDENTIALS SECTION — CLEAN MONOCHROME & PLATINUM BADGES
// ═══════════════════════════════════════════════════════════════════════════════

class CredentialsSection extends StatelessWidget {
  final bool isDesktop;

  const CredentialsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final credentials = [
      {
        'title': 'IBBI Registered Valuers',
        'sub': 'Insolvency and Bankruptcy Board of India',
        'desc': 'Statutory authority under Section 247 of Companies Act 2013.',
      },
      {
        'title': 'Chartered Engineers (IEI)',
        'sub': 'The Institution of Engineers (India)',
        'desc': 'Corporate Members executing verified physical engineering audits.',
      },
      {
        'title': 'Banking Consortia Aligned',
        'sub': 'Public & Private Sector Banks',
        'desc': 'Empanelled and accepted by leading national lending institutions.',
      },
      {
        'title': 'NCLT & Judicial Defense',
        'sub': 'Insolvency & Debt Recovery Tribunals',
        'desc': 'Defensible expert witness and statutory dispute valuation testimony.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const GlassEyebrowBadge(label: 'Credentials', icon: Icons.verified_user_rounded),
              const SizedBox(height: 20),
              Text(
                'Statutory Licensure & Recognition',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: Text(
                  'Qualified professionals recognized across judicial, banking, and regulatory authorities.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 50),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 20;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: credentials.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: VisionProGlassPanel(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: LandingTheme.primaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      c['title']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: LandingTheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c['sub']!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: LandingTheme.primaryAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c['desc']!,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 8. FINAL CONSULTATION SECTION — LUXURY GLASS CTA
// ═══════════════════════════════════════════════════════════════════════════════

class CtaBanner extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;

  const CtaBanner({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1024;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 90 : 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: VisionProGlassPanel(
            borderRadius: 32,
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 64 : 28,
              vertical: isDesktop ? 70 : 44,
            ),
            surfaceColor: Colors.white,
            customShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
            child: Column(
              children: [
                const GlassEyebrowBadge(label: 'Get In Touch', icon: Icons.mail_outline_rounded),
                const SizedBox(height: 24),
                Text(
                  'Ready for a Valuation Report That\nWithstands Every Level of Scrutiny?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 40 : 26,
                    fontWeight: FontWeight.w800,
                    color: LandingTheme.textPrimary,
                    letterSpacing: -1.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Text(
                    'Connect directly with our senior valuation partners for confidential institutional advisory and statutory documentation.',
                    textAlign: TextAlign.center,
                    style: LandingTheme.bodyMediumResponsive(screenW),
                  ),
                ),
                const SizedBox(height: 36),

                Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => launchWhatsApp('Hello, I would like to schedule a valuation consultation with Pro Valuer.'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LandingTheme.platinumButtonGradient,
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x280F172A),
                              blurRadius: 20,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Request Consultation',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => launchWhatsApp('Hello, please share your firm credentials and sample reports.'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          color: LandingTheme.pearlWhite,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xE2E8F0CC), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Sample Report',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: LandingTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_outward_rounded, size: 15, color: LandingTheme.textSecondary),
                          ],
                        ),
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. LUXURY MINIMAL FOOTER
// ═══════════════════════════════════════════════════════════════════════════════

class LandingFooter extends StatelessWidget {
  final bool isDesktop;

  const LandingFooter({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              const Divider(height: 1, color: Color(0x29CBD5E1)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: LandingTheme.platinumButtonGradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Center(
                          child: Text(
                            'PV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Pro Valuer',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: LandingTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '© ${DateTime.now().year} Pro Valuer. All rights reserved. IBBI Registered Valuers.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: LandingTheme.textMuted,
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
}

// ═══════════════════════════════════════════════════════════════════════════════
// 10. MOBILE MENU DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

class MobileMenuDrawer extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;

  const MobileMenuDrawer({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pro Valuer',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: LandingTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: LandingTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _mobileLink(context, 'Services'),
              _mobileLink(context, 'Why Pro Valuer'),
              _mobileLink(context, 'Process'),
              _mobileLink(context, 'Case Studies'),
              _mobileLink(context, 'Credentials'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    launchWhatsApp('Hello, I would like to request an institutional valuation consultation with Pro Valuer.');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LandingTheme.platinumButtonGradient,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(
                        'Request Consultation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileLink(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: LandingTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
