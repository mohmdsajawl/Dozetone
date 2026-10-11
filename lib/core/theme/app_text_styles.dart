import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography hierarchy for Dozetone.
///
/// Follows the Poppins type scale defined in the requirements:
/// - Screen title: 22 / 600
/// - Song title in list: 16 / 500
/// - Body: 14 / 400
/// - Caption: 12 / 400
/// - Button: 14 / 600
/// - Timer countdown: 40 / 600
abstract final class AppTextStyles {
  /// Font family name for bundled typography.
  static const String fontFamily = 'Poppins';

  /// Top app bar and modal screen titles (22/600).
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Primary song item title in library list (16/500).
  static const TextStyle songTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  /// Active playing song title in library list (16/500 with accent color).
  static const TextStyle songTitleActive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
  );

  /// Now Playing prominent title (22/600).
  static const TextStyle nowPlayingTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.25,
  );

  /// Artist and secondary information in Now Playing (16/400).
  static const TextStyle nowPlayingArtist = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Standard body content text (14/400).
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  /// Secondary body text (14/400 muted).
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Small captions, durations, timestamps, and hints (12/400).
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  /// Interactive buttons and action pills (14/600).
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onAccent,
  );

  /// Sleep timer prominent countdown display (40/600).
  static const TextStyle timerCountdown = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 1.0,
  );
}
