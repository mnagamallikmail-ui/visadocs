import 'package:flutter/material.dart';

/// AppColors — Clay Enterprise PropTech Color System
/// "Warm Cream × Deep Teal" editorial palette.
/// All legacy aliases preserved for zero-breakage downstream.
class AppColors {
  AppColors._();

  // ── Primary Backgrounds ──────────────────────────────────────────────────
  /// Main page canvas — neutral cool slate #F8FAFC
  static const Color canvas       = Color(0xFFF8FAFC);
  /// Soft alt background — cool slate-100 #F1F5F9
  static const Color surfaceSoft  = Color(0xFFF1F5F9);
  /// Card background — pure white #FFFFFF
  static const Color cardBg       = Color(0xFFFFFFFF);
  /// Pure white surface (dialogs, dropdowns)
  static const Color surface      = Color(0xFFFFFFFF);

  // ── Borders ──────────────────────────────────────────────────────────────
  /// Default borders — clean neutral gray-200 #E5E7EB
  static const Color hairline       = Color(0xFFE5E7EB);
  /// Soft inner dividers — #F3F4F6
  static const Color hairlineSoft   = Color(0xFFF3F4F6);
  /// Stronger borders for inputs — defined gray-300 #D1D5DB
  static const Color hairlineStrong = Color(0xFFD1D5DB);

  // ── Text ─────────────────────────────────────────────────────────────────
  /// Primary — high contrast near black #111827
  static const Color ink            = Color(0xFF111827);
  /// Secondary — readable slate #4B5563
  static const Color textSecondary  = Color(0xFF4B5563);
  /// Muted — medium gray #6B7280
  static const Color textMuted      = Color(0xFF6B7280);
  /// Slate — medium grey for captions/labels
  static const Color slate          = Color(0xFF4B5563);
  /// Steel — lighter muted text #6B7280
  static const Color steel          = Color(0xFF6B7280);
  /// Stone — disabled / hint text #9CA3AF
  static const Color stone          = Color(0xFF9CA3AF);
  /// On dark — white for dark backgrounds
  static const Color onDark         = Color(0xFFFFFFFF);
  /// Muted on dark
  static const Color onDarkMuted    = Color(0xFF9CA3AF);

  // ── Brand Accents — Professional Appraisal Workstation ───────────────────
  /// Dominant Primary Action Blue — #2563EB (Tailwind Blue-600)
  static const Color primaryBlue       = Color(0xFF2563EB);
  static const Color primaryBluePressed = Color(0xFF1D4ED8);
  static const Color primaryBlueLight  = Color(0xFFEFF6FF);
  /// Focus ring halo (3px rgba(37, 99, 235, 0.16))
  static const Color focusHalo         = Color(0x292563EB);

  /// Domain Brand Teal — deep professional engineering teal #0F4C5C
  static const Color deepTeal          = Color(0xFF0F4C5C);
  static const Color deepTealPressed   = Color(0xFF0A333E);
  static const Color tealLight         = Color(0xFFE6F4F7);
  static const Color brandTeal         = deepTeal;

  // ── Feature Card Colors (Clay palette preserved) ─────────────────────────
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
  static const Color featureTeal       = deepTeal;
  static const Color featureTealLight  = tealLight;

  // ── Semantic ─────────────────────────────────────────────────────────────
  static const Color successAccent = Color(0xFF16A34A); // emerald-600
  static const Color successBg     = Color(0xFFDCFCE7);
  static const Color warning       = Color(0xFFD97706); // amber-600
  static const Color warningBg     = Color(0xFFFEF3C7);
  static const Color brandRedDark  = Color(0xFFDC2626); // red-600
  static const Color brandRed      = Color(0xFFFEE2E2);

  // ── Footer ───────────────────────────────────────────────────────────────
  static const Color footerBg      = Color(0xFF111827);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  static const Color sidebarBg       = Color(0xFFFFFFFF);
  static const Color sidebarSelected = Color(0xFFF0FDF4); // subtle success/progress tint
  static const Color sidebarText     = Color(0xFF111827);
  static const Color sidebarMuted    = Color(0xFF6B7280);
  static const Color sidebarAccent   = Color(0xFF2563EB); // primary blue
  static const Color sidebarHover    = Color(0xFFF1F5F9); // slate-100

  // ── Legacy Backward-Compat Aliases ───────────────────────────────────────
  // These preserve all existing widget references without any breakage.
  static const Color brandBlue          = primaryBlue;
  static const Color bluePressed        = primaryBluePressed;
  static const Color primary            = primaryBlue;
  static const Color onPrimary          = onDark;
  static const Color primaryPressed     = primaryBluePressed;
  static const Color primaryDisabled    = hairlineStrong;
  static const Color surfacePricingFeatured = primaryBlueLight;

  // Legacy yellow → ochre
  static const Color brandYellow        = featureOchre;
  static const Color brandYellowDeep    = Color(0xFFD4A030);
  static const Color yellowLight        = featureOchreLight;
  static const Color yellowDark         = Color(0xFF7A5A10);

  // Legacy coral → peach
  static const Color brandCoral         = featurePeach;
  static const Color coralLight         = featurePeachLight;
  static const Color coralDark          = Color(0xFF8A4010);

  // Legacy teal aliases
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
  static const Color info               = primaryBlue;
  static const Color infoBg             = primaryBlueLight;
}
