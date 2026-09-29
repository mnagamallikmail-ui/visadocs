import 'package:flutter/material.dart';

/// AppColors — Clay Enterprise PropTech Color System
/// "Warm Cream × Deep Teal" editorial palette.
/// All legacy aliases preserved for zero-breakage downstream.
class AppColors {
  AppColors._();

  // ── Enterprise Primary Brand & Shell (#0F172A) ────────────────────────────
  /// Primary Brand Navy — top navigation, headings, structural anchors #0F172A
  static const Color brandNavy        = Color(0xFF0F172A);
  static const Color brandNavyLight   = Color(0xFF1E293B);

  // ── Enterprise Primary Action (#2563EB) ──────────────────────────────────
  /// The ONLY interactive action accent color
  static const Color primaryBlue       = Color(0xFF2563EB);
  static const Color primaryBluePressed = Color(0xFF1D4ED8);
  static const Color primaryBlueLight  = Color(0xFFEFF6FF);
  static const Color focusHalo         = Color(0x292563EB); // 3px rgba(37, 99, 235, 0.16)

  // ── Enterprise Monochromatic Neutral Scale ───────────────────────────────
  /// Main application base canvas — #F8FAFC
  static const Color canvas           = Color(0xFFF8FAFC);
  /// Pure white surfaces (cards, sheets, dropdowns, dialogs) — #FFFFFF
  static const Color surface          = Color(0xFFFFFFFF);
  static const Color cardBg           = Color(0xFFFFFFFF);
  /// Subtle surface (table header bands, disabled fills, segment chips) — #F1F5F9
  static const Color surfaceSoft      = Color(0xFFF1F5F9);
  /// Standard 1px borders & dividers — #E2E8F0
  static const Color hairline         = Color(0xFFE2E8F0);
  static const Color hairlineSoft     = Color(0xFFE2E8F0);
  /// Defined borders for inputs / active elements — #CBD5E1
  static const Color hairlineStrong   = Color(0xFFCBD5E1);

  // ── Enterprise Typography Colors ─────────────────────────────────────────
  /// High-contrast primary text & major headings — #0F172A
  static const Color ink              = Color(0xFF0F172A);
  /// Secondary muted text, metadata, labels — #475569
  static const Color slate            = Color(0xFF475569);
  static const Color textSecondary    = Color(0xFF475569);
  static const Color textMuted        = Color(0xFF475569);
  /// Placeholder hints & inactive states — #94A3B8
  static const Color steel            = Color(0xFF94A3B8);
  static const Color stone            = Color(0xFF94A3B8);
  static const Color onDark           = Color(0xFFFFFFFF);
  static const Color onDarkMuted      = Color(0xFF94A3B8);

  // ── Enterprise Semantic States ───────────────────────────────────────────
  /// Success — verified, approved, completed #047857
  static const Color successAccent    = Color(0xFF047857);
  static const Color successBg        = Color(0xFFECFDF5);
  static const Color successBorder    = Color(0xFFA7F3D0);

  /// Error — failures, validation alerts, destructive states #B91C1C
  static const Color brandRedDark     = Color(0xFFB91C1C);
  static const Color brandRed         = Color(0xFFFEF2F2);
  static const Color errorBorder      = Color(0xFFFECACA);

  /// Warning — genuine alerts only #B45309
  static const Color warning          = Color(0xFFB45309);
  static const Color warningBg        = Color(0xFFFFFBEB);
  static const Color warningBorder    = Color(0xFFFDE68A);

  // ── Enterprise Template Placeholder Tokens (Border-Only Architecture) ───
  /// Template placeholder-backed inputs: 1.5px solid #94A3B8 on white background
  static const Color placeholderBorder       = Color(0xFF94A3B8);
  static const Color placeholderSurface      = Color(0xFFFFFFFF);
  static const Color placeholderText         = Color(0xFF0F172A);
  static const Color placeholderBadgeBg      = Color(0xFFF1F5F9);
  static const Color placeholderBadgeBorder  = Color(0xFFE2E8F0);
  static const Color placeholderBadgeText    = Color(0xFF475569);

  // ── Document Workspace Aliases (Unified with Enterprise Scale) ───────────
  static const Color workspaceCanvas            = canvas;
  static const Color workspacePanel             = surface;
  static const Color workspacePrimaryText       = ink;
  static const Color workspaceSecondaryText     = slate;
  static const Color workspaceBorder            = hairline;
  static const Color workspaceSegmentBg         = surfaceSoft;
  static const Color workspaceSuccess           = successAccent;
  static const Color workspaceWarning           = warning;
  static const Color workspaceErrorSurface      = brandRed;
  static const Color workspaceErrorText         = brandRedDark;
  static const Color workspaceCorporateNavy     = brandNavy;
  static const Color workspaceCorporateNavyHover= brandNavyLight;
  static const Color workspaceFocusGlow         = focusHalo;
  static const Color workspaceTeal              = brandNavy;

  // ── Deprecated/Retired Brand Accents (Safely Mapped to Enterprise Tokens) ──
  /// Legacy deepTeal retired — mapped cleanly to Brand Navy / Primary Blue
  static const Color deepTeal           = brandNavy;
  static const Color deepTealPressed    = brandNavyLight;
  static const Color tealLight          = surfaceSoft;
  static const Color brandTeal          = brandNavy;

  // ── Legacy Aliases Preserved for Downstream Safety ─────────────────────────
  static const Color brandBlue          = primaryBlue;
  static const Color bluePressed        = primaryBluePressed;
  static const Color primary            = primaryBlue;
  static const Color onPrimary          = onDark;
  static const Color primaryPressed     = primaryBluePressed;
  static const Color primaryDisabled    = hairlineStrong;
  static const Color surfacePricingFeatured = primaryBlueLight;

  static const Color featurePink        = surfaceSoft;
  static const Color featurePinkLight   = surfaceSoft;
  static const Color featureLavender    = surfaceSoft;
  static const Color featureLavenderLight= surfaceSoft;
  static const Color featurePeach       = surfaceSoft;
  static const Color featurePeachLight  = surfaceSoft;
  static const Color featureOchre       = surfaceSoft;
  static const Color featureOchreLight  = surfaceSoft;
  static const Color featureTeal        = brandNavy;
  static const Color featureTealLight   = surfaceSoft;

  static const Color brandYellow        = warning;
  static const Color brandYellowDeep    = warning;
  static const Color yellowLight        = warningBg;
  static const Color yellowDark         = warning;

  static const Color brandCoral         = warning;
  static const Color coralLight         = warningBg;
  static const Color coralDark          = warning;

  static const Color tealDark           = brandNavyLight;
  static const Color mossDark           = brandNavy;

  static const Color brandRose          = brandRedDark;
  static const Color roseLight          = brandRed;
  static const Color brandPink          = brandRed;
  static const Color brandOrangeLight   = warningBg;

  static const Color inkDeep            = ink;
  static const Color charcoal           = ink;
  static const Color muted              = steel;
  static const Color textPrimary        = ink;

  static const Color background         = canvas;
  static const Color backgroundAlt      = surfaceSoft;
  static const Color backgroundSecondary= surfaceSoft;
  static const Color structural         = canvas;
  static const Color white              = surface;

  static const Color border             = hairline;
  static const Color borderDark         = hairlineStrong;

  static const Color success            = successAccent;
  static const Color brandGreen         = successAccent;
  static const Color brandGreenSoft     = successBg;
  static const Color brandRedSoft       = brandRed;
  static const Color error              = brandRedDark;
  static const Color errorBg            = brandRed;
  static const Color info               = primaryBlue;
  static const Color infoBg             = primaryBlueLight;

  static const Color footerBg           = brandNavy;
  static const Color sidebarBg          = surface;
  static const Color sidebarSelected    = primaryBlueLight;
  static const Color sidebarText        = ink;
  static const Color sidebarMuted       = slate;
  static const Color sidebarAccent      = primaryBlue;
  static const Color sidebarHover       = surfaceSoft;
}

