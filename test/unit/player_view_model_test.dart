import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/player/player_view_model.dart';

class FakePlayerRepository implements PlayerRepository {
  final StreamController<PlayerState> _controller =
      StreamController<PlayerState>.broadcast(sync: true);

  PlayerState _currentState = const PlayerState();

  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  bool skipNextCalled = false;
  bool skipPreviousCalled = false;
  bool toggleShuffleCalled = false;
  bool cycleRepeatCalled = false;
  Duration? lastSeekPosition;
  double? lastVolume;
  Song? lastPlayedSong;
  List<Song>? lastQueue;
  Song? lastInsertedSong;

  int? savedSongId;
  int? savedPositionMs;

  @override
  Stream<PlayerState> get playerStateStream => _controller.stream;

  void emitState(PlayerState state) {
    _currentState = state;
    _controller.add(state);
  }

  @override
  Future<void> playSong(Song song, List<Song> queue) async {
    lastPlayedSong = song;
    lastQueue = queue;
    emitState(_currentState.copyWith(
      currentSong: song,
      isPlaying: true,
      queue: queue,
    ));
  }

  @override
  Future<void> play() async {
    playCalled = true;
    emitState(_currentState.copyWith(isPlaying: true));
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    emitState(_currentState.copyWith(isPlaying: false));
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    emitState(_currentState.copyWith(isPlaying: false));
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    emitState(_currentState.copyWith(position: position));
  }

  @override
  Future<void> skipToNext() async {
    skipNextCalled = true;
  }

  @override
  Future<void> skipToPrevious() async {
    skipPreviousCalled = true;
  }

  @override
  void toggleShuffle() {
    toggleShuffleCalled = true;
    emitState(_currentState.copyWith(
      isShuffleEnabled: !_currentState.isShuffleEnabled,
    ));
  }

  @override
  void cycleRepeatMode() {
    cycleRepeatCalled = true;
    final next = switch (_currentState.repeatMode) {
      PlayerRepeatMode.off => PlayerRepeatMode.all,
      PlayerRepeatMode.all => PlayerRepeatMode.one,
      PlayerRepeatMode.one => PlayerRepeatMode.off,
    };
    emitState(_currentState.copyWith(repeatMode: next));
  }

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
  }

  @override
  void insertNext(Song song) {
    lastInsertedSong = song;
  }

  Song? lastAddedToQueueSong;
  int? lastRemovedSongId;

  @override
  void addToQueue(Song song) {
    lastAddedToQueueSong = song;
  }

  List<Song>? lastUpdatedQueue;

  @override
  void updatePlaybackQueue(List<Song> newQueue) {
    lastUpdatedQueue = newQueue;
    emitState(_currentState.copyWith(queue: newQueue));
  }

  @override
  Future<void> removeSongFromPlayback(int songId) async {
    lastRemovedSongId = songId;
    if (_currentState.currentSong?.id == songId) {
      emitState(_currentState.copyWith(clearCurrentSong: true, isPlaying: false));
    }
  }

  @override
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  }) async {
    emitState(_currentState.copyWith(
      currentSong: song,
      position: position,
      queue: queue,
      isPlaying: false,
    ));
  }

  @override
  Future<void> saveLastPlaybackSession(int songId, int positionMs) async {
    savedSongId = songId;
    savedPositionMs = positionMs;
  }

  @override
  Future<({int? songId, int? positionMs})> getLastPlaybackSession() async {
    return (songId: savedSongId, positionMs: savedPositionMs);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('PlayerViewModel Unit Tests', () {
    late FakePlayerRepository repository;
    late PlayerViewModel viewModel;

    const testSong1 = Song(
      id: 1,
      title: 'Song One',
      artist: 'Artist A',
      durationMs: 180000,
      dataUri: '/path/song1.mp3',
    );

    const testSong2 = Song(
      id: 2,
      title: 'Song Two',
      artist: 'Artist B',
      durationMs: 240000,
      dataUri: '/path/song2.mp3',
    );

    final testQueue = <Song>[testSong1, testSong2];

    setUp(() {
      repository = FakePlayerRepository();
      viewModel = PlayerViewModel(repository);
    });

    tearDown(() {
      viewModel.dispose();
      repository.dispose();
    });

    test('initial state is default PlayerState', () {
      expect(viewModel.state.currentSong, isNull);
      expect(viewModel.state.isPlaying, isFalse);
    });

    test('playSong updates repository and local state', () async {
      await viewModel.playSong(testSong1, testQueue);

      expect(repository.lastPlayedSong, equals(testSong1));
      expect(repository.lastQueue, equals(testQueue));
      expect(viewModel.state.currentSong, equals(testSong1));
      expect(viewModel.state.isPlaying, isTrue);
    });

    test('togglePlayPause pauses when playing', () async {
      await viewModel.playSong(testSong1, testQueue);
      expect(viewModel.state.isPlaying, isTrue);

      await viewModel.togglePlayPause();
      expect(repository.pauseCalled, isTrue);
      expect(viewModel.state.isPlaying, isFalse);
    });

    test('togglePlayPause resumes when paused', () async {
      repository.emitState(const PlayerState(isPlaying: false));
      await viewModel.togglePlayPause();

      expect(repository.playCalled, isTrue);
      expect(viewModel.state.isPlaying, isTrue);
    });

    test('seek calls repository seek with correct position', () async {
      const targetPos = Duration(seconds: 45);
      await viewModel.seek(targetPos);

      expect(repository.lastSeekPosition, equals(targetPos));
      expect(viewModel.state.position, equals(targetPos));
    });

    test('skipNext and skipPrevious forward calls to repository', () async {
      await viewModel.skipNext();
      expect(repository.skipNextCalled, isTrue);

      await viewModel.skipPrevious();
      expect(repository.skipPreviousCalled, isTrue);
    });

    test('toggleShuffle and cycleRepeatMode update state', () {
      viewModel.toggleShuffle();
      expect(repository.toggleShuffleCalled, isTrue);
      expect(viewModel.state.isShuffleEnabled, isTrue);

      viewModel.cycleRepeatMode();
      expect(repository.cycleRepeatCalled, isTrue);
      expect(viewModel.state.repeatMode, equals(PlayerRepeatMode.all));
    });

    test('insertNext forwards song to repository', () {
      viewModel.insertNext(testSong2);
      expect(repository.lastInsertedSong, equals(testSong2));
    });

    test('addToQueue forwards song to repository', () {
      viewModel.addToQueue(testSong2);
      expect(repository.lastAddedToQueueSong, equals(testSong2));
    });

    test('removeSongFromPlayback clears song if playing', () async {
      await viewModel.playSong(testSong1, testQueue);
      expect(viewModel.state.currentSong, equals(testSong1));

      await viewModel.removeSongFromPlayback(testSong1.id);
      expect(repository.lastRemovedSongId, equals(testSong1.id));
      expect(viewModel.state.currentSong, isNull);
      expect(viewModel.state.isPlaying, isFalse);
    });

    test('restoreSavedSession restores track when saved data exists', () async {
      repository.savedSongId = 2;
      repository.savedPositionMs = 30000;

      await viewModel.restoreSavedSession(testQueue);

      expect(viewModel.state.currentSong, equals(testSong2));
      expect(viewModel.state.position, equals(const Duration(milliseconds: 30000)));
      expect(viewModel.state.isPlaying, isFalse);
    });
  });
}
