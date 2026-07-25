import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// AppComponents — Reusable SaaS Widget Factory
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
        Container(
          width: fontSize * 1.2,
          height: fontSize * 1.2,
          decoration: BoxDecoration(
            color: overrideWordmark ?? AppColors.brandBlue,
            borderRadius: AppRadius.brXs,
          ),
          alignment: Alignment.center,
          child: Text(
            'P',
            style: AppTypography.bodyMdMedium(
              color: AppColors.onDark,
            ).copyWith(fontSize: fontSize * 0.7, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pro Valuer',
              style: AppTypography.bodyMdMedium(
                color: darkMode ? (overrideAccent ?? AppColors.onDark) : (overrideAccent ?? AppColors.ink),
              ).copyWith(fontSize: fontSize, fontWeight: FontWeight.w600, height: 1.1),
            ),
          ],
        ),
      ],
    );
  }

  // ── Button Styles ────────────────────────────────────────────────────────

  static ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.onDark,
        disabledBackgroundColor: AppColors.hairlineStrong,
        disabledForegroundColor: AppColors.slate,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: AppSpacing.buttonPadding,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.onDark),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.disabled)) return AppColors.hairlineStrong;
          if (states.contains(WidgetState.hovered)) return AppColors.bluePressed;
          return AppColors.brandBlue;
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
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
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
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return const Color(0xFFDC2626); // Darker red
          return AppColors.brandRedDark;
        }),
      );

  static ButtonStyle ghostButtonStyle() => TextButton.styleFrom(
        foregroundColor: AppColors.slate,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        textStyle: AppTypography.buttonMd(color: AppColors.slate),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return AppColors.surfaceSoft;
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.hovered)) return AppColors.ink;
          return AppColors.slate;
        }),
      );

  // Legacy compat aliases
  static ButtonStyle get primaryButton => primaryButtonStyle();
  static ButtonStyle get secondaryButton => secondaryButtonStyle();
  static ButtonStyle get outlinedButton => secondaryButtonStyle();
  static ButtonStyle get dangerButton => dangerButtonStyle();
  static ButtonStyle get premiumButton => primaryButtonStyle();
  static ButtonStyle yellowButtonStyle() => primaryButtonStyle();
  static ButtonStyle blueButtonStyle() => primaryButtonStyle();
  static ButtonStyle onDarkButtonStyle() => secondaryButtonStyle();


  // ── Card Decorations ────────────────────────────────────────────────────

  static BoxDecoration cardBase() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg, // 12px
        border: Border.all(color: AppColors.hairline),
        boxShadow: AppShadows.card,
      );

  // Map legacy cards to the new standard to maintain consistency
  static BoxDecoration cardFeature() => cardBase();
  static BoxDecoration cardFeatureYellow() => cardBase();
  static BoxDecoration cardFeatureCoral() => cardBase();
  static BoxDecoration cardFeatureTeal() => cardBase();
  static BoxDecoration cardFeatureRose() => cardBase();
  static BoxDecoration pricingCard() => cardBase();
  static BoxDecoration pricingCardFeatured() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.brandBlue, width: 2),
        boxShadow: AppShadows.card,
      );
  static BoxDecoration pricingCardEnterprise() => cardBase();
  static BoxDecoration get cardDecoration => cardBase();


  // ── Input Decorations ───────────────────────────────────────────────────

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
        hintStyle: AppTypography.bodySm(color: AppColors.stone),
        floatingLabelStyle: AppTypography.caption(color: AppColors.brandBlue),
      );

  // ── Status Badges ───────────────────────────────────────────────────────
  
  static Widget statusBadge(String status) {
    Color bg;
    Color fg;
    
    switch (status.toLowerCase()) {
      case 'new':
      case 'in_progress':
        bg = const Color(0xFFEFF6FF); // Blue 50
        fg = const Color(0xFF1D4ED8); // Blue 700
        break;
      case 'assigned':
      case 'under_review':
      case 'pending':
        bg = const Color(0xFFFEF3C7); // Amber 100
        fg = const Color(0xFFB45309); // Amber 700
        break;
      case 'completed':
      case 'approved':
        bg = const Color(0xFFD1FAE5); // Emerald 100
        fg = const Color(0xFF047857); // Emerald 700
        break;
      case 'rejected':
      case 'failed':
        bg = const Color(0xFFFEE2E2); // Red 100
        fg = const Color(0xFFB91C1C); // Red 700
        break;
      default:
        bg = AppColors.surfaceSoft;
        fg = AppColors.slate;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTypography.captionBold(color: fg).copyWith(fontSize: 11),
      ),
    );
  }

  // Legacy badge wrappers
  static Widget badgePromo(String text) => statusBadge(text);
  static Widget badgeTagYellow(String text) => statusBadge(text);
  static Widget badgeTagPurple(String text) => statusBadge(text);
  static Widget badgeTagCoral(String text) => statusBadge(text);
  static Widget badgeSuccess(String text) => statusBadge('completed');
  static Widget badgeDiscount(String text) => statusBadge(text);

  // ── Pill Tab ─────────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive ? AppColors.brandBlue : Colors.transparent,
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
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: size * 0.44, color: AppColors.slate),
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────
  
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppTypography.sectionTitle(color: AppColors.ink)),
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

  // ── Snack bar helpers ─────────────────────────────────────────────────────
  static SnackBar successSnack(String message) => SnackBar(
        backgroundColor: AppColors.successAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );

  static SnackBar errorSnack(String message) => SnackBar(
        backgroundColor: AppColors.brandRedDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );

  static SnackBar warningSnack(String message) => SnackBar(
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        content: Text(message, style: AppTypography.bodySmMedium(color: AppColors.onDark)),
      );
}
