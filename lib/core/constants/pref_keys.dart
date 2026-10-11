/// Keys used for SharedPreferences persistence.
///
/// Centralized in one place to avoid duplicate or misspelled storage keys.
abstract final class PrefKeys {
  /// Fade length in seconds (15, 30, or 60; default 30).
  static const String fadeSeconds = 'fade_seconds';

  /// Slow volume decline toggle (boolean; default true).
  static const String slowVolumeDecline = 'slow_volume_decline';

  /// Shake to extend sleep timer toggle (boolean; default true).
  static const String shakeToExtend = 'shake_to_extend';

  /// Bedtime auto-timer toggle (boolean; default false).
  static const String bedtimeAutoTimer = 'bedtime_auto_timer';

  /// Bedtime start time expressed in minutes after midnight (default 1320 -> 10:00 PM).
  static const String bedtimeStartMinutes = 'bedtime_start_minutes';

  /// Bedtime auto-timer duration in minutes (15, 30, 45, or 60; default 30).
  static const String bedtimeDurationMinutes = 'bedtime_duration_minutes';

  /// Last selected timer preset or custom duration mode string.
  static const String lastTimerChoice = 'last_timer_choice';

  /// ID of the last active audio track.
  static const String lastSongId = 'last_song_id';

  /// Last playback position in milliseconds.
  static const String lastPositionMs = 'last_position_ms';

  /// Shuffle mode toggle (boolean).
  static const String shuffleEnabled = 'shuffle_enabled';

  /// Repeat mode value ('off', 'all', 'one').
  static const String repeatMode = 'repeat_mode';

  /// Timestamp of the last bedtime auto-start to prevent re-trigger within 60 minutes.
  static const String lastBedtimeAutoStartTimestamp = 'last_bedtime_auto_start_timestamp';
}
