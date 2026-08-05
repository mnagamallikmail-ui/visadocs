import 'package:flutter/material.dart';

/// AppColors — Clay Enterprise PropTech Color System
/// "Warm Cream × Deep Teal" editorial palette.
/// All legacy aliases preserved for zero-breakage downstream.
class AppColors {
  AppColors._();

  // ── Primary Backgrounds ──────────────────────────────────────────────────
  /// Main page canvas — warm cream #FFFAF0
  static const Color canvas       = Color(0xFFFFFAF0);
  /// Soft alt background — #FAF5E8
  static const Color surfaceSoft  = Color(0xFFFAF5E8);
  /// Card background — #F5F0E0
  static const Color cardBg       = Color(0xFFF5F0E0);
  /// Pure white surface (dialogs, dropdowns)
  static const Color surface      = Color(0xFFFFFFFF);

  // ── Borders ──────────────────────────────────────────────────────────────
  /// Default borders — warm tan #E8E0D0
  static const Color hairline       = Color(0xFFE8E0D0);
  /// Soft inner dividers — #F0EAD8
  static const Color hairlineSoft   = Color(0xFFF0EAD8);
  /// Stronger borders for inputs — #D4C8B0
  static const Color hairlineStrong = Color(0xFFD4C8B0);

  // ── Text ─────────────────────────────────────────────────────────────────
  /// Primary — near black #0A0A0A
  static const Color ink            = Color(0xFF0A0A0A);
  /// Secondary — charcoal #3A3A3A
  static const Color textSecondary  = Color(0xFF3A3A3A);
  /// Muted — #6A6A6A
  static const Color textMuted      = Color(0xFF6A6A6A);
  /// Slate — medium grey for captions/labels
  static const Color slate          = Color(0xFF6A6A6A);
  /// Steel — lighter muted text
  static const Color steel          = Color(0xFF8A8A8A);
  /// Stone — disabled text
  static const Color stone          = Color(0xFFB0A898);
  /// On dark — white for dark backgrounds
  static const Color onDark         = Color(0xFFFFFFFF);
  /// Muted on dark
  static const Color onDarkMuted    = Color(0xFFBBB0A0);

  // ── Brand Accents — Clay Enterprise PropTech ─────────────────────────────
  /// Deep Teal — primary action #1A3A3A
  static const Color deepTeal       = Color(0xFF1A3A3A);
  /// Deep Teal pressed — darker hover state
  static const Color deepTealPressed = Color(0xFF122828);
  /// Teal light tint — #E8F4F4
  static const Color tealLight      = Color(0xFFE8F4F4);

  // ── Feature Card Colors (Clay palette) ───────────────────────────────────
  /// Pink — #FF4D8B
  static const Color featurePink       = Color(0xFFFF4D8B);
  static const Color featurePinkLight  = Color(0xFFFFF0F5);
  /// Lavender — #B8A4ED
  static const Color featureLavender   = Color(0xFFB8A4ED);
  static const Color featureLavenderLight = Color(0xFFF4F1FD);
  /// Peach — #FFB084
  static const Color featurePeach      = Color(0xFFFFB084);
  static const Color featurePeachLight = Color(0xFFFFF5EE);
  /// Ochre — #E8B94A
  static const Color featureOchre      = Color(0xFFE8B94A);
  static const Color featureOchreLight = Color(0xFFFFF8E8);
  /// Deep Teal feature card
  static const Color featureTeal       = Color(0xFF1A3A3A);
  static const Color featureTealLight  = Color(0xFFE8F4F4);

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color successAccent = Color(0xFF22C55E);
  static const Color successBg     = Color(0xFFDCFCE7);
  static const Color warning       = Color(0xFFF59E0B);
  static const Color warningBg     = Color(0xFFFEF3C7);
  static const Color brandRedDark  = Color(0xFFEF4444);
  static const Color brandRed      = Color(0xFFFEE2E2);

  // ── Footer ───────────────────────────────────────────────────────────────
  static const Color footerBg      = Color(0xFF0A0A0A);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebarBg       = Color(0xFFFFFAF0); // warm cream sidebar
  static const Color sidebarSelected = Color(0xFFE8F4F4); // teal tint
  static const Color sidebarText     = Color(0xFF0A0A0A);
  static const Color sidebarMuted    = Color(0xFF6A6A6A);
  static const Color sidebarAccent   = Color(0xFF1A3A3A); // deep teal
  static const Color sidebarHover    = Color(0xFFF5F0E0); // card bg

  // ── Legacy Backward-Compat Aliases ───────────────────────────────────────
  // These preserve all existing widget references without any breakage.

  // Primary blue → mapped to deep teal
  static const Color brandBlue          = deepTeal;
  static const Color bluePressed        = deepTealPressed;
  static const Color primary            = deepTeal;
  static const Color onPrimary          = onDark;
  static const Color primaryPressed     = deepTealPressed;
  static const Color primaryDisabled    = hairlineStrong;
  static const Color surfacePricingFeatured = tealLight;

  // Legacy yellow → ochre
  static const Color brandYellow        = featureOchre;
  static const Color brandYellowDeep    = Color(0xFFD4A030);
  static const Color yellowLight        = featureOchreLight;
  static const Color yellowDark         = Color(0xFF7A5A10);

  // Legacy coral → peach
  static const Color brandCoral         = featurePeach;
  static const Color coralLight         = featurePeachLight;
  static const Color coralDark          = Color(0xFF8A4010);

  // Legacy teal → featureTeal/tealLight
  static const Color brandTeal          = deepTeal;
  static const Color tealDark           = deepTealPressed;
  static const Color mossDark           = Color(0xFF0A2020);

  // Legacy rose → pink
  static const Color brandRose          = featurePink;
  static const Color roseLight          = featurePinkLight;
  static const Color brandPink          = featurePinkLight;

  // Legacy orange
  static const Color brandOrangeLight   = featurePeachLight;

  // Text aliases
  static const Color inkDeep            = ink;
  static const Color charcoal           = ink;
  static const Color muted              = stone;
  static const Color textPrimary        = ink;

  // Background aliases
  static const Color background         = canvas;
  static const Color backgroundAlt      = surfaceSoft;
  static const Color backgroundSecondary = surfaceSoft;
  static const Color structural         = canvas;
  static const Color white              = surface;

  // Border aliases
  static const Color border             = hairline;
  static const Color borderDark         = hairlineStrong;

  // Semantic aliases
  static const Color success            = successAccent;
  static const Color error              = brandRedDark;
  static const Color errorBg            = brandRed;
  static const Color info               = deepTeal;
  static const Color infoBg             = tealLight;
}
