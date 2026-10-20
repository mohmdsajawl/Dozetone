import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/core/utils/timer_notification_text.dart';
import 'package:dozetone/l10n/generated/app_localizations.dart';
import 'package:dozetone/model/sleep_timer_state.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('buildTimerNotificationText pure function tests', () {
    test('12 min', () {
      const state = SleepTimerState(
        isActive: true,
        remainingDuration: Duration(minutes: 12),
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep in 12 min',
      );
    });

    test('exactly 1 min', () {
      const state = SleepTimerState(
        isActive: true,
        remainingDuration: Duration(minutes: 1),
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep in 1 min',
      );
    });

    test('59 seconds', () {
      const state = SleepTimerState(
        isActive: true,
        remainingDuration: Duration(seconds: 59),
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep in under 1 min',
      );
    });

    test('fading', () {
      const state = SleepTimerState(
        isActive: true,
        isFadingOut: true,
        remainingDuration: Duration(seconds: 20),
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Fading out',
      );
    });

    test('end of song', () {
      const state = SleepTimerState(
        isActive: true,
        isEndOfSong: true,
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep after this song',
      );
    });

    test('3 tracks', () {
      const state = SleepTimerState(
        isActive: true,
        isTrackBased: true,
        totalTracks: 3,
        remainingTracks: 3,
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep after 3 songs',
      );
    });

    test('1 track', () {
      const state = SleepTimerState(
        isActive: true,
        isTrackBased: true,
        totalTracks: 1,
        remainingTracks: 1,
      );
      expect(
        buildTimerNotificationText(state: state, l10n: l10n),
        'Sleep after 1 song',
      );
    });

    test('inactive (null)', () {
      const state = SleepTimerState(isActive: false);
      expect(buildTimerNotificationText(state: state, l10n: l10n), isNull);
    });
  });
}
