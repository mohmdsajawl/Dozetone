import 'package:flutter/foundation.dart';
import 'song.dart';

/// Playback repeat modes for the audio player.
enum PlayerRepeatMode {
  /// Play through queue and stop after the last song.
  off,

  /// Loop the entire queue continuously.
  all,

  /// Repeat the current track indefinitely.
  one,
}

/// Immutable state representing playback status and active audio queue.
@immutable
class PlayerState {
  /// The audio track currently loaded in the player.
  final Song? currentSong;

  /// Whether audio is actively playing.
  final bool isPlaying;

  /// Whether audio is currently buffering or loading.
  final bool isBuffering;

  /// Current playback progress position.
  final Duration position;

  /// Total duration of the active audio track.
  final Duration duration;

  /// Whether shuffle playback order is active.
  final bool isShuffleEnabled;

  /// Active repeat mode.
  final PlayerRepeatMode repeatMode;

  /// Full current playback queue.
  final List<Song> queue;

  /// Index of the currently playing track in [queue].
  final int currentIndex;

  const PlayerState({
    this.currentSong,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffleEnabled = false,
    this.repeatMode = PlayerRepeatMode.off,
    this.queue = const <Song>[],
    this.currentIndex = -1,
  });

  /// Progress fraction (0.0 to 1.0) for progress bars.
  double get progressFraction {
    if (duration.inMilliseconds <= 0) {
      return 0.0;
    }
    final fraction = position.inMilliseconds / duration.inMilliseconds;
    return fraction.clamp(0.0, 1.0);
  }

  /// Whether an active song is currently loaded.
  bool get hasSong => currentSong != null;

  /// Whether previous track navigation or restart is available.
  bool get canSkipPrevious => queue.isNotEmpty;

  /// Whether next track navigation is available.
  bool get canSkipNext => queue.isNotEmpty;

  /// Returns a copy of this state with specified fields replaced.
  PlayerState copyWith({
    Song? currentSong,
    bool clearCurrentSong = false,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    bool? isShuffleEnabled,
    PlayerRepeatMode? repeatMode,
    List<Song>? queue,
    int? currentIndex,
  }) {
    return PlayerState(
      currentSong: clearCurrentSong ? null : (currentSong ?? this.currentSong),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerState &&
          runtimeType == other.runtimeType &&
          currentSong == other.currentSong &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          position == other.position &&
          duration == other.duration &&
          isShuffleEnabled == other.isShuffleEnabled &&
          repeatMode == other.repeatMode &&
          currentIndex == other.currentIndex;

  @override
  int get hashCode => Object.hash(
        currentSong,
        isPlaying,
        isBuffering,
        position,
        duration,
        isShuffleEnabled,
        repeatMode,
        currentIndex,
      );
}
