import '../../l10n/generated/app_localizations.dart';
import '../../model/sleep_timer_state.dart';

/// Formats the sleep timer status prefix for the media notification artist line.
///
/// Returns null when the sleep timer is inactive.
String? buildTimerNotificationText({
  required SleepTimerState state,
  required AppLocalizations l10n,
}) {
  if (!state.isActive) {
    return null;
  }

  // Fading out takes highest priority when active
  if (state.isFadingOut) {
    return l10n.notificationTimerFading;
  }

  // Track-based multi-track countdown
  if (state.isTrackBased) {
    return l10n.notificationTimerTracks(state.remainingTracks);
  }

  // End of current track timer
  if (state.isEndOfSong) {
    return l10n.notificationTimerEndOfSong;
  }

  // Time-based countdown timer
  final remainingSeconds = state.remainingDuration.inSeconds;
  if (remainingSeconds < 60) {
    return l10n.notificationTimerUnderMinute;
  }

  final minutes = (remainingSeconds / 60).ceil();
  return l10n.notificationTimerMinutes(minutes);
}
