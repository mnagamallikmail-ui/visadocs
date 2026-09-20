import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ultra-Luxury Modern Design Tokens (Apple Vision Pro, Stripe, Linear, Arc)
/// Pure white luxury experience, crystal glassmorphism, editorial typography.
class LandingTheme {
  LandingTheme._();

  // ── Pure White & Ambient Spatial Palette ───────────────────────────────────
  static const Color primaryBg = Color(0xFFFFFFFF); // Pure White Base
  static const Color secondaryBg = Color(0xFFF8FAFC); // Subtle Ambient Slate
  static const Color tertiaryBg = Color(0xFFF1F5F9); // Light Crystal Tint
  static const Color ambientBlueTint = Color(0xFFEFF6FF); // Ethereal Blue Glow

  // ── Apple Vision Pro Crystal Glass Materials ──────────────────────────────
  static const Color surfaceGlass = Color(0x8CFFFFFF); // rgba(255,255,255,0.55) - Liquid Glass
  static const Color surfaceGlassDense = Color(0xD9FFFFFF); // rgba(255,255,255,0.85) - High Clarity
  static const Color surfaceGlassUltra = Color(0xF2FFFFFF); // rgba(255,255,255,0.95) - Frosted Crystal
  static const Color surfaceGlassLight = Color(0x4DFFFFFF); // rgba(255,255,255,0.30) - Spatial Float

  // ── Refined Accent System ──────────────────────────────────────────────────
  static const Color primaryAccent = Color(0xFF2563EB); // Royal Blue
  static const Color accentLight = Color(0xFF93C5FD); // Crystalline Sky Blue
  static const Color secondaryAccent = Color(0xFF3B82F6); // Electric Accent
  static const Color accentGlow = Color(0xFF60A5FA); // Radiant Light Sweep
  static const Color accentSubtle = Color(0xFFEFF6FF); // Delicate Blue Backing

  // ── Crystal Edge & Specular Borders ────────────────────────────────────────
  static const Color hairlineBorder = Color(0x99E2E8F0); // Delicate Hairline Border
  static const Color glassBorderTop = Color(0xE6FFFFFF); // Specular Top Highlight (90% White)
  static const Color glassBorderBottom = Color(0x3394A3B8); // Subtle Shadow Catch (20% Slate)
  static const Color borderHover = Color(0x8093C5FD); // Light-catching active rim
  static const Color borderActive = Color(0xFF2563EB); // Focus edge

  // ── High-Contrast Luxury Typography ────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827); // Deepest Charcoal Slate
  static const Color textSecondary = Color(0xFF6B7280); // Sophisticated Cool Grey
  static const Color textMuted = Color(0xFF9CA3AF); // Subdued Caption Grey
  static const Color textTertiary = Color(0xFFCBD5E1); // Micro Annotation Grey

  // ── Apple Vision Pro Glass Gradients ──────────────────────────────────────
  static const LinearGradient glassSpecularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xCCFFFFFF), // 80% white highlight
      Color(0x66FFFFFF), // 40% white midtone
      Color(0x40F8FAFC), // soft ambient falloff
    ],
  );

  static const LinearGradient blueAccentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2563EB),
      Color(0xFF3B82F6),
    ],
  );

  static const LinearGradient textShimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF111827),
      Color(0xFF2563EB),
      Color(0xFF111827),
    ],
  );

  // ── Multi-Layer Physical Crystal Shadows ──────────────────────────────────
  static const List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% ambient black
      blurRadius: 32,
      spreadRadius: 0,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x050F172A), // 2% contact shadow
      blurRadius: 8,
      spreadRadius: 0,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x140F172A), // 8% lifted shadow
      blurRadius: 40,
      spreadRadius: -2,
      offset: Offset(0, 24),
    ),
    BoxShadow(
      color: Color(0x1A2563EB), // 10% ethereal blue caustics
      blurRadius: 30,
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
      color: Color(0x332563EB),
      blurRadius: 20,
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
