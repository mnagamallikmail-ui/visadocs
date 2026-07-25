import 'package:flutter/material.dart';

/// AppColors — Strict SaaS Premium Color System
/// Maps to the redesigned Enterprise theme (Linear/Stripe inspired).
class AppColors {
  AppColors._();

  // ── Core Surface & Background ─────────────────────────────────────────────
  /// Page background (#F8FAFC - Slate 50)
  static const Color canvas       = Color(0xFFF8FAFC);
  /// Surface background for cards/modals (#FFFFFF - White)
  static const Color surface      = Color(0xFFFFFFFF);
  /// Subtle offset surface for inner containers (#F1F5F9 - Slate 100)
  static const Color surfaceSoft  = Color(0xFFF1F5F9);
  
  // ── Borders ─────────────────────────────────────────────────────────────
  /// Default borders and dividers (#E2E8F0 - Slate 200)
  static const Color hairline     = Color(0xFFE2E8F0);
  /// Soft borders for inner dividers (#F1F5F9 - Slate 100)
  static const Color hairlineSoft = Color(0xFFF1F5F9);
  /// Strong borders for inputs/focus (#CBD5E1 - Slate 300)
  static const Color hairlineStrong = Color(0xFFCBD5E1);

  // ── Text & Typography ───────────────────────────────────────────────────
  /// Primary headlines and body text (#0F172A - Slate 900)
  static const Color ink          = Color(0xFF0F172A);
  /// Secondary text, metadata, captions (#64748B - Slate 500)
  static const Color slate        = Color(0xFF64748B);
  /// Tertiary muted text (#94A3B8 - Slate 400)
  static const Color steel        = Color(0xFF94A3B8);
  /// Disabled labels (#CBD5E1 - Slate 300)
  static const Color stone        = Color(0xFFCBD5E1);
  /// Pure white for text on dark backgrounds
  static const Color onDark       = Color(0xFFFFFFFF);
  /// Muted white for secondary text on dark
  static const Color onDarkMuted  = Color(0xFF94A3B8);

  // ── Brand Accents (Action) ──────────────────────────────────────────────
  /// Primary Action/Accent (#2563EB - Blue 600)
  static const Color brandBlue    = Color(0xFF2563EB);
  /// Primary Action/Accent Hover (#1D4ED8 - Blue 700)
  static const Color bluePressed  = Color(0xFF1D4ED8);
  /// Very light blue tint for active rows/selections (#EFF6FF - Blue 50)
  static const Color surfacePricingFeatured = Color(0xFFEFF6FF);

  // ── Semantic ────────────────────────────────────────────────────────────
  /// Success/Completed indicator (#10B981 - Emerald 500)
  static const Color successAccent = Color(0xFF10B981);
  /// Success background tint (#D1FAE5 - Emerald 100)
  static const Color successBg     = Color(0xFFD1FAE5);
  
  /// Warning/Pending indicator (#F59E0B - Amber 500)
  static const Color warning       = Color(0xFFF59E0B);
  /// Warning background tint (#FEF3C7 - Amber 100)
  static const Color warningBg     = Color(0xFFFEF3C7);
  
  /// Error/Rejected indicator (#EF4444 - Red 500)
  static const Color brandRedDark  = Color(0xFFEF4444);
  /// Error background tint (#FEE2E2 - Red 100)
  static const Color brandRed      = Color(0xFFFEE2E2);

  // ── Sidebar (Enterprise Soft Neutral - Linear/Claude/Vercel style) ─────
  /// Soft neutral sidebar background (#F8FAFC - Slate 50)
  static const Color sidebarBg       = Color(0xFFF8FAFC);
  /// Active/Selected sidebar state tint (#EFF6FF - Blue 50)
  static const Color sidebarSelected = Color(0xFFEFF6FF);
  /// Sidebar Primary Text (#0F172A - Slate 900)
  static const Color sidebarText     = Color(0xFF0F172A);
  /// Sidebar Muted Text (#64748B - Slate 500)
  static const Color sidebarMuted    = Color(0xFF64748B);
  /// Sidebar Active Accent Indicator (#2563EB - Blue 600)
  static const Color sidebarAccent   = Color(0xFF2563EB);

  // ── Legacy / Backward-compat aliases ────────────────────────────────────
  // Ensuring existing widgets don't break during transition.
  static const Color brandYellow      = Color(0xFFF59E0B); // Mapped to warning
  static const Color brandYellowDeep  = Color(0xFFD97706);
  static const Color yellowLight      = Color(0xFFFEF3C7);
  static const Color yellowDark       = Color(0xFF92400E);
  static const Color brandCoral       = Color(0xFFF97316);
  static const Color coralLight       = Color(0xFFFFEDD5);
  static const Color coralDark        = Color(0xFF9A3412);
  static const Color brandRose        = Color(0xFFEC4899);
  static const Color roseLight        = Color(0xFFFCE7F3);
  static const Color brandTeal        = Color(0xFF14B8A6);
  static const Color tealLight        = Color(0xFFCCFBF1);
  static const Color mossDark         = Color(0xFF115E59);
  static const Color brandPink        = Color(0xFFFBCFE8);
  static const Color brandOrangeLight = Color(0xFFFFEDD5);
  
  static const Color inkDeep          = ink;
  static const Color charcoal         = ink;
  static const Color muted            = stone;
  
  static const Color primary          = brandBlue;
  static const Color onPrimary        = onDark;
  static const Color primaryPressed   = bluePressed;
  static const Color primaryDisabled  = hairlineStrong;
  
  static const Color footerBg         = Color(0xFF0F172A); // Keep footer dark navy
  static const Color white            = surface;
  static const Color background       = canvas;
  static const Color backgroundAlt    = surfaceSoft;
  static const Color border           = hairline;
  static const Color borderDark       = hairlineStrong;
  static const Color textPrimary      = ink;
  static const Color textSecondary    = slate;
  static const Color textMuted        = steel;
  static const Color success          = successAccent;
  static const Color error            = brandRedDark;
  static const Color errorBg          = brandRed;
  static const Color info             = brandBlue;
  static const Color infoBg           = surfacePricingFeatured;
  static const Color structural       = canvas;
  static const Color backgroundSecondary = surfaceSoft;
  static const Color sidebarHover     = Color(0xFFF1F5F9); // Slate 100 on hover
}
