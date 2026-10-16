import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dozetone/core/constants/pref_keys.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/sleep_timer_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/sleep_timer/sleep_timer_view_model.dart';

class FakePlayerRepository implements PlayerRepository {
  final StreamController<PlayerState> _controller =
      StreamController<PlayerState>.broadcast();

  bool pauseCalled = false;
  double? lastVolume;
  List<double> volumeHistory = [];

  @override
  Stream<PlayerState> get playerStateStream => _controller.stream;

  void emitState(PlayerState state) {
    _controller.add(state);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
    volumeHistory.add(volume);
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> playSong(Song song, List<Song> queue) async {}

  @override
  Future<void> stop() async {}

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

  void dispose() {
    _controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePlayerRepository fakeRepo;
  late SleepTimerViewModel viewModel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.lastTimerChoice: '15 minutes',
      PrefKeys.fadeSeconds: 10,
    });
    fakeRepo = FakePlayerRepository();
    viewModel = SleepTimerViewModel(fakeRepo);
    // Allow asynchronous _loadInitialPreferences to complete
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  tearDown(() {
    viewModel.dispose();
    fakeRepo.dispose();
  });

  group('SleepTimerState formatting and progress tests', () {
    test('formattedRemaining handles minutes and seconds properly', () {
      const state = SleepTimerState(
        remainingDuration: Duration(minutes: 5, seconds: 23),
      );
      expect(state.formattedRemaining, '05:23');
    });

    test('formattedRemaining handles hours properly', () {
      const state = SleepTimerState(
        remainingDuration: Duration(hours: 1, minutes: 12, seconds: 4),
      );
      expect(state.formattedRemaining, '1:12:04');
    });

    test('progressFraction calculates correct ratio', () {
      const state = SleepTimerState(
        totalDuration: Duration(minutes: 10),
        remainingDuration: Duration(minutes: 4),
      );
      // elapsed = 6 min / 10 min = 0.6
      expect(state.progressFraction, closeTo(0.6, 0.001));
    });

    test('progressFraction returns 0.0 when total is zero or null', () {
      const state = SleepTimerState();
      expect(state.progressFraction, 0.0);
    });
  });

  group('SleepTimerViewModel basic operations', () {
    test('initializes with persisted preferences', () {
      expect(viewModel.state.lastUsedChoice, '15 minutes');
      expect(viewModel.state.isActive, false);
      expect(viewModel.state.volumeFactor, 1.0);
    });

    test('startTimer activates timer and sets volume to 1.0', () async {
      await viewModel.startTimer(
        const Duration(minutes: 30),
        choiceLabel: '30 minutes',
      );

      expect(viewModel.state.isActive, true);
      expect(viewModel.state.isEndOfSong, false);
      expect(viewModel.state.totalDuration, const Duration(minutes: 30));
      expect(viewModel.state.lastUsedChoice, '30 minutes');
      expect(fakeRepo.lastVolume, 1.0);
    });

    test('cancelTimer deactivates timer and restores volume to 1.0', () async {
      await viewModel.startTimer(const Duration(minutes: 20));
      expect(viewModel.state.isActive, true);

      await viewModel.cancelTimer();

      expect(viewModel.state.isActive, false);
      expect(viewModel.state.remainingDuration, Duration.zero);
      expect(viewModel.state.isFadingOut, false);
      expect(fakeRepo.lastVolume, 1.0);
    });

    test('add5Minutes extends remaining duration by 5 minutes', () async {
      await viewModel.startTimer(const Duration(minutes: 10));
      final initialRemaining = viewModel.state.remainingDuration;

      await viewModel.add5Minutes();

      final updatedRemaining = viewModel.state.remainingDuration;
      expect(
        updatedRemaining.inSeconds,
        greaterThanOrEqualTo(initialRemaining.inSeconds + 298),
      );
      expect(fakeRepo.lastVolume, 1.0);
    });
  });

  group('SleepTimer volume fade-out and termination', () {
    test('volume fades quadratically and pauses when timer expires', () async {
      // Start a short timer with total duration 2 seconds
      // Since fadeSeconds is 10, the entire 2 seconds will be in fade window
      await viewModel.startTimer(const Duration(seconds: 2));

      expect(viewModel.state.isActive, true);

      // Wait 1 second (halfway through fade)
      await Future<void>.delayed(const Duration(milliseconds: 1050));

      expect(viewModel.state.isFadingOut, true);
      // Volume factor should be less than 1.0
      expect(viewModel.state.volumeFactor, lessThan(1.0));
      expect(fakeRepo.lastVolume, lessThan(1.0));

      // Wait until timer finishes
      await Future<void>.delayed(const Duration(milliseconds: 1200));

      // After timer expires, playback must be paused and volume restored to 1.0
      expect(fakeRepo.pauseCalled, true);
      expect(fakeRepo.lastVolume, 1.0);
      expect(viewModel.state.isActive, false);
      expect(viewModel.state.volumeFactor, 1.0);
    });
  });

  group('End of song sleep timer', () {
    test('pauses and restores volume when track finishes or skips', () async {
      const songA = Song(
        id: 1,
        title: 'Song A',
        artist: 'Artist A',
        durationMs: 180000,
        dataUri: '/music/song_a.mp3',
      );

      const songB = Song(
        id: 2,
        title: 'Song B',
        artist: 'Artist B',
        durationMs: 200000,
        dataUri: '/music/song_b.mp3',
      );

      await viewModel.startEndOfSongTimer(choiceLabel: 'End of song');
      expect(viewModel.state.isActive, true);
      expect(viewModel.state.isEndOfSong, true);

      // Emit first track playing
      fakeRepo.emitState(const PlayerState(
        isPlaying: true,
        currentSong: songA,
        duration: Duration(minutes: 3),
        position: Duration(seconds: 30),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(fakeRepo.pauseCalled, false);

      // Emit second track (track changed)
      fakeRepo.emitState(const PlayerState(
        isPlaying: true,
        currentSong: songB,
        duration: Duration(minutes: 3),
        position: Duration.zero,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should detect song changed and finish timer
      expect(fakeRepo.pauseCalled, true);
      expect(fakeRepo.lastVolume, 1.0);
      expect(viewModel.state.isActive, false);
    });
  });
}
