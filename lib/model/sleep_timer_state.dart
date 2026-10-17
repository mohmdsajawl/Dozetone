import 'package:flutter/foundation.dart';
import 'song.dart';

/// Immutable state representing the sleep timer status.
@immutable
class SleepTimerState {
  /// Whether a sleep timer is currently actively counting down.
  final bool isActive;

  /// Absolute timestamp when playback should pause (for time-based timer).
  final DateTime? targetEndTime;

  /// Total configured duration when the timer was started (for time-based timer).
  final Duration? totalDuration;

  /// Calculated remaining duration until playback pauses.
  final Duration remainingDuration;

  /// Whether audio is currently in the gentle fade-out window.
  final bool isFadingOut;

  /// Whether the timer is configured to pause at the end of the current track.
  final bool isEndOfSong;

  /// Whether the active timer is track-based (pauses after N tracks or end of track).
  final bool isTrackBased;

  /// Total number of tracks configured for the timer (if track-based).
  final int totalTracks;

  /// Remaining number of tracks before playback pauses (if track-based).
  final int remainingTracks;

  /// Specific songs chosen for the sleep timer (empty if purely count-based).
  final List<Song> selectedTracks;

  /// Identifier or label of the last used preset/choice (persisted in settings).
  final String? lastUsedChoice;

  /// Current internal audio volume factor (1.0 down to 0.0 during fade-out).
  final double volumeFactor;

  /// Whether shaking the phone during fade-out adds 5 minutes.
  final bool shakeToExtendEnabled;

  const SleepTimerState({
    this.isActive = false,
    this.targetEndTime,
    this.totalDuration,
    this.remainingDuration = Duration.zero,
    this.isFadingOut = false,
    this.isEndOfSong = false,
    this.isTrackBased = false,
    this.totalTracks = 0,
    this.remainingTracks = 0,
    this.selectedTracks = const <Song>[],
    this.lastUsedChoice,
    this.volumeFactor = 1.0,
    this.shakeToExtendEnabled = true,
  });

  /// Formatted countdown display (e.g. "29:45" or "1:05:30" or "3 tracks").
  String get formattedRemaining {
    if (isTrackBased) {
      if (remainingTracks <= 1) {
        return '1 track';
      }
      return '$remainingTracks tracks';
    }
    if (isEndOfSong) return 'End of track';
    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress fraction of elapsed time or tracks (0.0 at start, 1.0 at finish).
  double get progressFraction {
    if (isTrackBased) {
      if (totalTracks <= 0) return 0.0;
      final completed = (totalTracks - remainingTracks).clamp(0, totalTracks);
      return (completed / totalTracks).clamp(0.0, 1.0);
    }
    if (totalDuration == null || totalDuration!.inMilliseconds == 0) {
      return 0.0;
    }
    final elapsedMs = totalDuration!.inMilliseconds - remainingDuration.inMilliseconds;
    return (elapsedMs / totalDuration!.inMilliseconds).clamp(0.0, 1.0);
  }

  SleepTimerState copyWith({
    bool? isActive,
    DateTime? targetEndTime,
    Duration? totalDuration,
    Duration? remainingDuration,
    bool? isFadingOut,
    bool? isEndOfSong,
    bool? isTrackBased,
    int? totalTracks,
    int? remainingTracks,
    List<Song>? selectedTracks,
    String? lastUsedChoice,
    bool clearLastUsedChoice = false,
    double? volumeFactor,
    bool? shakeToExtendEnabled,
  }) {
    return SleepTimerState(
      isActive: isActive ?? this.isActive,
      targetEndTime: targetEndTime ?? this.targetEndTime,
      totalDuration: totalDuration ?? this.totalDuration,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      isFadingOut: isFadingOut ?? this.isFadingOut,
      isEndOfSong: isEndOfSong ?? this.isEndOfSong,
      isTrackBased: isTrackBased ?? this.isTrackBased,
      totalTracks: totalTracks ?? this.totalTracks,
      remainingTracks: remainingTracks ?? this.remainingTracks,
      selectedTracks: selectedTracks ?? this.selectedTracks,
      lastUsedChoice:
          clearLastUsedChoice ? null : (lastUsedChoice ?? this.lastUsedChoice),
      volumeFactor: volumeFactor ?? this.volumeFactor,
      shakeToExtendEnabled: shakeToExtendEnabled ?? this.shakeToExtendEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepTimerState &&
        other.isActive == isActive &&
        other.targetEndTime == targetEndTime &&
        other.totalDuration == totalDuration &&
        other.remainingDuration == remainingDuration &&
        other.isFadingOut == isFadingOut &&
        other.isEndOfSong == isEndOfSong &&
        other.isTrackBased == isTrackBased &&
        other.totalTracks == totalTracks &&
        other.remainingTracks == remainingTracks &&
        listEquals(other.selectedTracks, selectedTracks) &&
        other.lastUsedChoice == lastUsedChoice &&
        other.volumeFactor == volumeFactor &&
        other.shakeToExtendEnabled == shakeToExtendEnabled;
  }

  @override
  int get hashCode => Object.hash(
        isActive,
        targetEndTime,
        totalDuration,
        remainingDuration,
        isFadingOut,
        isEndOfSong,
        isTrackBased,
        totalTracks,
        remainingTracks,
        Object.hashAll(selectedTracks),
        lastUsedChoice,
        volumeFactor,
        shakeToExtendEnabled,
      );
}

