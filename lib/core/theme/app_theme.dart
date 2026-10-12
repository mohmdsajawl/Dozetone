import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Single source of truth for the Dozetone Material 3 Dark Theme.
///
/// Configured with Option A (Midnight Blue) tokens so widgets can
/// access styles via Theme.of(context) without relying on raw colors.
abstract final class AppTheme {
  /// Builds the dark Material 3 theme configuration.
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.accent,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: AppColors.background,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: AppTextStyles.fontFamily,

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.screenTitle,
      ),

      // Card styling
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),

      // Bottom sheet styling (28 radius at top)
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28.0),
          ),
        ),
      ),

      // Dialog styling
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
        ),
      ),

      // Elevated button styling
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(48.0, 48.0),
          shape: const StadiumBorder(),
          elevation: 0.0,
        ),
      ),

      // Text button styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(48.0, 48.0),
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textPrimary,
        size: 24.0,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.outline,
        thickness: 1.0,
        space: 1.0,
      ),

      // Slider theme for seekbar and volume controls
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.outline,
        thumbColor: AppColors.accent,
        overlayColor: AppColors.softAccent(0.2),
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
      ),

      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: AppTextStyles.body.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: AppColors.outline),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
