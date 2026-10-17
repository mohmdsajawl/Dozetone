/// Immutable state model representing user preferences in Dozetone.
class SettingsState {
  /// Whether to hide WhatsApp audio and voice notes from the music library.
  final bool excludeWhatsapp;

  /// Whether shaking the device during sleep timer fade-out extends time.
  final bool shakeToExtend;

  /// Whether to gradually decline volume as timer approaches 0.
  final bool slowVolumeDecline;

  /// Audio fade-out duration in seconds (15, 30, or 60; default 30).
  final int fadeSeconds;

  /// Whether bedtime auto-timer is enabled.
  final bool bedtimeAutoTimer;

  /// Bedtime schedule start time in minutes after midnight (default: 1320 -> 10:00 PM).
  final int bedtimeStartMinutes;

  /// Bedtime timer duration in minutes (15, 30, 45, or 60; default: 30).
  final int bedtimeDurationMinutes;

  const SettingsState({
    this.excludeWhatsapp = true,
    this.shakeToExtend = true,
    this.slowVolumeDecline = true,
    this.fadeSeconds = 30,
    this.bedtimeAutoTimer = false,
    this.bedtimeStartMinutes = 1320,
    this.bedtimeDurationMinutes = 30,
  });

  /// Formatted bedtime start time string (e.g. "10:00 PM").
  String get formattedBedtimeStart {
    final hour = bedtimeStartMinutes ~/ 60;
    final minute = bedtimeStartMinutes % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  SettingsState copyWith({
    bool? excludeWhatsapp,
    bool? shakeToExtend,
    bool? slowVolumeDecline,
    int? fadeSeconds,
    bool? bedtimeAutoTimer,
    int? bedtimeStartMinutes,
    int? bedtimeDurationMinutes,
  }) {
    return SettingsState(
      excludeWhatsapp: excludeWhatsapp ?? this.excludeWhatsapp,
      shakeToExtend: shakeToExtend ?? this.shakeToExtend,
      slowVolumeDecline: slowVolumeDecline ?? this.slowVolumeDecline,
      fadeSeconds: fadeSeconds ?? this.fadeSeconds,
      bedtimeAutoTimer: bedtimeAutoTimer ?? this.bedtimeAutoTimer,
      bedtimeStartMinutes: bedtimeStartMinutes ?? this.bedtimeStartMinutes,
      bedtimeDurationMinutes:
          bedtimeDurationMinutes ?? this.bedtimeDurationMinutes,
    );
  }
}
