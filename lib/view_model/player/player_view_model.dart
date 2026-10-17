import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/player_repository.dart';
import '../../model/player_state.dart';
import '../../model/song.dart';
import '../library/library_state.dart';
import '../library/library_view_model.dart';

/// Provider exposing the reactive PlayerViewModel state and actions.
final playerViewModelProvider =
    StateNotifierProvider<PlayerViewModel, PlayerState>((ref) {
  final repository = ref.watch(playerRepositoryProvider);
  final viewModel = PlayerViewModel(repository);

  // Automatically restore saved playback session as soon as audio library is loaded
  ref.listen<LibraryState>(libraryViewModelProvider, (previous, next) {
    if (next is LibraryLoaded) {
      viewModel.restoreSavedSession(next.songs);
    }
  }, fireImmediately: true);

  return viewModel;
});

/// ViewModel managing playback state transitions and user controls.
///
/// Follows strict MVVM rules: pure Dart logic with no BuildContext or widget imports.
class PlayerViewModel extends StateNotifier<PlayerState> {
  final PlayerRepository _repository;
  StreamSubscription<PlayerState>? _subscription;
  DateTime _lastPersistTime = DateTime.fromMillisecondsSinceEpoch(0);

  PlayerViewModel(this._repository) : super(const PlayerState()) {
    _listenToPlaybackState();
  }

  void _listenToPlaybackState() {
    _subscription = _repository.playerStateStream.listen((newState) {
      state = newState;
      _handleStatePersistence(newState);
    });
  }

  void _handleStatePersistence(PlayerState currentState) {
    final song = currentState.currentSong;
    if (song == null) return;

    final now = DateTime.now();

    // If playback is paused/stopped or more than 2 seconds elapsed since last write, persist immediately
    if (!currentState.isPlaying || now.difference(_lastPersistTime).inSeconds >= 2) {
      _lastPersistTime = now;
      _repository.saveLastPlaybackSession(
        song.id,
        currentState.position.inMilliseconds,
      );
    }
  }

  void _persistImmediately() {
    final song = state.currentSong;
    if (song != null) {
      _lastPersistTime = DateTime.now();
      _repository.saveLastPlaybackSession(
        song.id,
        state.position.inMilliseconds,
      );
    }
  }

  /// Starts playback for a song within the active queue.
  Future<void> playSong(Song song, List<Song> queue) async {
    // If the song is already current and actively playing, do not restart it
    if (state.currentSong?.id == song.id && state.isPlaying) {
      return;
    }
    await _repository.playSong(song, queue);
    _persistImmediately();
  }

  /// Toggles between playing and paused states.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await _repository.pause();
    } else {
      await _repository.play();
    }
    _persistImmediately();
  }

  /// Resumes playback.
  Future<void> play() async {
    await _repository.play();
    _persistImmediately();
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _repository.pause();
    _persistImmediately();
  }

  /// Seeks to a specific [position].
  Future<void> seek(Duration position) async {
    await _repository.seek(position);
    _persistImmediately();
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

  /// Appends multiple [songs] to the end of the current playback queue.
  void addSongsToQueue(List<Song> songs) {
    _repository.addSongsToQueue(songs);
  }

  /// Reorders a song within the active playback queue.
  void reorderQueue(int oldIndex, int newIndex) {
    _repository.reorderQueue(oldIndex, newIndex);
  }

  /// Removes a song at [index] from the active playback queue.
  Future<void> removeFromQueue(int index) async {
    await _repository.removeFromQueue(index);
  }

  /// Clears all upcoming tracks after the active song.
  void clearUpNext() {
    _repository.clearUpNext();
  }

  /// Skips directly to a song at [index] in the active queue and starts playback.
  Future<void> skipToQueueIndex(int index) async {
    await _repository.skipToQueueIndex(index);
  }

  /// Updates the active playback queue to match new sorting or filtering.
  void updatePlaybackQueue(List<Song> newQueue) {
    _repository.updatePlaybackQueue(newQueue);
  }

  /// Removes a deleted track from playback and updates the active queue.
  Future<void> removeSongFromPlayback(int songId) async {
    await _repository.removeSongFromPlayback(songId);
  }

  /// Updates track metadata (e.g. title after rename) in the active player and queue.
  void updateSongMetadata(int songId, String newTitle) {
    _repository.updateSongMetadata(songId, newTitle);
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
    _persistImmediately();
    _subscription?.cancel();
    super.dispose();
  }
}
