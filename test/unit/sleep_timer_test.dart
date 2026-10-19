import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dozetone/core/constants/pref_keys.dart';
import 'package:dozetone/core/constants/sleep_timer_constants.dart';
import 'package:dozetone/core/utils/sleep_volume_curve.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/sleep_timer_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/sleep_timer/sleep_timer_view_model.dart';

class FakePlayerRepository implements PlayerRepository {
  final StreamController<PlayerState> _controller =
      StreamController<PlayerState>.broadcast();
  final StreamController<void> _trackCompletedController =
      StreamController<void>.broadcast();

  bool pauseCalled = false;
  bool pauseOnTrackEnd = false;
  bool loopForSleepTimer = false;
  double? lastVolume;
  List<double> volumeHistory = [];

  @override
  Stream<PlayerState> get playerStateStream => _controller.stream;

  @override
  Stream<void> get trackCompletedStream => _trackCompletedController.stream;

  @override
  void setPauseOnTrackEnd(bool pause) {
    pauseOnTrackEnd = pause;
  }

  @override
  void setLoopForSleepTimer(bool loop) {
    loopForSleepTimer = loop;
  }

  void emitState(PlayerState state) {
    _controller.add(state);
  }

  void emitTrackCompleted() {
    _trackCompletedController.add(null);
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

  void dispose() {
    _controller.close();
    _trackCompletedController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('dev.fluttercommunity.plus/sensors/method'),
            (call) async => null);
  });

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

    test('formattedRemaining returns End of track when isEndOfSong is true', () {
      const state = SleepTimerState(isEndOfSong: true);
      expect(state.formattedRemaining, 'End of track');
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

    test('fresh install has null lastUsedChoice by default', () async {
      SharedPreferences.setMockInitialValues({});
      final freshRepo = FakePlayerRepository();
      final freshViewModel = SleepTimerViewModel(freshRepo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(freshViewModel.state.lastUsedChoice, isNull);
      expect(freshViewModel.state.isActive, false);

      freshViewModel.dispose();
      freshRepo.dispose();
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
      expect(fakeRepo.pauseOnTrackEnd, false);
    });

    test('cancelTimer deactivates timer and restores volume to 1.0', () async {
      await viewModel.startTimer(const Duration(minutes: 20));
      expect(viewModel.state.isActive, true);

      await viewModel.cancelTimer();

      expect(viewModel.state.isActive, false);
      expect(viewModel.state.remainingDuration, Duration.zero);
      expect(viewModel.state.isFadingOut, false);
      expect(fakeRepo.lastVolume, 1.0);
      expect(fakeRepo.pauseOnTrackEnd, false);
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

  group('End of current track sleep timer', () {
    const testSong = Song(
      id: 1,
      title: 'Sleep Song',
      artist: 'Sleep Artist',
      durationMs: 180000,
      dataUri: '/music/song.mp3',
    );

    test('sets pauseOnTrackEnd and fades volume in gentleness window near end of song', () async {
      await viewModel.startEndOfSongTimer(choiceLabel: 'End of current track');
      expect(viewModel.state.isActive, true);
      expect(viewModel.state.isEndOfSong, true);
      expect(viewModel.state.lastUsedChoice, 'End of current track');
      expect(fakeRepo.pauseOnTrackEnd, true);

      // Emit playing state far from end (position 1m00s of 3m00s, fade is 10s)
      fakeRepo.emitState(const PlayerState(
        isPlaying: true,
        currentSong: testSong,
        duration: Duration(minutes: 3),
        position: Duration(minutes: 1),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.state.isFadingOut, false);
      expect(viewModel.state.volumeFactor, 1.0);

      // Emit playing state near end (position 2m55s of 3m00s, 5s remaining <= 10s fade)
      fakeRepo.emitState(const PlayerState(
        isPlaying: true,
        currentSong: testSong,
        duration: Duration(minutes: 3),
        position: Duration(minutes: 2, seconds: 55),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(viewModel.state.isFadingOut, true);
      expect(viewModel.state.volumeFactor, lessThan(1.0));
      expect(fakeRepo.lastVolume, lessThan(1.0));
    });

    test('track completion stream triggers pause, UI reset, and volume restoration', () async {
      await viewModel.startEndOfSongTimer(choiceLabel: 'End of current track');
      expect(viewModel.state.isActive, true);
      expect(fakeRepo.pauseOnTrackEnd, true);

      fakeRepo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(fakeRepo.pauseCalled, true);
      expect(fakeRepo.lastVolume, 1.0);
      expect(viewModel.state.isActive, false);
      expect(viewModel.state.isEndOfSong, false);
      expect(fakeRepo.pauseOnTrackEnd, false);
    });

    test('canceling End of Track timer resets pauseOnTrackEnd and restores volume', () async {
      await viewModel.startEndOfSongTimer(choiceLabel: 'End of current track');
      expect(fakeRepo.pauseOnTrackEnd, true);

      await viewModel.cancelTimer();

      expect(fakeRepo.pauseOnTrackEnd, false);
      expect(fakeRepo.lastVolume, 1.0);
      expect(viewModel.state.isActive, false);
    });
  });

  group('Shake to extend feature', () {
    late StreamController<UserAccelerometerEvent> accelController;
    late SleepTimerViewModel shakeViewModel;
    late FakePlayerRepository shakeRepo;

    setUp(() async {
      accelController = StreamController<UserAccelerometerEvent>.broadcast();
      shakeRepo = FakePlayerRepository();
      shakeViewModel = SleepTimerViewModel(
        shakeRepo,
        accelerometerStreamOverride: accelController.stream,
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });

    tearDown(() {
      shakeViewModel.dispose();
      shakeRepo.dispose();
      accelController.close();
    });

    test('ignores shake when timer is far from ending and not fading out', () async {
      await shakeViewModel.startTimer(const Duration(minutes: 30));
      final initialRemaining = shakeViewModel.state.remainingDuration;

      // Emit two vigorous shake peaks
      accelController.add(UserAccelerometerEvent(15.0, 15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      accelController.add(UserAccelerometerEvent(-15.0, -15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(shakeViewModel.state.remainingDuration.inMinutes, initialRemaining.inMinutes);
    });

    test('triggers add5Minutes when double shake detected during fade-out', () async {
      // 2-second timer so entire duration is in 10s fade window
      await shakeViewModel.startTimer(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(shakeViewModel.state.isFadingOut, true);

      // Emit double shake
      accelController.add(UserAccelerometerEvent(15.0, 15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      accelController.add(UserAccelerometerEvent(-15.0, -15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should add 5 minutes and reset fading out
      expect(shakeViewModel.state.isFadingOut, false);
      expect(shakeViewModel.state.remainingDuration.inSeconds, greaterThanOrEqualTo(290));
      // Volume starts ramping up smoothly without jumping immediately to 1.0
      expect(shakeRepo.lastVolume, lessThanOrEqualTo(1.0));
    });

    test('does not add 5 minutes if shakeToExtend is disabled', () async {
      await shakeViewModel.setShakeToExtend(false);
      await shakeViewModel.startTimer(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(shakeViewModel.state.isFadingOut, true);

      // Emit double shake
      accelController.add(UserAccelerometerEvent(15.0, 15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 150));
      accelController.add(UserAccelerometerEvent(-15.0, -15.0, 0.0, DateTime.now()));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Shaking ignored because disabled
      expect(shakeViewModel.state.remainingDuration.inSeconds, lessThanOrEqualTo(2));
    });
  });

  group('Track-based multi-track sleep timer', () {
    late FakePlayerRepository repo;
    late SleepTimerViewModel vm;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = FakePlayerRepository();
      vm = SleepTimerViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('startTracksTimer with 3 tracks sets up correct initial state', () async {
      await vm.startTracksTimer(trackCount: 3);

      expect(vm.state.isActive, true);
      expect(vm.state.isTrackBased, true);
      expect(vm.state.totalTracks, 3);
      expect(vm.state.remainingTracks, 3);
      expect(vm.state.isEndOfSong, false);
      expect(repo.pauseOnTrackEnd, false);
      expect(repo.lastVolume, 1.0);
    });

    test('multi-track countdown decrements and activates pauseOnTrackEnd on final track', () async {
      await vm.startTracksTimer(trackCount: 3);

      // Track 1 completes
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.remainingTracks, 2);
      expect(vm.state.isEndOfSong, false);
      expect(repo.pauseOnTrackEnd, false);

      // Track 2 completes -> only 1 remaining!
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.remainingTracks, 1);
      expect(vm.state.isEndOfSong, true);
      expect(repo.pauseOnTrackEnd, true);

      // Track 3 completes -> finishes timer!
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, false);
      expect(repo.pauseCalled, true);
      expect(repo.pauseOnTrackEnd, false);
    });

    test('dynamic track adjustments: addTracks and removeTracks', () async {
      await vm.startTracksTimer(trackCount: 2);
      expect(vm.state.remainingTracks, 2);

      // Add 2 tracks -> 4 tracks total
      await vm.addTracks(2);
      expect(vm.state.remainingTracks, 4);
      expect(vm.state.totalTracks, 4);

      // Remove 1 track -> 3 tracks remaining
      await vm.removeTracks(1);
      expect(vm.state.remainingTracks, 3);

      // Remove 2 tracks -> 1 track remaining (pauseOnTrackEnd should turn true)
      await vm.removeTracks(2);
      expect(vm.state.remainingTracks, 1);
      expect(vm.state.isEndOfSong, true);
      expect(repo.pauseOnTrackEnd, true);

      // Remove final track -> timer finishes
      await vm.removeTracks(1);
      expect(vm.state.isActive, false);
      expect(repo.pauseCalled, true);
    });

    test('updateSelectedTracks updates list and track count', () async {
      const song1 = Song(id: 1, title: 'Song 1', artist: 'Artist 1', durationMs: 180000, dataUri: 'uri1');
      const song2 = Song(id: 2, title: 'Song 2', artist: 'Artist 2', durationMs: 200000, dataUri: 'uri2');
      const song3 = Song(id: 3, title: 'Song 3', artist: 'Artist 3', durationMs: 220000, dataUri: 'uri3');

      await vm.startTracksTimer(trackCount: 2, specificTracks: [song1, song2]);
      expect(vm.state.selectedTracks.length, 2);

      // Update with 3 songs
      await vm.updateSelectedTracks([song1, song2, song3]);
      expect(vm.state.selectedTracks.length, 3);
      expect(vm.state.remainingTracks, 3);
      expect(repo.pauseOnTrackEnd, false);

      // Update with 1 song
      await vm.updateSelectedTracks([song1]);
      expect(vm.state.selectedTracks.length, 1);
      expect(vm.state.remainingTracks, 1);
      expect(vm.state.isEndOfSong, true);
      expect(repo.pauseOnTrackEnd, true);
    });

    test('3-track flow does not terminate prematurely when track 3 starts and fades at end', () async {
      final song1 = Song(
        id: 1,
        title: 'Song A',
        artist: 'Artist',
        album: 'Album',
        durationMs: 180000,
        dataUri: '/a.mp3',
        sizeBytes: 1000,
        dateAdded: 0,
      );
      final song2 = Song(
        id: 2,
        title: 'Song B',
        artist: 'Artist',
        album: 'Album',
        durationMs: 180000,
        dataUri: '/b.mp3',
        sizeBytes: 1000,
        dateAdded: 0,
      );
      final song3 = Song(
        id: 3,
        title: 'Song C',
        artist: 'Artist',
        album: 'Album',
        durationMs: 180000,
        dataUri: '/c.mp3',
        sizeBytes: 1000,
        dateAdded: 0,
      );

      await vm.startTracksTimer(
        trackCount: 3,
        specificTracks: [song1, song2, song3],
      );

      expect(vm.state.isActive, true);
      expect(vm.state.remainingTracks, 3);

      // Song A completes -> Song B begins
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, true);
      expect(vm.state.remainingTracks, 2);

      // Song B ends -> emit completed
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // At this point, Song C is starting!
      // Verify timer is STILL active and NOT prematurely cancelled!
      expect(vm.state.isActive, true);
      expect(vm.state.remainingTracks, 1);
      expect(vm.state.isEndOfSong, true);
      expect(repo.pauseOnTrackEnd, true);

      // Even if player emits stale position from end of Song B, timer must remain active
      repo.emitState(PlayerState(
        isPlaying: true,
        position: const Duration(milliseconds: 180000),
        duration: const Duration(milliseconds: 180000),
        currentSong: song2,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, true);

      // Song C starts playing
      repo.emitState(PlayerState(
        isPlaying: true,
        position: const Duration(seconds: 10),
        duration: const Duration(milliseconds: 180000),
        currentSong: song3,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, true);
      expect(vm.state.isFadingOut, false);
      expect(repo.lastVolume, 1.0);

      // Song C enters fade-out window (remaining 5s <= 10s fade window)
      repo.emitState(PlayerState(
        isPlaying: true,
        position: const Duration(milliseconds: 175000),
        duration: const Duration(milliseconds: 180000),
        currentSong: song3,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, true);
      expect(vm.state.isFadingOut, true);
      expect(vm.state.volumeFactor, lessThan(1.0));
      expect(repo.lastVolume, lessThan(1.0));

      // Song C completes -> timer finishes cleanly
      repo.emitTrackCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(vm.state.isActive, false);
      expect(repo.pauseCalled, true);
      expect(repo.lastVolume, 1.0);
    });
  });

  group('Dynamic in-flight time editing', () {
    late FakePlayerRepository repo;
    late SleepTimerViewModel vm;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = FakePlayerRepository();
      vm = SleepTimerViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
    });

    test('adjustTime adds and subtracts duration accurately', () async {
      await vm.startTimer(const Duration(minutes: 15));
      expect(vm.state.remainingDuration.inMinutes, 15);

      // Add 5 minutes
      await vm.adjustTime(const Duration(minutes: 5));
      expect(vm.state.remainingDuration.inMinutes, greaterThanOrEqualTo(19));

      // Subtract 10 minutes
      await vm.adjustTime(const Duration(minutes: -10));
      expect(vm.state.remainingDuration.inMinutes, lessThanOrEqualTo(10));
    });

    test('adjustTime to zero or negative terminates timer', () async {
      await vm.startTimer(const Duration(minutes: 5));
      await vm.adjustTime(const Duration(minutes: -10));

      expect(vm.state.isActive, false);
      expect(repo.pauseCalled, true);
    });

    test('setTime sets exact countdown duration', () async {
      await vm.startTimer(const Duration(minutes: 10));
      await vm.setTime(const Duration(minutes: 45));

      expect(vm.state.remainingDuration.inMinutes, 45);
      expect(vm.state.totalDuration, const Duration(minutes: 45));
    });
  });

  group('computeTimerVolumeFactor pure function tests', () {
    test('decline off before fade = 1.0', () {
      final factor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 80),
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: false,
      );
      expect(factor, closeTo(1.0, 1e-6));
    });

    test('decline on at start = 1.0', () {
      final factor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 100),
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: true,
      );
      expect(factor, closeTo(1.0, 1e-6));
    });

    test('halfway through the pre-fade part = 0.8', () {
      // Total 100s, fade 20s: preFade is 80s.
      // Halfway through pre-fade is elapsed 40s, so remaining 60s.
      final factor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 60),
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: true,
      );
      expect(factor, closeTo(0.8, 1e-6));
    });

    test('exactly at fade start = 0.6', () {
      // Exactly at fade start: remaining equals fade duration (20s).
      final factor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 20),
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: true,
      );
      expect(factor, closeTo(0.6, 1e-6));
    });

    test('halfway through the fade = 0.15', () {
      // Halfway through 20s fade: remaining is 10s.
      // Factor is 0.6 * (10 / 20)^2 = 0.6 * 0.25 = 0.15.
      final factor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 10),
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: true,
      );
      expect(factor, closeTo(0.15, 1e-6));
    });

    test('total shorter than fade', () {
      // When total <= fade, no pre-fade part exists; normal fade starts at 1.0.
      final startFactor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 15),
        total: const Duration(seconds: 15),
        fade: const Duration(seconds: 30),
        declineEnabled: true,
      );
      expect(startFactor, closeTo(1.0, 1e-6));

      final halfFactor = computeTimerVolumeFactor(
        remaining: const Duration(milliseconds: 7500),
        total: const Duration(seconds: 15),
        fade: const Duration(seconds: 30),
        declineEnabled: true,
      );
      expect(halfFactor, closeTo(0.25, 1e-6));
    });

    test('total equal to fade', () {
      // When total == fade, normal quadratic fade starts at 1.0.
      final startFactor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 30),
        total: const Duration(seconds: 30),
        fade: const Duration(seconds: 30),
        declineEnabled: true,
      );
      expect(startFactor, closeTo(1.0, 1e-6));

      final halfFactor = computeTimerVolumeFactor(
        remaining: const Duration(seconds: 15),
        total: const Duration(seconds: 30),
        fade: const Duration(seconds: 30),
        declineEnabled: true,
      );
      expect(halfFactor, closeTo(0.25, 1e-6));
    });

    test('remaining zero = 0.0', () {
      final factor = computeTimerVolumeFactor(
        remaining: Duration.zero,
        total: const Duration(seconds: 100),
        fade: const Duration(seconds: 20),
        declineEnabled: true,
      );
      expect(factor, closeTo(0.0, 1e-6));
    });
  });

  group('Slow volume decline ViewModel integration', () {
    test('setVolume values follow the curve', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.slowVolumeDecline: true,
        PrefKeys.fadeSeconds: 1,
      });
      final repo = FakePlayerRepository();
      final vm = SleepTimerViewModel(repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Start a 2-second timer (pre-fade = 1s, fade = 1s)
      await vm.startTimer(const Duration(seconds: 2));
      expect(repo.lastVolume, 1.0);

      // Wait about 550 ms (halfway through 1-second pre-fade)
      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(vm.state.isFadingOut, false);
      expect(vm.state.volumeFactor, lessThan(1.0));
      expect(vm.state.volumeFactor, greaterThan(0.6));
      expect(repo.lastVolume, closeTo(vm.state.volumeFactor, 1e-3));

      // Wait another 650 ms (now inside 1-second fade window)
      await Future<void>.delayed(const Duration(milliseconds: 650));
      expect(vm.state.isFadingOut, true);
      expect(vm.state.volumeFactor, lessThanOrEqualTo(0.6));
      expect(repo.lastVolume, lessThanOrEqualTo(0.6));

      vm.dispose();
      repo.dispose();
    });

    test('adding 5 minutes never raises volume by more than 0.1 per tick', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.slowVolumeDecline: true,
        PrefKeys.fadeSeconds: 1,
      });
      final repo = FakePlayerRepository();
      final vm = SleepTimerViewModel(repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Start 2-second timer and wait until volume is low inside the fade window
      await vm.startTimer(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 1600));

      final volumeBeforeAdd = repo.lastVolume ?? 0.0;
      expect(volumeBeforeAdd, lessThan(0.4));

      final historyIndexBeforeAdd = repo.volumeHistory.length;

      // Add 5 minutes to trigger volume recalculation
      await vm.add5Minutes();

      // Wait for 3 ticks (about 800 ms) while volume ramps back up
      await Future<void>.delayed(const Duration(milliseconds: 800));

      // Verify that every recorded step increased by at most 0.1
      double previousVolume = volumeBeforeAdd;
      for (int i = historyIndexBeforeAdd; i < repo.volumeHistory.length; i++) {
        final current = repo.volumeHistory[i];
        final increase = current - previousVolume;
        expect(
          increase,
          lessThanOrEqualTo(SleepTimerConstants.maxVolumeIncreasePerTick + 1e-4),
          reason: 'Volume jump at step $i was $increase, exceeding 0.1',
        );
        previousVolume = current;
      }

      vm.dispose();
      repo.dispose();
    });

    test('cancel and finish restore 1.0', () async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.slowVolumeDecline: true,
        PrefKeys.fadeSeconds: 1,
      });
      final repo = FakePlayerRepository();
      final vm = SleepTimerViewModel(repo);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // 1. Cancel restore check
      await vm.startTimer(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 550));
      expect(repo.lastVolume, lessThan(1.0));

      await vm.cancelTimer();
      expect(vm.state.isActive, false);
      expect(repo.lastVolume, 1.0);

      // 2. Finish restore check
      await vm.startTimer(const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      expect(vm.state.isActive, false);
      expect(repo.pauseCalled, true);
      expect(repo.lastVolume, 1.0);

      vm.dispose();
      repo.dispose();
    });
  });
}

