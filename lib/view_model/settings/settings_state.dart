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

  const SettingsState({
    this.excludeWhatsapp = true,
    this.shakeToExtend = true,
    this.slowVolumeDecline = true,
    this.fadeSeconds = 30,
  });

  SettingsState copyWith({
    bool? excludeWhatsapp,
    bool? shakeToExtend,
    bool? slowVolumeDecline,
    int? fadeSeconds,
  }) {
    return SettingsState(
      excludeWhatsapp: excludeWhatsapp ?? this.excludeWhatsapp,
      shakeToExtend: shakeToExtend ?? this.shakeToExtend,
      slowVolumeDecline: slowVolumeDecline ?? this.slowVolumeDecline,
      fadeSeconds: fadeSeconds ?? this.fadeSeconds,
    );
  }
}
