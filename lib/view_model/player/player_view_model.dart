import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/player_repository.dart';
import '../../model/player_state.dart';
import '../../model/song.dart';

/// Provider exposing the reactive PlayerViewModel state and actions.
final playerViewModelProvider =
    StateNotifierProvider<PlayerViewModel, PlayerState>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return PlayerViewModel(repository);
});

/// ViewModel managing playback state transitions and user controls.
///
/// Follows strict MVVM rules: pure Dart logic with no BuildContext or widget imports.
class PlayerViewModel extends StateNotifier<PlayerState> {
  final PlayerRepository _repository;
  StreamSubscription<PlayerState>? _subscription;
  Timer? _persistenceTimer;

  PlayerViewModel(this._repository) : super(const PlayerState()) {
    _listenToPlaybackState();
  }

  void _listenToPlaybackState() {
    _subscription = _repository.playerStateStream.listen((newState) {
      state = newState;
      _schedulePersistence(newState);
    });
  }

  void _schedulePersistence(PlayerState currentState) {
    if (currentState.currentSong == null) return;

    _persistenceTimer?.cancel();
    _persistenceTimer = Timer(const Duration(seconds: 3), () {
      final song = currentState.currentSong;
      if (song != null) {
        _repository.saveLastPlaybackSession(
          song.id,
          currentState.position.inMilliseconds,
        );
      }
    });
  }

  /// Starts playback for a song within the active queue.
  Future<void> playSong(Song song, List<Song> queue) async {
    await _repository.playSong(song, queue);
  }

  /// Toggles between playing and paused states.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
  }

  /// Resumes playback.
  Future<void> play() async {
    await _repository.play();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _repository.pause();
  }

  /// Seeks to a specific [position].
  Future<void> seek(Duration position) async {
    await _repository.seek(position);
  }

  /// Skips to the next song in the queue.
  Future<void> skipNext() async {
    await _repository.skipToNext();
  }

  /// Skips to the previous song or restarts current track.
  Future<void> skipPrevious() async {
    await _repository.skipToPrevious();
  }

  /// Toggles shuffle mode.
  void toggleShuffle() {
    _repository.toggleShuffle();
  }

  /// Cycles through repeat modes: off -> all -> one.
  void cycleRepeatMode() {
    _repository.cycleRepeatMode();
  }

  /// Sets player volume factor (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    await _repository.setVolume(volume);
  }

  /// Inserts [song] to play immediately after the active song.
  void insertNext(Song song) {
    _repository.insertNext(song);
  }

  /// Appends [song] to the end of the current playback queue.
  void addToQueue(Song song) {
    _repository.addToQueue(song);
  }

  /// Removes a deleted track from playback and updates the active queue.
  Future<void> removeSongFromPlayback(int songId) async {
    await _repository.removeSongFromPlayback(songId);
  }

  /// Restores previous playback session if available and no song is playing.
  Future<void> restoreSavedSession(List<Song> librarySongs) async {
    if (state.currentSong != null || librarySongs.isEmpty) return;

    final session = await _repository.getLastPlaybackSession();
    if (session.songId == null) return;

    final targetSong = librarySongs.where((s) => s.id == session.songId).firstOrNull;
    if (targetSong != null) {
      await _repository.restoreLastSession(
        song: targetSong,
        position: Duration(milliseconds: session.positionMs ?? 0),
        queue: librarySongs,
      );
    }
  }

  @override
  void dispose() {
    _persistenceTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
