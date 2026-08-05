import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_components.dart';

/// AppTheme — Clay Enterprise PropTech MaterialApp ThemeData
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.deepTeal,
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.deepTeal,
          onPrimary: AppColors.onDark,
          secondary: AppColors.deepTeal,
          onSecondary: AppColors.onDark,
          surface: AppColors.canvas,
          onSurface: AppColors.ink,
          error: AppColors.brandRedDark,
          onError: AppColors.onDark,
          surfaceContainerHighest: AppColors.surface,
          outline: AppColors.hairline,
        ),
        // Typography — Inter via google_fonts
        textTheme: TextTheme(
          displayLarge:  AppTypography.displayHero(),
          displayMedium: AppTypography.sectionHeading(),
          displaySmall:  AppTypography.pageTitle(),
          headlineLarge: AppTypography.sectionTitle(),
          headlineMedium: AppTypography.cardTitle(),
          headlineSmall: AppTypography.cardTitle(),
          titleLarge:    AppTypography.bodyMdMedium(),
          titleMedium:   AppTypography.bodyMd(),
          titleSmall:    AppTypography.bodySmMedium(),
          bodyLarge:     AppTypography.bodyMd(),
          bodyMedium:    AppTypography.bodySm(),
          bodySmall:     AppTypography.caption(),
          labelLarge:    AppTypography.buttonMd(),
          labelMedium:   AppTypography.captionBold(),
          labelSmall:    AppTypography.micro(),
        ),
        // Input fields — cream fill, deep teal focus, 12px radius
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
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
          isDense: true,
        ),
        // Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: AppComponents.primaryButtonStyle(),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: AppComponents.secondaryButtonStyle(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: AppComponents.ghostButtonStyle(),
        ),
        // Dialog — warm cream
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXxl,
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
        ),
        // Card — warm cream
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.brXl,
            side: const BorderSide(color: AppColors.hairlineSoft),
          ),
        ),
        // AppBar — cream, no elevation
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          titleTextStyle: AppTypography.cardTitle(color: AppColors.ink),
          iconTheme: const IconThemeData(color: AppColors.ink),
        ),
        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.hairline,
          thickness: 1,
          space: 1,
        ),
        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.cardBg,
          labelStyle: AppTypography.captionBold(),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brFull),
        ),
        // Snackbar
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          contentTextStyle:
              AppTypography.bodySmMedium(color: AppColors.onDark),
        ),
      );
}
