import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'landing_theme.dart';
import 'widgets/commercial_intake_modal.dart';
import '../../services/analytics_service.dart';

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
    final double screenW = MediaQuery.of(context).size.width;
    final double horizontalPadding = isDesktop ? (screenW < 1440 ? 40 : 60) : 20;
    final double linkSpacing = screenW >= LandingTheme.wideDesktopBreakpoint ? 30.0 : 22.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isScrolled ? 12 : 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
                        SizedBox(width: linkSpacing),
                        _HeaderLink(label: 'Why Pro Valuer', onTap: () => _scrollTo('why-pro-valuer')),
                        SizedBox(width: linkSpacing),
                        _HeaderLink(label: 'Process', onTap: () => _scrollTo('process')),
                        SizedBox(width: linkSpacing),
                        _HeaderLink(label: 'Credentials', onTap: () => _scrollTo('credentials')),
                        SizedBox(width: linkSpacing),

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

class _HeroSectionState extends State<HeroSection> {
  // Buyer-focused service keywords — pairs dynamically with 'Independent Valuation'
  static const List<String> _keywords = [
    'Land & Buildings',
    'Industrial Assets',
    'Plant & Machinery',
    'Financial Assets',
    'Net Worth Certificates',
    'Technical Due Diligence',
  ];

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;
    final double screenW = MediaQuery.of(context).size.width;
    final bool isDesktop = widget.isDesktop;
    final bool isTablet = LandingTheme.isTablet(context);
    final bool isCompactDesktop = isDesktop && (screenH < 900 || screenW < 1440);

    // Fluid hero sizing without rigid minimum clamps that force scrolling
    final double? targetMinH = isDesktop
        ? (screenH >= 900 ? screenH * 0.88 : screenH * 0.82)
        : null;

    return Container(
      width: double.infinity,
      constraints: targetMinH != null ? BoxConstraints(minHeight: targetMinH) : null,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        gradient: RadialGradient(
          center: Alignment(0.6, -0.3),
          radius: 1.3,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isDesktop ? (isCompactDesktop ? 40 : 60) : (screenW < 360 ? 14 : (screenW < 400 ? 18 : 24)),
          right: isDesktop ? (isCompactDesktop ? 40 : 60) : (screenW < 360 ? 14 : (screenW < 400 ? 18 : 24)),
          top: isDesktop ? (isCompactDesktop ? 76 : 96) : 76,
          bottom: isDesktop ? (isCompactDesktop ? 28 : 44) : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
            child: SizedBox(
              width: double.infinity,
              child: _buildForegroundContent(screenW, screenH, isDesktop, isTablet),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForegroundContent(double screenW, double screenH, bool isDesktop, bool isTablet) {
    final bool isCompactDesktop = isDesktop && (screenH < 900 || screenW < 1440);
    final bool isNarrow = !isDesktop || isCompactDesktop;
    final bool isLargeDesktop = screenW >= 1440;
    // Hero Layout Balance: 58/42 on desktop below 1440px; 54/46 on desktop above 1440px
    final int leftFlex = isLargeDesktop ? 54 : 58;
    final int rightFlex = isLargeDesktop ? 46 : 42;

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Column: Hero Content, Headline, Trust, CTAs
              Expanded(
                flex: leftFlex,
                child: _buildLeftHeroContent(screenW, screenH, isDesktop, isTablet, isCompactDesktop),
              ),
              SizedBox(width: isCompactDesktop ? 32 : 44),
              // Right Column: Accordion-Style Visual Showcase
              Expanded(
                flex: rightFlex,
                child: _HeroAccordionVisual(isCompact: isCompactDesktop),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLeftHeroContent(screenW, screenH, isDesktop, isTablet, isNarrow),
              const SizedBox(height: 32),
              _HeroAccordionVisual(isCompact: isNarrow),
            ],
          );
  }

  Widget _buildLeftHeroContent(double screenW, double screenH, bool isDesktop, bool isTablet, bool isCompactDesktop) {
    // Fluid responsive typography scaling with sensible clamps to prevent compression
    final double headlineSize = isDesktop
        ? (isCompactDesktop ? (screenW * 0.034).clamp(38.0, 46.0) : (screenW * 0.036).clamp(42.0, 50.0))
        : (isTablet ? 36.0 : 28.0);

    final double keywordSize = isDesktop
        ? (isCompactDesktop ? (screenW * 0.028).clamp(30.0, 38.0) : (screenW * 0.032).clamp(36.0, 46.0))
        : (isTablet ? 30.0 : 24.0);

    final double bodySize = isCompactDesktop
        ? 14.5
        : (isDesktop ? 16.0 : 14.0);

    // Responsive Vertical Rhythm (Target Ranges: 24-36px, 14-18px, 16-22px, 24-32px, 24-36px)
    final double gapEyebrowToHeadline = isCompactDesktop ? 26.0 : 34.0;
    final double gapHeadlineToFor = isCompactDesktop ? 14.0 : 18.0;
    final double gapForToKeyword = isCompactDesktop ? 16.0 : 20.0;
    final double gapKeywordToDesc = isCompactDesktop ? 24.0 : 32.0;
    final double gapDescToCta = isCompactDesktop ? 26.0 : 34.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. IBBI REGISTERED VALUERS (Eyebrow Badge)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompactDesktop ? 14 : 16,
            vertical: isCompactDesktop ? 6 : 8,
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
                      fontSize: isCompactDesktop ? 9.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: LandingTheme.textPrimary,
                      letterSpacing: isCompactDesktop ? 0.8 : 1.0,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            ],
          ),
        ),

        // [24-36px spacing]
        SizedBox(height: gapEyebrowToHeadline),

        // 2. Independent Valuation (Single-line headline stability across all desktop resolutions)
        Text(
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

        // [14-18px spacing]
        SizedBox(height: gapHeadlineToFor),

        // 3. For
        Text(
          'For',
          style: GoogleFonts.montserrat(
            fontSize: isCompactDesktop ? 20.0 : 24.0,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
            letterSpacing: -0.5,
          ),
        ),

        // [16-22px spacing]
        SizedBox(height: gapForToKeyword),

        // 4. Animated Service Keyword (Apple-quality blur, rise, sharpen & sweep)
        _AppleAnimatedKeyword(
          keywords: _keywords,
          fontSize: keywordSize,
        ),

        // [24-32px spacing]
        SizedBox(height: gapKeywordToDesc),

        // 5. Supporting Paragraph
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isCompactDesktop ? 540 : 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Statutory valuation and asset intelligence for banks, NBFCs, private equity funds, insolvency professionals, and property owners — across India.',
                style: GoogleFonts.montserrat(
                  fontSize: bodySize,
                  fontWeight: FontWeight.w500,
                  color: LandingTheme.textSecondary,
                  letterSpacing: -0.2,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildGovtApprovedBadge(isCompactDesktop),
                  _buildTrustBadge(Icons.verified_user_outlined, 'IBBI Registered · Sec 247', isCompactDesktop),
                  _buildTrustBadge(Icons.gavel_outlined, 'Rule 11UA / Income Tax', isCompactDesktop),
                ],
              ),
            ],
          ),
        ),

        // [24-36px spacing]
        SizedBox(height: gapDescToCta),

        // 6. CTA Buttons
        Wrap(
          spacing: 14,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Primary CTA: Request Valuation Report (Solid Deep Teal)
            GestureDetector(
              onTap: () => CommercialIntakeModal.show(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompactDesktop ? 22 : 28,
                  vertical: isCompactDesktop ? 13 : 16,
                ),
                decoration: BoxDecoration(
                  color: LandingTheme.brandGreen,
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
                          fontSize: isCompactDesktop ? 13.5 : 14.5,
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
            _HeroPhonePill(isCompact: isCompactDesktop),
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


/// Symmetrical Hero Phone Pill with Smooth Hover Transition
class _HeroPhonePill extends StatefulWidget {
  final bool isCompact;

  const _HeroPhonePill({required this.isCompact});

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
          AnalyticsService.logPhoneClicked(
            phoneNumber: '+918500019091',
            serviceType: 'LANDING_HERO',
            pageUrl: Uri.base.toString(),
          );
          final uri = Uri.parse('tel:+918500019091');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 20 : 24,
            vertical: widget.isCompact ? 13 : 16,
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
                    fontSize: widget.isCompact ? 13.5 : 14.5,
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
// APPLE-QUALITY ANIMATED KEYWORD (SMOOTH BLUR, RISE, SHARPEN & SWEEP)
// ═══════════════════════════════════════════════════════════════════════════════

class _AppleAnimatedKeyword extends StatefulWidget {
  final List<String> keywords;
  final double fontSize;

  const _AppleAnimatedKeyword({
    required this.keywords,
    required this.fontSize,
  });

  @override
  State<_AppleAnimatedKeyword> createState() => _AppleAnimatedKeywordState();
}

class _AppleAnimatedKeywordState extends State<_AppleAnimatedKeyword>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _currentIndex = 0;
  int _nextIndex = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 3600), (_) {
      if (!mounted) return;
      _nextIndex = (_currentIndex + 1) % widget.keywords.length;
      _animController.forward(from: 0.0).then((_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = _nextIndex;
        });
        _animController.reset();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.fontSize * 1.35,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          final double progress = _animController.value;
          final bool isAnimating = _animController.isAnimating;

          if (!isAnimating) {
            // Calm, settled resting state
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.keywords[_currentIndex],
                style: GoogleFonts.montserrat(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  color: LandingTheme.brandGreen,
                  letterSpacing: -1.2,
                  height: 1.15,
                ),
              ),
            );
          }

          // ── Outgoing word: blur out, move upward, fade gently ─────────────
          // Active during first 45% of transition
          final double outProgress = (progress / 0.45).clamp(0.0, 1.0);
          final double outCurve = Curves.easeInQuad.transform(outProgress);
          final double outOpacity = (1.0 - outCurve).clamp(0.0, 1.0);
          final double outBlur = 5.0 * outCurve;
          final double outTranslateY = -20.0 * outCurve;

          // ── Incoming word: rise from below, sharpen, platinum reflection sweep ──
          // Active from 30% through 100%
          final double inProgress = ((progress - 0.30) / 0.70).clamp(0.0, 1.0);
          final double inCurve = Curves.easeOutCubic.transform(inProgress);
          final double inOpacity = inCurve;
          final double inBlur = 6.0 * (1.0 - inCurve);
          final double inTranslateY = 24.0 * (1.0 - inCurve);

          // Platinum Reflection sweep across incoming word:
          // Colors: #CBD5E1, #F8FAFC, #CBD5E1. Very subtle, very elegant, very premium.
          final double sweepCenter = -0.4 + (inCurve * 1.8);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Outgoing word
              if (outOpacity > 0.01)
                Transform.translate(
                  offset: Offset(0, outTranslateY),
                  child: Opacity(
                    opacity: outOpacity,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: outBlur, sigmaY: outBlur),
                      child: Text(
                        widget.keywords[_currentIndex],
                        style: GoogleFonts.montserrat(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w800,
                          color: LandingTheme.brandGreen,
                          letterSpacing: -1.2,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                ),

              // Incoming word with soft settling & subtle platinum reflection
              if (inOpacity > 0.01)
                Transform.translate(
                  offset: Offset(0, inTranslateY),
                  child: Opacity(
                    opacity: inOpacity,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: inBlur, sigmaY: inBlur),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [
                              (sweepCenter - 0.22).clamp(0.0, 1.0),
                              (sweepCenter - 0.10).clamp(0.0, 1.0),
                              sweepCenter.clamp(0.0, 1.0),
                              (sweepCenter + 0.10).clamp(0.0, 1.0),
                              (sweepCenter + 0.22).clamp(0.0, 1.0),
                            ],
                            colors: const [
                              LandingTheme.brandGreen,
                              Color(0xFFCBD5E1), // Platinum reflection
                              Color(0xFFF8FAFC), // Pure platinum highlight
                              Color(0xFFCBD5E1), // Platinum reflection
                              LandingTheme.brandGreen,
                            ],
                          ).createShader(bounds);
                        },
                        child: Text(
                          widget.keywords[_nextIndex],
                          style: GoogleFonts.montserrat(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ACCORDION-STYLE HERO VISUAL SHOWCASE (ORIGINAL VISUAL RESTORED & REFINED)
// ═══════════════════════════════════════════════════════════════════════════════

class _AccordionPanelData {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageAsset;
  final IconData icon;
  final Color baseColor;

  const _AccordionPanelData({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageAsset,
    required this.icon,
    required this.baseColor,
  });
}

class _HeroAccordionVisual extends StatefulWidget {
  final bool isCompact;

  const _HeroAccordionVisual({
    required this.isCompact,
  });

  @override
  State<_HeroAccordionVisual> createState() => _HeroAccordionVisualState();
}

class _HeroAccordionVisualState extends State<_HeroAccordionVisual> {
  int _activeIndex = 0;
  Timer? _autoTimer;
  Timer? _hoverDebounceTimer;
  bool _isHovered = false;
  bool _isVisible = true;

  static const List<_AccordionPanelData> _panels = [
    _AccordionPanelData(
      id: '01',
      title: 'Land Valuation',
      category: 'LAND & CORRIDORS',
      description: 'Agricultural, Commercial, Industrial & Institutional Land',
      imageAsset: 'assets/images/hero/land_valuation.webp',
      icon: Icons.landscape_rounded,
      baseColor: Color(0xFF1E293B),
    ),
    _AccordionPanelData(
      id: '02',
      title: 'Building Valuation',
      category: 'BUILT ASSETS',
      description: 'Residential, Commercial, Industrial & Mixed-Use Assets',
      imageAsset: 'assets/images/hero/building_valuation.webp',
      icon: Icons.apartment_rounded,
      baseColor: Color(0xFF0F172A),
    ),
    _AccordionPanelData(
      id: '03',
      title: 'Plant & Machinery Valuation',
      category: 'PLANT & MACHINERY',
      description: 'Industrial Equipment, Manufacturing Facilities & Technical Assets',
      imageAsset: 'assets/images/hero/plant_machinery_valuation.webp',
      icon: Icons.precision_manufacturing_rounded,
      baseColor: Color(0xFF1E293B),
    ),
    _AccordionPanelData(
      id: '04',
      title: 'Financial Assets Valuation',
      category: 'FINANCIAL ASSETS',
      description: 'Shares, Securities, Business & Enterprise Value',
      imageAsset: 'assets/images/hero/financial_assets_valuation.webp',
      icon: Icons.query_stats_rounded,
      baseColor: Color(0xFF0F172A),
    ),
    _AccordionPanelData(
      id: '05',
      title: 'Net Worth Certificates',
      category: 'NET WORTH & SOLVENCY',
      description: 'Individual, Corporate & Regulatory Certification',
      imageAsset: 'assets/images/hero/net_worth_valuation.webp',
      icon: Icons.verified_user_rounded,
      baseColor: Color(0xFF1E293B),
    ),
    _AccordionPanelData(
      id: '06',
      title: 'Technical Due Diligence',
      category: 'TECHNICAL AUDIT',
      description: 'Engineering Review, Condition Assessment & Risk Analysis',
      imageAsset: 'assets/images/hero/technical_due_diligence.webp',
      icon: Icons.engineering_rounded,
      baseColor: Color(0xFF0F172A),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoRotation();
  }

  void _startAutoRotation() {
    _autoTimer?.cancel();
    if (!_isVisible) return;
    _autoTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || _isHovered || !_isVisible) return;
      setState(() {
        _activeIndex = (_activeIndex + 1) % _panels.length;
      });
    });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final bool visible = info.visibleFraction > 0.05;
    if (_isVisible != visible) {
      _isVisible = visible;
      if (!_isVisible) {
        _autoTimer?.cancel();
      } else if (!_isHovered) {
        _startAutoRotation();
      }
    }
  }

  void _handleHover(bool hovering, int? index) {
    _hoverDebounceTimer?.cancel();
    if (hovering && index != null) {
      // 60ms lightweight debounce to prevent rapid mouse sweep thrashing
      _hoverDebounceTimer = Timer(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        setState(() {
          _isHovered = true;
          _activeIndex = index;
        });
      });
    } else {
      setState(() {
        _isHovered = false;
      });
      _startAutoRotation();
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _hoverDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;

    return VisibilityDetector(
      key: const Key('hero-accordion-visibility-detector'),
      onVisibilityChanged: _handleVisibilityChanged,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Lower threshold to 390 to keep horizontal accordion on scaled 1366x768 laptops (412px column)
          final bool isHorizontal = constraints.maxWidth >= 390;
          final double containerHeight = isHorizontal
              ? (widget.isCompact
                  ? (screenH * 0.50).clamp(380.0, 460.0)
                  : (screenH * 0.54).clamp(420.0, 520.0))
              : 500.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Accordion Showcase Deck ─────────────────────────────────────
              Container(
                height: isHorizontal ? containerHeight : 500.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 36,
                      offset: Offset(0, 14),
                    ),
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: isHorizontal
                    ? _buildHorizontalAccordion(constraints.maxWidth, containerHeight)
                    : _buildVerticalAccordion(),
              ),

              const SizedBox(height: 16),

              // ── Subdued Minimal Progress Rail ──────────────────────────────
              Row(
                children: List.generate(_panels.length, (index) {
                  final bool isActive = index == _activeIndex;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => _handleHover(true, index),
                      onExit: (_) => _handleHover(false, null),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _activeIndex = index;
                          });
                          _startAutoRotation();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 4.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            height: 3.0,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? LandingTheme.brandGreen
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(2.0),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: LandingTheme.brandGreen.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHorizontalAccordion(double totalWidth, double height) {
    const double spacing = 6.0;
    final double totalSpacing = spacing * (_panels.length - 1);
    final double availWidth = totalWidth - totalSpacing;
    // Exact proportional width calculations: active panel ~44%, inactive evenly split remaining space
    final double activeWidth = availWidth * 0.44;
    final double inactiveWidth = (availWidth - activeWidth) / (_panels.length - 1);

    return Row(
      children: List.generate(_panels.length, (index) {
        final panel = _panels[index];
        final bool isActive = index == _activeIndex;
        final double width = isActive ? activeWidth : inactiveWidth;

        return RepaintBoundary(
          child: Padding(
            padding: EdgeInsets.only(right: index == _panels.length - 1 ? 0 : spacing),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => _handleHover(true, index),
              onExit: (_) => _handleHover(false, null),
              child: GestureDetector(
                onTap: () {
                  setState(() => _activeIndex = index);
                  _startAutoRotation();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 520),
                  curve: const Cubic(0.16, 1.0, 0.3, 1.0),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: panel.baseColor,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image with local WebP & GPU decode constraint
                      Image.asset(
                        panel.imageAsset,
                        cacheWidth: 800,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [panel.baseColor, const Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),

                    // Multi-stop Luxurious Scrim Gradient
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: isActive
                              ? const [0.0, 0.40, 0.70, 1.0]
                              : const [0.0, 0.50, 1.0],
                          colors: isActive
                              ? [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.35),
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.black.withValues(alpha: 0.94),
                                ]
                              : [
                                  Colors.black.withValues(alpha: 0.45),
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.black.withValues(alpha: 0.85),
                                ],
                        ),
                      ),
                    ),

                    // Top Glass Pill: Category Indicator
                    Positioned(
                      top: 14,
                      left: 14,
                      right: 14,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  panel.icon,
                                  size: 13,
                                  color: isActive ? const Color(0xFF5EEAD4) : Colors.white70,
                                ),
                                if (isActive) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    panel.category,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            panel.id,
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? Colors.white : Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Active Detailed Content (Calm, Editorial, Maximum Clarity)
                    if (isActive)
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 22,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isActive ? 1.0 : 0.0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                panel.title,
                                style: GoogleFonts.montserrat(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Description (Maximum 2 lines, pure service clarity)
                              Text(
                                panel.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFFCBD5E1),
                                  letterSpacing: -0.1,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Inactive Vertical Orientation Cue
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              panel.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                                letterSpacing: 0.5,
                              ),
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
      );
      }),
    );
  }

  Widget _buildVerticalAccordion() {
    return Column(
      children: List.generate(_panels.length, (index) {
        final panel = _panels[index];
        final bool isActive = index == _activeIndex;

        return Expanded(
          flex: isActive ? 5 : 1,
          child: GestureDetector(
            onTap: () {
              setState(() => _activeIndex = index);
              _startAutoRotation();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 520),
              curve: const Cubic(0.16, 1.0, 0.3, 1.0),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: panel.baseColor,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    panel.imageAsset,
                    cacheWidth: 800,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: panel.baseColor,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.35),
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    top: 10,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(panel.icon, size: 16, color: isActive ? const Color(0xFF5EEAD4) : Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                panel.title,
                                style: GoogleFonts.montserrat(
                                  fontSize: isActive ? 15 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isActive) ...[
                                const SizedBox(height: 3),
                                Text(
                                  panel.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFFCBD5E1),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
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
      }),
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
    const metrics = [
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
    final bool isDesktop = LandingTheme.isDesktop(context);

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 24,
        vertical: isDesktop ? 90 : 50,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
          constraints: const BoxConstraints(maxWidth: LandingTheme.maxContentWidth),
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
