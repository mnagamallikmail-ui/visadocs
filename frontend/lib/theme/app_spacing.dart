import 'package:flutter/material.dart';

/// AppSpacing — Design.md spacing tokens (base unit: 4px)
class AppSpacing {
  AppSpacing._();

  static const double xxs       = 4.0;   // {spacing.xxs}
  static const double xs        = 8.0;   // {spacing.xs}
  static const double sm        = 12.0;  // {spacing.sm}
  static const double md        = 16.0;  // {spacing.md}
  static const double lg        = 20.0;  // {spacing.lg}
  static const double xl        = 24.0;  // {spacing.xl}
  static const double xxl       = 32.0;  // {spacing.xxl}
  static const double xxxl      = 40.0;  // {spacing.xxxl}
  static const double sectionSm = 48.0;  // {spacing.section-sm}
  static const double section   = 64.0;  // {spacing.section}
  static const double sectionLg = 96.0;  // {spacing.section-lg}
  static const double hero      = 120.0; // {spacing.hero}

  // Card padding shortcuts
  static const EdgeInsets cardPadding        = EdgeInsets.all(xl);   // 24px compact cards
  static const EdgeInsets cardPaddingFeature = EdgeInsets.all(xxl);  // 32px feature panels
  static const EdgeInsets buttonPadding      = EdgeInsets.symmetric(horizontal: xl, vertical: sm); // 12×24

  // Section padding helpers
  static EdgeInsets pagePadding({bool isDesktop = true}) =>
      EdgeInsets.symmetric(horizontal: isDesktop ? sectionLg : xxl, vertical: isDesktop ? sectionLg : section);
}

/// AppRadius — Design.md border-radius tokens
class AppRadius {
  AppRadius._();

  static const double xs      = 4.0;    // {rounded.xs} — small chips
  static const double sm      = 6.0;    // {rounded.sm} — discount badges
  static const double md      = 8.0;    // {rounded.md} — inputs, search-pill
  static const double lg      = 12.0;   // {rounded.lg} — standard cards, table containers
  static const double xl      = 16.0;   // {rounded.xl} — pricing cards, feature panels
  static const double xxl     = 20.0;   // {rounded.xxl} — larger feature cards
  static const double xxxl    = 28.0;   // {rounded.xxxl} — pastel feature cards
  static const double feature = 32.0;   // {rounded.feature} — hero CTA banner cards
  static const double full    = 9999.0; // {rounded.full} — ALL buttons, pill tabs, badges

  // BorderRadius helpers
  static BorderRadius brXs      = BorderRadius.circular(xs);
  static BorderRadius brSm      = BorderRadius.circular(sm);
  static BorderRadius brMd      = BorderRadius.circular(md);
  static BorderRadius brLg      = BorderRadius.circular(lg);
  static BorderRadius brXl      = BorderRadius.circular(xl);
  static BorderRadius brXxl     = BorderRadius.circular(xxl);
  static BorderRadius brXxxl    = BorderRadius.circular(xxxl);
  static BorderRadius brFeature = BorderRadius.circular(feature);
  static BorderRadius brFull    = BorderRadius.circular(full);
}

/// AppShadows — Design.md elevation model
class AppShadows {
  AppShadows._();

  /// Level 0 — flat (no shadow, hairline-soft border)
  static const List<BoxShadow> flat = [];

  /// Level 1 — subtle hover-elevated tile
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A050038), // rgba(5,0,56,0.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  /// Level 2 — standard feature cards
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F050038), // rgba(5,0,56,0.06)
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Level 3 — hero whiteboard mockup framing
  static const List<BoxShadow> mockup = [
    BoxShadow(
      color: Color(0x14050038), // rgba(5,0,56,0.08)
      blurRadius: 32,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
  ];

  /// Level 4 — modals, dropdowns
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1F050038), // rgba(5,0,56,0.12)
      blurRadius: 48,
      spreadRadius: -8,
      offset: Offset(0, 16),
    ),
  ];
}
