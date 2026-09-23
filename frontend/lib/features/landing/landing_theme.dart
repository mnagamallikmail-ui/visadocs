import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-Luxury Architectural & Monochromatic Design Tokens
/// Inspired by: Apple Vision Pro launch films, Foster + Partners, Porsche Design,
/// high-end architectural visualization, and tactile crystal materials.
/// Pure white background, platinum highlights, pearl white, soft graphite, zero tint.
class LandingTheme {
  LandingTheme._();

  // ── Pure White & Monochromatic Pearl Foundation ────────────────────────────
  static const Color primaryBg = Color(0xFFFFFFFF); // Pure White Base
  static const Color secondaryBg = Color(0xFFF8FAFC); // Pearl Slate Ambient
  static const Color tertiaryBg = Color(0xFFEEF2F7); // Light Platinum Tint
  static const Color ambientPearl = Color(0xFFF1F5F9); // Soft Architectural Mists

  // ── Apple Vision Pro Crystal & Frosted Glass Materials ─────────────────────
  static const Color surfaceGlass = Color(0xA6FFFFFF); // rgba(255,255,255,0.65) - Liquid Glass
  static const Color surfaceGlassDense = Color(0xF2FFFFFF); // rgba(255,255,255,0.95) - High Clarity
  static const Color surfaceGlassUltra = Color(0xFAFFFFFF); // rgba(255,255,255,0.98) - Frosted Crystal
  static const Color surfaceGlassLight = Color(0x59FFFFFF); // rgba(255,255,255,0.35) - Spatial Float

  // ── Architectural Platinum & Graphite Material Palette ─────────────────────
  static const Color primaryAccent = Color(0xFF111827); // Deep Graphite / Charcoal
  static const Color brandGreen = Color(0xFF005C5C); // Solid Deep Teal / Institutional Brand Green
  static const Color secondaryAccent = Color(0xFF334155); // Slate Graphite
  static const Color platinumHighlight = Color(0xFFE2E8F0); // Polished Platinum
  static const Color pearlWhite = Color(0xFFF8FAFC); // Pearl White
  static const Color softGraphite = Color(0xFF64748B); // Soft Architectural Graphite
  static const Color accentSubtle = Color(0xFFF1F5F9); // Crisp Platinum Backing

  // ── Crystal Edge & Specular Borders ────────────────────────────────────────
  static const Color hairlineBorder = Color(0x33CBD5E1); // Delicate Platinum Hairline
  static const Color glassBorderTop = Color(0xF2FFFFFF); // Specular Top Highlight (95% White)
  static const Color glassBorderBottom = Color(0x2994A3B8); // Subtle Shadow Catch
  static const Color borderHover = Color(0x8094A3B8); // Platinum active rim
  static const Color borderActive = Color(0xFF111827); // Deep Charcoal Focus

  // ── High-Contrast Luxury Typography ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827); // Deepest Charcoal Slate
  static const Color textSecondary = Color(0xFF64748B); // Soft Graphite Grey
  static const Color textMuted = Color(0xFF94A3B8); // Subdued Caption Grey
  static const Color textTertiary = Color(0xFFCBD5E1); // Micro Annotation Platinum

  // ── Platinum & Specular Editorial Gradients ────────────────────────────────
  static const LinearGradient platinumButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E293B), // Deep Slate
      Color(0xFF0F172A), // Pure Obsidian Graphite
    ],
  );

  static const LinearGradient glassSpecularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // White Specular
      Color(0xFFF8FAFC), // Pearl
      Color(0xFFEEF2F7), // Soft Platinum
    ],
  );

  static const LinearGradient textPlatinumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F172A), // Deep Slate
      Color(0xFF475569), // Soft Graphite
      Color(0xFF1E293B), // Obsidian
    ],
  );

  // ── Multi-Layer Physical Crystal Shadows ──────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% ambient dark slate
      blurRadius: 36,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x05000000), // 2% contact shadow
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x120F172A), // 7% lifted shadow
      blurRadius: 44,
      spreadRadius: -2,
      offset: Offset(0, 24),
    ),
    BoxShadow(
      color: Color(0x0A94A3B8), // 4% subtle platinum caustics
      blurRadius: 28,
      spreadRadius: 0,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x1F0F172A),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ── Editorial Typography Scale (Plus Jakarta Sans / Inter) ─────────────────
  static TextStyle heroHeading(double screenWidth) {
    final double size = screenWidth >= 1280
        ? 78
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
        ? 78
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
