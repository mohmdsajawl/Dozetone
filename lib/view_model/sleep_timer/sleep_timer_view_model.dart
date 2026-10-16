import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_durations.dart';
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
/// track completion triggers, and shake-to-extend gestures.
class SleepTimerViewModel extends StateNotifier<SleepTimerState> {
  final PlayerRepository _playerRepository;
  final Stream<UserAccelerometerEvent>? accelerometerStreamOverride;

  Timer? _ticker;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<void>? _trackCompletedSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  Song? _trackedSongForEndOfSong;
  PlayerState? _lastPlayerState;

  int _fadeSeconds = 30;
  bool _shakeToExtendEnabled = true;

  DateTime? _lastShakePeakTime;
  int _shakePeakCount = 0;
  DateTime? _lastShakeTriggerTime;

  SleepTimerViewModel(
    this._playerRepository, {
    this.accelerometerStreamOverride,
  }) : super(const SleepTimerState()) {
    _loadInitialPreferences();
  }

  /// Loads persisted last used choice and configured fade duration.
  Future<void> _loadInitialPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastChoice = prefs.getString(PrefKeys.lastTimerChoice);
      final fade = prefs.getInt(PrefKeys.fadeSeconds) ?? 30;
      final shakeEnabled = prefs.getBool(PrefKeys.shakeToExtend) ?? true;
      _fadeSeconds = fade;
      _shakeToExtendEnabled = shakeEnabled;

      state = state.copyWith(
        shakeToExtendEnabled: shakeEnabled,
      );

      if (lastChoice != null && lastChoice.isNotEmpty) {
        state = state.copyWith(lastUsedChoice: lastChoice);
      }
    } catch (_) {
      // SharedPreferences failure fallback to defaults
    }
  }

  /// Updates shake to extend setting and persists it.
  Future<void> setShakeToExtend(bool enabled) async {
    _shakeToExtendEnabled = enabled;
    state = state.copyWith(shakeToExtendEnabled: enabled);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.shakeToExtend, enabled);
    } catch (_) {}

    if (!enabled) {
      _stopShakeListening();
    } else if (state.isActive) {
      _startShakeListening();
    }
  }

  /// Starts a countdown sleep timer for [duration].
  ///
  /// [choiceLabel] is saved as the last used choice for quick re-selection.
  Future<void> startTimer(Duration duration, {String? choiceLabel}) async {
    _stopTicker();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);

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
    _startShakeListening();
  }

  /// Starts an "End of current track" timer that pauses when current track ends.
  Future<void> startEndOfSongTimer({String? choiceLabel}) async {
    _stopTicker();
    _cancelEndOfSongSubscription();

    _playerRepository.setPauseOnTrackEnd(true);

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

    // Track completion signal directly from player service
    _trackCompletedSubscription =
        _playerRepository.trackCompletedStream.listen((_) {
      _onTimerFinished();
    });

    // Track active song and position to detect progress, changes, and fade out
    _playerStateSubscription =
        _playerRepository.playerStateStream.listen(_handlePlayerStateForEndOfSong);

    _startTicker();
    _startShakeListening();
  }

  void _handlePlayerStateForEndOfSong(PlayerState playerState) {
    if (!mounted || !state.isActive || !state.isEndOfSong) return;

    _lastPlayerState = playerState;
    final song = playerState.currentSong;
    if (song == null) {
      // No active song playing, cancel timer
      cancelTimer();
      return;
    }

    if (_trackedSongForEndOfSong == null) {
      _trackedSongForEndOfSong = song;
    } else if (_trackedSongForEndOfSong!.id != song.id) {
      // Song changed (e.g. user manually changed track)
      _trackedSongForEndOfSong = song;
      if (state.isFadingOut) {
        _playerRepository.setVolume(1.0);
      }
    }

    _updateEndOfSongFade(playerState);
  }

  Future<void> _updateEndOfSongFade(PlayerState playerState) async {
    if (!mounted || !state.isActive || !state.isEndOfSong) return;

    final duration = playerState.duration;
    final position = playerState.position;

    if (duration <= Duration.zero) return;

    final remaining = duration - position;
    final remainingMs = remaining.inMilliseconds;

    if (remainingMs <= 0 && position >= duration) {
      await _onTimerFinished();
      return;
    }

    final fadeLengthMs = math.min(_fadeSeconds * 1000, duration.inMilliseconds);

    if (remainingMs <= fadeLengthMs && fadeLengthMs > 0 && playerState.isPlaying) {
      // Inside gentle fade-out window
      // Formula: factor = (remainingMs / fadeLengthMs)^2
      final progress = (remainingMs / fadeLengthMs).clamp(0.0, 1.0);
      final factor = math.pow(progress, 2).toDouble();

      await _playerRepository.setVolume(factor);

      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: true,
        volumeFactor: factor,
      );
    } else if (state.isFadingOut) {
      // Restores volume if sought backward out of fade window
      await _playerRepository.setVolume(1.0);
      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    } else {
      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    }
  }

  /// Extends active sleep timer by 5 minutes.
  ///
  /// If a fade-out was actively running, resets the fade and restores full volume.
  Future<void> add5Minutes() async {
    if (!state.isActive) return;

    if (state.isEndOfSong) {
      // Convert End of Track to 5-minute timed duration
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
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);

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
    _trackCompletedSubscription?.cancel();
    _trackCompletedSubscription = null;
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    _trackedSongForEndOfSong = null;
    _lastPlayerState = null;
  }

  Future<void> _tick() async {
    if (!mounted || !state.isActive) return;

    if (state.isEndOfSong) {
      if (_lastPlayerState != null) {
        await _updateEndOfSongFade(_lastPlayerState!);
      }
      return;
    }

    if (state.targetEndTime == null) return;

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
      if (!mounted || !state.isActive) return;

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
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);

    // 1. Pause playback
    await _playerRepository.pause();

    // 2. Restore internal player volume multiplier so next play session is clean
    await _playerRepository.setVolume(1.0);

    // 3. Deactivate timer state if still mounted
    if (!mounted) return;
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

  void _startShakeListening() {
    if (!_shakeToExtendEnabled || _accelerometerSubscription != null) return;

    runZonedGuarded(() {
      try {
        final stream =
            accelerometerStreamOverride ?? userAccelerometerEventStream();
        _accelerometerSubscription = stream.listen(
          _onAccelerometerEvent,
          onError: (_) {
            _stopShakeListening();
          },
          cancelOnError: false,
        );
      } catch (_) {
        _stopShakeListening();
      }
    }, (error, stack) {
      // Gracefully handle missing platform channels (e.g. unit tests or platforms without sensors)
      _stopShakeListening();
    });
  }

  void _stopShakeListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _lastShakePeakTime = null;
    _shakePeakCount = 0;
  }

  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    if (!mounted || !state.isActive) return;

    // Shake to extend is only valid when timer is nearing end or in fade-out
    final isNearingEnd = state.isFadingOut ||
        (state.remainingDuration > Duration.zero &&
            state.remainingDuration <= const Duration(seconds: 60)) ||
        (state.isEndOfSong && state.isFadingOut);

    if (!isNearingEnd) return;

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Shake threshold (m/s^2) for deliberate shaking
    const shakeThreshold = 12.0;

    if (magnitude < shakeThreshold) return;

    final now = DateTime.now();

    // Check debounce for entire shake action (ignore for 2.5s after successful trigger)
    if (_lastShakeTriggerTime != null &&
        now.difference(_lastShakeTriggerTime!) <
            const Duration(milliseconds: 2500)) {
      return;
    }

    // Double shake detection within AppDurations.shakeWindow (1.0 s)
    if (_lastShakePeakTime == null ||
        now.difference(_lastShakePeakTime!) > AppDurations.shakeWindow) {
      _shakePeakCount = 1;
      _lastShakePeakTime = now;
    } else if (now.difference(_lastShakePeakTime!) >
        const Duration(milliseconds: 100)) {
      _shakePeakCount++;
      _lastShakePeakTime = now;

      if (_shakePeakCount >= 2) {
        _shakePeakCount = 0;
        _lastShakeTriggerTime = now;
        _onShakeDetected();
      }
    }
  }

  Future<void> _onShakeDetected() async {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    await add5Minutes();
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
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);
    super.dispose();
  }
}
