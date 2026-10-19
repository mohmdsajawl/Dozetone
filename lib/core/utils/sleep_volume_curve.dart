import '../constants/sleep_timer_constants.dart';

/// Computes the volume factor for time-based sleep timers.
///
/// Follows the gentle volume decline specification:
/// 1. If [declineEnabled] is false:
///    - 1.0 factor before the fade window.
///    - (remaining / fade)^2 quadratic decay inside the fade window.
/// 2. If [declineEnabled] is true:
///    - If [total] <= [fade]: no pre-fade part exists, so normal fade is used (start factor 1.0).
///    - If [total] > [fade]:
///      - Pre-fade window: linear decrease from 1.0 at timer start to 0.6 at fade window start.
///      - Fade window: 0.6 * (remaining / fade)^2.
/// 3. If [remaining] <= Duration.zero, returns 0.0.
double computeTimerVolumeFactor({
  required Duration remaining,
  required Duration total,
  required Duration fade,
  required bool declineEnabled,
}) {
  if (remaining <= Duration.zero || total <= Duration.zero) {
    return 0.0;
  }

  final effectiveRemaining = remaining > total ? total : remaining;
  final effectiveFade = fade > total ? total : (fade < Duration.zero ? Duration.zero : fade);

  // If fade duration is zero, volume stays at 1.0 (or pre-fade decay) until timer finishes.
  if (effectiveFade <= Duration.zero) {
    if (!declineEnabled) {
      return 1.0;
    }
    final preFadeUs = total.inMicroseconds.toDouble();
    final elapsedUs = (total - effectiveRemaining).inMicroseconds.toDouble();
    final progress = (elapsedUs / preFadeUs).clamp(0.0, 1.0);
    return 1.0 - (1.0 - SleepTimerConstants.slowDeclineTargetFactor) * progress;
  }

  // If total duration is less than or equal to fade window, no pre-fade window exists.
  // Standard quadratic fade starting from 1.0 is used.
  if (total <= effectiveFade) {
    final progress = (effectiveRemaining.inMicroseconds / effectiveFade.inMicroseconds).clamp(0.0, 1.0);
    return progress * progress;
  }

  final preFade = total - effectiveFade;

  if (effectiveRemaining <= effectiveFade) {
    // Inside the fade window
    final progress = (effectiveRemaining.inMicroseconds / effectiveFade.inMicroseconds).clamp(0.0, 1.0);
    final baseFactor = progress * progress;
    if (declineEnabled) {
      return SleepTimerConstants.slowDeclineTargetFactor * baseFactor;
    } else {
      return baseFactor;
    }
  } else {
    // Before the fade window (pre-fade region)
    if (!declineEnabled) {
      return 1.0;
    }
    final elapsedUs = (total - effectiveRemaining).inMicroseconds.toDouble();
    final preFadeUs = preFade.inMicroseconds.toDouble();
    final progress = (elapsedUs / preFadeUs).clamp(0.0, 1.0);
    return 1.0 - (1.0 - SleepTimerConstants.slowDeclineTargetFactor) * progress;
  }
}
