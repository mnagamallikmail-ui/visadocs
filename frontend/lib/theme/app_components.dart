import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// AppComponents — Reusable widget factories from Design.md component spec.
/// All buttons use borderRadius = 9999 (pill shape).
class AppComponents {
  AppComponents._();

  static Widget logo({
    double fontSize = 22,
    bool darkMode = false,
    Color? overrideWordmark,
    Color? overrideAccent,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Yellow square wordmark block — signature brand element
        Container(
          width: fontSize * 1.2,
          height: fontSize * 1.2,
          decoration: BoxDecoration(
            color: overrideWordmark ?? AppColors.brandYellow,
            borderRadius: AppRadius.brXs,
          ),
          alignment: Alignment.center,
          child: Text(
            'P',
            style: AppTypography.bodyMdMedium(
              color: AppColors.primary,
            ).copyWith(fontSize: fontSize * 0.7, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pro Valuer OPC Pvt Ltd',
              style: AppTypography.bodyMdMedium(
                color: darkMode
                    ? (overrideAccent ?? AppColors.onDark)
                    : (overrideAccent ?? AppColors.ink),
              ).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600, height: 1.1),
            ),
            Text(
              'Professional Valuation Services',
              style: AppTypography.bodyMdMedium(
                color: darkMode
                    ? (overrideAccent ?? AppColors.onDark).withOpacity(0.75)
                    : (overrideAccent ?? AppColors.ink).withOpacity(0.75),
              ).copyWith(fontSize: fontSize * 0.55, fontWeight: FontWeight.w400, height: 1.1),
            ),
          ],
        ),
      ],
    );
  }

  // ── Button Styles ────────────────────────────────────────────────────────

  /// button-primary — Black pill, dominant CTA
  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primaryDisabled,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        textStyle: AppTypography.buttonMd(color: AppColors.onPrimary),
      );

  /// button-secondary — Outlined pill for secondary actions
  static ButtonStyle secondaryButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: const BorderSide(color: AppColors.hairlineStrong, width: 1),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        textStyle: AppTypography.buttonMd(color: AppColors.ink),
      );

  /// button-yellow — Brand-yellow pill for brand emphasis moments
  static ButtonStyle yellowButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandYellow,
        foregroundColor: AppColors.primary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        textStyle: AppTypography.buttonMd(color: AppColors.primary),
      );

  /// button-blue — Brand-blue pill for inline action callouts
  static ButtonStyle blueButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        textStyle: AppTypography.buttonMd(color: AppColors.onPrimary),
      );

  /// button-on-dark — White pill for dark CTA banners
  static ButtonStyle onDarkButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.onDark,
        foregroundColor: AppColors.primary,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        textStyle: AppTypography.buttonMd(color: AppColors.primary),
      );

  /// button-ghost — Quieter rectangular ghost for nav/toolbar
  static ButtonStyle ghostButtonStyle() => TextButton.styleFrom(
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.ink),
      );

  /// Legacy compat — used by DesignSystem.primaryButton references
  static ButtonStyle get primaryButton => primaryButtonStyle();
  static ButtonStyle get secondaryButton => secondaryButtonStyle();
  static ButtonStyle get outlinedButton => secondaryButtonStyle();
  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
      );
  static ButtonStyle get premiumButton => blueButtonStyle();

  // ── Card Decorations ────────────────────────────────────────────────────

  /// card-base — Standard content card
  static BoxDecoration cardBase() => BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.hairlineSoft),
      );

  /// card-feature — White feature card with 28px corners
  static BoxDecoration cardFeature() => BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brXxxl,
        border: Border.all(color: AppColors.hairlineSoft),
      );

  /// card-feature-yellow — Pastel yellow feature card
  static BoxDecoration cardFeatureYellow() => BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: AppRadius.brXxxl,
      );

  /// card-feature-coral — Pastel coral feature card
  static BoxDecoration cardFeatureCoral() => BoxDecoration(
        color: AppColors.coralLight,
        borderRadius: AppRadius.brXxxl,
      );

  /// card-feature-teal — Pastel teal feature card
  static BoxDecoration cardFeatureTeal() => BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: AppRadius.brXxxl,
      );

  /// card-feature-rose — Pastel rose feature card
  static BoxDecoration cardFeatureRose() => BoxDecoration(
        color: AppColors.roseLight,
        borderRadius: AppRadius.brXxxl,
      );

  /// pricing-card — Standard tier
  static BoxDecoration pricingCard() => BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.hairline),
      );

  /// pricing-card-featured — Business tier (lavender bg + blue border)
  static BoxDecoration pricingCardFeatured() => BoxDecoration(
        color: AppColors.surfacePricingFeatured,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.brandBlue, width: 2),
      );

  /// pricing-card-enterprise — Dark enterprise tier
  static BoxDecoration pricingCardEnterprise() => BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.brXl,
      );

  /// Legacy cardDecoration compat
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      );

  // ── Input Decorations ───────────────────────────────────────────────────

  /// text-input — Standard text field (44px height, 8px radius)
  static InputDecoration textInput({
    String? label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.brandRedDark),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.brandRedDark, width: 2),
        ),
        labelStyle: AppTypography.bodySm(color: AppColors.slate),
        hintStyle: AppTypography.bodySm(color: AppColors.muted),
        floatingLabelStyle: AppTypography.caption(color: AppColors.brandBlue),
      );

  // ── Badges / Tags ───────────────────────────────────────────────────────

  /// badge-promo — Yellow promo strip badge
  static Widget badgePromo(String text) => _pill(
        text: text,
        bg: AppColors.brandYellow,
        fg: AppColors.primary,
      );

  /// badge-tag-yellow
  static Widget badgeTagYellow(String text) => _pill(
        text: text,
        bg: AppColors.surfaceYellow,
        fg: AppColors.yellowDark,
      );

  /// badge-tag-purple
  static Widget badgeTagPurple(String text) => _pill(
        text: text,
        bg: AppColors.surfacePricingFeatured,
        fg: AppColors.brandBlue,
      );

  /// badge-tag-coral
  static Widget badgeTagCoral(String text) => _pill(
        text: text,
        bg: AppColors.coralLight,
        fg: AppColors.coralDark,
      );

  /// badge-success
  static Widget badgeSuccess(String text) => _pill(
        text: text,
        bg: AppColors.successAccent,
        fg: AppColors.onPrimary,
      );

  /// badge-discount — "Save 15%" — rounded-sm not full
  static Widget badgeDiscount(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.brandYellow,
          borderRadius: AppRadius.brSm,
        ),
        child: Text(text, style: AppTypography.captionBold(color: AppColors.primary)),
      );

  static Widget _pill({
    required String text,
    required Color bg,
    required Color fg,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.brFull),
        child: Text(text, style: AppTypography.captionBold(color: fg)),
      );

  // ── Pill Tab ─────────────────────────────────────────────────────────────
  static Widget pillTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.canvas,
          borderRadius: AppRadius.brFull,
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.hairline,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.buttonMd(
            color: isActive ? AppColors.onPrimary : AppColors.steel,
          ),
        ),
      ),
    );
  }

  // ── icon-circular button — 36×36 ─────────────────────────────────────────
  static Widget iconCircular({
    required IconData icon,
    required VoidCallback onTap,
    double size = 36,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.44, color: AppColors.ink),
      ),
    );
  }

  // ── Snack bar helpers ─────────────────────────────────────────────────────
  static SnackBar successSnack(String message) => SnackBar(
        backgroundColor: AppColors.successAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onPrimary)),
      );

  static SnackBar errorSnack(String message) => SnackBar(
        backgroundColor: AppColors.brandRedDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onPrimary)),
      );

  static SnackBar warningSnack(String message) => SnackBar(
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onPrimary)),
      );
}
