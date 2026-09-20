import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_components.dart';
import '../../theme/app_spacing.dart';
import 'landing_theme.dart';
import 'widgets/hero_video_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// 1. FLOATING GLASS NAVIGATION BAR (BlackRock / Palantir Luxury Glass)
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isScrolled ? 16 : 8,
          sigmaY: isScrolled ? 16 : 8,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
            vertical: isScrolled ? 14 : 18,
          ),
          decoration: BoxDecoration(
            color: isScrolled
                ? LandingTheme.surfaceGlassDense
                : LandingTheme.primaryBg.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isScrolled
                    ? LandingTheme.borderHover
                    : LandingTheme.hairlineBorder,
                width: 1.0,
              ),
            ),
            boxShadow: isScrolled ? LandingTheme.glassShadow : const [],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _brandLogo(),
                if (isDesktop) ...[
                  const Row(
                    children: [
                      _HeaderNavLink(text: 'Services', sectionKey: 'services'),
                      SizedBox(width: 28),
                      _HeaderNavLink(text: 'Industries', sectionKey: 'industries'),
                      SizedBox(width: 28),
                      _HeaderNavLink(text: 'Why Pro Valuer', sectionKey: 'why-us'),
                      SizedBox(width: 28),
                      _HeaderNavLink(text: 'Process', sectionKey: 'process'),
                      SizedBox(width: 28),
                      _HeaderNavLink(text: 'Case Studies', sectionKey: 'cases'),
                      SizedBox(width: 28),
                      _HeaderNavLink(text: 'Empanelments', sectionKey: 'empanelments'),
                    ],
                  ),
                  Row(
                    children: [
                      _headerButton(
                        label: 'Client Login',
                        isPrimary: false,
                        onTap: () => context.go('/login'),
                      ),
                      const SizedBox(width: 12),
                      _headerButton(
                        label: 'Schedule Consultation',
                        isPrimary: true,
                        onTap: () => launchWhatsApp(
                          'Hello Pro Valuer, I would like to schedule an institutional valuation consultation.',
                        ),
                      ),
                    ],
                  ),
                ] else
                  IconButton(
                    icon: const Icon(Icons.menu, color: LandingTheme.textPrimary, size: 24),
                    onPressed: onMenuTap,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _brandLogo() {
    return AppComponents.logo(
      fontSize: 20,
      darkMode: true,
      overrideWordmark: LandingTheme.textPrimary,
      overrideAccent: LandingTheme.secondaryAccent,
    );
  }

  Widget _headerButton({
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return _HeaderActionButton(
      label: label,
      isPrimary: isPrimary,
      onTap: onTap,
    );
  }
}

class _HeaderNavLink extends StatefulWidget {
  final String text;
  final String sectionKey;
  const _HeaderNavLink({required this.text, required this.sectionKey});

  @override
  State<_HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<_HeaderNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 150),
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
          color: _hovered ? LandingTheme.secondaryAccent : LandingTheme.textSecondary,
          letterSpacing: -0.1,
        ),
        child: Text(widget.text),
      ),
    );
  }
}

class _HeaderActionButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_HeaderActionButton> createState() => _HeaderActionButtonState();
}

class _HeaderActionButtonState extends State<_HeaderActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: widget.isPrimary ? LandingTheme.blueGradient : null,
            color: widget.isPrimary
                ? null
                : (_hovered
                    ? LandingTheme.secondaryBg
                    : LandingTheme.surfaceGlass),
            border: Border.all(
              color: widget.isPrimary
                  ? (_hovered ? LandingTheme.glowAccent : LandingTheme.secondaryAccent)
                  : (_hovered ? LandingTheme.borderHover : LandingTheme.hairlineBorder),
              width: 1.0,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: LandingTheme.primaryAccent.withValues(alpha: _hovered ? 0.45 : 0.25),
                      blurRadius: _hovered ? 18 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isPrimary
                  ? LandingTheme.textPrimary
                  : (_hovered ? LandingTheme.textPrimary : LandingTheme.textSecondary),
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. HERO SECTION — Institutional Asset Intelligence
// ═══════════════════════════════════════════════════════════════════════════════

class HeroSection extends StatelessWidget {
  final bool isDesktop;
  final Future<void> Function(String) launchWhatsApp;

  const HeroSection({
    super.key,
    required this.isDesktop,
    required this.launchWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      child: Stack(
        children: [
          // Ambient Radial Blue Lighting
          Positioned(
            top: -120,
            left: screenW * 0.25,
            child: const FloatingAmbientGlow(
              width: 700,
              height: 500,
              opacity: 0.10,
            ),
          ),
          const Positioned(
            top: 200,
            right: -100,
            child: FloatingAmbientGlow(
              width: 500,
              height: 500,
              opacity: 0.06,
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
              vertical: isDesktop ? 64 : 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 36),

                // Institutional Authority Badge
                const LuxuryEyebrowBadge(
                  label: 'IBBI REGISTERED · CHARTERED ENGINEERS · INSTITUTIONAL LENDING STANDARDS',
                  icon: Icons.verified_rounded,
                ),

                const SizedBox(height: 24),

                // Hero Headline
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    children: [
                      Text(
                        'Institutional Valuation Intelligence',
                        textAlign: TextAlign.center,
                        style: LandingTheme.heroHeading(screenW),
                      ),
                      const SizedBox(height: 4),
                      GradientText(
                        'For Banks, Funds & Enterprise Assets',
                        style: LandingTheme.heroHeading(screenW).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        gradient: LandingTheme.cyanGlowGradient,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Subheadline
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Text(
                    'IBBI Registered Valuers, Chartered Engineering Professionals, and Institutional Advisors delivering valuation, diligence, and risk assessment services for real estate, infrastructure, industrial, and enterprise assets across India.',
                    textAlign: TextAlign.center,
                    style: LandingTheme.bodyMediumResponsive(screenW),
                  ),
                ),

                const SizedBox(height: 36),

                // Dual CTAs
                _buildHeroActions(context, isDesktop),

                const SizedBox(height: 48),

                // Verified Credentials Cards
                _buildCredentialCards(isDesktop),

                const SizedBox(height: 44),

                // Hero Visual: Looping Asset Valuation Intelligence Console
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1140),
                  child: Column(
                    children: [
                      // Telemetry HUD Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: LandingTheme.secondaryBg,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                          border: Border.all(color: LandingTheme.hairlineBorder, width: 1.0),
                        ),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                _hudDot(LandingTheme.secondaryAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'ASSET VALUATION INTELLIGENCE CONSOLE · RTK CADASTRAL SPATIAL MAPPING',
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: LandingTheme.secondaryAccent,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (isDesktop)
                              Text(
                                'INDEPENDENT METHODOLOGY · REVENUE SURVEY BOUNDARY VERIFICATION',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: LandingTheme.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Video Player Container
                      const HeroVideoWidget(
                        videoAssets: [
                          'assets/videos/hero_animation.mp4',
                          'assets/videos/Create_a_premium_animated_hero.mp4',
                        ],
                        height: 540,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActions(BuildContext context, bool isDesktop) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: [
        // Primary CTA
        _ActionButton(
          label: 'Schedule Institutional Consultation',
          icon: Icons.arrow_forward_rounded,
          isPrimary: true,
          onTap: () => launchWhatsApp(
            'Hello Pro Valuer, I would like to schedule an institutional valuation consultation.',
          ),
        ),
        // Secondary CTA
        _ActionButton(
          label: 'Download Sample Valuation Report',
          icon: Icons.file_download_outlined,
          isPrimary: false,
          onTap: () => launchWhatsApp(
            'Hello Pro Valuer, please provide a sample institutional valuation report dossier.',
          ),
        ),
      ],
    );
  }

  Widget _buildCredentialCards(bool isDesktop) {
    final credentials = [
      {'title': 'IBBI Registered Valuers', 'sub': 'Insolvency & Bankruptcy Board Compliant', 'icon': Icons.shield_outlined},
      {'title': 'Chartered Engineering Expertise', 'sub': 'Institution of Engineers (India) Certified', 'icon': Icons.architecture_outlined},
      {'title': 'Independent Assessment Standards', 'sub': 'Unbiased Multi-Asset Valuation', 'icon': Icons.account_balance_outlined},
      {'title': 'Regulatory-Compliant Reporting', 'sub': 'Companies Act 2013 & RBI Prudential Norms', 'icon': Icons.gavel_outlined},
      {'title': 'Audit-Ready Documentation', 'sub': 'Multi-Tier Review & Evidentiary Support', 'icon': Icons.inventory_2_outlined},
    ];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1140),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: credentials.map((item) {
              return SizedBox(
                width: isWide ? (constraints.maxWidth - (4 * 12)) / 5 : (constraints.maxWidth > 500 ? (constraints.maxWidth - 12) / 2 : double.infinity),
                child: PalantirGlassPanel(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  borderRadius: 10,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          size: 17,
                          color: LandingTheme.secondaryAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: LandingTheme.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['sub'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w400,
                                color: LandingTheme.textMuted,
                              ),
                            ),
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
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: widget.isPrimary ? LandingTheme.blueGradient : null,
            color: widget.isPrimary
                ? null
                : (_hovered ? LandingTheme.secondaryBg : LandingTheme.surfaceGlassDense),
            border: Border.all(
              color: widget.isPrimary
                  ? (_hovered ? LandingTheme.glowAccent : LandingTheme.secondaryAccent)
                  : (_hovered ? LandingTheme.secondaryAccent : LandingTheme.hairlineBorder),
              width: 1.2,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: LandingTheme.primaryAccent.withValues(alpha: _hovered ? 0.45 : 0.25),
                      blurRadius: _hovered ? 20 : 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: widget.isPrimary
                      ? LandingTheme.textPrimary
                      : (_hovered ? LandingTheme.secondaryAccent : LandingTheme.textPrimary),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                widget.icon,
                size: 16,
                color: widget.isPrimary
                    ? LandingTheme.textPrimary
                    : (_hovered ? LandingTheme.secondaryAccent : LandingTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. PROMINENT TRUST LAYER — Why Financial Institutions Work With Pro Valuer
// ═══════════════════════════════════════════════════════════════════════════════

class WhyFinancialInstitutionsWorkWithProValuerSection extends StatelessWidget {
  final bool isDesktop;

  const WhyFinancialInstitutionsWorkWithProValuerSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final trustCards = [
      {
        'title': 'IBBI Registered Valuers',
        'desc': 'Statutory authority under Section 247 of the Companies Act 2013, licensed across Land & Building, Plant & Machinery, and Securities.',
      },
      {
        'title': 'Chartered Engineering Expertise',
        'desc': 'In-house technical inspections by Corporate Members of The Institution of Engineers (India), ensuring physical asset ground truth.',
      },
      {
        'title': 'Independent Assessment Methodology',
        'desc': 'Objective multi-model valuation free from developer, borrower, or volume pressures, delivering defensible valuation conclusions.',
      },
      {
        'title': 'Audit-Ready Documentation',
        'desc': 'Comprehensive evidentiary trail, sub-registrar transaction cross-referencing, and 256-bit tamper-evident verification.',
      },
      {
        'title': 'Regulatory-Aligned Reporting',
        'desc': 'Direct compliance with IBC 2016 (CIRP Regulations), SARFAESI security valuation, and RBI Prudential Master Directions.',
      },
      {
        'title': 'Lender-Focused Deliverables',
        'desc': 'Executive summaries, forced sale value calibrations, and sensitivity stress-testing tailored for credit committees and risk officers.',
      },
      {
        'title': 'Institutional Quality Control',
        'desc': 'Rigorous internal verification protocols ensuring standardized data integrity, municipal master plan alignment, and accuracy.',
      },
      {
        'title': 'Multi-Level Review Standards',
        'desc': 'Mandatory three-tier review with partner-level dual sign-off, eliminating single-analyst error vectors across all mandates.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'INSTITUTIONAL TRUST FOUNDATION',
                icon: Icons.security_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Why Financial Institutions Work With Pro Valuer',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Text(
                  'Independent valuation, engineering due diligence, and risk advisory services prepared for institutional credit committees, corporate boards, and regulatory forums.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 16;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: trustCards.map((card) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(20),
                          borderRadius: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: LandingTheme.secondaryAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      card['title']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: LandingTheme.textPrimary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                card['desc']!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
// 4. TRUST BAR — Regulatory Standards & Institutional Lending Framework
// ═══════════════════════════════════════════════════════════════════════════════

class TrustBar extends StatelessWidget {
  const TrustBar({super.key});

  @override
  Widget build(BuildContext context) {
    final pillars = [
      {'title': 'IBBI REGISTERED', 'sub': 'Statutory Valuation Authority'},
      {'title': 'CHARTERED ENGINEERING', 'sub': 'Institution of Engineers Certified'},
      {'title': 'INSTITUTIONAL LENDING', 'sub': 'Consortium Standard Aligned'},
      {'title': 'STATUTORY REPORTING', 'sub': 'IBC, SARFAESI & Companies Act'},
      {'title': 'INDEPENDENT METHODOLOGY', 'sub': 'DCF, GIS & Yield Capitalization'},
    ];

    final frameworks = [
      'Insolvency & Bankruptcy Code 2016',
      'Companies Act 2013 §247',
      'SARFAESI Asset Realization Standards',
      'RBI Prudential Guidelines',
      'Ind AS 16 & Ind AS 36 Fair Value',
      'Chartered Engineers Technical Division',
      'National Company Law Tribunal (NCLT) Compliance',
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: LandingTheme.primaryBg,
        border: Border.symmetric(
          horizontal: BorderSide(color: LandingTheme.hairlineBorder, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 850;
                  return Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.spaceAround,
                    children: pillars.map((p) {
                      return SizedBox(
                        width: isWide ? (constraints.maxWidth - (4 * 24)) / 5 : (constraints.maxWidth > 500 ? (constraints.maxWidth - 24) / 2 : double.infinity),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: LandingTheme.secondaryAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p['title']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: LandingTheme.textPrimary,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p['sub']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w400,
                                      color: LandingTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1, color: LandingTheme.hairlineBorder),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'PREPARED IN ACCORDANCE WITH INSTITUTIONAL LENDING & REGULATORY REQUIREMENTS :',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LandingTheme.secondaryAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 20),
                  ...frameworks.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              f,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: LandingTheme.textSecondary,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: LandingTheme.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 5. EXECUTIVE AUTHORITY SECTION — Institutional Expertise Backed By Professionals
// ═══════════════════════════════════════════════════════════════════════════════

class ExecutiveAuthoritySection extends StatelessWidget {
  final bool isDesktop;

  const ExecutiveAuthoritySection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final pillars = [
      {
        'title': 'Senior Valuation Leadership',
        'sub': 'EXPERIENCED PRACTITIONERS',
        'icon': Icons.groups_rounded,
        'desc': 'Our practice is directed by senior valuation professionals with decades of continuous experience executing asset appraisals for credit institutions and investment funds.',
      },
      {
        'title': 'IBBI Registration & Licensure',
        'sub': 'STATUTORY AUTHORITY',
        'icon': Icons.verified_user_rounded,
        'desc': 'Recognized Registered Valuers under Section 247 of the Companies Act 2013, licensed across Land & Building, Plant & Machinery, and Securities & Financial Assets.',
      },
      {
        'title': 'Chartered Engineer Credentials',
        'sub': 'TECHNICAL CERTIFICATION',
        'icon': Icons.architecture_rounded,
        'desc': 'In-house Corporate Members of The Institution of Engineers (India) lead on-site civil structural audits, mechanical plant inspections, and capital expenditure verification.',
      },
      {
        'title': 'Regulatory & Judicial Experience',
        'sub': 'AUDIT & TRIBUNAL DEFENSE',
        'icon': Icons.gavel_rounded,
        'desc': 'Extensive experience preparing documentation capable of withstanding scrutiny before NCLT benches, Debt Recovery Tribunals (DRT), and statutory audit panels.',
      },
      {
        'title': 'Comprehensive Industry Coverage',
        'sub': 'MULTI-ASSET CLASS MASTERY',
        'icon': Icons.domain_rounded,
        'desc': 'Specialized valuation capability across commercial IT parks, heavy manufacturing plants, power and highway infrastructure, maritime assets, and land parcels.',
      },
      {
        'title': 'Technical Review Framework',
        'sub': 'THREE-TIER GOVERNANCE',
        'icon': Icons.fact_check_rounded,
        'desc': 'Every valuation dossier undergoes rigorous peer review, geospatial boundary verification, and mandatory dual sign-off before delivery to lenders.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'EXECUTIVE CREDENTIALS',
                icon: Icons.person_search_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Institutional Expertise Backed By Qualified Professionals',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: Text(
                  'Our institutional credibility is anchored by qualified valuation practitioners, certified Chartered Engineers, and regulatory advisors committed to objective analysis.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 18;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: pillars.map((p) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(22),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      p['icon'] as IconData,
                                      size: 18,
                                      color: LandingTheme.secondaryAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['sub'] as String,
                                          style: GoogleFonts.sourceCodePro(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: LandingTheme.secondaryAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p['title'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: LandingTheme.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
// 6. SERVICES SECTION — 8 Institutional Asset Valuation Cards
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
        'title': 'Property Valuation',
        'tag': 'REAL ESTATE & COMMERCIAL',
        'icon': Icons.business_rounded,
        'desc': 'Valuation of prime commercial office towers, IT tech parks, shopping malls, logistics warehouses, and residential portfolios.',
        'outputs': ['Discounted Cash Flow (DCF)', 'Direct Capitalization Yield', 'Fair Market & Forced Sale Value'],
      },
      {
        'title': 'Land & Cadastral Valuation',
        'tag': 'SPATIAL GIS RECONCILIATION',
        'icon': Icons.terrain_rounded,
        'desc': 'Valuation of industrial layouts, SEZs, agricultural parcels, open plotting projects, and contiguous land assemblies.',
        'outputs': ['RTK Satellite Boundary Overlay', 'Master Plan Zoning Audit', 'Encumbrance Buffer Analysis'],
      },
      {
        'title': 'Industrial Asset Valuation',
        'tag': 'MANUFACTURING & PLANTS',
        'icon': Icons.precision_manufacturing_rounded,
        'desc': 'Appraisal of large-scale manufacturing facilities, chemical plants, pharmaceutical units, and automotive complexes.',
        'outputs': ['Depreciated Replacement Cost', 'Operational Utility Index', 'Salvage & Scrap Realization'],
      },
      {
        'title': 'Plant & Machinery Appraisals',
        'tag': 'CHARTERED ENGINEER AUDIT',
        'icon': Icons.build_circle_rounded,
        'desc': 'Chartered Engineering technical assessment of specialized equipment, assembly lines, robotics, and heavy mining machinery.',
        'outputs': ['Remaining Useful Life (RUL)', 'Physical Wear Calibration', 'IBC Liquidation Benchmark'],
      },
      {
        'title': 'Infrastructure & Project Valuation',
        'tag': 'UTILITIES & CONCESSIONS',
        'icon': Icons.alt_route_rounded,
        'desc': 'Valuation of toll highways, sea ports, container terminals, solar/wind renewable farms, and airport concessions.',
        'outputs': ['Concession Agreement Audit', 'Traffic & Yield DCF Modeling', 'Asset Capitalization Proof'],
      },
      {
        'title': 'Technical Due Diligence',
        'tag': 'STRUCTURAL & STATUTORY',
        'icon': Icons.engineering_rounded,
        'desc': 'Comprehensive technical audit of civil integrity, sanctioned plan conformity, MEP systems, and environmental compliance.',
        'outputs': ['Civil Defect Liability Review', 'Statutory NOC Audit', 'CAPEX / OPEX Forecasting'],
      },
      {
        'title': 'Financial Risk Advisory',
        'tag': 'IBC & IMPAIRMENT TESTING',
        'icon': Icons.analytics_rounded,
        'desc': 'Ind AS / IFRS impairment testing, CIRP liquidation valuation under IBC 2016, and dispute resolution expert testimony.',
        'outputs': ['Section 29A Eligibility Audit', 'Liquidation Value Modeling', 'NCLT Tribunal Defense'],
      },
      {
        'title': 'Chartered Engineering Certification',
        'tag': 'CUSTOMS & EPC CERTIFICATION',
        'icon': Icons.verified_rounded,
        'desc': 'Statutory certification for customs duty exemption, EPC commercial commissioning, and lender independent engineer (LIE) reviews.',
        'outputs': ['Capital Goods Installation Cert', 'Advance License Reconciliation', 'Lender Engineer Milestones'],
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'INSTITUTIONAL SERVICE SUITE',
                icon: Icons.apps_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Comprehensive Valuation & Asset Intelligence',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Text(
                  'Independent, audit-defensible reporting across all asset classes with multi-tier statutory signoffs from IBBI Registered Valuers and Chartered Engineers.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 4 : (isTablet ? 2 : 1);
                  const double spacing = 18;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: services.map((s) {
                      return SizedBox(
                        width: cardWidth,
                        child: _InstitutionalServiceCard(
                          title: s['title'] as String,
                          tag: s['tag'] as String,
                          icon: s['icon'] as IconData,
                          desc: s['desc'] as String,
                          outputs: s['outputs'] as List<String>,
                          onTap: () => launchWhatsApp(
                            'Hello Pro Valuer, I require advisory for ${s['title']}.',
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

class _InstitutionalServiceCard extends StatefulWidget {
  final String title;
  final String tag;
  final IconData icon;
  final String desc;
  final List<String> outputs;
  final VoidCallback onTap;

  const _InstitutionalServiceCard({
    required this.title,
    required this.tag,
    required this.icon,
    required this.desc,
    required this.outputs,
    required this.onTap,
  });

  @override
  State<_InstitutionalServiceCard> createState() => _InstitutionalServiceCardState();
}

class _InstitutionalServiceCardState extends State<_InstitutionalServiceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _hovered ? LandingTheme.secondaryBg : LandingTheme.surfaceGlassDense,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? LandingTheme.secondaryAccent : LandingTheme.hairlineBorder,
              width: _hovered ? 1.2 : 1.0,
            ),
            boxShadow: _hovered ? LandingTheme.hoverShadow : LandingTheme.subtleShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      widget.tag,
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: LandingTheme.secondaryAccent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  Icon(
                    widget.icon,
                    size: 22,
                    color: _hovered ? LandingTheme.glowAccent : LandingTheme.secondaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: LandingTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.desc,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: LandingTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1, color: LandingTheme.hairlineBorder),
              const SizedBox(height: 14),
              ...widget.outputs.map((out) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 13,
                          color: LandingTheme.secondaryAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            out,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: LandingTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 7. INDUSTRIES SECTION — 10 Institutional Ecosystem Sectors
// ═══════════════════════════════════════════════════════════════════════════════

class IndustriesSection extends StatelessWidget {
  final bool isDesktop;

  const IndustriesSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final industries = [
      {
        'title': 'Banks & Financial Institutions',
        'desc': 'Pre-disbursement mortgage appraisal, SARFAESI auction reserves, and periodic collateral revaluation.',
        'icon': Icons.account_balance_rounded,
      },
      {
        'title': 'NBFCs & Private Credit',
        'desc': 'Underwriting diligence, loan-to-value stress tests, and structured debt security validation.',
        'icon': Icons.credit_score_rounded,
      },
      {
        'title': 'Private Equity Funds',
        'desc': 'Platform acquisition due diligence, post-merger integration assets, and portfolio mark-to-market.',
        'icon': Icons.trending_up_rounded,
      },
      {
        'title': 'Venture Capital Firms',
        'desc': 'Fixed asset appraisal, specialized technology hardware verification, and equipment valuation.',
        'icon': Icons.rocket_launch_rounded,
      },
      {
        'title': 'Corporate Treasury Teams',
        'desc': 'Balance sheet asset revaluation under Ind AS 16/36, M&A carve-out pricing, and financial reporting.',
        'icon': Icons.corporate_fare_rounded,
      },
      {
        'title': 'Government Organizations',
        'desc': 'Disinvestment valuation, public asset concession pricing, and sovereign infrastructure audits.',
        'icon': Icons.account_balance_outlined,
      },
      {
        'title': 'Infrastructure Developers',
        'desc': 'BOT / HAM project asset appraisal, toll road refinancing, and airport/port concessions.',
        'icon': Icons.traffic_rounded,
      },
      {
        'title': 'Asset Reconstruction (ARCs)',
        'desc': 'Stressed asset fair value determination, liquidation benchmarks, and security enforcement.',
        'icon': Icons.restore_page_rounded,
      },
      {
        'title': 'Insolvency Professionals (IPs)',
        'desc': 'IBC Section 35(1) CIRP liquidation and fair value determinations defensible before NCLT benches.',
        'icon': Icons.gavel_rounded,
      },
      {
        'title': 'Real Estate Funds (REITs)',
        'desc': 'Statutory periodic NAV valuations, tenant covenant risk models, and asset acquisition underwriting.',
        'icon': Icons.domain_rounded,
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'ECOSYSTEM COVERAGE',
                icon: Icons.public_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Trusted by Institutional Capital & Enterprise Risk Officers',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Delivering audit-defensible valuation intelligence tailored to the statutory and risk mandate of every institutional stakeholder.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 48),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 5 : (constraints.maxWidth >= 700 ? 3 : 2);
                  const double spacing = 14;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: industries.map((ind) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(18),
                          borderRadius: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: LandingTheme.secondaryAccent.withValues(alpha: 0.25),
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  ind['icon'] as IconData,
                                  size: 18,
                                  color: LandingTheme.secondaryAccent,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                ind['title'] as String,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ind['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textSecondary,
                                  height: 1.4,
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
// 8. WHY PRO VALUER — Institutional Advantage Matrix (10 Criteria)
// ═══════════════════════════════════════════════════════════════════════════════

class WhyProValuerSection extends StatelessWidget {
  final bool isDesktop;

  const WhyProValuerSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final matrix = [
      {
        'criterion': 'IBBI Registration & Accreditation',
        'proValuer': 'Full IBBI Institutional Entity Registration across Land & Building, Plant & Machinery, and Securities/Financial Assets.',
        'traditional': 'Unaccredited local firms or single-license individuals with limited statutory authority.',
      },
      {
        'criterion': 'Chartered Engineer Technical Oversight',
        'proValuer': 'In-house certified Chartered Engineers (Civil, Mechanical, Electrical) conduct physical on-site technical audits.',
        'traditional': 'Omitted or outsourced to third-party consultants with no unified legal accountability.',
      },
      {
        'criterion': 'Regulatory Compliance Framework',
        'proValuer': '100% compliant with IBC 2016, Companies Act 2013 §247, SARFAESI, and RBI Prudential Guidelines.',
        'traditional': 'Generic templates prone to rejection by banking credit committees and statutory auditors.',
      },
      {
        'criterion': 'Audit Readiness & Legal Defense',
        'proValuer': 'Legally binding, audit-ready defense before NCLT benches, DRT, SEBI, and CAG audit teams.',
        'traditional': 'Zero post-submission support; reports frequently challenged and disqualified.',
      },
      {
        'criterion': 'Institutional Valuation Methodology',
        'proValuer': 'GIS spatial mapping + DCF Discounted Cash Flow + Depreciated Replacement Cost (DRC) modeling.',
        'traditional': 'Rough rule-of-thumb guesswork and unverified circle rate extrapolations.',
      },
      {
        'criterion': 'Independent Assessment Standards',
        'proValuer': '100% independent asset appraisal without broker bias, developer influence, or lending volume pressure.',
        'traditional': 'Vulnerable to commercial commission bias and inflated borrower valuations.',
      },
      {
        'criterion': 'Multi-Level Verification Protocol',
        'proValuer': 'Mandatory 3-tier review: Field Surveyor → Technical Valuer → Partner Dual-Signoff.',
        'traditional': 'Single-individual unverified draft with high likelihood of clerical and valuation errors.',
      },
      {
        'criterion': 'Risk Intelligence & Spatial GIS Analytics',
        'proValuer': 'Satellite cadastral telemetry, title buffer zones, and stress-tested LTV modeling.',
        'traditional': 'Blind manual paperwork without spatial boundary analysis or stress tests.',
      },
      {
        'criterion': 'Institutional Turnaround Time (SLA)',
        'proValuer': 'Guaranteed 48–72 hours for urban assets; 5 business days for complex multi-location industrial plants.',
        'traditional': 'Unpredictable 3–5 week delivery cycles with complete communication blackout.',
      },
      {
        'criterion': 'Bank Acceptance Experience',
        'proValuer': 'Prepared in accordance with institutional lending and regulatory requirements nationwide.',
        'traditional': 'Limited panel presence requiring cumbersome one-off approval letters.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'INSTITUTIONAL BENCHMARK',
                icon: Icons.compare_arrows_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'The Institutional Advantage Matrix',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Text(
                  'Why credit institutions, funds, and insolvency professionals mandate Pro Valuer over traditional appraisal firms for high-stakes capital decisions.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 48),

              Container(
                decoration: BoxDecoration(
                  color: LandingTheme.surfaceGlassDense,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LandingTheme.hairlineBorder, width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Column(
                    children: [
                      Container(
                        color: LandingTheme.secondaryBg,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                'EVALUATION CRITERIA',
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textMuted,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: LandingTheme.secondaryAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PRO VALUER INSTITUTIONAL',
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: LandingTheme.secondaryAccent,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isDesktop)
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'TRADITIONAL APPRAISAL FIRMS',
                                  style: GoogleFonts.sourceCodePro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: LandingTheme.textTertiary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: LandingTheme.hairlineBorder),

                      ...matrix.asMap().entries.map((entry) {
                        final i = entry.key;
                        final row = entry.value;
                        final isEven = i % 2 == 0;

                        return Container(
                          color: isEven ? Colors.transparent : LandingTheme.secondaryBg.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  row['criterion']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: LandingTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 4,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: LandingTheme.secondaryAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        row['proValuer']!,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: LandingTheme.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isDesktop) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 4,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.cancel_outlined,
                                        size: 15,
                                        color: LandingTheme.textTertiary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          row['traditional']!,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: LandingTheme.textMuted,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 9. WHY REPORTS GET ACCEPTED — Institutional Credit & Regulatory Scrutiny
// ═══════════════════════════════════════════════════════════════════════════════

class WhyReportsGetAcceptedSection extends StatelessWidget {
  final bool isDesktop;

  const WhyReportsGetAcceptedSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final pillars = [
      {
        'title': 'Documentation Standards',
        'sub': 'COMPREHENSIVE EVIDENTIARY TRAIL',
        'icon': Icons.inventory_2_rounded,
        'desc': 'Complete supporting evidence including title document reviews, municipal sanctioned plans, registrar transaction indices, and 256-bit tamper-evident digital verification.',
      },
      {
        'title': 'Methodology',
        'sub': 'REPRODUCIBLE ANALYTICAL MODELS',
        'icon': Icons.analytics_rounded,
        'desc': 'Adherence to Discounted Cash Flow (DCF), direct income capitalization, and depreciated replacement cost models benchmarked against verified micro-market yield data.',
      },
      {
        'title': 'Compliance',
        'sub': 'STATUTORY ALIGNMENT',
        'icon': Icons.gavel_rounded,
        'desc': 'Strict conformance with Section 247 of the Companies Act 2013, Companies (Registered Valuers & Valuation) Rules 2017, and IBC Section 35(1) CIRP regulations.',
      },
      {
        'title': 'Audit Readiness',
        'sub': 'DEFENSIBLE BEFORE TRIBUNALS',
        'icon': Icons.verified_user_rounded,
        'desc': 'Reports structured to withstand independent examination by statutory auditors, banking inspection teams, NCLT judicial benches, and CAG oversight.',
      },
      {
        'title': 'Engineering Review',
        'sub': 'CHARTERED ENGINEER TECHNICAL AUDIT',
        'icon': Icons.architecture_rounded,
        'desc': 'Mandatory physical on-site inspection of civil structural health, MEP services, and mechanical equipment wear conducted by certified Corporate Members.',
      },
      {
        'title': 'Independent Assessment',
        'sub': 'UNBIASED PROFESSIONAL STANDARDS',
        'icon': Icons.balance_rounded,
        'desc': 'Free from commercial commission incentives or developer pressure, ensuring uncompromised fiduciary objectivity in every valuation conclusion.',
      },
      {
        'title': 'Regulatory Alignment',
        'sub': 'PRUDENTIAL NORM HARMONIZATION',
        'icon': Icons.account_balance_rounded,
        'desc': 'Reports calibrated to Reserve Bank of India (RBI) loan security valuation guidelines, SARFAESI auction reserves, and institutional credit limits.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'CREDIT & REGULATORY SCRUTINY',
                icon: Icons.shield_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Why Pro Valuer Reports Get Accepted',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Text(
                  'Engineered specifically to survive the scrutiny of bank credit committees, statutory auditors, rating agencies, and NCLT judicial benches.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 18;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: pillars.map((p) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(22),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Icon(
                                      p['icon'] as IconData,
                                      size: 19,
                                      color: LandingTheme.secondaryAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['sub'] as String,
                                          style: GoogleFonts.sourceCodePro(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w600,
                                            color: LandingTheme.secondaryAccent,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          p['title'] as String,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: LandingTheme.textPrimary,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                p['desc'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
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
// 10. PROCESS SECTION — Interactive Institutional Workflow (6 Stages)
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
        'title': 'Asset Inspection',
        'desc': 'On-site geo-tagged inspection by certified Chartered Engineers, assessing structural health, civil condition, and machinery wear.',
        'tag': 'STAGE 1 · FIELDWORK',
      },
      {
        'step': '02',
        'title': 'Data Collection & Ingestion',
        'desc': 'Digital intake of title deeds, sanctioned plans, asset registers, and automated satellite GIS cadastral parcel demarcation.',
        'tag': 'STAGE 2 · INTAKE',
      },
      {
        'step': '03',
        'title': 'Financial & Geospatial Modeling',
        'desc': 'Cross-referencing municipal master plans, sub-registrar transaction indices, and micro-market commercial capitalization yields.',
        'tag': 'STAGE 3 · ANALYTICS',
      },
      {
        'step': '04',
        'title': 'Independent Valuation Analysis',
        'desc': 'Executing Discounted Cash Flow (DCF), Depreciated Replacement Cost (DRC), and liquidation value stress testing.',
        'tag': 'STAGE 4 · VALUATION',
      },
      {
        'step': '05',
        'title': 'Multi-Level Review',
        'desc': 'Mandatory sign-off by IBBI Registered Valuer and Chartered Engineer, verifying compliance against IBC, SARFAESI, and RBI norms.',
        'tag': 'STAGE 5 · DUAL AUDIT',
      },
      {
        'step': '06',
        'title': 'Lender-Ready Report Delivery',
        'desc': 'Delivery of tamper-evident digital dossiers, institutional summary dashboards, and complete post-mandate audit defense.',
        'tag': 'STAGE 6 · ACCEPTANCE',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'RIGOROUS EXECUTION',
                icon: Icons.timeline_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Institutional Valuation Workflow',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'End-to-end data integrity, physical ground truth, and regulatory verification at every step of the assignment.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : (constraints.maxWidth >= 700 ? 2 : 1);
                  const double spacing = 18;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: steps.map((s) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(22),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    s['step']!,
                                    style: GoogleFonts.sourceCodePro(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: LandingTheme.secondaryAccent,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.25),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      s['tag']!,
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: LandingTheme.secondaryAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                s['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                s['desc']!,
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
// 11. CASE STUDIES SECTION — Outcome-Driven Real Enterprise Engagements
// ═══════════════════════════════════════════════════════════════════════════════

class CaseStudiesSection extends StatelessWidget {
  final bool isDesktop;

  const CaseStudiesSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final cases = [
      {
        'title': 'Maritime Bulk Port & Container Terminal',
        'sector': 'INFRASTRUCTURE & LOGISTICS',
        'clientType': 'National Banking Consortium (Lead Public Sector Bank)',
        'challenge': 'Lending consortium required simultaneous technical and asset due diligence across extensive waterfront infrastructure, deep-water berths, and heavy handling equipment under strict refinancing timelines.',
        'scope': 'Comprehensive Technical Due Diligence, Chartered Engineering Plant Audit, and Fair Market & Realizable Liquidation Valuation.',
        'methodology': 'Geospatial cadastral boundary verification combined with itemized mechanical depreciation schedules and operational utility indexing.',
        'outcome': 'Delivered an audit-defensible valuation dossier accepted by credit risk committees of all consortium lenders without qualification.',
        'deliverables': 'Independent Valuation Report, Chartered Engineer Technical Audit Certificate, and Asset Realizability Sensitivity Matrix.',
      },
      {
        'title': 'Commercial IT Park & Special Economic Zone',
        'sector': 'REIT & INSTITUTIONAL REAL ESTATE',
        'clientType': 'Real Estate Investment Trust (REIT) & Institutional Asset Manager',
        'challenge': 'Asset portfolio ingestion required granular multi-tenant lease covenant analysis, micro-market yield calibration, and strict Ind AS 16/36 compliance.',
        'scope': 'Tenant-by-tenant Discounted Cash Flow (DCF) modeling, civil structural MEP audit, and statutory master plan zoning verification.',
        'methodology': 'DCF modeling incorporating weighted average unexpired lease terms (WAULT), localized absorption trends, and capital expenditure forecasts.',
        'outcome': 'Successfully incorporated into institutional asset portfolio; approved by statutory auditors and regulatory monitoring trustees.',
        'deliverables': 'Statutory Valuation Dossier, Financial Model DCF Sheet, and Structural Integrity Due Diligence Report.',
      },
      {
        'title': 'Integrated Steel & Rolling Mill Complex',
        'sector': 'HEAVY MANUFACTURING & IBC',
        'clientType': 'Insolvency Resolution Professional (IRP) under IBC 2016',
        'challenge': 'Stressed manufacturing enterprise under CIRP proceedings requiring independent fair value and liquidation value determination defensible before the Committee of Creditors.',
        'scope': 'Itemized plant and machinery appraisal, physical operational utility inspection, and scrap realization analysis across specialized rolling lines.',
        'methodology': 'Depreciated Replacement Cost (DRC) approach supplemented by equipment operational history and salvage realization benchmarks.',
        'outcome': 'Defended successfully before NCLT judicial bench; approved by Committee of Creditors with decisive voting majority.',
        'deliverables': 'IBC Section 35(1) Valuation Report, Plant Machinery Inventory Register, and Liquidation Benchmark Certificate.',
      },
      {
        'title': 'Greenfield Expressway & Toll Concession',
        'sector': 'TRANSPORTATION & PUBLIC INFRASTRUCTURE',
        'clientType': 'Infrastructure Concessionaire & National Highway Entity',
        'challenge': 'Statutory requirement for asset capitalization certification across an extended greenfield highway corridor to unlock milestone institutional refinancing.',
        'scope': 'Chartered Engineering Milestone Verification, civil structural stability audit, and traffic yield capitalization analysis.',
        'methodology': 'Corridor-wide engineering verification with physical milestone expenditure reconciliation and statutory conformance checks.',
        'outcome': 'Certified within established delivery schedules; enabled institutional refinancing with full consortium lender concurrence.',
        'deliverables': 'Chartered Engineer Completion Certificate, Concession Asset Capitalization Report, and Risk Assessment Dossier.',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'PROVEN OUTCOMES',
                icon: Icons.workspace_premium_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Institutional Engagement Case Studies',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Delivering audit-defensible valuation certainty on complex, multi-asset institutional transactions.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 52),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 2 : 1;
                  const double spacing = 20;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: cases.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(26),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c['title']!,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: LandingTheme.textPrimary,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: LandingTheme.primaryAccent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: LandingTheme.secondaryAccent.withValues(alpha: 0.3),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      c['sector']!,
                                      style: GoogleFonts.sourceCodePro(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: LandingTheme.secondaryAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _caseField('Client Type', c['clientType']!),
                              _caseField('Challenge', c['challenge']!),
                              _caseField('Scope', c['scope']!),
                              _caseField('Methodology', c['methodology']!),
                              _caseField('Outcome', c['outcome']!, isHighlight: true),
                              _caseField('Deliverables', c['deliverables']!),
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

  static Widget _caseField(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label : ',
              style: GoogleFonts.sourceCodePro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isHighlight ? LandingTheme.secondaryAccent : LandingTheme.textMuted,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w400,
                color: isHighlight ? LandingTheme.textPrimary : LandingTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 12. TESTIMONIALS SECTION — Institutional C-Suite Endorsements
// ═══════════════════════════════════════════════════════════════════════════════

class TestimonialsSection extends StatelessWidget {
  final bool isDesktop;

  const TestimonialsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final endorsements = [
      {
        'quote': 'Pro Valuer’s reports have consistently withstood our highest level of credit committee scrutiny. Their depth of technical diligence and IBBI compliance is rigorous and reliable.',
        'name': 'Senior Executive & Risk Head',
        'org': 'National Commercial Banking Institution',
      },
      {
        'quote': 'In complex resolution mandates, precision is essential. Pro Valuer delivers institutional modeling and spatial clarity that gives investment committees complete conviction.',
        'name': 'Managing Director',
        'org': 'Private Credit & Special Situations Fund',
      },
      {
        'quote': 'Their valuation reports for CIRP mandates are watertight. Methodical analysis, prompt turnaround, and defensible documentation before NCLT judicial benches.',
        'name': 'Insolvency Resolution Professional (IRP)',
        'org': 'National Insolvency Practice',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.primaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'INSTITUTIONAL TRUST',
                icon: Icons.format_quote_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Credit Committee & Risk Leadership Perspectives',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 48),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 3 : 1;
                  const double spacing = 20;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: endorsements.map((e) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(24),
                          borderRadius: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.format_quote_rounded,
                                size: 28,
                                color: LandingTheme.secondaryAccent,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                e['quote']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w400,
                                  color: LandingTheme.textPrimary,
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 22),
                              const Divider(height: 1, color: LandingTheme.hairlineBorder),
                              const SizedBox(height: 14),
                              Text(
                                e['name']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                e['org']!,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: LandingTheme.secondaryAccent,
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
// 13. EMPANELMENTS & REGULATORY CREDENTIALS SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class EmpanelmentsSection extends StatelessWidget {
  final bool isDesktop;

  const EmpanelmentsSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    final credentials = [
      {
        'title': 'Insolvency & Bankruptcy Board of India (IBBI)',
        'sub': 'Registered Valuer Entity under the Companies (Registered Valuers & Valuation) Rules 2017.',
        'code': 'IBBI / STATUTORY VALUER ENTITY',
      },
      {
        'title': 'The Institution of Engineers (India)',
        'sub': 'Chartered Engineers authorized for Technical Inspections, Plant Audits & EPC Certifications.',
        'code': 'CHARTERED ENGINEERING DIVISION',
      },
      {
        'title': 'Registered Valuers Organisations (RVO)',
        'sub': 'Affiliated with prominent RVOs recognized by IBBI across statutory asset classes.',
        'code': 'MULTI-ASSET STATUTORY LICENSURE',
      },
      {
        'title': 'Institutional Lending Consortia',
        'sub': 'Reports structured and prepared in alignment with Public and Private Scheduled Commercial Bank standards.',
        'code': 'LENDING CONSORTIA ALIGNED',
      },
    ];

    return Container(
      width: double.infinity,
      color: LandingTheme.secondaryBg,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              const LuxuryEyebrowBadge(
                label: 'STATUTORY LICENSURE & STANDARDS',
                icon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: 18),
              Text(
                'Accredited by National Regulatory Authorities',
                textAlign: TextAlign.center,
                style: LandingTheme.sectionTitleResponsive(screenW),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Every valuation report issued complies strictly with statutory mandates and is recognized across judicial, regulatory, and financial forums.',
                  textAlign: TextAlign.center,
                  style: LandingTheme.bodyMediumResponsive(screenW),
                ),
              ),
              const SizedBox(height: 48),

              LayoutBuilder(
                builder: (context, constraints) {
                  final int columns = isDesktop ? 2 : 1;
                  const double spacing = 18;
                  final double cardWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: credentials.map((c) {
                      return SizedBox(
                        width: cardWidth,
                        child: PalantirGlassPanel(
                          padding: const EdgeInsets.all(22),
                          borderRadius: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['code']!,
                                style: GoogleFonts.sourceCodePro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.secondaryAccent,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c['title']!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LandingTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                c['sub']!,
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
// 14. FINAL CTA BANNER — Institutional Mandate Engagement
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
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 48 : 24,
              vertical: isDesktop ? 48 : 36,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LandingTheme.meshGradient,
              border: Border.all(
                color: LandingTheme.glowAccent.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: LandingTheme.primaryAccent.withValues(alpha: 0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const LuxuryEyebrowBadge(
                  label: 'INSTITUTIONAL ASSET MANDATES',
                  icon: Icons.shield_rounded,
                ),
                const SizedBox(height: 20),
                Text(
                  'Need a Valuation Report That Can Withstand Credit, Audit & Regulatory Review?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isDesktop ? 34 : 24,
                    fontWeight: FontWeight.w800,
                    color: LandingTheme.textPrimary,
                    letterSpacing: -1.0,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    'Connect directly with senior valuation partners for confidential institutional-grade valuation and advisory services.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: LandingTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  alignment: WrapAlignment.center,
                  children: [
                    _ActionButton(
                      label: 'Schedule Consultation',
                      icon: Icons.arrow_forward_rounded,
                      isPrimary: true,
                      onTap: () => launchWhatsApp(
                        'Hello Pro Valuer, I would like to connect directly with a senior valuation partner for an institutional asset advisory.',
                      ),
                    ),
                    _ActionButton(
                      label: 'Download Sample Valuation Report',
                      icon: Icons.file_download_outlined,
                      isPrimary: false,
                      onTap: () => launchWhatsApp(
                        'Hello Pro Valuer, please share your sample institutional valuation report and credentials dossier.',
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
// 15. EXECUTIVE FOOTER — Institutional Dark Navy
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
        horizontal: isDesktop ? AppSpacing.sectionLg : AppSpacing.lg,
        vertical: 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isDesktop ? 4 : 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppComponents.logo(
                          fontSize: 20,
                          darkMode: true,
                          overrideWordmark: LandingTheme.textPrimary,
                          overrideAccent: LandingTheme.secondaryAccent,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Institutional asset valuation, engineering due diligence, and risk advisory for credit committees, private funds, and enterprise asset holders.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: LandingTheme.textMuted,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'IBBI REGISTERED VALUER ENTITY · CHARTERED ENGINEERS',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: LandingTheme.secondaryAccent,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 2,
                      child: _footerCol(
                        'SERVICES',
                        [
                          'Property Valuation',
                          'Land & Cadastral GIS',
                          'Industrial Plant Valuation',
                          'Plant & Machinery',
                          'Infrastructure Assets',
                          'Technical Due Diligence',
                          'Financial Risk Advisory',
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _footerCol(
                        'SECTORS',
                        [
                          'Banks & Financial Institutions',
                          'NBFCs & Private Credit',
                          'Private Equity Funds',
                          'Insolvency (IBC / CIRP)',
                          'Asset Reconstruction',
                          'REITs & InvITs',
                          'Government & PSUs',
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: _footerCol(
                        'COMPLIANCE',
                        [
                          'IBBI Valuation Rules 2017',
                          'Companies Act 2013 §247',
                          'Insolvency & Bankruptcy Code',
                          'SARFAESI Security Valuation',
                          'Ind AS 16 / 36 Fair Value',
                          'Chartered Engineers Division',
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 48),
              const Divider(height: 1, color: LandingTheme.hairlineBorder),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '© ${DateTime.now().year} Pro Valuer. All rights reserved. Institutional reports are confidential and prepared under statutory valuation guidelines.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: LandingTheme.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    '256-BIT ENCRYPTED DOSSIERS',
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: LandingTheme.textMuted,
                      letterSpacing: 0.8,
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

  Widget _footerCol(String header, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: GoogleFonts.sourceCodePro(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: LandingTheme.secondaryAccent,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                link,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: LandingTheme.textSecondary,
                ),
              ),
            )),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 16. MOBILE MENU DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

class MobileMenuDrawer extends StatelessWidget {
  final Future<void> Function(String) launchWhatsApp;

  const MobileMenuDrawer({super.key, required this.launchWhatsApp});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: LandingTheme.secondaryBg,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppComponents.logo(
                    fontSize: 18,
                    darkMode: true,
                    overrideWordmark: LandingTheme.textPrimary,
                    overrideAccent: LandingTheme.secondaryAccent,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: LandingTheme.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _drawerItem('Services', () => Navigator.of(context).pop()),
              _drawerItem('Industries', () => Navigator.of(context).pop()),
              _drawerItem('Why Pro Valuer', () => Navigator.of(context).pop()),
              _drawerItem('Process', () => Navigator.of(context).pop()),
              _drawerItem('Case Studies', () => Navigator.of(context).pop()),
              _drawerItem('Empanelments', () => Navigator.of(context).pop()),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingTheme.surfaceGlassDense,
                    foregroundColor: LandingTheme.textPrimary,
                    side: const BorderSide(color: LandingTheme.hairlineBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Client Login'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    launchWhatsApp('Hello Pro Valuer, I would like to schedule an institutional valuation consultation.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LandingTheme.primaryAccent,
                    foregroundColor: LandingTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Schedule Consultation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: LandingTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
