/// Centralized constants for audio playback, audio session, and focus management.
abstract final class AudioConstants {
  /// Volume factor applied when ducking during transient audio interruptions (0.5, or 50%).
  static const double duckVolumeFactor = 0.5;

  /// Custom action identifier for extending active sleep timer by 5 minutes from media notification.
  static const String addFiveMinutesActionName = 'add_five_minutes';

  /// Separator between the sleep timer status prefix and original track artist in media notification.
  static const String notificationStatusSeparator = ' \u2022 ';
}
