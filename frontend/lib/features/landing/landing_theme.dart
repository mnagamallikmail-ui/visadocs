import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-Luxury Architectural & Institutional Design Tokens
/// Inspired by: Apple Vision Pro, Bentley, Porsche Design, Aman Resorts,
/// Four Seasons Residences, Sotheby's International Realty, Foster + Partners.
/// Pure white background, warm champagne-gold accents, architectural crystal glassmorphism.
class LandingTheme {
  LandingTheme._();

  // ── Pure White & Warm Ambient Spatial Palette ──────────────────────────────
  static const Color primaryBg = Color(0xFFFFFFFF); // Pure White Base
  static const Color secondaryBg = Color(0xFFFAF8F4); // Warm Sand / Alabaster Ambient
  static const Color tertiaryBg = Color(0xFFF5F1EA); // Warm Crystal Tint
  static const Color ambientWarmTint = Color(0xFFFBF9F5); // Ethereal Warm Glow

  // ── Apple Vision Pro Crystal Glass Materials ──────────────────────────────
  static const Color surfaceGlass = Color(0x99FFFFFF); // rgba(255,255,255,0.60) - Liquid Glass
  static const Color surfaceGlassDense = Color(0xEBFFFFFF); // rgba(255,255,255,0.92) - High Clarity
  static const Color surfaceGlassUltra = Color(0xF7FFFFFF); // rgba(255,255,255,0.97) - Frosted Crystal
  static const Color surfaceGlassLight = Color(0x59FFFFFF); // rgba(255,255,255,0.35) - Spatial Float

  // ── Luxury Champagne Gold & Architectural Bronze System ───────────────────
  static const Color primaryAccent = Color(0xFFC6A76A); // Champagne Gold / Bronze
  static const Color secondaryAccent = Color(0xFFE8D3A5); // Soft Champagne Gold
  static const Color glassReflection = Color(0xFFF4E8CB); // Warm Crystal Light
  static const Color softSurface = Color(0xFFFAF8F4); // Alabaster Surface
  static const Color accentSubtle = Color(0xFFFBF8F2); // Warm Ivory Backing

  // ── Crystal Edge & Specular Borders ────────────────────────────────────────
  static const Color hairlineBorder = Color(0x33C6A76A); // Delicate Gold Hairline
  static const Color glassBorderTop = Color(0xF2FFFFFF); // Specular Top Highlight (95% White)
  static const Color glassBorderBottom = Color(0x29C6A76A); // Warm Shadow Catch
  static const Color borderHover = Color(0x80C6A76A); // Gold Light-catching active rim
  static const Color borderActive = Color(0xFFC6A76A); // Focus edge

  // ── High-Contrast Luxury Typography ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827); // Deepest Charcoal Slate
  static const Color textSecondary = Color(0xFF6B7280); // Sophisticated Cool Grey
  static const Color textMuted = Color(0xFF9CA3AF); // Subdued Caption Grey
  static const Color textTertiary = Color(0xFFCBD5E1); // Micro Annotation Grey

  // ── Architectural Champagne Gold Gradients ────────────────────────────────
  static const LinearGradient goldAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC6A76A), // Rich Champagne Gold
      Color(0xFFDFCA9B), // Luminous Highlight Gold
    ],
  );

  static const LinearGradient goldSpecularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFAF8F4), // Alabaster
      Color(0xFFF4E8CB), // Warm Crystal
      Color(0xFFFFFFFF), // White Specular
    ],
  );

  static const LinearGradient textGoldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB8934C), // Deep Bronze Gold
      Color(0xFFC6A76A), // Pure Champagne Gold
      Color(0xFFE8D3A5), // Soft Gold Reflection
    ],
  );

  // ── Multi-Layer Physical Crystal Shadows ──────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0A111827), // 4% ambient dark slate
      blurRadius: 36,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x0F000000), // 6% contact shadow
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x14111827), // 8% lifted shadow
      blurRadius: 44,
      spreadRadius: -2,
      offset: Offset(0, 24),
    ),
    BoxShadow(
      color: Color(0x24C6A76A), // 14% warm champagne gold caustics
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x08111827),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x38C6A76A),
      blurRadius: 22,
      offset: Offset(0, 8),
    ),
  ];

  // ── Editorial Typography Scale (Plus Jakarta Sans / Inter) ─────────────────
  static TextStyle heroHeading(double screenWidth) {
    final double size = screenWidth >= 1280
        ? 76
        : screenWidth >= 1024
            ? 64
            : screenWidth >= 768
                ? 48
                : 36;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: textPrimary,
      letterSpacing: -2.8,
      height: 1.05,
    );
  }

  static TextStyle heroKeyword(double screenWidth) {
    final double size = screenWidth >= 1280
        ? 76
        : screenWidth >= 1024
            ? 64
            : screenWidth >= 768
                ? 48
                : 36;
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: primaryAccent,
      letterSpacing: -2.8,
      height: 1.05,
    );
  }

  static TextStyle sectionTitleResponsive(double screenWidth) {
    final double size = screenWidth >= 1024 ? 44 : (screenWidth >= 768 ? 36 : 28);
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: textPrimary,
      letterSpacing: -1.6,
      height: 1.15,
    );
  }

  static TextStyle cardTitle = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.6,
    height: 1.3,
  );

  static TextStyle eyebrow = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: primaryAccent,
    letterSpacing: 1.8,
    height: 1.2,
  );

  static TextStyle bodyLargeResponsive(double screenWidth) {
    final double size = screenWidth >= 768 ? 19 : 16;
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      letterSpacing: -0.3,
      height: 1.6,
    );
  }

  static TextStyle bodyMediumResponsive(double screenWidth) {
    final double size = screenWidth >= 768 ? 16 : 14.5;
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      letterSpacing: -0.2,
      height: 1.6,
    );
  }
}
