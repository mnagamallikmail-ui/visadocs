/// design_system.dart — backward-compatibility shim
/// All new code should import from:
///   app_colors.dart, app_typography.dart, app_spacing.dart,
///   app_components.dart, app_theme.dart
///
/// Existing files that import DesignSystem continue to compile unchanged.
library design_system;

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_components.dart';

export 'app_colors.dart';
export 'app_typography.dart';
export 'app_spacing.dart';
export 'app_components.dart';
export 'app_theme.dart';

/// DesignSystem — shim that exposes the same API surface as before,
/// but delegates to the new Design.md token classes.
class DesignSystem {
  DesignSystem._();

  // ── Colors (all delegate to AppColors) ───────────────────────────────────
  static const Color black              = AppColors.inkDeep;
  static const Color white              = AppColors.surface;
  static const Color background         = AppColors.canvas;
  static const Color backgroundAlt      = AppColors.surfaceSoft;
  static const Color surface            = AppColors.surface;
  static const Color border             = AppColors.hairline;
  static const Color borderDark         = AppColors.hairlineStrong;
  static const Color structural         = AppColors.surface;
  static const Color textPrimary        = AppColors.ink;
  static const Color textSecondary      = AppColors.slate;
  static const Color textMuted          = AppColors.steel;
  static const Color primaryNavy        = AppColors.primary;
  static const Color primary            = AppColors.brandBlue;  // legacy "blue" action
  static const Color primaryDark        = AppColors.bluePressed;
  static const Color primaryLight       = AppColors.surfacePricingFeatured;
  static const Color primaryBorder      = AppColors.sidebarAccent;
  static const Color secondary          = AppColors.brandBlue;
  static const Color secondaryDark      = AppColors.bluePressed;
  static const Color backgroundSecondary = AppColors.backgroundSecondary;
  static const Color success            = AppColors.successAccent;
  static const Color successBg          = AppColors.successBg;
  static const Color warning            = AppColors.warning;
  static const Color warningBg          = AppColors.warningBg;
  static const Color error              = AppColors.brandRedDark;
  static const Color errorBg            = AppColors.brandRed;
  static const Color info               = AppColors.brandBlue;
  static const Color infoBg             = AppColors.infoBg;
  static const Color sidebarBg          = AppColors.sidebarBg;
  static const Color sidebarSelected    = AppColors.sidebarSelected;
  static const Color sidebarText        = AppColors.sidebarText;
  static const Color sidebarMuted       = AppColors.sidebarMuted;
  static const Color sidebarAccent      = AppColors.sidebarAccent;
  static const Color sidebarHover       = AppColors.sidebarHover;

  // ── Spacing (delegate to AppSpacing) ─────────────────────────────────────
  static const double space4  = AppSpacing.xxs;
  static const double space8  = AppSpacing.xs;
  static const double space12 = AppSpacing.sm;
  static const double space16 = AppSpacing.md;
  static const double space20 = AppSpacing.lg;
  static const double space24 = AppSpacing.xl;
  static const double space32 = AppSpacing.xxl;
  static const double space48 = AppSpacing.sectionSm;
  static const double space64 = AppSpacing.section;

  // ── Typography (delegate to AppTypography) ────────────────────────────────
  static TextStyle heroTitle({Color color = AppColors.ink}) =>
      AppTypography.heroDisplay(color: color);

  static TextStyle pageTitle({Color color = AppColors.ink}) =>
      AppTypography.heading1(color: color);

  static TextStyle sectionTitle({Color color = AppColors.ink}) =>
      AppTypography.heading3(color: color);

  static TextStyle h1({Color color = AppColors.ink}) =>
      AppTypography.h1(color: color);

  static TextStyle cardTitle({Color color = AppColors.ink}) =>
      AppTypography.heading4(color: color);

  static TextStyle h2({Color color = AppColors.ink}) =>
      AppTypography.h2(color: color);

  static TextStyle h3({Color color = AppColors.ink}) =>
      AppTypography.h3(color: color);

  static TextStyle body({
    Color color = AppColors.ink,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
  }) =>
      AppTypography.body(color: color, fontSize: fontSize, fontWeight: fontWeight);

  static TextStyle metadata({Color color = AppColors.slate}) =>
      AppTypography.caption(color: color);

  static TextStyle label({Color color = AppColors.slate}) =>
      AppTypography.micro(color: color);

  static TextStyle overline({Color color = AppColors.steel}) =>
      AppTypography.microUppercase(color: color);

  // ── Button Styles (delegate to AppComponents) ─────────────────────────────
  static ButtonStyle get primaryButton  => AppComponents.primaryButtonStyle();
  static ButtonStyle get secondaryButton => AppComponents.secondaryButtonStyle();
  static ButtonStyle get premiumButton  => AppComponents.blueButtonStyle();
  static ButtonStyle get dangerButton   => AppComponents.dangerButton;
  static ButtonStyle get outlinedButton => AppComponents.secondaryButtonStyle();

  // ── Card Decoration ───────────────────────────────────────────────────────
  static BoxDecoration get cardDecoration => AppComponents.cardDecoration;

  // ── Logo Widget ───────────────────────────────────────────────────────────
  static Widget logo({
    double fontSize = 22,
    Color? overrideBlue,
    Color? overrideGold,
    bool darkMode = false,
  }) =>
      AppComponents.logo(fontSize: fontSize, darkMode: darkMode);
}
