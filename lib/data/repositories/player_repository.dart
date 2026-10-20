import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';
import '../../core/utils/app_logger.dart';
import '../../model/player_state.dart';
import '../../model/song.dart';
import '../../model/timer_notification_action.dart';
import '../services/audio_handler.dart';

/// Provider for accessing PlayerRepository instance.
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final audioHandler = ref.watch(audioHandlerProvider);
  return PlayerRepositoryImpl(audioHandler);
});

/// Contract for audio playback operations and persistence.
abstract class PlayerRepository {
  /// Stream emitting real-time player states.
  Stream<PlayerState> get playerStateStream;

  /// Stream firing when a track reaches completion.
  Stream<void> get trackCompletedStream;

  /// Stream emitting sleep timer action events triggered from system media notification.
  Stream<TimerNotificationAction> get timerNotificationActions;

  /// Sets whether the sleep timer extension action (+5 min) is displayed on media notification.
  void setTimerActionVisible(bool visible);

  /// Sets the sleep timer notification status prefix displayed before the artist name.
  void setTimerNotificationText(String? text);

  /// Sets whether playback should automatically pause at the end of the current track
  /// rather than advancing to the next song or repeating.
  void setPauseOnTrackEnd(bool pause);

  /// Sets whether playback should loop to the start of the queue when reaching the end,
  /// used while sleep timer is active so playback doesn't terminate before time expires.
  void setLoopForSleepTimer(bool loop);

  /// Starts playback for [song] with the provided [queue].
  Future<void> playSong(Song song, List<Song> queue);

  /// Resumes audio playback.
  Future<void> play();

  /// Pauses audio playback.
  Future<void> pause();

  /// Stops audio playback.
  Future<void> stop();

  /// Seeks to a specific [position].
  Future<void> seek(Duration position);

  /// Skips to the next track.
  Future<void> skipToNext();

  /// Skips to the previous track or restarts the current track.
  Future<void> skipToPrevious();

  /// Toggles shuffle mode.
  void toggleShuffle();

  /// Cycles through repeat modes.
  void cycleRepeatMode();

  /// Sets audio player volume factor.
  Future<void> setVolume(double volume);

  /// Inserts [song] to play immediately next in the queue.
  void insertNext(Song song);

  /// Appends [song] to the end of the queue.
  void addToQueue(Song song);

  /// Appends multiple [songs] to the end of the queue.
  void addSongsToQueue(List<Song> songs);

  /// Reorders a song within the queue.
  void reorderQueue(int oldIndex, int newIndex);

  /// Removes a song at [index] from the active playback queue.
  Future<void> removeFromQueue(int index);

  /// Clears all upcoming songs scheduled after the currently playing song.
  void clearUpNext();

  /// Skips directly to a song at [index] in the active queue and starts playback.
  Future<void> skipToQueueIndex(int index);

  /// Updates playback queue to match new sorting without restarting audio.
  void updatePlaybackQueue(List<Song> newQueue);

  /// Removes a song from playback and queue when deleted from device storage.
  Future<void> removeSongFromPlayback(int songId);

  /// Updates song metadata (e.g. title after rename) in the active playback queue.
  void updateSongMetadata(int songId, String newTitle);

  /// Preloads a saved song and position without starting playback.
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  });

  /// Saves the last played track ID and playback position.
  Future<void> saveLastPlaybackSession(int songId, int positionMs);

  /// Retrieves the saved last playback session data.
  Future<({int? songId, int? positionMs})> getLastPlaybackSession();
}

/// Implementation of PlayerRepository interfacing with DozetoneAudioHandler.
class PlayerRepositoryImpl implements PlayerRepository {
  final DozetoneAudioHandler _audioHandler;

  PlayerRepositoryImpl(this._audioHandler);

  @override
  Stream<PlayerState> get playerStateStream => _audioHandler.playerStateStream;

  @override
  Stream<void> get trackCompletedStream => _audioHandler.trackCompletedStream;

  @override
  Stream<TimerNotificationAction> get timerNotificationActions =>
      _audioHandler.timerNotificationActions;

  @override
  void setTimerActionVisible(bool visible) =>
      _audioHandler.setTimerActionVisible(visible);

  @override
  void setTimerNotificationText(String? text) =>
      _audioHandler.setTimerNotificationText(text);

  @override
  void setPauseOnTrackEnd(bool pause) => _audioHandler.setPauseOnTrackEnd(pause);

  @override
  void setLoopForSleepTimer(bool loop) =>
      _audioHandler.setLoopForSleepTimer(loop);

  @override
  Future<void> playSong(Song song, List<Song> queue) {
    return _audioHandler.playSong(song, queue);
  }

  @override
  Future<void> play() => _audioHandler.play();

  @override
  Future<void> pause() => _audioHandler.pause();

  @override
  Future<void> stop() => _audioHandler.stop();

  @override
  Future<void> seek(Duration position) => _audioHandler.seek(position);

  @override
  Future<void> skipToNext() => _audioHandler.skipToNext();

  @override
  Future<void> skipToPrevious() => _audioHandler.skipToPrevious();

  @override
  void toggleShuffle() => _audioHandler.toggleShuffle();

  @override
  void cycleRepeatMode() => _audioHandler.cycleRepeatMode();

  @override
  Future<void> setVolume(double volume) => _audioHandler.setVolume(volume);

  @override
  void insertNext(Song song) => _audioHandler.insertNext(song);

  @override
  void addToQueue(Song song) => _audioHandler.addToQueue(song);

  @override
  void addSongsToQueue(List<Song> songs) => _audioHandler.addSongsToQueue(songs);

  @override
  void reorderQueue(int oldIndex, int newIndex) =>
      _audioHandler.reorderQueue(oldIndex, newIndex);

  @override
  Future<void> removeFromQueue(int index) =>
      _audioHandler.removeFromQueue(index);

  @override
  void clearUpNext() => _audioHandler.clearUpNext();

  @override
  Future<void> skipToQueueIndex(int index) =>
      _audioHandler.skipToQueueIndex(index);

  @override
  void updatePlaybackQueue(List<Song> newQueue) =>
      _audioHandler.updatePlaybackQueue(newQueue);

  @override
  Future<void> removeSongFromPlayback(int songId) =>
      _audioHandler.removeSongFromPlayback(songId);

  @override
  void updateSongMetadata(int songId, String newTitle) =>
      _audioHandler.updateSongMetadata(songId, newTitle);

  @override
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  }) {
    return _audioHandler.restoreLastSession(
      song: song,
      position: position,
      queue: queue,
    );
  }

  @override
  Future<void> saveLastPlaybackSession(int songId, int positionMs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.lastSongId, songId);
      await prefs.setInt(PrefKeys.lastPositionMs, positionMs);
    } catch (e, st) {
      AppLogger.w(
        'Failed to save last playback session',
        tag: 'PlayerRepository',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<({int? songId, int? positionMs})> getLastPlaybackSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final songId = prefs.getInt(PrefKeys.lastSongId);
      final positionMs = prefs.getInt(PrefKeys.lastPositionMs);
      return (songId: songId, positionMs: positionMs);
    } catch (e, st) {
      AppLogger.w(
        'Failed to read last playback session',
        tag: 'PlayerRepository',
        error: e,
        stackTrace: st,
      );
      return (songId: null, positionMs: null);
    }
  }
}
