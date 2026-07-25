import 'package:flutter/material.dart';

/// AppSpacing — Strict 8pt SaaS Scale
class AppSpacing {
  AppSpacing._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
  static const double sectionSm = 48.0;
  static const double section   = 64.0;
  
  // Legacy mappings to prevent build breaks temporarily
  static const double xxs  = 4.0;
  static const double xxxl = 48.0;
  static const double sectionLg = 64.0;
  static const double hero = 64.0;

  // Card padding shortcuts
  static const EdgeInsets cardPadding        = EdgeInsets.all(xl);
  static const EdgeInsets cardPaddingFeature = EdgeInsets.all(xxl);
  static const EdgeInsets buttonPadding      = EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  // Section padding helpers
  static EdgeInsets pagePadding({bool isDesktop = true}) =>
      EdgeInsets.symmetric(horizontal: isDesktop ? xxl : xl, vertical: isDesktop ? xxl : xl);
}

/// AppRadius — Modern SaaS border-radius tokens
class AppRadius {
  AppRadius._();

  static const double xs      = 4.0;
  static const double sm      = 6.0;
  static const double md      = 8.0;
  static const double lg      = 12.0;
  static const double xl      = 16.0;
  static const double xxl     = 24.0;
  static const double full    = 9999.0;
  
  static const double xxxl    = 24.0; // Legacy mapping
  static const double feature = 16.0; // Legacy mapping

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

/// AppShadows — Enterprise SaaS elevation model (Linear/Stripe inspired)
class AppShadows {
  AppShadows._();

  /// Level 0 — flat (no shadow, hairline-soft border)
  static const List<BoxShadow> flat = [];

  /// Level 1 — standard cards
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A0F172A), // Slate 900 at 4%
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 2 — hover states
  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x140F172A), // Slate 900 at 8%
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  /// Level 3 — dropdowns, popovers
  static const List<BoxShadow> mockup = [
    BoxShadow(
      color: Color(0x1A0F172A), // Slate 900 at 10%
      blurRadius: 24,
      spreadRadius: -4,
      offset: Offset(0, 12),
    ),
  ];

  /// Level 4 — modals
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x260F172A), // Slate 900 at 15%
      blurRadius: 48,
      spreadRadius: -8,
      offset: Offset(0, 24),
    ),
  ];
}
