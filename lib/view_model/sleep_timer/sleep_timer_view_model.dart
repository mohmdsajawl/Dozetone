import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart' show Locale;
import '../../core/constants/app_durations.dart';
import '../../core/constants/pref_keys.dart';
import '../../core/constants/sleep_timer_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/sleep_volume_curve.dart';
import '../../core/utils/timer_notification_text.dart';
import '../../data/repositories/player_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../model/player_state.dart';
import '../../model/sleep_timer_state.dart';
import '../../model/song.dart';
import '../../model/timer_notification_action.dart';

/// Provider exposing the singleton application-level SleepTimerViewModel.
///
/// Lives at the app root so the sleep timer survives screen transitions
/// and continues running during lockscreen background playback.
final sleepTimerProvider =
    StateNotifierProvider<SleepTimerViewModel, SleepTimerState>((ref) {
  final playerRepository = ref.watch(playerRepositoryProvider);
  return SleepTimerViewModel(playerRepository);
});

/// Provider exposing bedtime auto-start event stream.
final bedtimeAutoStartStreamProvider = StreamProvider<Duration>((ref) {
  final vm = ref.watch(sleepTimerProvider.notifier);
  return vm.bedtimeAutoStartStream;
});

/// ViewModel managing sleep timer countdown, gentle volume fade-out,
/// track completion triggers, and shake-to-extend gestures.
class SleepTimerViewModel extends StateNotifier<SleepTimerState> {
  final PlayerRepository _playerRepository;
  final Stream<UserAccelerometerEvent>? accelerometerStreamOverride;

  Timer? _ticker;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<PlayerState>? _bedtimePlaybackSubscription;
  StreamSubscription<void>? _trackCompletedSubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<TimerNotificationAction>?
      _timerNotificationActionSubscription;
  Song? _trackedSongForEndOfSong;
  PlayerState? _lastPlayerState;

  final _bedtimeAutoStartController = StreamController<Duration>.broadcast();

  /// Stream emitting bedtime auto-timer durations when automatically triggered.
  Stream<Duration> get bedtimeAutoStartStream =>
      _bedtimeAutoStartController.stream;

  int _fadeSeconds = 30;
  bool _shakeToExtendEnabled = true;
  bool _slowVolumeDecline = true;
  double _appliedVolumeFactor = 1.0;
  DateTime? _lastVolumeDebugPrintTime;

  /// Whether slow volume decline is currently enabled for time-based timers.
  bool get slowVolumeDecline => _slowVolumeDecline;

  /// Updates the slow volume decline setting and applies it immediately.
  void setSlowVolumeDecline(bool enabled) {
    _slowVolumeDecline = enabled;
  }

  /// Updates the audio fade-out duration in seconds immediately.
  void setFadeSeconds(int seconds) {
    _fadeSeconds = seconds;
  }

  DateTime? _lastShakePeakTime;
  int _shakePeakCount = 0;
  DateTime? _lastShakeTriggerTime;
  String? _lastNotificationText;
  RemoveListener? _removeNotificationListener;

  SleepTimerViewModel(
    this._playerRepository, {
    this.accelerometerStreamOverride,
  }) : super(const SleepTimerState()) {
    _loadInitialPreferences();
    _listenToPlaybackForBedtime();
    _listenToTimerNotificationActions();
    _removeNotificationListener = addListener(_syncNotification);
  }

  /// Single point of synchronization for media notification action and status text.
  void _syncNotification(SleepTimerState s) {
    _playerRepository.setTimerActionVisible(s.isActive);

    final text = buildTimerNotificationText(
      state: s,
      l10n: lookupAppLocalizations(const Locale('en')),
    );
    if (_lastNotificationText != text) {
      _lastNotificationText = text;
      _playerRepository.setTimerNotificationText(text);
    }
  }

  void _listenToPlaybackForBedtime() {
    _bedtimePlaybackSubscription =
        _playerRepository.playerStateStream.listen((playerState) {
      final wasPlaying = _lastPlayerState?.isPlaying ?? false;
      _lastPlayerState = playerState;
      if (!wasPlaying && playerState.isPlaying) {
        checkAndTriggerBedtimeAutoTimer();
      }
    });
  }

  /// Subscribes to notification custom actions (e.g. +5 min button tapped).
  void _listenToTimerNotificationActions() {
    _timerNotificationActionSubscription =
        _playerRepository.timerNotificationActions.listen((action) {
      if (action == TimerNotificationAction.addFiveMinutes) {
        // Tapping +5 min on notification triggers the exact same logic as in-app button
        if (state.isActive) {
          add5Minutes();
        }
      }
    });
  }

  /// Loads persisted last used choice and configured fade duration.
  Future<void> _loadInitialPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastChoice = prefs.getString(PrefKeys.lastTimerChoice);
      final fade = prefs.getInt(PrefKeys.fadeSeconds) ?? 30;
      final shakeEnabled = prefs.getBool(PrefKeys.shakeToExtend) ?? true;
      final slowDecline = prefs.getBool(PrefKeys.slowVolumeDecline) ?? true;
      _fadeSeconds = fade;
      _shakeToExtendEnabled = shakeEnabled;
      _slowVolumeDecline = slowDecline;

      state = state.copyWith(
        shakeToExtendEnabled: shakeEnabled,
      );

      if (lastChoice != null && lastChoice.isNotEmpty) {
        state = state.copyWith(lastUsedChoice: lastChoice);
      }
    } catch (e, st) {
      AppLogger.w(
        'Failed to load persisted sleep timer preferences, using defaults',
        tag: 'SleepTimerViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Updates shake to extend setting and persists it.
  Future<void> setShakeToExtend(bool enabled) async {
    _shakeToExtendEnabled = enabled;
    state = state.copyWith(shakeToExtendEnabled: enabled);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(PrefKeys.shakeToExtend, enabled);
    } catch (e, st) {
      AppLogger.e(
        'Failed to persist shakeToExtend preference',
        tag: 'SleepTimerViewModel',
        error: e,
        stackTrace: st,
      );
    }

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
    _playerRepository.setLoopForSleepTimer(true);

    final now = DateTime.now();
    final endTime = now.add(duration);

    if (choiceLabel != null) {
      _saveLastUsedChoice(choiceLabel);
    }

    _appliedVolumeFactor = 1.0;
    _lastVolumeDebugPrintTime = null;

    // Ensure volume starts at 1.0
    await _playerRepository.setVolume(1.0);

    state = state.copyWith(
      isActive: true,
      targetEndTime: endTime,
      totalDuration: duration,
      remainingDuration: duration,
      isFadingOut: false,
      isEndOfSong: false,
      isTrackBased: false,
      totalTracks: 0,
      remainingTracks: 0,
      selectedTracks: const <Song>[],
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
    _playerRepository.setLoopForSleepTimer(true);

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
      isTrackBased: false,
      totalTracks: 0,
      remainingTracks: 0,
      selectedTracks: const <Song>[],
      volumeFactor: 1.0,
      lastUsedChoice: choiceLabel ?? 'End of current track',
    );

    _trackCompletedSubscription =
        _playerRepository.trackCompletedStream.listen((_) {
      _onTrackCompleted();
    });

    _playerStateSubscription =
        _playerRepository.playerStateStream.listen(_handlePlayerStateForEndOfSong);

    _startTicker();
    _startShakeListening();
  }

  /// Starts a track-based timer that pauses playback after [trackCount] tracks finish.
  ///
  /// Optionally accepts [specificTracks] if the user handpicked specific songs.
  Future<void> startTracksTimer({
    required int trackCount,
    List<Song>? specificTracks,
    String? choiceLabel,
  }) async {
    if (trackCount <= 0) return;

    _stopTicker();
    _cancelEndOfSongSubscription();

    final isSingleTrack = trackCount == 1;
    _playerRepository.setPauseOnTrackEnd(isSingleTrack);
    _playerRepository.setLoopForSleepTimer(true);

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
      isEndOfSong: isSingleTrack,
      isTrackBased: true,
      totalTracks: trackCount,
      remainingTracks: trackCount,
      selectedTracks: specificTracks ?? const <Song>[],
      volumeFactor: 1.0,
      lastUsedChoice: choiceLabel ?? state.lastUsedChoice,
    );

    _trackCompletedSubscription =
        _playerRepository.trackCompletedStream.listen((_) {
      _onTrackCompleted();
    });

    _playerStateSubscription =
        _playerRepository.playerStateStream.listen(_handlePlayerStateForEndOfSong);

    _startTicker();
    _startShakeListening();
  }

  /// Adjusts active time-based timer by [delta] (positive or negative).
  Future<void> adjustTime(Duration delta) async {
    if (!state.isActive) return;

    if (state.isTrackBased) {
      // If currently track-based, convert to time-based timer (15 min base)
      const baseMinutes = 15;
      final newDuration = const Duration(minutes: baseMinutes) + delta;
      await startTimer(
        newDuration > const Duration(minutes: 1)
            ? newDuration
            : const Duration(minutes: 1),
      );
      return;
    }

    final currentTarget = state.targetEndTime ?? DateTime.now();
    final newEndTime = currentTarget.add(delta);
    final remaining = newEndTime.difference(DateTime.now());

    if (remaining <= Duration.zero) {
      await _onTimerFinished();
      return;
    }

    final newTotal = (state.totalDuration ?? Duration.zero) + delta;
    final resolvedTotal = newTotal > Duration.zero ? newTotal : remaining;

    state = state.copyWith(
      targetEndTime: newEndTime,
      totalDuration: resolvedTotal,
      remainingDuration: remaining,
      isFadingOut: remaining <= Duration(seconds: _fadeSeconds),
    );
  }

  /// Sets active countdown to exact [duration].
  Future<void> setTime(Duration duration) async {
    if (duration <= Duration.zero) {
      await _onTimerFinished();
      return;
    }

    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);

    final now = DateTime.now();
    final endTime = now.add(duration);

    state = state.copyWith(
      isActive: true,
      targetEndTime: endTime,
      totalDuration: duration,
      remainingDuration: duration,
      isFadingOut: duration <= Duration(seconds: _fadeSeconds),
      isEndOfSong: false,
      isTrackBased: false,
      totalTracks: 0,
      remainingTracks: 0,
      selectedTracks: const <Song>[],
    );

    if (_ticker == null) {
      _startTicker();
    }
    _startShakeListening();
  }

  /// Dynamically increments remaining tracks for track-based sleep timer.
  Future<void> addTracks(int count) async {
    if (!state.isActive || !state.isTrackBased) return;
    final newRemaining = state.remainingTracks + count;
    final newTotal = state.totalTracks + count;

    if (newRemaining > 1) {
      _playerRepository.setPauseOnTrackEnd(false);
      if (state.isFadingOut) {
        await _playerRepository.setVolume(1.0);
      }
    }

    state = state.copyWith(
      remainingTracks: newRemaining,
      totalTracks: newTotal,
      isEndOfSong: newRemaining == 1,
      isFadingOut: false,
      volumeFactor: 1.0,
    );
  }

  /// Dynamically decrements remaining tracks for track-based sleep timer.
  Future<void> removeTracks(int count) async {
    if (!state.isActive || !state.isTrackBased) return;
    final newRemaining = state.remainingTracks - count;
    if (newRemaining <= 0) {
      await _onTimerFinished();
      return;
    }

    if (newRemaining == 1) {
      _playerRepository.setPauseOnTrackEnd(true);
    }

    List<Song> updatedSelected = state.selectedTracks;
    if (updatedSelected.length > newRemaining) {
      updatedSelected = updatedSelected.sublist(0, newRemaining);
    }

    state = state.copyWith(
      remainingTracks: newRemaining,
      selectedTracks: updatedSelected,
      isEndOfSong: newRemaining == 1,
    );
  }

  /// Updates user-selected songs list for active track-based timer.
  Future<void> updateSelectedTracks(List<Song> newTracks) async {
    if (newTracks.isEmpty) {
      await cancelTimer();
      return;
    }

    final newRemaining = newTracks.length;
    final newTotal = math.max(state.totalTracks, newTracks.length);

    if (newRemaining == 1) {
      _playerRepository.setPauseOnTrackEnd(true);
    } else {
      _playerRepository.setPauseOnTrackEnd(false);
      if (state.isFadingOut) {
        await _playerRepository.setVolume(1.0);
      }
    }

    state = state.copyWith(
      selectedTracks: newTracks,
      remainingTracks: newRemaining,
      totalTracks: newTotal,
      isEndOfSong: newRemaining == 1,
      isFadingOut: false,
      volumeFactor: 1.0,
    );
  }

  void _onTrackCompleted() async {
    if (!mounted || !state.isActive) return;

    if (state.isTrackBased && state.remainingTracks > 1) {
      final nextRemaining = state.remainingTracks - 1;
      List<Song> nextSelected = state.selectedTracks;
      if (nextSelected.isNotEmpty) {
        nextSelected = nextSelected.sublist(1);
      }

      if (nextRemaining == 1) {
        _playerRepository.setPauseOnTrackEnd(true);
      }

      // Reset stale player state and volume for transitioning to next track
      _lastPlayerState = null;
      _trackedSongForEndOfSong = null;
      await _playerRepository.setVolume(1.0);

      state = state.copyWith(
        remainingTracks: nextRemaining,
        selectedTracks: nextSelected,
        isEndOfSong: nextRemaining == 1,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    } else {
      await _onTimerFinished();
    }
  }

  void _handlePlayerStateForEndOfSong(PlayerState playerState) {
    if (!mounted || !state.isActive) return;
    if (!state.isEndOfSong && (!state.isTrackBased || state.remainingTracks > 1)) {
      return;
    }

    _lastPlayerState = playerState;
    final song = playerState.currentSong;
    if (song == null && playerState.queue.isEmpty) {
      // No active song and queue empty, cancel timer
      cancelTimer();
      return;
    }
    if (song == null) return;

    if (_trackedSongForEndOfSong == null) {
      _trackedSongForEndOfSong = song;
    } else if (_trackedSongForEndOfSong!.id != song.id) {
      // Song changed (e.g. next track started or user changed track)
      _trackedSongForEndOfSong = song;
      _playerRepository.setVolume(1.0);
      if (state.isFadingOut) {
        state = state.copyWith(isFadingOut: false, volumeFactor: 1.0);
      }
    }

    if (state.remainingTracks <= 1 || state.isEndOfSong) {
      _updateEndOfSongFade(playerState);
    }
  }

  Future<void> _updateEndOfSongFade(PlayerState playerState) async {
    if (!mounted || !state.isActive) return;
    if (!state.isEndOfSong && state.remainingTracks > 1) return;

    final duration = playerState.duration;
    final position = playerState.position;

    if (duration <= Duration.zero) return;

    final remaining = duration - position;
    final remainingMs = remaining.inMilliseconds;

    if (remainingMs <= 0 && position >= duration) {
      await _playerRepository.setVolume(0.0);
      return;
    }

    final fadeLengthMs = math.min(_fadeSeconds * 1000, duration.inMilliseconds);

    if (remainingMs <= fadeLengthMs && fadeLengthMs > 0 && playerState.isPlaying) {
      // Inside gentle fade-out window
      // Formula: factor = (remainingMs / fadeLengthMs)^2
      final progress = (remainingMs / fadeLengthMs).clamp(0.0, 1.0);
      final factor = math.pow(progress, 2).toDouble();

      await _playerRepository.setVolume(factor);

      if (!mounted || !state.isActive) return;
      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: true,
        volumeFactor: factor,
      );
    } else if (state.isFadingOut) {
      // Restores volume if sought backward out of fade window
      await _playerRepository.setVolume(1.0);
      if (!mounted || !state.isActive) return;
      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    } else {
      if (!mounted || !state.isActive) return;
      state = state.copyWith(
        remainingDuration: remaining > Duration.zero ? remaining : Duration.zero,
        isFadingOut: false,
        volumeFactor: 1.0,
      );
    }
  }

  /// Extends active sleep timer by 5 minutes or 1 track.
  Future<void> add5Minutes() async {
    if (!state.isActive) return;

    if (state.isTrackBased) {
      await addTracks(1);
      return;
    }

    await adjustTime(const Duration(minutes: 5));
  }

  /// Cancels any active sleep timer and restores audio volume multiplier to 1.0.
  Future<void> cancelTimer() async {
    _stopTicker();
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);
    _playerRepository.setLoopForSleepTimer(false);

    _appliedVolumeFactor = 1.0;
    _lastVolumeDebugPrintTime = null;
    await _playerRepository.setVolume(1.0);

    state = state.copyWith(
      isActive: false,
      targetEndTime: null,
      totalDuration: null,
      remainingDuration: Duration.zero,
      isFadingOut: false,
      isEndOfSong: false,
      isTrackBased: false,
      totalTracks: 0,
      remainingTracks: 0,
      selectedTracks: const <Song>[],
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

    if (state.isEndOfSong || state.isTrackBased) {
      if (_lastPlayerState != null &&
          (state.remainingTracks <= 1 || state.isEndOfSong)) {
        await _updateEndOfSongFade(_lastPlayerState!);
      }
      return;
    }

    if (state.targetEndTime == null) return;

    // Wall-clock time (DateTime.now()) is used here because it continues counting
    // during device deep sleep, which Dart's monotonic Stopwatch does not count.
    // Known limitation: if the user changes the system time manually, the timer is affected.
    await _updateTimeBasedVolume(DateTime.now());
  }

  Future<void> _updateTimeBasedVolume(DateTime now) async {
    if (state.targetEndTime == null) return;

    final remaining = state.targetEndTime!.difference(now);

    if (remaining <= Duration.zero) {
      await _onTimerFinished();
      return;
    }

    final total = state.totalDuration ?? remaining;
    final fade = Duration(seconds: _fadeSeconds);

    final targetFactor = computeTimerVolumeFactor(
      remaining: remaining,
      total: total,
      fade: fade,
      declineEnabled: _slowVolumeDecline,
    );

    double nextFactor;
    if (targetFactor > _appliedVolumeFactor) {
      // Limit any increase to at most maxVolumeIncreasePerTick (0.1) per tick
      nextFactor = math.min(
        targetFactor,
        _appliedVolumeFactor + SleepTimerConstants.maxVolumeIncreasePerTick,
      );
    } else {
      // Decreases follow the calculated curve directly
      nextFactor = targetFactor;
    }

    _appliedVolumeFactor = nextFactor;
    await _playerRepository.setVolume(nextFactor);

    if (kDebugMode) {
      if (_lastVolumeDebugPrintTime == null ||
          now.difference(_lastVolumeDebugPrintTime!) >=
              const Duration(seconds: 5)) {
        _lastVolumeDebugPrintTime = now;
        debugPrint(
          'SleepTimer volume factor: ${nextFactor.toStringAsFixed(3)}',
        );
      }
    }

    if (!mounted || !state.isActive) return;

    final isFading = remaining <= fade && fade > Duration.zero;
    state = state.copyWith(
      remainingDuration: remaining,
      isFadingOut: isFading,
      volumeFactor: nextFactor,
    );
  }

  Future<void> _onTimerFinished() async {
    _stopTicker();
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);
    _playerRepository.setLoopForSleepTimer(false);

    // 1. Pause playback
    await _playerRepository.pause();

    // 2. Restore internal player volume multiplier so next play session is clean
    _appliedVolumeFactor = 1.0;
    _lastVolumeDebugPrintTime = null;
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
      isTrackBased: false,
      totalTracks: 0,
      remainingTracks: 0,
      selectedTracks: const <Song>[],
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
          onError: (dynamic error) {
            AppLogger.w(
              'Accelerometer stream emitted error',
              tag: 'SleepTimerViewModel',
              error: error,
            );
            _stopShakeListening();
          },
          cancelOnError: false,
        );
      } catch (e, st) {
        AppLogger.w(
          'Failed to initialize accelerometer stream',
          tag: 'SleepTimerViewModel',
          error: e,
          stackTrace: st,
        );
        _stopShakeListening();
      }
    }, (error, stack) {
      AppLogger.d(
        'Missing platform sensor channel (expected in unit tests or unsupported hardware)',
        tag: 'SleepTimerViewModel',
        error: error,
      );
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
    } catch (e) {
      AppLogger.d(
        'HapticFeedback not supported or failed',
        tag: 'SleepTimerViewModel',
        error: e,
      );
    }
    await add5Minutes();
  }

  Future<void> _saveLastUsedChoice(String choice) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(PrefKeys.lastTimerChoice, choice);
    } catch (e, st) {
      AppLogger.w(
        'Failed to persist lastTimerChoice',
        tag: 'SleepTimerViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Checks whether [now] falls within the configured bedtime window.
  ///
  /// The window begins at [startMinutes] after midnight and ends at [endMinutes]
  /// after midnight (default: 300 minutes -> 5:00 AM).
  /// Correctly handles windows that cross midnight (e.g. 10:00 PM to 5:00 AM).
  static bool isInsideBedtimeWindow({
    required DateTime now,
    required int startMinutes,
    int endMinutes = 300,
  }) {
    final currentMinutes = now.hour * 60 + now.minute;
    if (startMinutes > endMinutes) {
      // Window crosses midnight (e.g., 22:00 [1320] to 05:00 [300])
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Window does not cross midnight (e.g., 01:00 [60] to 05:00 [300])
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Evaluates bedtime auto-timer conditions and activates the timer if eligible.
  ///
  /// Requires:
  /// 1. No sleep timer currently running.
  /// 2. Bedtime auto-timer enabled in SharedPreferences.
  /// 3. Current local time inside bedtime window (start time to 5:00 AM).
  /// 4. At least 60 minutes passed since last auto-start (prevents re-trigger spam).
  Future<bool> checkAndTriggerBedtimeAutoTimer([DateTime? currentTime]) async {
    if (state.isActive) return false;

    final now = currentTime ?? DateTime.now();

    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(PrefKeys.bedtimeAutoTimer) ?? false;
      if (!enabled) return false;

      final startMinutes = prefs.getInt(PrefKeys.bedtimeStartMinutes) ?? 1320;
      if (!isInsideBedtimeWindow(now: now, startMinutes: startMinutes)) {
        return false;
      }

      final lastTimestamp =
          prefs.getInt(PrefKeys.lastBedtimeAutoStartTimestamp) ?? 0;
      const cooldownMs = 60 * 60 * 1000; // 60 minutes cooldown
      if (now.millisecondsSinceEpoch - lastTimestamp < cooldownMs) {
        return false;
      }

      final durationMinutes =
          prefs.getInt(PrefKeys.bedtimeDurationMinutes) ?? 30;
      final duration = Duration(minutes: durationMinutes);

      // Persist trigger timestamp
      await prefs.setInt(
        PrefKeys.lastBedtimeAutoStartTimestamp,
        now.millisecondsSinceEpoch,
      );

      // Start the sleep timer
      await startTimer(duration, choiceLabel: 'Bedtime auto-timer');

      // Notify UI
      _bedtimeAutoStartController.add(duration);
      return true;
    } catch (e, st) {
      AppLogger.e(
        'Failed to trigger bedtime auto-timer',
        tag: 'SleepTimerViewModel',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  @override
  void dispose() {
    _removeNotificationListener?.call();
    _playerRepository.setTimerActionVisible(false);
    _playerRepository.setTimerNotificationText(null);
    _timerNotificationActionSubscription?.cancel();
    _bedtimePlaybackSubscription?.cancel();
    _bedtimeAutoStartController.close();
    _stopTicker();
    _stopShakeListening();
    _cancelEndOfSongSubscription();
    _playerRepository.setPauseOnTrackEnd(false);
    _playerRepository.setLoopForSleepTimer(false);
    super.dispose();
  }
}
