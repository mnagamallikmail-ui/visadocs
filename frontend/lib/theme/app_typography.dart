import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppTypography — Strict SaaS Premium Type System
/// Font: Inter
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
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  // ── Scale ────────────────────────────────────────────────────────────────

  /// 32px / 600 / 1.20 — Page Title
  static TextStyle pageTitle({Color color = AppColors.ink}) => _make(
        size: 32, weight: FontWeight.w600, height: 1.20, letterSpacing: -0.5, color: color);

  /// 22px / 600 / 1.30 — Section Title
  static TextStyle sectionTitle({Color color = AppColors.ink}) => _make(
        size: 22, weight: FontWeight.w600, height: 1.30, letterSpacing: -0.3, color: color);

  /// 16px / 500 / 1.40 — Card Title
  static TextStyle cardTitle({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w500, height: 1.40, letterSpacing: -0.1, color: color);

  /// 14px / 400 / 1.50 — Body
  static TextStyle body({Color color = AppColors.ink, double? fontSize, FontWeight? fontWeight}) => _make(
        size: fontSize ?? 14, weight: fontWeight ?? FontWeight.w400, height: 1.50, color: color);

  /// 12px / 400 / 1.50 — Caption
  static TextStyle caption({Color color = AppColors.slate}) => _make(
        size: 12, weight: FontWeight.w400, height: 1.50, color: color);


  // ── Additional Semantic Styles ───────────────────────────────────────────
  static TextStyle bodySm({Color color = AppColors.slate}) => _make(
        size: 14, weight: FontWeight.w400, height: 1.50, color: color);
  static TextStyle bodySmMedium({Color color = AppColors.ink}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.50, color: color);
  static TextStyle bodyMd({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w400, height: 1.50, color: color);
  static TextStyle bodyMdMedium({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w500, height: 1.50, color: color);
  static TextStyle buttonMd({Color color = AppColors.onDark}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.30, color: color);

  // ── Legacy aliases (for backward compat in existing widgets) ─────────────
  static TextStyle heroDisplay({Color color = AppColors.ink}) => pageTitle(color: color);
  static TextStyle displayLg({Color color = AppColors.ink}) => pageTitle(color: color);
  static TextStyle heading1({Color color = AppColors.ink}) => pageTitle(color: color);
  static TextStyle heading2({Color color = AppColors.ink}) => sectionTitle(color: color);
  static TextStyle heading3({Color color = AppColors.ink}) => sectionTitle(color: color);
  static TextStyle heading4({Color color = AppColors.ink}) => cardTitle(color: color);
  static TextStyle heading5({Color color = AppColors.ink}) => cardTitle(color: color);
  static TextStyle subtitle({Color color = AppColors.slate}) => bodyMd(color: color);
  static TextStyle captionBold({Color color = AppColors.ink}) => _make(
        size: 12, weight: FontWeight.w600, height: 1.40, color: color);
  static TextStyle micro({Color color = AppColors.steel}) => caption(color: color);
  static TextStyle microUppercase({Color color = AppColors.stone}) => _make(
        size: 11, weight: FontWeight.w600, height: 1.40, letterSpacing: 0.5, color: color);
  static TextStyle statDisplay({Color color = AppColors.ink}) => _make(
        size: 48, weight: FontWeight.w600, height: 1.10, letterSpacing: -1.0, color: color);
  static TextStyle heroDisplayResponsive(double width, {Color color = AppColors.ink}) => pageTitle(color: color);
  
  static TextStyle label({Color color = AppColors.slate}) => caption(color: color);
  static TextStyle metadata({Color color = AppColors.slate}) => caption(color: color);
  static TextStyle overline({Color color = AppColors.steel}) => microUppercase(color: color);

  static TextStyle h1({Color color = AppColors.ink}) => pageTitle(color: color);
  static TextStyle h2({Color color = AppColors.ink}) => sectionTitle(color: color);
  static TextStyle h3({Color color = AppColors.ink}) => cardTitle(color: color);
}
