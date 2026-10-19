/// Centralized constants for sleep timer volume curves and transitions.
///
/// Keeps sleep timer math and threshold numbers synchronized without magic numbers.
abstract final class SleepTimerConstants {
  /// Target volume factor reached at the start of the fade window
  /// when slow volume decline is enabled (0.6, or 60%).
  static const double slowDeclineTargetFactor = 0.6;

  /// Maximum allowed volume factor increase per 250 ms tick (0.1).
  ///
  /// Prevents sudden audio jumps when extending the timer or shaking the device.
  static const double maxVolumeIncreasePerTick = 0.1;
}
