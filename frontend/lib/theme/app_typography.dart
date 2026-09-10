import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// AppTypography — Clay Enterprise PropTech Type System
/// Font: Inter throughout. Editorial hierarchy.
class AppTypography {
  AppTypography._();

  // ── Internal Helper ───────────────────────────────────────────────────────
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

  // ── Editorial Display Scale ───────────────────────────────────────────────

  /// 72px / 500 / 1.05 — Hero display (desktop)
  static TextStyle displayHero({Color color = AppColors.ink}) => _make(
        size: 72, weight: FontWeight.w500, height: 1.05,
        letterSpacing: -2.0, color: color);

  /// 48px / 500 / 1.08 — Hero display (tablet)
  static TextStyle displayHeroMd({Color color = AppColors.ink}) => _make(
        size: 48, weight: FontWeight.w500, height: 1.08,
        letterSpacing: -1.5, color: color);

  /// 36px / 500 / 1.10 — Hero display (mobile)
  static TextStyle displayHeroSm({Color color = AppColors.ink}) => _make(
        size: 36, weight: FontWeight.w500, height: 1.10,
        letterSpacing: -1.0, color: color);

  /// Responsive hero display
  static TextStyle heroDisplayResponsive(double width, {Color color = AppColors.ink}) {
    final size = width >= 1280
        ? 72.0
        : width >= 1024
            ? 56.0
            : width >= 768
                ? 44.0
                : width >= 480
                    ? 36.0
                    : 30.0;
    final ls = width >= 1280 ? -2.0 : width >= 768 ? -1.5 : -1.0;
    return _make(size: size, weight: FontWeight.w500, height: 1.05,
        letterSpacing: ls, color: color);
  }

  // ── Structural Headings ───────────────────────────────────────────────────

  /// 40px / 500 / 1.15 — Section heading
  static TextStyle sectionHeading({Color color = AppColors.ink}) => _make(
        size: 40, weight: FontWeight.w500, height: 1.15,
        letterSpacing: -1.0, color: color);

  /// 32px / 600 / 1.20 — Page title
  static TextStyle pageTitle({Color color = AppColors.ink}) => _make(
        size: 32, weight: FontWeight.w600, height: 1.20,
        letterSpacing: -0.5, color: color);

  /// 22px / 600 / 1.30 — Section title
  static TextStyle sectionTitle({Color color = AppColors.ink}) => _make(
        size: 22, weight: FontWeight.w600, height: 1.30,
        letterSpacing: -0.3, color: color);

  /// 18px / 600 / 1.35 — Card title
  static TextStyle cardTitle({Color color = AppColors.ink}) => _make(
        size: 18, weight: FontWeight.w600, height: 1.35,
        letterSpacing: -0.2, color: color);

  // ── Body Scale ────────────────────────────────────────────────────────────

  /// 16px / 400 / 1.60 — Standard body
  static TextStyle body({Color color = AppColors.ink,
      double? fontSize, FontWeight? fontWeight}) => _make(
        size: fontSize ?? 16, weight: fontWeight ?? FontWeight.w400,
        height: 1.60, color: color);

  /// 14px / 400 / 1.55 — Small body
  static TextStyle bodySm({Color color = AppColors.slate}) => _make(
        size: 14, weight: FontWeight.w400, height: 1.55, color: color);

  /// 14px / 500 / 1.50 — Small body medium weight
  static TextStyle bodySmMedium({Color color = AppColors.ink}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.50, color: color);

  /// 16px / 400 / 1.60 — Medium body
  static TextStyle bodyMd({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w400, height: 1.60, color: color);

  /// 16px / 500 / 1.50 — Medium body medium weight
  static TextStyle bodyMdMedium({Color color = AppColors.ink}) => _make(
        size: 16, weight: FontWeight.w500, height: 1.50, color: color);

  // ── Utility ───────────────────────────────────────────────────────────────

  /// 13px / 400 / 1.50 — Caption
  static TextStyle caption({Color color = AppColors.slate}) => _make(
        size: 13, weight: FontWeight.w400, height: 1.50, color: color);

  /// 13px / 600 / 1.40 — Caption bold
  static TextStyle captionBold({Color color = AppColors.ink}) => _make(
        size: 13, weight: FontWeight.w600, height: 1.40, color: color);

  /// 11px / 400 / 1.50 — Micro
  static TextStyle micro({Color color = AppColors.steel}) => _make(
        size: 11, weight: FontWeight.w400, height: 1.50, color: color);

  /// 11px / 600 / 1.40 / +0.8 LS — Micro uppercase labels
  static TextStyle microUppercase({Color color = AppColors.stone}) => _make(
        size: 11, weight: FontWeight.w600, height: 1.40,
        letterSpacing: 0.8, color: color);

  /// 14px / 500 / 1.30 — Button label
  static TextStyle buttonMd({Color color = AppColors.onDark}) => _make(
        size: 14, weight: FontWeight.w500, height: 1.30, color: color);

  /// 48px / 600 / 1.10 — Stat display number
  static TextStyle statDisplay({Color color = AppColors.deepTeal}) => _make(
        size: 48, weight: FontWeight.w600, height: 1.10,
        letterSpacing: -1.0, color: color);

  // ── Legacy Alias Map (all existing code continues to work) ────────────────
  static TextStyle heroDisplay({Color color = AppColors.ink}) =>
      pageTitle(color: color);
  static TextStyle displayLg({Color color = AppColors.ink}) =>
      pageTitle(color: color);
  static TextStyle heading1({Color color = AppColors.ink}) =>
      pageTitle(color: color);
  static TextStyle heading2({Color color = AppColors.ink}) =>
      sectionTitle(color: color);
  static TextStyle heading3({Color color = AppColors.ink}) =>
      sectionTitle(color: color);
  static TextStyle heading4({Color color = AppColors.ink}) =>
      cardTitle(color: color);
  static TextStyle heading5({Color color = AppColors.ink}) =>
      cardTitle(color: color);
  static TextStyle subtitle({Color color = AppColors.slate}) =>
      bodyMd(color: color);
  static TextStyle label({Color color = AppColors.slate}) =>
      caption(color: color);
  static TextStyle metadata({Color color = AppColors.slate}) =>
      caption(color: color);
  static TextStyle overline({Color color = AppColors.steel}) =>
      microUppercase(color: color);
  static TextStyle h1({Color color = AppColors.ink}) =>
      pageTitle(color: color);
  static TextStyle h2({Color color = AppColors.ink}) =>
      sectionTitle(color: color);
  static TextStyle h3({Color color = AppColors.ink}) =>
      cardTitle(color: color);

  // ── Document Workspace Typography (Montserrat — Approved Directive) ──────

  static TextStyle _makeMontserrat({
    required double size,
    required FontWeight weight,
    required double height,
    double letterSpacing = 0,
    Color color = AppColors.workspacePrimaryText,
  }) {
    return GoogleFonts.montserrat(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  /// Metadata Labels: SemiBold, 11px–12px, #64748B, letterSpacing 1px, uppercase
  static TextStyle workspaceMetadataLabel({Color color = AppColors.workspaceSecondaryText}) =>
      _makeMontserrat(
        size: 11,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 1.0,
        color: color,
      );

  /// Primary Metadata Values: Medium, 13px–14px, #0F172A
  static TextStyle workspaceMetadataValue({Color color = AppColors.workspacePrimaryText}) =>
      _makeMontserrat(
        size: 13,
        weight: FontWeight.w500,
        height: 1.3,
        letterSpacing: -0.1,
        color: color,
      );

  /// Section Titles: Bold, 16px, #0F172A
  static TextStyle workspaceSectionTitle({Color color = AppColors.workspacePrimaryText}) =>
      _makeMontserrat(
        size: 16,
        weight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: color,
      );

  /// Sidebar / Subsection Heading: SemiBold, 12.5px
  static TextStyle workspaceSidebarItem({
    Color color = AppColors.workspacePrimaryText,
    bool isActive = false,
  }) =>
      _makeMontserrat(
        size: 12.5,
        weight: isActive ? FontWeight.w700 : FontWeight.w600,
        height: 1.3,
        color: color,
      );

  /// Input Text: Regular/Medium, 13px, #0F172A
  static TextStyle workspaceInput({Color color = AppColors.workspacePrimaryText}) =>
      _makeMontserrat(
        size: 13,
        weight: FontWeight.w500,
        height: 1.35,
        color: color,
      );

  /// Input Hint: 12px, #64748B
  static TextStyle workspaceHint({Color color = AppColors.workspaceSecondaryText}) =>
      _makeMontserrat(
        size: 12,
        weight: FontWeight.w400,
        height: 1.35,
        color: color,
      );

  /// Segment / Action Button: Medium/SemiBold, 12px
  static TextStyle workspaceButton({
    Color color = AppColors.workspacePrimaryText,
    FontWeight weight = FontWeight.w600,
    double letterSpacing = 0.2,
  }) =>
      _makeMontserrat(
        size: 12,
        weight: weight,
        height: 1.2,
        letterSpacing: letterSpacing,
        color: color,
      );

  /// Micro Tag / Status: 10px–11px, SemiBold/Bold
  static TextStyle workspaceMicro({
    Color color = AppColors.workspaceSecondaryText,
    FontWeight weight = FontWeight.w600,
  }) =>
      _makeMontserrat(
        size: 10.5,
        weight: weight,
        height: 1.2,
        letterSpacing: 0.3,
        color: color,
      );

  /// Workspace Body: Regular/Medium, 13px, #0F172A
  static TextStyle workspaceBody({
    Color color = AppColors.workspacePrimaryText,
    FontWeight weight = FontWeight.w400,
  }) =>
      _makeMontserrat(
        size: 13,
        weight: weight,
        height: 1.4,
        color: color,
      );
}
