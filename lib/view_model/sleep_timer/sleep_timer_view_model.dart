import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';
import '../../data/repositories/player_repository.dart';
import '../../model/player_state.dart';
import '../../model/sleep_timer_state.dart';
import '../../model/song.dart';

/// Provider exposing the singleton application-level SleepTimerViewModel.
///
/// Lives at the app root so the sleep timer survives screen transitions
/// and continues running during lockscreen background playback.
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerViewModel, SleepTimerState>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  return SleepTimerViewModel(playerRepository);
});

/// ViewModel managing sleep timer countdown, gentle volume fade-out,
/// and track completion triggers.
class SleepTimerViewModel extends StateNotifier<SleepTimerState> {
  final PlayerRepository _playerRepository;

  Timer? _ticker;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Song? _trackedSongForEndOfSong;

  int _fadeSeconds = 30;

  SleepTimerViewModel(this._playerRepository)
      : super(const SleepTimerState()) {
    _loadInitialPreferences();
  }

  /// Loads persisted last used choice and configured fade duration.
  Future<void> _loadInitialPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastChoice = prefs.getString(PrefKeys.lastTimerChoice) ?? '30 minutes';
      final fade = prefs.getInt(PrefKeys.fadeSeconds) ?? 30;
      _fadeSeconds = fade;

      state = state.copyWith(lastUsedChoice: lastChoice);
    } catch (_) {
      // SharedPreferences failure fallback to defaults
    }
  }

  /// Starts a countdown sleep timer for [duration].
  ///
  /// [choiceLabel] is saved as the last used choice for quick re-selection.
  Future<void> startTimer(Duration duration, {String? choiceLabel}) async {
    _stopTicker();
    _cancelEndOfSongSubscription();

    final now = DateTime.now();
    final endTime = now.add(duration);

    if (choiceLabel != null) {
      _saveLastUsedChoice(choiceLabel);
    }

    // Ensure volume starts at 1.0
    await _playerRepository.setVolume(1.0);

    state = state.copyWith(
      isActive: true,
      targetEndTime: endTime,
      totalDuration: duration,
      remainingDuration: duration,
      isFadingOut: false,
      isEndOfSong: false,
      volumeFactor: 1.0,
      lastUsedChoice: choiceLabel ?? state.lastUsedChoice,
    );

    _startTicker();
  }

  /// Starts an "End of current song" timer that pauses when current track ends.
  Future<void> startEndOfSongTimer({String? choiceLabel}) async {
    _stopTicker();
    _cancelEndOfSongSubscription();

    if (choiceLabel != null) {
      _saveLastUsedChoice(choiceLabel);
    }

    await _playerRepository.setVolume(1.0);

    state = state.copyWith(
      isActive: true,
      targetEndTime: null,
      totalDuration: null,
      remainingDuration: Duration.zero,
      isFadingOut: false,
      isEndOfSong: true,
      volumeFactor: 1.0,
      lastUsedChoice: choiceLabel ?? state.lastUsedChoice,
    );

    // Track active song to detect when it changes or finishes
    _playerStateSubscription =
        _playerRepository.playerStateStream.listen(_handlePlayerStateForEndOfSong);
  }

  void _handlePlayerStateForEndOfSong(PlayerState playerState) {
    if (!state.isActive || !state.isEndOfSong) return;

    final song = playerState.currentSong;
    if (song == null) {
      // No active song playing, cancel timer
      cancelTimer();
      return;
    }

    if (_trackedSongForEndOfSong == null) {
      _trackedSongForEndOfSong = song;
      return;
    }

    // Track has changed (or finished and skipped)
    if (_trackedSongForEndOfSong!.id != song.id) {
      _trackedSongForEndOfSong = null;
      _onTimerFinished();
      return;
    }

    // Song position reached or exceeded track duration
    if (playerState.duration > Duration.zero &&
        playerState.position >= playerState.duration) {
      _trackedSongForEndOfSong = null;
      _onTimerFinished();
    }
  }

  /// Extends active sleep timer by 5 minutes.
  ///
  /// If a fade-out was actively running, resets the fade and restores full volume.
  Future<void> add5Minutes() async {
    if (!state.isActive) return;

    if (state.isEndOfSong) {
      // Convert End of Song to 5-minute timed duration
      await startTimer(const Duration(minutes: 5));
      return;
    }

    final currentTarget = state.targetEndTime ?? DateTime.now();
    final newEndTime = currentTarget.add(const Duration(minutes: 5));
    final newTotal = (state.totalDuration ?? Duration.zero) + const Duration(minutes: 5);

    // If currently fading, restore full volume
    if (state.isFadingOut) {
      await _playerRepository.setVolume(1.0);
    }

    final remaining = newEndTime.difference(DateTime.now());

    state = state.copyWith(
      targetEndTime: newEndTime,
      totalDuration: newTotal,
      remainingDuration: remaining.isNegative ? Duration.zero : remaining,
      isFadingOut: false,
      volumeFactor: 1.0,
    );
  }

  /// Cancels any active sleep timer and restores audio volume multiplier to 1.0.
  Future<void> cancelTimer() async {
    _stopTicker();
    _cancelEndOfSongSubscription();

    await _playerRepository.setVolume(1.0);

    state = state.copyWith(
      isActive: false,
      targetEndTime: null,
      totalDuration: null,
      remainingDuration: Duration.zero,
      isFadingOut: false,
      isEndOfSong: false,
      volumeFactor: 1.0,
    );
  }

  void _startTicker() {
    // 250ms interval ensures smooth volume stepping 4 times per second during fade
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _tick();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _cancelEndOfSongSubscription() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _trackedSongForEndOfSong = null;
  }

  Future<void> _tick() async {
    if (!state.isActive || state.targetEndTime == null) return;

    final now = DateTime.now();
    final remaining = state.targetEndTime!.difference(now);

    if (remaining <= Duration.zero) {
      await _onTimerFinished();
      return;
    }

    final totalMs = state.totalDuration?.inMilliseconds ?? 0;
    final remainingMs = remaining.inMilliseconds;
    final fadeLengthMs = math.min(_fadeSeconds * 1000, totalMs);

    if (remainingMs <= fadeLengthMs && fadeLengthMs > 0) {
      // Inside gentle fade-out window
      // Formula: factor = (remainingMs / fadeLengthMs)^2
      final progress = (remainingMs / fadeLengthMs).clamp(0.0, 1.0);
      final factor = math.pow(progress, 2).toDouble();

      await _playerRepository.setVolume(factor);

      state = state.copyWith(
        remainingDuration: remaining,
        isFadingOut: true,
        volumeFactor: factor,
      );
    } else {
      // Normal countdown before fade-out
      state = state.copyWith(
        remainingDuration: remaining,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    }
  }

  Future<void> _onTimerFinished() async {
    _stopTicker();
    _cancelEndOfSongSubscription();

    // 1. Pause playback
    await _playerRepository.pause();

    // 2. Restore internal player volume multiplier so next play session is clean
    await _playerRepository.setVolume(1.0);

    // 3. Deactivate timer state
    state = state.copyWith(
      isActive: false,
      targetEndTime: null,
      totalDuration: null,
      remainingDuration: Duration.zero,
      isFadingOut: false,
      isEndOfSong: false,
      volumeFactor: 1.0,
    );
  }

  Future<void> _saveLastUsedChoice(String choice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefKeys.lastTimerChoice, choice);
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopTicker();
    _cancelEndOfSongSubscription();
    super.dispose();
  }
}
