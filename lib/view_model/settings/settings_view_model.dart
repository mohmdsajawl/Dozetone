import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';
import '../library/library_view_model.dart';
import 'settings_state.dart';

/// Provider exposing SettingsViewModel and its state.
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel(ref);
});

/// ViewModel managing user settings, persistence, and reactive library updates.
class SettingsViewModel extends StateNotifier<SettingsState> {
  final Ref _ref;

  SettingsViewModel(this._ref) : super(const SettingsState()) {
    loadSettings();
  }

  /// Loads persisted settings from SharedPreferences on initialization.
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = SettingsState(
        excludeWhatsapp: prefs.getBool(PrefKeys.excludeWhatsappAudio) ?? true,
        shakeToExtend: prefs.getBool(PrefKeys.shakeToExtend) ?? true,
        slowVolumeDecline: prefs.getBool(PrefKeys.slowVolumeDecline) ?? true,
        fadeSeconds: prefs.getInt(PrefKeys.fadeSeconds) ?? 30,
        bedtimeAutoTimer: prefs.getBool(PrefKeys.bedtimeAutoTimer) ?? false,
        bedtimeStartMinutes: prefs.getInt(PrefKeys.bedtimeStartMinutes) ?? 1320,
        bedtimeDurationMinutes:
            prefs.getInt(PrefKeys.bedtimeDurationMinutes) ?? 30,
      );
    } catch (_) {}
  }

  /// Updates WhatsApp / voice notes exclusion filter and rescans the library.
  Future<void> toggleExcludeWhatsapp(bool value) async {
    state = state.copyWith(excludeWhatsapp: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.excludeWhatsappAudio, value);
    } catch (_) {}

    // Rescan library immediately so changes appear right away
    await _ref.read(libraryViewModelProvider.notifier).rescan();
  }

  /// Updates shake to extend setting.
  Future<void> toggleShakeToExtend(bool value) async {
    state = state.copyWith(shakeToExtend: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.shakeToExtend, value);
    } catch (_) {}
  }

  /// Updates slow volume decline setting.
  Future<void> toggleSlowVolumeDecline(bool value) async {
    state = state.copyWith(slowVolumeDecline: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.slowVolumeDecline, value);
    } catch (_) {}
  }

  /// Updates audio fade duration in seconds.
  Future<void> setFadeSeconds(int seconds) async {
    state = state.copyWith(fadeSeconds: seconds);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.fadeSeconds, seconds);
    } catch (_) {}
  }

  /// Updates bedtime auto-timer toggle.
  Future<void> toggleBedtimeAutoTimer(bool value) async {
    state = state.copyWith(bedtimeAutoTimer: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.bedtimeAutoTimer, value);
    } catch (_) {}
  }

  /// Updates bedtime start time in minutes after midnight.
  Future<void> setBedtimeStartMinutes(int minutes) async {
    state = state.copyWith(bedtimeStartMinutes: minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.bedtimeStartMinutes, minutes);
    } catch (_) {}
  }

  /// Updates bedtime auto-timer duration in minutes.
  Future<void> setBedtimeDurationMinutes(int minutes) async {
    state = state.copyWith(bedtimeDurationMinutes: minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.bedtimeDurationMinutes, minutes);
    } catch (_) {}
  }
}
