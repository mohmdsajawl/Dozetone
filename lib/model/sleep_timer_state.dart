import 'package:flutter/foundation.dart';

/// Immutable state representing the sleep timer status.
@immutable
class SleepTimerState {
  /// Whether a sleep timer is currently actively counting down.
  final bool isActive;

  /// Absolute timestamp when playback should pause.
  final DateTime? targetEndTime;

  /// Total configured duration when the timer was started.
  final Duration? totalDuration;

  /// Calculated remaining duration until playback pauses.
  final Duration remainingDuration;

  /// Whether audio is currently in the gentle fade-out window.
  final bool isFadingOut;

  /// Whether the timer is configured to pause at the end of the current track.
  final bool isEndOfSong;

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
    this.lastUsedChoice,
    this.volumeFactor = 1.0,
    this.shakeToExtendEnabled = true,
  });

  /// Formatted countdown display (e.g. "29:45" or "1:05:30").
  String get formattedRemaining {
    if (isEndOfSong) return 'End of track';
    final hours = remainingDuration.inHours;
    final minutes = remainingDuration.inMinutes.remainder(60);
    final seconds = remainingDuration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Progress fraction of elapsed time (0.0 at start, 1.0 at finish).
  double get progressFraction {
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
        lastUsedChoice,
        volumeFactor,
        shakeToExtendEnabled,
      );
}
