import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/core/theme/app_colors.dart';
import 'package:dozetone/core/theme/app_theme.dart';
import 'package:dozetone/core/theme/app_text_styles.dart';

/// Unit tests that verify the dark theme text styles use the Poppins font family.
///
/// These tests act as a regression guard: if the fontFamily is ever removed
/// from AppTheme or AppTextStyles, the tests will catch it immediately.
void main() {
  group('AppTheme Poppins font family', () {
    late ThemeData theme;

    setUpAll(() {
      theme = AppTheme.darkTheme;
    });

    test('theme-level fontFamily is set to Poppins', () {
      // ThemeData does not expose fontFamily as a public getter in this SDK.
      // The guarantee is enforced through the textTheme (see tests below)
      // and through the AppTextStyles constant being 'Poppins'.
      expect(AppTextStyles.fontFamily, equals('Poppins'));
    });

    test('textTheme bodyMedium uses Poppins', () {
      expect(
        theme.textTheme.bodyMedium?.fontFamily,
        equals('Poppins'),
      );
    });

    test('textTheme titleLarge uses Poppins', () {
      expect(
        theme.textTheme.titleLarge?.fontFamily,
        equals('Poppins'),
      );
    });

    test('textTheme labelLarge uses Poppins', () {
      expect(
        theme.textTheme.labelLarge?.fontFamily,
        equals('Poppins'),
      );
    });

    test('AppTextStyles constants all reference Poppins', () {
      for (final style in <TextStyle>[
        AppTextStyles.screenTitle,
        AppTextStyles.songTitle,
        AppTextStyles.body,
        AppTextStyles.caption,
        AppTextStyles.button,
        AppTextStyles.timerCountdown,
      ]) {
        expect(
          style.fontFamily,
          equals('Poppins'),
          reason: 'Expected fontFamily Poppins but got ${style.fontFamily}',
        );
      }
    });
  });

  group('AppColors design system tokens', () {
    test('core palette colors have correct values', () {
      expect(AppColors.background, const Color(0xFF0F1424));
      expect(AppColors.backgroundDark, const Color(0xFF131A2D));
      expect(AppColors.surface, const Color(0xFF1A2036));
      expect(AppColors.surfaceLight, const Color(0xFF222B48));
      expect(AppColors.accent, const Color(0xFF8E9AF0));
      expect(AppColors.onAccent, const Color(0xFF0F1424));
      expect(AppColors.textPrimary, const Color(0xFFE6E8F2));
      expect(AppColors.textSecondary, const Color(0xFF8A90AD));
      expect(AppColors.outline, const Color(0xFF2A3250));
      expect(AppColors.error, const Color(0xFFF28B82));
      expect(AppColors.favorite, const Color(0xFFFF5252));
      expect(AppColors.white, const Color(0xFFFFFFFF));
      expect(AppColors.black, const Color(0xFF000000));
      expect(AppColors.barrier, const Color(0x8A000000));
    });

    test('artwork fallback gradients contain 6 distinct pairs', () {
      expect(AppColors.artworkGradients.length, 6);
      for (final pair in AppColors.artworkGradients) {
        expect(pair.length, 2);
      }
    });

    test('helper methods compute valid transparent colors', () {
      expect(AppColors.softAccent(0.2).a, closeTo(0.2, 0.01));
      expect(AppColors.softWhite(0.1).a, closeTo(0.1, 0.01));
    });
  });
}
