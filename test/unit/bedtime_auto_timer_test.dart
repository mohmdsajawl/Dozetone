import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dozetone/core/constants/pref_keys.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/model/timer_notification_action.dart';
import 'package:dozetone/view_model/settings/settings_state.dart';
import 'package:dozetone/view_model/settings/settings_view_model.dart';
import 'package:dozetone/view_model/sleep_timer/sleep_timer_view_model.dart';

class FakePlayerRepository implements PlayerRepository {
  double currentVolume = 1.0;
  bool pauseOnTrackEnd = false;
  bool loopForSleepTimer = false;
  bool paused = false;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<void> get trackCompletedStream => const Stream.empty();

  @override
  Stream<TimerNotificationAction> get timerNotificationActions =>
      const Stream.empty();

  @override
  void setTimerActionVisible(bool visible) {}

  @override
  Future<void> setVolume(double volume) async {
    currentVolume = volume;
  }

  @override
  void setPauseOnTrackEnd(bool pause) {
    pauseOnTrackEnd = pause;
  }

  @override
  void setLoopForSleepTimer(bool loop) {
    loopForSleepTimer = loop;
  }

  @override
  Future<void> pause() async {
    paused = true;
  }

  @override
  Future<void> play() async {
    paused = false;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> playSong(Song song, List<Song> queue) async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> skipToNext() async {}

  @override
  Future<void> skipToPrevious() async {}

  @override
  void toggleShuffle() {}

  @override
  void cycleRepeatMode() {}

  @override
  void insertNext(Song song) {}

  @override
  void addToQueue(Song song) {}

  @override
  void addSongsToQueue(List<Song> songs) {}

  @override
  void reorderQueue(int oldIndex, int newIndex) {}

  @override
  Future<void> removeFromQueue(int index) async {}

  @override
  void clearUpNext() {}

  @override
  Future<void> skipToQueueIndex(int index) async {}

  @override
  void updatePlaybackQueue(List<Song> newQueue) {}

  @override
  Future<void> removeSongFromPlayback(int songId) async {}

  @override
  void updateSongMetadata(int songId, String newTitle) {}

  @override
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  }) async {}

  @override
  Future<void> saveLastPlaybackSession(int songId, int positionMs) async {}

  @override
  Future<({int? songId, int? positionMs})> getLastPlaybackSession() async =>
      (songId: null, positionMs: null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Bedtime Window Calculations', () {
    test('crosses midnight: 10:00 PM (1320) to 5:00 AM (300)', () {
      const startMinutes = 1320; // 22:00
      const endMinutes = 300; // 05:00

      // 10:30 PM (22:30 -> 1350)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 17, 22, 30),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 11:59 PM (23:59 -> 1439)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 17, 23, 59),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 12:00 AM / Midnight (00:00 -> 0)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 0, 0),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 03:15 AM (03:15 -> 195)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 3, 15),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 04:59 AM (04:59 -> 299)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 4, 59),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 05:00 AM exactly (05:00 -> 300) -> outside
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 5, 0),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isFalse,
      );

      // Daytime 02:00 PM (14:00 -> 840) -> outside
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 17, 14, 0),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isFalse,
      );

      // Evening 09:30 PM (21:30 -> 1290) -> before start
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 17, 21, 30),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isFalse,
      );
    });

    test('does not cross midnight: 01:00 AM (60) to 05:00 AM (300)', () {
      const startMinutes = 60; // 01:00
      const endMinutes = 300; // 05:00

      // 02:30 AM
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 2, 30),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isTrue,
      );

      // 12:30 AM (before start)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 0, 30),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isFalse,
      );

      // 06:00 AM (after end)
      expect(
        SleepTimerViewModel.isInsideBedtimeWindow(
          now: DateTime(2026, 10, 18, 6, 0),
          startMinutes: startMinutes,
          endMinutes: endMinutes,
        ),
        isFalse,
      );
    });
  });

  group('SleepTimerViewModel.checkAndTriggerBedtimeAutoTimer', () {
    late FakePlayerRepository playerRepo;
    late SleepTimerViewModel viewModel;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        PrefKeys.bedtimeAutoTimer: true,
        PrefKeys.bedtimeStartMinutes: 1320, // 10:00 PM
        PrefKeys.bedtimeDurationMinutes: 30,
        PrefKeys.lastBedtimeAutoStartTimestamp: 0,
      });

      playerRepo = FakePlayerRepository();
      viewModel = SleepTimerViewModel(playerRepo);
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('activates timer when inside bedtime window and enabled', () async {
      final nightTime = DateTime(2026, 10, 17, 23, 15); // 11:15 PM

      final triggered = await viewModel.checkAndTriggerBedtimeAutoTimer(nightTime);
      expect(triggered, isTrue);
      expect(viewModel.state.isActive, isTrue);
      expect(viewModel.state.totalDuration, equals(const Duration(minutes: 30)));
      expect(viewModel.state.lastUsedChoice, equals('Bedtime auto-timer'));

      // Check persisted timestamp updated
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getInt(PrefKeys.lastBedtimeAutoStartTimestamp),
        equals(nightTime.millisecondsSinceEpoch),
      );
    });

    test('ignores trigger if bedtime auto timer is disabled in preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.bedtimeAutoTimer, false);

      final nightTime = DateTime(2026, 10, 17, 23, 15);
      final triggered = await viewModel.checkAndTriggerBedtimeAutoTimer(nightTime);

      expect(triggered, isFalse);
      expect(viewModel.state.isActive, isFalse);
    });

    test('ignores trigger if outside bedtime window (daytime)', () async {
      final daytime = DateTime(2026, 10, 17, 14, 0); // 2:00 PM
      final triggered = await viewModel.checkAndTriggerBedtimeAutoTimer(daytime);

      expect(triggered, isFalse);
      expect(viewModel.state.isActive, isFalse);
    });

    test('enforces 60-minute cooldown preventing re-trigger spam', () async {
      final nightTime = DateTime(2026, 10, 17, 23, 0); // 11:00 PM
      final triggered1 = await viewModel.checkAndTriggerBedtimeAutoTimer(nightTime);
      expect(triggered1, isTrue);

      // Cancel timer (as user might do)
      await viewModel.cancelTimer();
      expect(viewModel.state.isActive, isFalse);

      // 10 minutes later (same night, 11:10 PM)
      final shortlyAfter = DateTime(2026, 10, 17, 23, 10);
      final triggered2 =
          await viewModel.checkAndTriggerBedtimeAutoTimer(shortlyAfter);

      // Must be rejected due to 60-min cooldown
      expect(triggered2, isFalse);
      expect(viewModel.state.isActive, isFalse);

      // 61 minutes later (12:01 AM)
      final afterCooldown = DateTime(2026, 10, 18, 0, 1);
      final triggered3 =
          await viewModel.checkAndTriggerBedtimeAutoTimer(afterCooldown);

      // Successfully triggers after cooldown
      expect(triggered3, isTrue);
      expect(viewModel.state.isActive, isTrue);
    });

    test('does not override an already running user timer', () async {
      // User manually started 60 min timer
      await viewModel.startTimer(const Duration(minutes: 60));
      expect(viewModel.state.totalDuration, equals(const Duration(minutes: 60)));

      final nightTime = DateTime(2026, 10, 17, 23, 15);
      final triggered = await viewModel.checkAndTriggerBedtimeAutoTimer(nightTime);

      expect(triggered, isFalse);
      // Timer remains 60 min, not changed to 30 min
      expect(viewModel.state.totalDuration, equals(const Duration(minutes: 60)));
    });
  });

  group('SettingsViewModel Bedtime Operations', () {
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({
        PrefKeys.bedtimeAutoTimer: false,
        PrefKeys.bedtimeStartMinutes: 1320,
        PrefKeys.bedtimeDurationMinutes: 30,
      });

      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('formattedBedtimeStart formats correctly', () {
      const state1 = SettingsState(bedtimeStartMinutes: 1320); // 22:00
      expect(state1.formattedBedtimeStart, equals('10:00 PM'));

      const state2 = SettingsState(bedtimeStartMinutes: 1350); // 22:30
      expect(state2.formattedBedtimeStart, equals('10:30 PM'));

      const state3 = SettingsState(bedtimeStartMinutes: 60); // 01:00
      expect(state3.formattedBedtimeStart, equals('1:00 AM'));

      const state4 = SettingsState(bedtimeStartMinutes: 0); // 00:00
      expect(state4.formattedBedtimeStart, equals('12:00 AM'));
    });

    test('toggling and updating settings persists to SharedPreferences', () async {
      final viewModel = container.read(settingsViewModelProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      await viewModel.loadSettings();

      expect(container.read(settingsViewModelProvider).bedtimeAutoTimer, isFalse);

      await viewModel.toggleBedtimeAutoTimer(true);
      expect(container.read(settingsViewModelProvider).bedtimeAutoTimer, isTrue);

      await viewModel.setBedtimeStartMinutes(1380); // 11:00 PM
      expect(container.read(settingsViewModelProvider).bedtimeStartMinutes, equals(1380));

      await viewModel.setBedtimeDurationMinutes(45);
      expect(container.read(settingsViewModelProvider).bedtimeDurationMinutes, equals(45));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(PrefKeys.bedtimeAutoTimer), isTrue);
      expect(prefs.getInt(PrefKeys.bedtimeStartMinutes), equals(1380));
      expect(prefs.getInt(PrefKeys.bedtimeDurationMinutes), equals(45));
    });
  });
}
