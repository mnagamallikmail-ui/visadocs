import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_components.dart';

/// AppTheme — MaterialApp ThemeData built entirely from Design.md tokens.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          secondary: AppColors.brandBlue,
          onSecondary: AppColors.onPrimary,
          surface: AppColors.canvas,
          onSurface: AppColors.ink,
          error: AppColors.brandRedDark,
          onError: AppColors.onPrimary,
          surfaceContainerHighest: AppColors.surface,
          outline: AppColors.hairline,
        ),
        // Typography — Noto Sans as Roobert PRO fallback
        textTheme: TextTheme(
          displayLarge:  AppTypography.heroDisplay(),
          displayMedium: AppTypography.displayLg(),
          displaySmall:  AppTypography.heading1(),
          headlineLarge: AppTypography.heading2(),
          headlineMedium: AppTypography.heading3(),
          headlineSmall: AppTypography.heading4(),
          titleLarge:    AppTypography.heading5(),
          titleMedium:   AppTypography.subtitle(),
          titleSmall:    AppTypography.bodyMdMedium(),
          bodyLarge:     AppTypography.bodyMd(),
          bodyMedium:    AppTypography.bodySm(),
          bodySmall:     AppTypography.caption(),
          labelLarge:    AppTypography.buttonMd(),
          labelMedium:   AppTypography.captionBold(),
          labelSmall:    AppTypography.micro(),
        ),
        // Input theme — text-input spec from Design.md
        inputDecorationTheme: InputDecorationTheme(
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
          isDense: true,
        ),
        // ElevatedButton — pill-primary
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppComponents.primaryButtonStyle(),
        ),
        // OutlinedButton — pill-secondary
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppComponents.secondaryButtonStyle(),
        ),
        // TextButton — ghost / link
        textButtonTheme: TextButtonThemeData(
          style: AppComponents.ghostButtonStyle(),
        ),
        // Dialog — modal elevation level 4
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
        ),
        // Card — card-base spec
        cardTheme: CardThemeData(
          color: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
        ),
        // AppBar — clean white, flat
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleTextStyle: AppTypography.heading5(color: AppColors.ink),
          iconTheme: const IconThemeData(color: AppColors.ink),
        ),
        // Divider — hairline
        dividerTheme: const DividerThemeData(
          color: AppColors.hairline,
          thickness: 1,
          space: 1,
        ),
        // Chip — pill-shaped
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          labelStyle: AppTypography.captionBold(),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        ),
        // Snackbar — floating
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brLg),
          contentTextStyle: AppTypography.bodySmMedium(color: AppColors.onPrimary),
        ),
      );
}
