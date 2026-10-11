// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dozetone';

  @override
  String get libraryTitle => 'Library';

  @override
  String get searchPlaceholder => 'Search by title or artist...';

  @override
  String get scanningMusic => 'Scanning your music...';

  @override
  String get noSongsFound => 'No songs found';

  @override
  String get shortSongsHiddenHint => 'Songs shorter than 30 seconds are hidden';

  @override
  String noSearchResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get permissionRequired =>
      'Audio permission is required to play local songs';

  @override
  String get grantPermission => 'Grant permission';

  @override
  String get openSettings => 'Open settings';

  @override
  String get retry => 'Retry';

  @override
  String get unknownTitle => 'Unknown Title';

  @override
  String get unknownArtist => 'Unknown Artist';

  @override
  String get nowPlayingTitle => 'Now playing';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get timerPreset5Min => '5 minutes';

  @override
  String get timerPreset10Min => '10 minutes';

  @override
  String get timerPreset15Min => '15 minutes';

  @override
  String get timerPreset30Min => '30 minutes';

  @override
  String get timerPreset45Min => '45 minutes';

  @override
  String get timerPreset60Min => '60 minutes';

  @override
  String get timerCustom => 'Custom';

  @override
  String get timerEndOfSong => 'End of current song';

  @override
  String get lastUsed => 'Last used';

  @override
  String timerSetSnackbar(String duration) {
    return 'Sleep timer set for $duration';
  }

  @override
  String get add5Min => 'Add 5 min';

  @override
  String get cancelTimer => 'Cancel timer';

  @override
  String get fadingOut => 'Fading out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sleepTimerSection => 'Sleep timer';

  @override
  String get fadeLength => 'Fade length';

  @override
  String secondsUnit(int seconds) {
    return '$seconds seconds';
  }

  @override
  String get slowVolumeDeclineTitle => 'Slow volume decline';

  @override
  String get slowVolumeDeclineHint =>
      'Volume lowers gently to 60% before the fade';

  @override
  String get shakeToExtendTitle => 'Shake to extend';

  @override
  String get shakeToExtendHint =>
      'Shake your phone during the fade to add 5 minutes';

  @override
  String get bedtimeAutoTimerTitle => 'Bedtime auto-timer';

  @override
  String get bedtimeStartTime => 'Start time';

  @override
  String get bedtimeDuration => 'Duration';

  @override
  String bedtimeStartedSnackbar(String duration) {
    return 'Bedtime timer started: $duration';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get aboutSection => 'About';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyNotice => 'Dozetone works offline and collects no data';

  @override
  String get openSourceLicenses => 'Open source licenses';
}
