import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppTypography — Design.md type system mapped to Flutter TextStyles.
/// Font: Roobert PRO → falls back to Noto Sans → system sans.
/// Weights: 400 (body), 500 (headings/medium), 600 (badges/uppercase).
/// Weight 700 is explicitly NOT used in this design system.
class AppTypography {
  AppTypography._();

  // ── Helper ───────────────────────────────────────────────────────────────
  static TextStyle _make({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.ink,
  }) {
    return GoogleFonts.notoSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ── Scale ────────────────────────────────────────────────────────────────

  /// 80px / 500 / 1.05 / -2px — Marketing hero
  static TextStyle heroDisplay({Color color = AppColors.ink}) => _make(
        size: 80, weight: FontWeight.w500, height: 1.05, letterSpacing: -2, color: color);

  /// 60px / 500 / 1.10 / -1.5px — Major section openers
  static TextStyle displayLg({Color color = AppColors.ink}) => _make(
        size: 60, weight: FontWeight.w500, height: 1.10, letterSpacing: -1.5, color: color);

  /// 48px / 500 / 1.15 / -1px — Page-level headlines
  static TextStyle heading1({Color color = AppColors.ink}) => _make(
        size: 48, weight: FontWeight.w500, height: 1.15, letterSpacing: -1, color: color);

  /// 36px / 500 / 1.20 / -0.5px — Subsection headlines
  static TextStyle heading2({Color color = AppColors.ink}) => _make(
        size: 36, weight: FontWeight.w500, height: 1.20, letterSpacing: -0.5, color: color);

  /// 28px / 500 / 1.25 / 0 — Card titles
  static TextStyle heading3({Color color = AppColors.ink}) => _make(
        size: 28, weight: FontWeight.w500, height: 1.25, color: color);

  /// 22px / 500 / 1.30 / 0 — Feature tile titles
  static TextStyle heading4({Color color = AppColors.ink}) => _make(
        size: 22, weight: FontWeight.w500, height: 1.30, color: color);

  /// 18px / 500 / 1.40 / 0 — FAQ questions, smaller cards
  static TextStyle heading5({Color color = AppColors.ink}) => _make(
        size: 18, weight: FontWeight.w500, height: 1.40, color: color);

  /// 18px / 400 / 1.50 / 0 — Hero subtitle
  static TextStyle subtitle({Color color = AppColors.slate}) => _make(
        size: 18, weight: FontWeight.w400, height: 1.50, color: color);

  /// 16px / 400 / 1.50 / 0 — Primary body text
  static TextStyle bodyMd({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w400, height: 1.50, color: color);

  /// 16px / 500 / 1.50 / 0 — Logo wall labels
  static TextStyle bodyMdMedium({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w500, height: 1.50, color: color);

  /// 14px / 400 / 1.50 / 0 — Secondary body, table cells
  static TextStyle bodySm({Color color = AppColors.slate}) => _make(
        size: 14, weight: FontWeight.w400, height: 1.50, color: color);

  /// 14px / 500 / 1.50 / 0 — Filter dropdowns, button labels
  static TextStyle bodySmMedium({Color color = AppColors.ink}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.50, color: color);

  /// 13px / 400 / 1.40 / 0 — Helper text
  static TextStyle caption({Color color = AppColors.slate}) => _make(
        size: 13, weight: FontWeight.w400, height: 1.40, color: color);

  /// 13px / 600 / 1.40 / 0 — Badge labels, tag chips
  static TextStyle captionBold({Color color = AppColors.ink}) => _make(
        size: 13, weight: FontWeight.w600, height: 1.40, color: color);

  /// 12px / 500 / 1.40 / 0 — Footer microcopy
  static TextStyle micro({Color color = AppColors.steel}) => _make(
        size: 12, weight: FontWeight.w500, height: 1.40, color: color);

  /// 11px / 600 / 1.40 / 0.5px — Section dividers in tables (uppercase)
  static TextStyle microUppercase({Color color = AppColors.stone}) => _make(
        size: 11, weight: FontWeight.w600, height: 1.40, letterSpacing: 0.5, color: color);

  /// 14px / 500 / 1.30 / 0 — Pill button labels
  static TextStyle buttonMd({Color color = AppColors.onPrimary}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.30, color: color);

  /// 64px / 500 / 1.10 / -1.5px — Stat callouts "100M+ users"
  static TextStyle statDisplay({Color color = AppColors.ink}) => _make(
        size: 64, weight: FontWeight.w500, height: 1.10, letterSpacing: -1.5, color: color);

  // ── Responsive hero scaling ───────────────────────────────────────────────
  /// Hero display scaled by breakpoint width
  static TextStyle heroDisplayResponsive(double width, {Color color = AppColors.ink}) {
    final double size = width >= 1280 ? 80 :
                        width >= 1024 ? 64 :
                        width >= 480  ? 48 : 36;
    final double ls   = width >= 1280 ? -2.0 :
                        width >= 1024 ? -1.5 :
                        width >= 480  ? -1.0 : -0.5;
    return _make(size: size, weight: FontWeight.w500, height: 1.05, letterSpacing: ls, color: color);
  }

  // ── Legacy aliases (for backward compat in existing widgets) ─────────────
  static TextStyle body({
    Color color = AppColors.ink,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
  }) => _make(size: fontSize, weight: fontWeight, height: 1.5, color: color);

  static TextStyle label({Color color = AppColors.slate}) =>
      micro(color: color);

  static TextStyle metadata({Color color = AppColors.slate}) =>
      caption(color: color);

  static TextStyle overline({Color color = AppColors.steel}) =>
      microUppercase(color: color);

  static TextStyle sectionTitle({Color color = AppColors.ink}) =>
      heading3(color: color);

  static TextStyle pageTitle({Color color = AppColors.ink}) =>
      heading1(color: color);

  static TextStyle cardTitle({Color color = AppColors.ink}) =>
      heading4(color: color);

  static TextStyle h1({Color color = AppColors.ink}) => heading3(color: color);
  static TextStyle h2({Color color = AppColors.ink}) => heading4(color: color);
  static TextStyle h3({Color color = AppColors.ink}) => heading5(color: color);
}
