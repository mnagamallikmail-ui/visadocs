import 'package:flutter/material.dart';

/// AppSpacing — Clay Enterprise PropTech spacing system
/// Preserves all existing constants, updates radius tokens.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
  static const double xxxl     = 48.0;
  static const double sectionSm = 48.0;
  static const double section   = 64.0;
  static const double sectionLg = 80.0;
  static const double hero      = 80.0;

  // Card & button padding shortcuts
  static const EdgeInsets cardPadding        = EdgeInsets.all(xl);
  static const EdgeInsets cardPaddingFeature = EdgeInsets.all(xxl);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 12);

  // Section padding helpers
  static EdgeInsets pagePadding({bool isDesktop = true}) =>
      EdgeInsets.symmetric(
        horizontal: isDesktop ? xxl : xl,
        vertical: isDesktop ? xxl : xl,
      );
}

/// AppRadius — Clay Enterprise PropTech border-radius tokens
class AppRadius {
  AppRadius._();

  // Raw values
  static const double xs      = 4.0;
  static const double sm      = 6.0;
  static const double md      = 12.0;   // buttons, forms — 12px
  static const double lg      = 12.0;   // buttons alias
  static const double xl      = 16.0;   // cards — 16px
  static const double xxl     = 24.0;   // feature cards — 24px
  static const double xxxl    = 24.0;   // legacy
  static const double feature = 24.0;   // feature cards — 24px
  static const double full    = 9999.0; // pills

  // BorderRadius helpers
  static BorderRadius brXs      = BorderRadius.circular(xs);
  static BorderRadius brSm      = BorderRadius.circular(sm);
  static BorderRadius brMd      = BorderRadius.circular(md);   // 12px
  static BorderRadius brLg      = BorderRadius.circular(lg);   // 12px
  static BorderRadius brXl      = BorderRadius.circular(xl);   // 16px
  static BorderRadius brXxl     = BorderRadius.circular(xxl);  // 24px
  static BorderRadius brXxxl    = BorderRadius.circular(xxxl);
  static BorderRadius brFeature = BorderRadius.circular(feature); // 24px
  static BorderRadius brFull    = BorderRadius.circular(full);
}

/// AppShadows — Clay Enterprise PropTech elevation model
/// Soft, warm shadows appropriate for cream backgrounds.
class AppShadows {
  AppShadows._();

  /// Level 0 — flat
  static const List<BoxShadow> flat = [];

  /// Level 1 — cards: very soft warm shadow
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A1A3A3A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 2 — hover: slightly more visible
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x141A3A3A),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// Level 3 — dropdowns / popovers
  static const List<BoxShadow> mockup = [
    BoxShadow(
      color: Color(0x1A1A3A3A),
      blurRadius: 32,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
  ];

  /// Level 4 — modals
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x261A3A3A),
      blurRadius: 60,
      spreadRadius: -8,
      offset: Offset(0, 24),
    ),
  ];
}
