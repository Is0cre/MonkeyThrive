import 'package:flutter/material.dart';
import 'app_appearance.dart';

// THRIVES colour palette — deep navy, soft teal, warm amber
class AppColors {
  AppColors._();

  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceVariant = Color(0xFF1C2430);
  static const teal = Color(0xFF4ECDC4);
  static const tealDim = Color(0xFF2A7A75);
  static const amber = Color(0xFFE8A645);
  static const amberDim = Color(0xFF8A6228);
  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const textMuted = Color(0xFF484F58);
  static const danger = Color(0xFFDA3633);
  static const dangerSurface = Color(0xFF2D1F1F);
}

class AppTheme {
  AppTheme._();

  static ThemeData dark(
      [AppearanceSettings appearance = const AppearanceSettings()]) {
    final accent = appearance.accentColor;
    final background = appearance.background;
    final surface = appearance.surface;
    final surfaceVariant = appearance.surfaceVariant;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: AppColors.amber,
        surface: surface,
        surfaceContainer: surface,
        surfaceContainerHighest: surfaceVariant,
        onPrimary: background,
        onSecondary: AppColors.background,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w300,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          height: 1.6,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(44, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
      ),
      useMaterial3: true,
    );
  }
}
