import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'landing_theme.dart';
import 'widgets/hero_video_widget.dart';
import 'widgets/commercial_intake_modal.dart';

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
            style: GoogleFonts.montserrat(
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
                                color: LandingTheme.brandGreen,
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
                              style: GoogleFonts.montserrat(
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
                        _HeaderLink(label: 'Credentials', onTap: () => _scrollTo('credentials')),
                        const SizedBox(width: 24),

                        // Compact Client Login Icon Button (Secondary Action)
                        const _HeaderClientLoginButton(),
                        const SizedBox(width: 10),

                        // Request Valuation Report Button (Obsidian & Platinum)
                        GestureDetector(
                          onTap: () => CommercialIntakeModal.show(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                            decoration: BoxDecoration(
                              color: LandingTheme.brandGreen,
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: LandingTheme.brandGreen.withValues(alpha: 0.18),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Request Valuation Report',
                                  style: GoogleFonts.montserrat(
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

/// Compact Client Login Button for Header (Secondary Action with Blue Hover)
class _HeaderClientLoginButton extends StatefulWidget {
  const _HeaderClientLoginButton();

  @override
  State<_HeaderClientLoginButton> createState() => _HeaderClientLoginButtonState();
}

class _HeaderClientLoginButtonState extends State<_HeaderClientLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0x0F2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: _isHovered ? const Color(0xFF2563EB) : const Color(0x33CBD5E1),
              width: 1.1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: _isHovered ? const Color(0xFF2563EB) : LandingTheme.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'Client Login',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isHovered ? const Color(0xFF2563EB) : LandingTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
        style: GoogleFonts.montserrat(
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
  // Ordered sequence of 7 institutional story videos (Video 6 excluded)
  static const List<String> _heroStoryVideos = [
    'assets/videos/hero_story/1.mp4',
    'assets/videos/hero_story/2.mp4',
    'assets/videos/hero_story/3.mp4',
    'assets/videos/hero_story/4.mp4',
    'assets/videos/hero_story/5.mp4',
    'assets/videos/hero_story/7.mp4',
    'assets/videos/hero_story/8.mp4',
  ];

  // Institutional Mandate keywords — pairs dynamically with 'Independent Valuation'
  // Answers WHAT high-stakes assets & proceedings ProValuer delivers across its practice areas.
  final List<String> _keywords = [
    'Banking Collaterals',
    'Infrastructure Portfolios',
    'Industrial Assets',
    'Plant & Machinery',
    'NCLT & IBC Matters',
    'Distressed Assets',
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

  int? _pendingNextVideoIndex = 0;
  Timer? _readingCountdownTimer;

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

    // 2. Initial page load: Page starts in Reading Mode with Valuation Expertise deck building.
    // Reading timer begins ONLY after Card 8 has fully settled (_onDeckSettled callback).
  }

  void _onDeckSettled() {
    if (!mounted || _storyCompleted || _isVideoPlaying) return;
    if (_pendingNextVideoIndex == null) return;

    // Requirement 5: Reading timer begins ONLY AFTER Card 8 has fully settled
    _readingCountdownTimer?.cancel();
    _readingCountdownTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted || _storyCompleted || _isVideoPlaying) return;
      final nextIndex = _pendingNextVideoIndex;
      _pendingNextVideoIndex = null;
      if (nextIndex != null && nextIndex < _heroStoryVideos.length) {
        _startVideo(nextIndex);
      }
    });
  }

  void _startVideo(int index) {
    if (!mounted || _storyCompleted) return;
    _readingCountdownTimer?.cancel();
    setState(() {
      _currentVideoIndex = index;
      _isVideoPlaying = true;
    });
  }

  void _onVideoCompleted(int completedIndex) {
    if (!mounted) return;

    _readingCountdownTimer?.cancel();

    // Immediately stop video playback
    setState(() {
      _isVideoPlaying = false;
    });

    // If final video in story has finished:
    if (completedIndex >= _heroStoryVideos.length - 1) {
      setState(() {
        _storyCompleted = true;
        _pendingNextVideoIndex = null;
      });
      return;
    }

    // Next video will be queued; reading timer triggers once the deck settles
    _pendingNextVideoIndex = completedIndex + 1;
  }

  @override
  void dispose() {
    _readingCountdownTimer?.cancel();
    _keywordTimer?.cancel();
    _keywordAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = screenW >= 1024;
    final bool isTablet = screenW >= 768 && screenW < 1024;

    // Viewport-aware sizing: Fit inside browser viewport without scrolling
    final double heroHeight = isDesktop
        ? (screenH - 16).clamp(420.0, 820.0)
        : isTablet
            ? (screenH - 16).clamp(480.0, 750.0)
            : (screenH * 0.82).clamp(480.0, 700.0);

    final bool isCompactLaptop = isDesktop && (screenH < 850 || screenW < 1440);

    return ClipRect(
      child: Container(
        width: double.infinity,
        height: isDesktop ? heroHeight : null,
        constraints: isDesktop ? BoxConstraints(minHeight: heroHeight) : null,
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
        child: Padding(
          padding: EdgeInsets.only(
            left: isDesktop ? 60 : (screenW < 360 ? 14 : (screenW < 400 ? 18 : 24)),
            right: isDesktop ? 60 : (screenW < 360 ? 14 : (screenW < 400 ? 18 : 24)),
            top: isDesktop ? (isCompactLaptop ? 6 : 8) : 12,
            bottom: isDesktop ? (isCompactLaptop ? 12 : 16) : 18,
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
    );
  }

  Widget _buildForegroundContent(double screenW, double screenH, bool isDesktop, bool isTablet) {
    final bool isCompactLaptop = isDesktop && (screenH < 850 || screenW < 1440);
    final bool isNarrow = !isDesktop || isCompactLaptop;

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Hero Content, Headline, Trust, CTAs (Permanently visible on white background)
              Expanded(
                flex: isCompactLaptop ? 13 : 14,
                child: _buildLeftHeroContent(screenW, screenH, isDesktop, isTablet, isCompactLaptop),
              ),
              SizedBox(width: isCompactLaptop ? 28 : 40),
              // Right Column: Dynamic area (Video Mode OR Valuation Expertise Mode)
              Expanded(
                flex: isCompactLaptop ? 9 : 10,
                child: _buildRightDynamicContent(isCompactLaptop),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLeftHeroContent(screenW, screenH, isDesktop, isTablet, isNarrow),
              const SizedBox(height: 28),
              _buildRightDynamicContent(isNarrow),
            ],
          );
  }

  Widget _buildRightDynamicContent(bool isCompact) {
    if (_isVideoPlaying) {
      // VIDEO MODE:
      // Video occupies ONLY the right side.
      // Valuation Expertise heading, service deck, and service tile animation are completely hidden.
      // Remove ALL visual framing around the video:
      // No borders, no rounded frame, no card appearance, no drop shadows, no outlines, no floating container.
      return ClipRect(
        child: HeroVideoWidget(
          videoAssets: _heroStoryVideos,
          activeVideoIndex: _currentVideoIndex,
          isPlaying: _isVideoPlaying,
          onVideoCompleted: _onVideoCompleted,
        ),
      );
    } else {
      // VALUATION EXPERTISE MODE:
      // Institutional Practice Area Spotlight under fixed #0F172A header tile
      return _PracticeAreaSpotlight(
        isCompact: isCompact,
        isVideoPlaying: _isVideoPlaying,
        isCompleted: _storyCompleted,
        onDeckSettled: _onDeckSettled,
      );
    }
  }

  Widget _buildLeftHeroContent(double screenW, double screenH, bool isDesktop, bool isTablet, bool isCompactLaptop) {
    final double headlineSize = isCompactLaptop
        ? 44.0
        : (isDesktop ? 56.0 : (isTablet ? 38.0 : 32.0));

    final double keywordSize = isCompactLaptop
        ? 38.0
        : (isDesktop ? 48.0 : (isTablet ? 32.0 : 28.0));

    final double bodySize = isCompactLaptop
        ? 15.0
        : (isDesktop ? 17.5 : 14.5);

    final double keywordGap = isCompactLaptop ? 4.0 : 6.0;
    final double descGap = isCompactLaptop ? 12.0 : 18.0;
    final double trustGap = isCompactLaptop ? 14.0 : 20.0;
    final double ctaGap = isCompactLaptop ? 18.0 : 26.0;
    final bool isNarrow = !isDesktop || isCompactLaptop;

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
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'REGISTERED VALUERS (GOVT APPROVED) • IBBI • INCOME TAX • ASSET INTELLIGENCE',
                    style: GoogleFonts.montserrat(
                      fontSize: isCompactLaptop ? 9.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: LandingTheme.textPrimary,
                      letterSpacing: isCompactLaptop ? 0.8 : 1.0,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: isNarrow ? 6.0 : (isCompactLaptop ? 7.0 : 8.0)),

        // High-Trust Ribbon (Subtle single row on desktop, balanced 2-line on mobile)
        _HeroTrustStrip(
          isNarrow: isNarrow,
          isCompact: isCompactLaptop,
        ),

        SizedBox(height: isNarrow ? 10.0 : (isCompactLaptop ? 11.0 : 13.0)),

        // Hero Headline Line 1: "Independent Valuation" (Guaranteed 1 line)
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Independent Valuation',
            maxLines: 1,
            softWrap: false,
            style: GoogleFonts.montserrat(
              fontSize: headlineSize,
              fontWeight: FontWeight.w800,
              color: LandingTheme.textPrimary,
              letterSpacing: -1.8,
              height: 1.08,
            ),
          ),
        ),

        SizedBox(height: keywordGap),

        // Hero Headline Line 2: Rotating trust credential (Guaranteed 1 line).
        // No 'For ' prefix — each trust signal stands alone as a declarative credential.
        // Rotation answers WHY TRUST PROVALUER at any single animation frame.
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AnimatedBuilder(
            animation: _keywordAnimController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _keywordSlideAnimation.value),
                child: Opacity(
                  opacity: _keywordOpacityAnimation.value,
                  child: Text(
                    _keywords[_currentKeywordIndex],
                    style: GoogleFonts.montserrat(
                      fontSize: keywordSize,
                      fontWeight: FontWeight.w800,
                      color: LandingTheme.brandGreen,
                      letterSpacing: -1.8,
                      height: 1.08,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: descGap),

        // Description — includes institutional AND individual clients for full-spectrum coverage.
        // 'property owners' provides retail/NRI/visa client recognition without diluting institutional tone.
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompactLaptop ? 560 : 620),
          child: Text(
            'Statutory valuation and asset intelligence for banks, NBFCs, private equity funds, insolvency professionals, and property owners — across India.',
            style: GoogleFonts.montserrat(
              fontSize: bodySize,
              fontWeight: FontWeight.w500,
              color: LandingTheme.textSecondary,
              letterSpacing: -0.2,
              height: 1.55,
            ),
          ),
        ),

        SizedBox(height: trustGap),

        // Trust Indicators — Tier 2 authority (Govt Approved, elevated) + Tier 3 regulatory mandates.
        // Government Approved Valuers receives a dedicated green-tinted badge: higher visual weight
        // than the standard charcoal pills to signal primary institutional authority.
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            _buildGovtApprovedBadge(isCompactLaptop),
            _buildTrustBadge(Icons.verified_user_outlined, 'IBBI Registered · Sec 247', isCompactLaptop),
            _buildTrustBadge(Icons.gavel_outlined, 'Rule 11UA / Income Tax', isCompactLaptop),
          ],
        ),

        SizedBox(height: ctaGap),

        // CTA Buttons (Always Visible during Reading Mode & Immediately Clickable)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            // Primary CTA: Request Valuation Report (Solid Deep Teal)
            GestureDetector(
              onTap: () => CommercialIntakeModal.show(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactLaptop ? 18 : 28,
                  vertical: isCompactLaptop ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen, // Reusing brand green token
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: LandingTheme.brandGreen.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Request Valuation Report',
                        style: GoogleFonts.montserrat(
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
            ),

            // Secondary Contact: Direct Phone Call (Matching Height & Smooth Hover Transition)
            _HeroPhonePill(isCompactLaptop: isCompactLaptop),
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String text, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
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
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.montserrat(
                fontSize: isCompact ? 11.0 : 12.5,
                fontWeight: FontWeight.w600,
                color: LandingTheme.textPrimary,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Dedicated Government Approved Valuers badge — Tier 2 authority signal.
  /// Green-tinted background, green border, and green text give it higher visual
  /// weight than the standard charcoal trust badges, making it immediately
  /// distinguishable as the primary statutory credential for retail and
  /// institutional visitors alike.
  Widget _buildGovtApprovedBadge(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 14,
        vertical: isCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: LandingTheme.brandGreen.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: LandingTheme.brandGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_rounded,
            size: isCompact ? 13 : 14,
            color: LandingTheme.brandGreen,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Government Approved Valuers',
              style: GoogleFonts.montserrat(
                fontSize: isCompact ? 11.0 : 12.5,
                fontWeight: FontWeight.w700,
                color: LandingTheme.brandGreen,
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle Institutional Trust Strip (Executive Masthead Ribbon)
class _HeroTrustStrip extends StatelessWidget {
  final bool isNarrow;
  final bool isCompact;

  const _HeroTrustStrip({
    required this.isNarrow,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final double fontSize = isNarrow ? 10.5 : (isCompact ? 11.5 : 12.5);
    final TextStyle itemStyle = GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF334155), // Slate-700 executive tone
      letterSpacing: -0.1,
    );
    final TextStyle strongStyle = GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: LandingTheme.textPrimary,
      letterSpacing: -0.1,
    );
    const Widget bullet = Padding(
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        '•',
        style: TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8), // Slate-400 subtle bullet
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (isNarrow) {
      // Mobile trust strip — Tier 1 (Volume: ₹15k+ Cr) • Tier 2 (Banking: PSU & Private Banks)
      // Tier 3 (Statutory: IBBI Registered Valuers) • Tier 4 (Reach: PAN India Coverage)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹15,000+ Cr Valued', style: strongStyle),
                bullet,
                Text('PSU & Private Banks', style: strongStyle),
              ],
            ),
          ),
          const SizedBox(height: 3.5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('IBBI Registered Valuers', style: itemStyle),
                bullet,
                Text('PAN India Coverage', style: itemStyle),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop trust strip — Tier 1 (Volume) • Tier 2 (Banking) • Tier 3 (Statutory) • Tier 4 (Reach)
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('₹15,000+ Cr Valued', style: strongStyle),
          bullet,
          Text('PSU & Private Banks', style: strongStyle),
          bullet,
          Text('IBBI Registered Valuers', style: itemStyle),
          bullet,
          Text('PAN India Coverage', style: itemStyle),
        ],
      ),
    );
  }
}

/// Symmetrical Hero Phone Pill with Smooth Hover Transition
class _HeroPhonePill extends StatefulWidget {
  final bool isCompactLaptop;

  const _HeroPhonePill({required this.isCompactLaptop});

  @override
  State<_HeroPhonePill> createState() => _HeroPhonePillState();
}

class _HeroPhonePillState extends State<_HeroPhonePill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse('tel:+918500019091');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompactLaptop ? 20 : 24,
            vertical: widget.isCompactLaptop ? 13 : 16,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: LandingTheme.brandGreen.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(100),
            color: _isHovered
                ? LandingTheme.brandGreen.withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FaIcon(
                  FontAwesomeIcons.phone,
                  color: LandingTheme.brandGreen,
                  size: 15,
                ),
                const SizedBox(width: 8),
                Text(
                  '+91 85000 19091',
                  style: GoogleFonts.montserrat(
                    fontSize: widget.isCompactLaptop ? 13.5 : 14.5,
                    fontWeight: FontWeight.w600,
                    color: LandingTheme.brandGreen,
                    letterSpacing: -0.2,
                  ),
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
// VALUATION EXPERTISE — EXECUTIVE CAPABILITY CARD SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════

class _ExecutiveCapabilityCardData {
  final String id;
  final String practiceArea;
  final String capability;
  final String clientType;

  const _ExecutiveCapabilityCardData({
    required this.id,
    required this.practiceArea,
    required this.capability,
    required this.clientType,
  });
}

const List<_ExecutiveCapabilityCardData> _capabilityCards = [
  _ExecutiveCapabilityCardData(
    id: '01',
    practiceArea: 'BANKING',
    capability: 'Collateral & Security Valuation',
    clientType: 'For PSU & Private Banks',
  ),
  _ExecutiveCapabilityCardData(
    id: '02',
    practiceArea: 'CORPORATE',
    capability: 'Share Valuation &\nNet Worth Certification',
    clientType: 'For Corporates & Investors',
  ),
  _ExecutiveCapabilityCardData(
    id: '03',
    practiceArea: 'REGULATORY',
    capability: 'NCLT & IBC\nValuation Support',
    clientType: 'For Resolution Professionals',
  ),
  _ExecutiveCapabilityCardData(
    id: '04',
    practiceArea: 'TECHNICAL',
    capability: 'Plant & Machinery\nTechnical Certification',
    clientType: 'For Industry & Engineering Assets',
  ),
];

class _PracticeAreaSpotlight extends StatefulWidget {
  final bool isCompact;
  final bool isVideoPlaying;
  final bool isCompleted;
  final VoidCallback? onDeckSettled;

  const _PracticeAreaSpotlight({
    required this.isCompact,
    required this.isVideoPlaying,
    required this.isCompleted,
    this.onDeckSettled,
  });

  @override
  State<_PracticeAreaSpotlight> createState() => _PracticeAreaSpotlightState();
}

class _PracticeAreaSpotlightState extends State<_PracticeAreaSpotlight> {
  int _currentIndex = 0;
  Timer? _rotationTimer;
  bool _hasTriggeredSettled = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isVideoPlaying) {
      _startRotation();
    }
  }

  void _startRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (!mounted) return;
      if (_isHovered) return;

      setState(() {
        final nextIndex = (_currentIndex + 1) % _capabilityCards.length;
        if (nextIndex == 0) {
          // Completed full cycle of 4 capability cards (01 -> 02 -> 03 -> 04)
          if (!_hasTriggeredSettled) {
            _hasTriggeredSettled = true;
            widget.onDeckSettled?.call();
          }
        }
        _currentIndex = nextIndex;
      });
    });
  }

  void _stopRotation() {
    _rotationTimer?.cancel();
    _rotationTimer = null;
  }

  void _resetTimer() {
    _stopRotation();
    _startRotation();
  }

  @override
  void didUpdateWidget(covariant _PracticeAreaSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isVideoPlaying && !widget.isVideoPlaying) {
      // Returning to Reading Mode from Video Mode:
      _hasTriggeredSettled = false;
      _currentIndex = 0;
      _startRotation();
    } else if (!oldWidget.isVideoPlaying && widget.isVideoPlaying) {
      // Entering Video Mode:
      _stopRotation();
    }
  }

  @override
  void dispose() {
    _stopRotation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = _capabilityCards[_currentIndex];
    final bool isCompact = widget.isCompact;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── TOP PERMANENT FIXED HEADER TILE (#0F172A, #FFFFFF text, brand green dot, SINGLE LINE) ────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 20,
              vertical: isCompact ? 10.5 : 12.5,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: LandingTheme.brandGreen, // Exact unified brand green token
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'VALUATION EXPERTISE',
                      style: GoogleFonts.montserrat(
                        fontSize: isCompact ? 11.5 : 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFFFFFF),
                        letterSpacing: 1.4,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 1.5), // Hairline spacing between header and card

          // ── ROTATING EXECUTIVE CAPABILITY CARD ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 18 : 22,
              vertical: isCompact ? 14 : 16.5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.0,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A0F172A),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated Switcher: card fades out and slides upward, new card enters and settles
                // Wrapped in an opaque surface to eliminate ALL ghosted background text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.topLeft,
                      children: <Widget>[
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (child, animation) {
                    final bool isIncoming = child.key == ValueKey<int>(_currentIndex);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: isIncoming
                            ? Tween<Offset>(
                                begin: const Offset(0.0, 0.08),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              ))
                            : Tween<Offset>(
                                begin: const Offset(0.0, -0.08),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInCubic,
                              )),
                        child: Container(
                          color: const Color(0xFFF8FAFC), // Opaque background eliminates ghosting
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentIndex),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Standalone Primary Counter Row (Sole Progression Indicator)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${card.id} / 04',
                            style: GoogleFonts.montserrat(
                              fontSize: isCompact ? 13.0 : 14.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 9 : 11),

                        // Tier 1: Practice Area (Large, Strong, Dominant)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 4,
                              height: isCompact ? 22 : 26,
                              decoration: BoxDecoration(
                                color: LandingTheme.brandGreen,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  card.practiceArea,
                                  style: GoogleFonts.montserrat(
                                    fontSize: isCompact ? 22.0 : 26.0,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: 0.8,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Hairline Divider
                        Container(
                          height: 1,
                          color: const Color(0xFFE2E8F0),
                          margin: EdgeInsets.symmetric(vertical: isCompact ? 7.5 : 8.5),
                        ),

                        // Tier 2: Core Capability Statement (+10% prominence: 23.5px / 20.0px)
                        SizedBox(
                          height: isCompact ? 52 : 58,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                card.capability,
                                style: GoogleFonts.montserrat(
                                  fontSize: isCompact ? 20.0 : 23.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: isCompact ? 7.5 : 8.5),

                        // Tier 3: Client Type Supporting Line
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: LandingTheme.brandGreen,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                card.clientType,
                                style: GoogleFonts.montserrat(
                                  fontSize: isCompact ? 12.0 : 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isCompact ? 11 : 12.5),

                // ── PROGRESS RAIL (SUBTLE SECONDARY CUE, 2.0PX HEIGHT) ─────────────────
                Row(
                  children: List.generate(_capabilityCards.length, (index) {
                    final bool isActive = index == _currentIndex;
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _currentIndex = index;
                          });
                          _resetTimer();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 3.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 2.0,
                            decoration: BoxDecoration(
                              color: isActive ? LandingTheme.brandGreen : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(1.0),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ═══════════════════════════════════════════════════════════════════════════════
// 2. AUTHORITY METRICS SECTION — VERIFIED TRACK RECORD
// ═══════════════════════════════════════════════════════════════════════════════
// Positioned immediately below the hero to anchor social proof before the
// visitor reads service or credential descriptions.
// DEPLOYMENT NOTE: Replace all TODO placeholders with exact verified figures
// from business records before going live. Using inflated or unverified numbers
// constitutes a compliance risk for a regulated valuation firm.
// ═══════════════════════════════════════════════════════════════════════════════

class AuthorityMetricsSection extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;

  const AuthorityMetricsSection({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;
    final bool isNarrow = !isDesktop;

    // TODO: Replace placeholder metric values with exact verified business figures
    // before deployment. Each value must be supportable by internal assignment records.
    final metrics = [
      _MetricData(
        value: '₹15,000+\u202fCr',    // TODO: Confirm exact figure
        label: 'Total Assets Valued',
        sublabel: 'Across All Asset Classes',
        icon: Icons.trending_up_rounded,
      ),
      _MetricData(
        value: '5,000+',             // TODO: Replace with actual completed assignment count
        label: 'Assignments Completed',
        sublabel: 'Statutory & Advisory Reports',
        icon: Icons.description_rounded,
      ),
      _MetricData(
        value: '15+',                // TODO: Replace with actual years since firm establishment
        label: 'Years Operating',
        sublabel: 'Institutional Practice',
        icon: Icons.history_rounded,
      ),
      _MetricData(
        value: '22+',                // TODO: Replace with actual city/district coverage count
        label: 'Cities Served',
        sublabel: 'PAN India Coverage',
        icon: Icons.location_on_rounded,
      ),
    ];

    // TODO: Replace with actual empanelled bank names (verify each empanelment is documented).
    // If specific bank logos require trademark permission, use text-only names.
    const String bankStrip =
        'SBI  ·  Bank of Baroda  ·  Union Bank  ·  HDFC Bank  ·  ICICI Bank  ·  Axis Bank  ·  PNB  ·  Canara Bank  ·  and 18+ more';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC), // Pearl slate — visually separates from hero white
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 72 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            children: [
              // ── Section Eyebrow ────────────────────────────────────────────
              const GlassEyebrowBadge(
                label: 'Verified Track Record',
                icon: Icons.military_tech_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Proof in Every Assignment',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: screenW >= 1024 ? 38 : (screenW >= 768 ? 30 : 24),
                  fontWeight: FontWeight.w800,
                  color: LandingTheme.textPrimary,
                  letterSpacing: -1.2,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Text(
                  'Numbers drawn from completed statutory assignments across India\'s banking, corporate, and regulatory sectors.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: screenW >= 768 ? 15.5 : 13.5,
                    fontWeight: FontWeight.w400,
                    color: LandingTheme.textSecondary,
                    height: 1.55,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── 4 Authority Metrics ────────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (constraints.maxWidth >= 640 ? 2 : 2);
                  const double spacing = 16;
                  final double tileW = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics.map((m) => SizedBox(
                      width: tileW,
                      child: _AuthorityMetricTile(metric: m, isNarrow: isNarrow),
                    )).toList(),
                  );
                },
              ),

              const SizedBox(height: 40),

              // ── Bank Empanelment Strip ────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: isDesktop ? 18 : 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060F172A),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EMPANELLED ACROSS',
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: LandingTheme.textMuted,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        bankStrip,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: isNarrow ? 12.5 : 14,
                          fontWeight: FontWeight.w600,
                          color: LandingTheme.textPrimary,
                          letterSpacing: -0.1,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        softWrap: true,
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
}

/// Data model for a single authority metric tile.
class _MetricData {
  final String value;
  final String label;
  final String sublabel;
  final IconData icon;

  const _MetricData({
    required this.value,
    required this.label,
    required this.sublabel,
    required this.icon,
  });
}

/// Individual metric display tile.
/// Large value (48px), label (14px), sublabel (11px), hairline border.
class _AuthorityMetricTile extends StatelessWidget {
  final _MetricData metric;
  final bool isNarrow;

  const _AuthorityMetricTile({required this.metric, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 16 : 24,
        vertical: isNarrow ? 20 : 28,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon (subtle, small, charcoal)
          Icon(
            metric.icon,
            size: 18,
            color: LandingTheme.brandGreen,
          ),
          SizedBox(height: isNarrow ? 10 : 14),

          // Large metric value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              metric.value,
              style: GoogleFonts.montserrat(
                fontSize: isNarrow ? 34 : 42,
                fontWeight: FontWeight.w800,
                color: LandingTheme.textPrimary,
                letterSpacing: -1.8,
                height: 1.0,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Primary label
          Text(
            metric.label,
            style: GoogleFonts.montserrat(
              fontSize: isNarrow ? 13 : 14,
              fontWeight: FontWeight.w700,
              color: LandingTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 3),

          // Sublabel (muted)
          Text(
            metric.sublabel,
            style: GoogleFonts.montserrat(
              fontSize: isNarrow ? 11 : 12,
              fontWeight: FontWeight.w400,
              color: LandingTheme.textMuted,
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
                                style: GoogleFonts.montserrat(
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
                                      style: GoogleFonts.montserrat(
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.primaryAccent,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p['title'] as String,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                p['desc'] as String,
                                style: GoogleFonts.montserrat(
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: LandingTheme.primaryAccent,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s['title']!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                s['desc']!,
                                style: GoogleFonts.montserrat(
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
// 6. CREDENTIALS SECTION — CLEAN MONOCHROME & PLATINUM BADGES
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
                                      style: GoogleFonts.montserrat(
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
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: LandingTheme.primaryAccent,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c['desc']!,
                                style: GoogleFonts.montserrat(
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
                  style: GoogleFonts.montserrat(
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
                      onTap: () => CommercialIntakeModal.show(context),
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
                              'Request Valuation Report',
                              style: GoogleFonts.montserrat(
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
                              style: GoogleFonts.montserrat(
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
              const SizedBox(height: 24),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _buildFooterServiceLink(context, 'Government Approved Valuers', '/government-approved-valuers'),
                  _buildFooterServiceLink(context, 'Property Valuation Services', '/services/property-valuation'),
                  _buildFooterServiceLink(context, 'Visa & Immigration Valuations', '/services/visa-and-immigration-valuations'),
                  _buildFooterServiceLink(context, 'Bank Collateral Valuation', '/services/bank-collateral-valuation'),
                  _buildFooterServiceLink(context, 'NCLT & IBC Valuation', '/services/nclt-ibc-valuation'),
                  _buildFooterServiceLink(context, 'Divorce & Matrimonial Valuation', '/services/divorce-matrimonial-valuation'),
                  _buildFooterServiceLink(context, 'Probate & Estate Valuation', '/services/probate-inheritance-valuation'),
                  _buildFooterServiceLink(context, 'Share & Equity Valuation', '/services/share-valuation'),
                ],
              ),
              const SizedBox(height: 24),
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
                        style: GoogleFonts.montserrat(
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
                    style: GoogleFonts.montserrat(
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

  Widget _buildFooterServiceLink(BuildContext context, String title, String route) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: LandingTheme.textSecondary,
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
                    style: GoogleFonts.montserrat(
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
              _mobileLink(context, 'Credentials'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    CommercialIntakeModal.show(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: LandingTheme.brandGreen,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Center(
                      child: Text(
                        'Request Valuation Report',
                        style: GoogleFonts.montserrat(
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
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: LandingTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
