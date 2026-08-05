import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// AppComponents — Clay Enterprise PropTech Widget Factory
/// All existing method signatures preserved. Visual styles updated.
class AppComponents {
  AppComponents._();

  // ── Logo ──────────────────────────────────────────────────────────────────

  static Widget logo({
    double fontSize = 22,
    bool darkMode = false,
    Color? overrideWordmark,
    Color? overrideAccent,
  }) {
    final boxColor = overrideWordmark ?? AppColors.deepTeal;
    final textColor = darkMode
        ? (overrideAccent ?? AppColors.onDark)
        : (overrideAccent ?? AppColors.ink);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: fontSize * 1.25,
          height: fontSize * 1.25,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: AppRadius.brMd,
          ),
          alignment: Alignment.center,
          child: Text(
            'P',
            style: AppTypography.bodyMdMedium(color: AppColors.onDark)
                .copyWith(
                    fontSize: fontSize * 0.68,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
          ),
        ),
        const SizedBox(width: 9),
        Text(
          'Pro Valuer',
          style: AppTypography.bodyMdMedium(color: textColor).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              height: 1.1),
        ),
      ],
    );
  }

  // ── Button Styles ─────────────────────────────────────────────────────────

  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepTeal,
        foregroundColor: AppColors.onDark,
        disabledBackgroundColor: AppColors.hairlineStrong,
        disabledForegroundColor: AppColors.slate,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.onDark),
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.hairlineStrong;
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.deepTealPressed;
          }
          return AppColors.deepTeal;
        }),
      );

  static ButtonStyle secondaryButtonStyle() => OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.hairlineStrong, width: 1),
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.ink),
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return AppColors.surfaceSoft;
          return AppColors.surface;
        }),
      );

  static ButtonStyle dangerButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandRedDark,
        foregroundColor: AppColors.onDark,
        elevation: 0,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.onDark),
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFDC2626);
          }
          return AppColors.brandRedDark;
        }),
      );

  static ButtonStyle ghostButtonStyle() => TextButton.styleFrom(
        foregroundColor: AppColors.slate,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.slate),
      ).copyWith(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return AppColors.surfaceSoft;
          return Colors.transparent;
        }),
        foregroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return AppColors.ink;
          return AppColors.slate;
        }),
      );

  // Legacy aliases
  static ButtonStyle get primaryButton => primaryButtonStyle();
  static ButtonStyle get secondaryButton => secondaryButtonStyle();
  static ButtonStyle get outlinedButton => secondaryButtonStyle();
  static ButtonStyle get dangerButton => dangerButtonStyle();
  static ButtonStyle get premiumButton => primaryButtonStyle();
  static ButtonStyle yellowButtonStyle() => primaryButtonStyle();
  static ButtonStyle blueButtonStyle() => primaryButtonStyle();
  static ButtonStyle onDarkButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.onDark,
        foregroundColor: AppColors.deepTeal,
        elevation: 0,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      );

  // ── Card Decorations ──────────────────────────────────────────────────────

  static BoxDecoration cardBase() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.brXl, // 16px
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      );

  /// Clay-inspired feature card — cream base
  static BoxDecoration cardFeature() => BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.brFeature, // 24px
        border: Border.all(color: AppColors.hairline),
      );

  /// Feature card — ochre (yellow) variant
  static BoxDecoration cardFeatureYellow() => BoxDecoration(
        color: AppColors.featureOchreLight,
        borderRadius: AppRadius.brFeature,
        border: Border.all(color: AppColors.featureOchre.withOpacity(0.3)),
      );

  /// Feature card — peach (coral) variant
  static BoxDecoration cardFeatureCoral() => BoxDecoration(
        color: AppColors.featurePeachLight,
        borderRadius: AppRadius.brFeature,
        border: Border.all(color: AppColors.featurePeach.withOpacity(0.3)),
      );

  /// Feature card — deep teal variant
  static BoxDecoration cardFeatureTeal() => BoxDecoration(
        color: AppColors.featureTeal,
        borderRadius: AppRadius.brFeature,
        border: Border.all(color: AppColors.featureTeal.withOpacity(0.5)),
      );

  /// Feature card — rose/pink variant
  static BoxDecoration cardFeatureRose() => BoxDecoration(
        color: AppColors.featurePinkLight,
        borderRadius: AppRadius.brFeature,
        border: Border.all(color: AppColors.featurePink.withOpacity(0.3)),
      );

  /// Feature card — lavender variant
  static BoxDecoration cardFeatureLavender() => BoxDecoration(
        color: AppColors.featureLavenderLight,
        borderRadius: AppRadius.brFeature,
        border: Border.all(color: AppColors.featureLavender.withOpacity(0.3)),
      );

  static BoxDecoration pricingCard() => cardBase();
  static BoxDecoration pricingCardFeatured() => BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: AppRadius.brXl,
        border: Border.all(color: AppColors.deepTeal, width: 2),
        boxShadow: AppShadows.card,
      );
  static BoxDecoration pricingCardEnterprise() => cardBase();
  static BoxDecoration get cardDecoration => cardBase();

  // ── Input Decoration ──────────────────────────────────────────────────────

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
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd, // 12px
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.hairlineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: const BorderSide(color: AppColors.deepTeal, width: 2),
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
        hintStyle: AppTypography.bodySm(color: AppColors.stone),
        floatingLabelStyle: AppTypography.caption(color: AppColors.deepTeal),
      );

  // ── Status Badges ─────────────────────────────────────────────────────────

  static Widget statusBadge(String status) {
    Color bg;
    Color fg;

    switch (status.toLowerCase()) {
      case 'new':
      case 'in_progress':
        bg = AppColors.tealLight;
        fg = AppColors.deepTeal;
        break;
      case 'assigned':
      case 'under_review':
      case 'pending':
        bg = AppColors.featureOchreLight;
        fg = const Color(0xFF7A5A10);
        break;
      case 'completed':
      case 'approved':
        bg = AppColors.successBg;
        fg = const Color(0xFF15803D);
        break;
      case 'rejected':
      case 'failed':
        bg = AppColors.brandRed;
        fg = const Color(0xFFB91C1C);
        break;
      default:
        bg = AppColors.cardBg;
        fg = AppColors.slate;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: AppTypography.captionBold(color: fg).copyWith(fontSize: 11),
      ),
    );
  }

  // Legacy badge aliases
  static Widget badgePromo(String text) => statusBadge(text);
  static Widget badgeTagYellow(String text) => statusBadge(text);
  static Widget badgeTagPurple(String text) => statusBadge(text);
  static Widget badgeTagCoral(String text) => statusBadge(text);
  static Widget badgeSuccess(String text) => statusBadge('completed');
  static Widget badgeDiscount(String text) => statusBadge(text);

  // ── Pill Tab ──────────────────────────────────────────────────────────────

  static Widget pillTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brFull,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? AppColors.deepTeal : Colors.transparent,
          borderRadius: AppRadius.brFull,
        ),
        child: Text(
          label,
          style: AppTypography.buttonMd(
            color: isActive ? AppColors.onDark : AppColors.slate,
          ),
        ),
      ),
    );
  }

  // ── Icon Circle Button ────────────────────────────────────────────────────

  static Widget iconCircular({
    required IconData icon,
    required VoidCallback onTap,
    double size = 36,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.44, color: AppColors.slate),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────

  static Widget emptyState({
    required IconData icon,
    required String title,
    required String description,
    required String primaryButtonText,
    required VoidCallback onPrimaryAction,
    String? secondaryButtonText,
    VoidCallback? onSecondaryAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      decoration: cardBase(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.deepTeal),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title,
              style: AppTypography.sectionTitle(color: AppColors.ink)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: AppTypography.body(color: AppColors.slate),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (secondaryButtonText != null && onSecondaryAction != null) ...[
                OutlinedButton(
                  onPressed: onSecondaryAction,
                  style: secondaryButtonStyle(),
                  child: Text(secondaryButtonText),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              ElevatedButton(
                onPressed: onPrimaryAction,
                style: primaryButtonStyle(),
                child: Text(primaryButtonText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Snack Bars ────────────────────────────────────────────────────────────

  static SnackBar successSnack(String message) => SnackBar(
        backgroundColor: AppColors.successAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        content:
            Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );

  static SnackBar errorSnack(String message) => SnackBar(
        backgroundColor: AppColors.brandRedDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        content:
            Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );

  static SnackBar warningSnack(String message) => SnackBar(
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        content:
            Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );
}
