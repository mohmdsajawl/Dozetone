import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';
import '../../core/utils/app_logger.dart';
import '../library/library_view_model.dart';
import '../sleep_timer/sleep_timer_view_model.dart';
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
    } catch (e, st) {
      AppLogger.e(
        'Failed to load settings from SharedPreferences, using defaults',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates WhatsApp / voice notes exclusion filter and rescans the library.
  Future<void> toggleExcludeWhatsapp(bool value) async {
    state = state.copyWith(excludeWhatsapp: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.excludeWhatsappAudio, value);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist excludeWhatsapp setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }

    // Rescan library immediately so changes appear right away
    await _ref.read(libraryViewModelProvider.notifier).rescan();
  }

  /// Updates shake to extend setting.
  Future<void> toggleShakeToExtend(bool value) async {
    state = state.copyWith(shakeToExtend: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.shakeToExtend, value);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist shakeToExtend setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates slow volume decline setting.
  Future<void> toggleSlowVolumeDecline(bool value) async {
    state = state.copyWith(slowVolumeDecline: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.slowVolumeDecline, value);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist slowVolumeDecline setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }

    // Immediately update active or next sleep timer
    _ref.read(sleepTimerProvider.notifier).setSlowVolumeDecline(value);
  }

  /// Updates audio fade duration in seconds.
  Future<void> setFadeSeconds(int seconds) async {
    state = state.copyWith(fadeSeconds: seconds);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.fadeSeconds, seconds);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist fadeSeconds setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }

    // Immediately update active or next sleep timer
    _ref.read(sleepTimerProvider.notifier).setFadeSeconds(seconds);
  }

  /// Updates bedtime auto-timer toggle.
  Future<void> toggleBedtimeAutoTimer(bool value) async {
    state = state.copyWith(bedtimeAutoTimer: value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.bedtimeAutoTimer, value);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist bedtimeAutoTimer setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates bedtime start time in minutes after midnight.
  Future<void> setBedtimeStartMinutes(int minutes) async {
    state = state.copyWith(bedtimeStartMinutes: minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.bedtimeStartMinutes, minutes);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist bedtimeStartMinutes setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates bedtime auto-timer duration in minutes.
  Future<void> setBedtimeDurationMinutes(int minutes) async {
    state = state.copyWith(bedtimeDurationMinutes: minutes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(PrefKeys.bedtimeDurationMinutes, minutes);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist bedtimeDurationMinutes setting',
        tag: 'SettingsViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }
}
