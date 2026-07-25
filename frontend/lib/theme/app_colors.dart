import 'package:flutter/material.dart';

/// AppColors — Design.md color tokens
/// Maps exactly to the Miro-inspired palette specified in Design.md.
/// Use ONLY these tokens; never hardcode colors in UI code.
class AppColors {
  AppColors._();

  // ── Brand & Accent ──────────────────────────────────────────────────────
  /// Miro canary yellow — wordmark, promo banner, yellow-tag chips ONLY
  static const Color brandYellow      = Color(0xFFFFD02B);
  /// Darker hover variant of brand yellow
  static const Color brandYellowDeep  = Color(0xFFE5B800);
  /// Pale yellow background tint for tag chips
  static const Color yellowLight      = Color(0xFFFFF8D6);
  /// Yellow-tag text (dark olive) for chip foreground
  static const Color yellowDark       = Color(0xFF5C4B00);
  /// Action blue — inline links, featured-pricing border
  static const Color brandBlue        = Color(0xFF1A73E8);
  /// Pressed-state blue
  static const Color bluePressed      = Color(0xFF1557B0);
  /// Coral accent for warm callouts
  static const Color brandCoral       = Color(0xFFFF6B47);
  /// Pale coral for feature card backgrounds
  static const Color coralLight       = Color(0xFFFFEDE8);
  /// Coral-tag text (deep wine)
  static const Color coralDark        = Color(0xFF7A1F00);
  /// Soft rose-pink for feature card variants
  static const Color brandRose        = Color(0xFFF9A8C9);
  /// Pale rose for feature card backgrounds
  static const Color roseLight        = Color(0xFFFFF0F5);
  /// Brand teal
  static const Color brandTeal        = Color(0xFF00B8A9);
  /// Pale teal for feature card backgrounds
  static const Color tealLight        = Color(0xFFE0FAF7);
  /// Deep teal-green text color (moss)
  static const Color mossDark         = Color(0xFF004D47);
  /// Pale pink for soft callouts
  static const Color brandPink        = Color(0xFFFCE4EC);
  /// Soft orange for feature card backgrounds
  static const Color brandOrangeLight = Color(0xFFFFF3E0);

  // ── Surface ─────────────────────────────────────────────────────────────
  /// Page background and primary card surface (stark white canvas)
  static const Color canvas                = Color(0xFFFFFFFF);
  /// Subtle section backgrounds, search-pill rest
  static const Color surface               = Color(0xFFF7F7F7);
  /// Quieter section divisions
  static const Color surfaceSoft           = Color(0xFFFAFAFA);
  /// Pale yellow-tinted surface for tag chip
  static const Color surfaceYellow         = Color(0xFFFFF8D6);
  /// Pale lavender for featured pricing tier
  static const Color surfacePricingFeatured = Color(0xFFEEF2FF);
  /// 1px borders and primary dividers
  static const Color hairline             = Color(0xFFE0E0E0);
  /// Quieter table-row dividers
  static const Color hairlineSoft         = Color(0xFFEEEEEE);
  /// Stronger 1px border for inputs
  static const Color hairlineStrong       = Color(0xFFBDBDBD);

  // ── Text ────────────────────────────────────────────────────────────────
  /// Headlines on lighter feature cards
  static const Color inkDeep     = Color(0xFF0A0A0A);
  /// Primary headlines and body text
  static const Color ink         = Color(0xFF1A1A1A);
  /// Body emphasis text
  static const Color charcoal    = Color(0xFF2D2D2D);
  /// Secondary text, metadata
  static const Color slate       = Color(0xFF616161);
  /// Tertiary text, footer links
  static const Color steel       = Color(0xFF9E9E9E);
  /// Captions, muted labels
  static const Color stone       = Color(0xFFBDBDBD);
  /// Disabled labels, input placeholders
  static const Color muted       = Color(0xFFD4D4D4);
  /// White text on dark surfaces
  static const Color onDark      = Color(0xFFFFFFFF);
  /// Reduced-opacity white on dark
  static const Color onDarkMuted = Color(0xFFAAAAAA);

  // ── Primary & UI ────────────────────────────────────────────────────────
  /// Black — dominant primary CTA color
  static const Color primary   = Color(0xFF1A1A1A);
  /// White — text on primary (black) surfaces
  static const Color onPrimary = Color(0xFFFFFFFF);
  /// Dark charcoal — pressed state for primary buttons
  static const Color primaryPressed = Color(0xFF2D2D2D);
  /// Disabled button background
  static const Color primaryDisabled = Color(0xFFE0E0E0);

  // ── Semantic ────────────────────────────────────────────────────────────
  /// Confirmation/success indicator green
  static const Color successAccent = Color(0xFF1E8C45);
  /// Soft red for error backgrounds
  static const Color brandRed      = Color(0xFFFFEBEE);
  /// Stronger red for error borders
  static const Color brandRedDark  = Color(0xFFE53935);

  // ── Footer ──────────────────────────────────────────────────────────────
  /// Massive dark footer background
  static const Color footerBg = Color(0xFF111111);

  // ── Legacy / Backward-compat aliases (used by existing providers/services)
  static const Color white           = canvas;
  static const Color background      = surface;
  static const Color backgroundAlt   = surfaceSoft;
  static const Color border          = hairline;
  static const Color borderDark      = hairlineStrong;
  static const Color textPrimary     = ink;
  static const Color textSecondary   = slate;
  static const Color textMuted       = steel;
  static const Color success         = successAccent;
  static const Color successBg       = Color(0xFFF0FDF4);
  static const Color warning         = Color(0xFFF59E0B);
  static const Color warningBg       = Color(0xFFFFFBEB);
  static const Color error           = brandRedDark;
  static const Color errorBg         = brandRed;
  static const Color info            = brandBlue;
  static const Color infoBg          = Color(0xFFEFF6FF);
  static const Color structural      = surface;
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  // ── Sidebar ──────────────────────────────────────────────────────────────
  /// Premium monochrome sidebar foundation
  static const Color sidebarBg       = inkDeep;
  /// Subtle charcoal for hover/selected states
  static const Color sidebarSelected = Color(0xFF1F1F1F);
  /// Crisp white for active text
  static const Color sidebarText     = onDark;
  /// Muted gray for inactive text
  static const Color sidebarMuted    = stone;
  /// Warm yellow accent for active indicator
  static const Color sidebarAccent   = brandYellow;
}
