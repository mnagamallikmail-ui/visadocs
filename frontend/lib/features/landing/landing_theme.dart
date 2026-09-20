import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Institutional Asset Intelligence & Valuation Platform Design Tokens
/// Inspired by: BlackRock Aladdin, Palantir Foundry, Bloomberg Terminal, Stripe Enterprise, McKinsey Digital.
class LandingTheme {
  LandingTheme._();

  // ── Institutional Dark Navy Palette ───────────────────────────────────────
  static const Color primaryBg = Color(0xFF07142B); // Deepest Institutional Navy
  static const Color secondaryBg = Color(0xFF0B1F44); // Elevated Midnight Surface
  static const Color tertiaryBg = Color(0xFF0E2554); // Elevated Card Surface
  static const Color surfaceGlass = Color(0x990B1F44); // 60% Frosted Dark Glass
  static const Color surfaceGlassDense = Color(0xCC07142B); // 80% Dense Glass

  // ── Enterprise Blue Accent & Glow System ───────────────────────────────────
  static const Color primaryAccent = Color(0xFF0F4CFF); // Electric Royal Blue
  static const Color secondaryAccent = Color(0xFF5EA8FF); // Vibrant Sky Highlight
  static const Color accentHighlight = Color(0xFF5EA8FF); // Secondary Accent
  static const Color glowAccent = Color(0xFF6CC0FF); // Atmospheric Horizon Glow
  static const Color premiumAccent = Color(0xFF6CC0FF); // Cyan Highlight

  // ── Hairline Institutional Borders ─────────────────────────────────────────
  static const Color hairlineBorder = Color(0x265EA8FF); // rgba(94,168,255,0.15)
  static const Color borderHover = Color(0x665EA8FF); // rgba(94,168,255,0.40)
  static const Color borderActive = Color(0x995EA8FF); // rgba(94,168,255,0.60)

  // ── High-Trust Institutional Typography ────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF); // Pure White High-Contrast
  static const Color textSecondary = Color(0xFFB8C4D9); // Muted Silver Slate
  static const Color textMuted = Color(0xFF8A9BA8); // Subdued Bloomberg Grey
  static const Color textTertiary = Color(0xFF5B6B82); // Micro Footnotes

  // ── Mesh & Signature Gradients ────────────────────────────────────────────
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0F4CFF), Color(0xFF5EA8FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGlowGradient = LinearGradient(
    colors: [Color(0xFF5EA8FF), Color(0xFF6CC0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.35, 0.70, 1.0],
    colors: [
      Color(0xFF07142B),
      Color(0xFF0B1F44),
      Color(0xFF0F4CFF),
      Color(0xFF5EA8FF),
    ],
  );

  // ── Elevated Glass Shadows ────────────────────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0F0F4CFF),
      blurRadius: 16,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x2E0F4CFF),
      blurRadius: 24,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x3D0F4CFF),
      blurRadius: 16,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];

  // ── Editorial Typography Scale ────────────────────────────────────────────
  static TextStyle heroHeading(double screenWidth) {
    final double size = screenWidth >= 1280
        ? 62
        : screenWidth >= 1024
            ? 52
            : screenWidth >= 768
                ? 42
                : screenWidth >= 480
                    ? 34
                    : 28;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: textPrimary,
      letterSpacing: -2.2,
      height: 1.08,
    );
  }

  static TextStyle sectionTitleResponsive(double screenWidth) {
    final double size = screenWidth >= 768 ? 40 : 28;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -1.2,
      height: 1.15,
    );
  }

  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static TextStyle eyebrow = GoogleFonts.inter(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: secondaryAccent,
    letterSpacing: 2.0,
    height: 1.2,
  );

  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.2,
    height: 1.65,
  );

  static TextStyle bodyMediumResponsive(double screenWidth) {
    return GoogleFonts.inter(
      fontSize: screenWidth >= 768 ? 16 : 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      letterSpacing: -0.15,
      height: 1.55,
    );
  }

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.15,
    height: 1.6,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textMuted,
    letterSpacing: -0.1,
    height: 1.55,
  );

  static TextStyle bodySmMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: -0.1,
    height: 1.5,
  );

  static TextStyle statNumeral = GoogleFonts.plusJakartaSans(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    letterSpacing: -2.0,
    height: 1.0,
  );

  static TextStyle button = GoogleFonts.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// PALANTIR GLASS PANEL (Frosted Glass with Hairline Cyan-Blue Border)
// ═══════════════════════════════════════════════════════════════════════════════

class PalantirGlassPanel extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool enableHover;
  final Color? customBorderColor;

  const PalantirGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 12.0,
    this.onTap,
    this.enableHover = true,
    this.customBorderColor,
  });

  @override
  State<PalantirGlassPanel> createState() => _PalantirGlassPanelState();
}

class _PalantirGlassPanelState extends State<PalantirGlassPanel> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget panel = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: widget.padding ?? const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _hovered
            ? LandingTheme.secondaryBg.withValues(alpha: 0.85)
            : LandingTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: _hovered
              ? LandingTheme.borderHover
              : (widget.customBorderColor ?? LandingTheme.hairlineBorder),
          width: 1.0,
        ),
        boxShadow: _hovered ? LandingTheme.hoverShadow : LandingTheme.subtleShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap != null || widget.enableHover) {
      panel = MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: widget.onTap != null
            ? GestureDetector(onTap: widget.onTap, child: panel)
            : panel,
      );
    }

    return panel;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LUXURY INSTITUTIONAL EYEBROW BADGE (Apple Keynote Style)
// ═══════════════════════════════════════════════════════════════════════════════

class LuxuryEyebrowBadge extends StatelessWidget {
  final String? text;
  final String? label;
  final IconData? icon;
  final bool useBlueDot;
  final bool showGradientLine;

  const LuxuryEyebrowBadge({
    super.key,
    this.text,
    this.label,
    this.icon,
    this.useBlueDot = true,
    this.showGradientLine = true,
  });

  String get _display => (label ?? text ?? '').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: LandingTheme.secondaryAccent),
          const SizedBox(width: 8),
        ] else ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: useBlueDot ? LandingTheme.secondaryAccent : LandingTheme.textPrimary,
              shape: BoxShape.circle,
              boxShadow: useBlueDot
                  ? [
                      BoxShadow(
                        color: LandingTheme.glowAccent.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          _display,
          style: LandingTheme.eyebrow,
        ),
        if (showGradientLine) ...[
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  LandingTheme.secondaryAccent.withValues(alpha: 0.6),
                  LandingTheme.glowAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// APPLE STYLE HIGHLIGHT BAR (3px Gradient Accent Line)
// ═══════════════════════════════════════════════════════════════════════════════

class AppleHighlightBar extends StatelessWidget {
  final double width;
  final double height;
  final AlignmentGeometry alignment;

  const AppleHighlightBar({
    super.key,
    this.width = 48,
    this.height = 3.0,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(1.5),
          gradient: LandingTheme.blueGradient,
          boxShadow: [
            BoxShadow(
              color: LandingTheme.primaryAccent.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GRADIENT TEXT (ShaderMask with Electric Royal to Sky Blue Gradient)
// ═══════════════════════════════════════════════════════════════════════════════

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          (gradient ?? LandingTheme.blueGradient).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// FLOATING AMBIENT GLOW SYSTEM (Stripe Atmosphere)
// ═══════════════════════════════════════════════════════════════════════════════

class FloatingAmbientGlow extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  final Alignment alignment;

  const FloatingAmbientGlow({
    super.key,
    this.width = 600,
    this.height = 400,
    this.opacity = 0.05,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                LandingTheme.primaryAccent.withValues(alpha: opacity * 1.5),
                LandingTheme.secondaryAccent.withValues(alpha: opacity * 0.5),
                Colors.transparent,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SIGNATURE BRAND WORD SYSTEM (Palantir / BlackRock Anchors)
// ═══════════════════════════════════════════════════════════════════════════════

class BrandAnchorText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color? accentColor;
  final int? maxLines;
  final TextOverflow? overflow;

  const BrandAnchorText({
    super.key,
    required this.text,
    required this.style,
    this.accentColor,
    this.maxLines,
    this.overflow,
  });

  static final RegExp _pattern = RegExp(
    r'(Valuation|Institutional|Certified|Bank-Accepted|Bank Accepted|Bank Empanelled|Net Worth|IBBI|Chartered Engineers?|Asset Intelligence|Due Diligence)',
    caseSensitive: true,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? LandingTheme.secondaryAccent;
    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in _pattern.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: style,
        ));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: style.copyWith(
          color: effectiveAccent,
          fontWeight: FontWeight.w600,
        ),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
