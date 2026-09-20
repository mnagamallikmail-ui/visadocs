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
  static const Color textPrimary = Color(0xFF111827); // Rich Charcoal Black
  static const Color textSecondary = Color(0xFF4B5563); // Readable Slate Grey
  static const Color textMuted = Color(0xFF6B7280); // Restrained Secondary Grey
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Executive Charcoal Accents
  static const Color charcoal = Color(0xFF111827);
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

/// Editorial Eyebrow Tag (Understated, Zero Bubble Backgrounds)
class LuxuryEyebrowBadge extends StatelessWidget {
  final String text;

  const LuxuryEyebrowBadge({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: LandingTheme.charcoal,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: LandingTheme.eyebrow,
        ),
      ],
    );
  }
}
