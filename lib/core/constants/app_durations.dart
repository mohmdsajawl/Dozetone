/// Centralized animation and timing durations.
///
/// Keeps all motion synchronized and configurable without magic numbers.
abstract final class AppDurations {
  /// Standard UI micro-interaction animation duration (200 ms).
  static const Duration uiChange = Duration(milliseconds: 200);

  /// Search query input debounce duration (200 ms).
  static const Duration searchDebounce = Duration(milliseconds: 200);

  /// Now Playing sheet slide up transition (300 ms).
  static const Duration nowPlayingSlide = Duration(milliseconds: 300);

  /// Crossfade navigation transition duration (250 ms).
  static const Duration pageCrossfade = Duration(milliseconds: 250);

  /// Static splash pause when system reduce-motion is active (600 ms).
  static const Duration reduceMotionSplash = Duration(milliseconds: 600);

  /// Total duration of the animated sound wave splash controller (2.8 s).
  static const Duration splashTotal = Duration(milliseconds: 2800);

  /// Volume step interval during timer fade-out (250 ms).
  static const Duration fadeVolumeStep = Duration(milliseconds: 250);

  /// Volume ramp duration when canceling fade or adding 5 minutes (1.0 s).
  static const Duration volumeRamp = Duration(milliseconds: 1000);

  /// Timer clock tick interval for UI update (1.0 s).
  static const Duration timerTicker = Duration(seconds: 1);

  /// Double shake detection window (1.0 s).
  static const Duration shakeWindow = Duration(seconds: 1);
}
