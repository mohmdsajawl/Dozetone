import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
