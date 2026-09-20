import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-Premium Enterprise Design Tokens & Components (Final 20% Reduction Pass)
/// Calmer, cleaner, more spacious.
/// Inspired by: Apple Business, McKinsey Digital, Stripe Enterprise, Notion Enterprise.
class LandingTheme {
  LandingTheme._();

  // ── Architectural Palette ────────────────────────────────────────────────
  static const Color primaryBg = Color(0xFFFFFFFF);
  static const Color secondaryBg = Color(0xFFFAFAFA);
  static const Color surfaceLight = Color(0xFFF9FAFB);
  static const Color surfaceSoft = Color(0xFFF3F4F6);

  // Hairline Rules & Dividers
  static const Color border = Color(0xFFE5E7EB);
  static const Color hairlineBorder = Color(0xFFE5E7EB);
  static const Color borderHover = Color(0xFFD1D5DB);

  // Deep High-Trust Monochromatic Typography
  static const Color textPrimary = Color(0xFF0F172A); // Midnight Navy / Deep Charcoal
  static const Color textSecondary = Color(0xFF4B5563); // Readable Slate Grey
  static const Color textMuted = Color(0xFF6B7280); // Restrained Secondary Grey
  static const Color textTertiary = Color(0xFF9CA3AF);

  // ── Enterprise Blue Accent Strategy (Option F) ───────────────────────────
  static const Color primaryText = Color(0xFF0F172A);
  static const Color secondaryText = Color(0xFF4B5563);
  static const Color primaryAccent = Color(0xFF2563EB); // Royal / Enterprise Blue
  static const Color accentHighlight = Color(0xFF3B82F6); // Electric Blue
  static const Color premiumAccent = Color(0xFF38BDF8); // Sky Blue
  static const Color softBgTint = Color(0xFFEFF6FF); // Ultra-light blue tint

  // Signature Blue Gradient
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Executive Charcoal Accents
  static const Color charcoal = Color(0xFF0F172A);
  static const Color charcoalHover = Color(0xFF000000);

  // High-Density Frosted Surfaces (Barely Noticeable Glass)
  static const Color glassWhite = Color(0xF7FFFFFF); // 97% opacity
  static const Color glassWhiteDense = Color(0xFCFFFFFF); // 99% opacity

  // Calm Micro-Elevations
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x03000000), // 1.2% micro-depth
      blurRadius: 16,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x06000000), // 2.5% micro-depth
      blurRadius: 24,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x02000000),
      blurRadius: 8,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x10111827),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // ── Editorial Typography ────────────────────────────────────────────────
  static TextStyle heroHeading(double screenWidth) {
    final double size = screenWidth >= 1280
        ? 66
        : screenWidth >= 1024
            ? 54
            : screenWidth >= 768
                ? 44
                : screenWidth >= 480
                    ? 34
                    : 29;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -2.5,
      height: 1.05,
    );
  }

  static TextStyle sectionTitleResponsive(double screenWidth) {
    final double size = screenWidth >= 768 ? 42 : 30;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: textPrimary,
      letterSpacing: -1.3,
      height: 1.14,
    );
  }

  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static TextStyle bodyLg = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.2,
    height: 1.7,
  );

  static TextStyle bodyMd = GoogleFonts.plusJakartaSans(
    fontSize: 15.5,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.15,
    height: 1.7,
  );

  static TextStyle bodySm = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: -0.1,
    height: 1.65,
  );

  static TextStyle bodySmMedium = GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: -0.1,
  );

  static TextStyle eyebrow = GoogleFonts.plusJakartaSans(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: textMuted,
    letterSpacing: 1.8,
  );

  static TextStyle button = GoogleFonts.plusJakartaSans(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static TextStyle statNumeral = GoogleFonts.plusJakartaSans(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -2.2,
    height: 1.0,
  );
}

/// Restrained Minimalist Card
/// Zero visual noise, architectural lines, calm breathing room
class LuxuryGlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableHover;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? customBorder;

  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32),
    this.borderRadius = 12,
    this.enableHover = true,
    this.onTap,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  State<LuxuryGlassCard> createState() => _LuxuryGlassCardState();
}

class _LuxuryGlassCardState extends State<LuxuryGlassCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final border = widget.customBorder ??
        Border.all(
          color: _isHovered && widget.enableHover
              ? LandingTheme.borderHover
              : LandingTheme.hairlineBorder,
          width: 1.0,
        );

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.backgroundColor ??
            (_isHovered && widget.enableHover
                ? LandingTheme.glassWhiteDense
                : LandingTheme.primaryBg),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: border,
        boxShadow: _isHovered && widget.enableHover
            ? LandingTheme.hoverShadow
            : LandingTheme.glassShadow,
      ),
      child: widget.child,
    );

    if (widget.onTap != null) {
      content = GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }

    if (widget.enableHover) {
      content = MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: content,
      );
    }

    return content;
  }
}

/// Editorial Eyebrow Tag with Subtle Enterprise Blue Datum Dot & Gradient Line Accent (Option 6)
class LuxuryEyebrowBadge extends StatelessWidget {
  final String text;
  final bool useBlueDot;
  final bool showGradientLine;

  const LuxuryEyebrowBadge({
    super.key,
    required this.text,
    this.useBlueDot = true,
    this.showGradientLine = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: useBlueDot ? LandingTheme.primaryAccent : LandingTheme.charcoal,
            shape: BoxShape.circle,
            boxShadow: useBlueDot
                ? [
                    BoxShadow(
                      color: LandingTheme.primaryAccent.withValues(alpha: 0.45),
                      blurRadius: 4,
                      offset: const Offset(0, 0),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: LandingTheme.eyebrow.copyWith(
            color: LandingTheme.primaryText,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        if (showGradientLine) ...[
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LandingTheme.primaryAccent.withValues(alpha: 0.45),
                  LandingTheme.premiumAccent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Signature Enterprise Blue Gradient Text (Option A & C)
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

/// Floating Blue Ambient Glow System (Option D)
/// Extremely subtle 5-8% opacity radial glow felt subconsciously behind key sections.
class FloatingAmbientGlow extends StatelessWidget {
  final double width;
  final double height;
  final double opacity;
  final Alignment alignment;

  const FloatingAmbientGlow({
    super.key,
    this.width = 600,
    this.height = 400,
    this.opacity = 0.06,
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
                LandingTheme.primaryAccent.withValues(alpha: opacity),
                LandingTheme.premiumAccent.withValues(alpha: opacity * 0.4),
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

/// Signature Brand Word System (Option 9)
/// Highlights only designated institutional brand anchor terms:
/// 'Valuation', 'Institutional', 'Certified', 'Bank-Accepted', 'Bank Accepted',
/// 'Bank Empanelled', 'Net Worth', 'IBBI', 'Chartered Engineer', 'Chartered Engineers'
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
    r'(Valuation|Institutional|Certified|Bank-Accepted|Bank Accepted|Bank Empanelled|Net Worth|IBBI|Chartered Engineers?)',
    caseSensitive: true,
  );

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? LandingTheme.primaryAccent;
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
