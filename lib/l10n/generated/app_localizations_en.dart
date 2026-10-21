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
  String get playAll => 'Play All';

  @override
  String get shuffle => 'Shuffle';

  @override
  String songsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tracks',
      one: '1 Track',
    );
    return '$_temp0';
  }

  @override
  String get sortBy => 'Sort by';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortDateAdded => 'Date added (Newest first)';

  @override
  String get songDetails => 'Track Details';

  @override
  String get playNext => 'Play next';

  @override
  String get addToQueue => 'Add to queue';

  @override
  String get addToPlaylist => 'Add to playlist';

  @override
  String get delete => 'Delete';

  @override
  String get deleteSongTitle => 'Delete song?';

  @override
  String deleteSongMessage(String title) {
    return 'Are you sure you want to delete \"$title\" from your device? This cannot be undone.';
  }

  @override
  String songDeleted(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String songDeleteFailed(String title) {
    return 'Could not delete \"$title\"';
  }

  @override
  String get renameSong => 'Rename';

  @override
  String get renameSongDialogTitle => 'Rename song';

  @override
  String get renameSongFieldLabel => 'Song title';

  @override
  String renameSongSuccess(String title) {
    return 'Renamed to \"$title\"';
  }

  @override
  String get renameSongFailed => 'Could not rename song';

  @override
  String get dateAdded => 'Date Added';

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
  String get timerEndOfSong => 'End of current track';

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

  @override
  String get createNewPlaylist => 'Create New Playlist';

  @override
  String get playlistSubtitle => 'Group songs by mood, sleep, or genre';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get enterPlaylistName => 'Enter playlist name';

  @override
  String get renamePlaylist => 'Rename Playlist';

  @override
  String get deletePlaylist => 'Delete Playlist';

  @override
  String deletePlaylistConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"? The songs will remain on your device.';
  }

  @override
  String playlistCreated(String name) {
    return 'Created playlist \"$name\"';
  }

  @override
  String playlistRenamed(String name) {
    return 'Renamed to \"$name\"';
  }

  @override
  String playlistDeleted(String name) {
    return 'Deleted playlist \"$name\"';
  }

  @override
  String playlistAlreadyExists(String name) {
    return 'Playlist \"$name\" already exists';
  }

  @override
  String get addSongs => 'Add Songs';

  @override
  String get removeSongFromPlaylist => 'Remove from playlist';

  @override
  String songRemovedFromPlaylist(String name) {
    return 'Removed from \"$name\"';
  }

  @override
  String get noSongsInPlaylist => 'No songs in this playlist yet';

  @override
  String get emptyPlaylistPrompt =>
      'Tap \"Add Songs\" to add tracks from your library';

  @override
  String tracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get addTo => 'Add to...';

  @override
  String get removeFromFavorites => 'Remove from Favorites';

  @override
  String removedFromFavorites(String title) {
    return 'Removed \"$title\" from Favorites';
  }

  @override
  String get queueTitle => 'Queue';

  @override
  String get nowPlayingHeader => 'Now Playing';

  @override
  String get upNextHeader => 'Up Next';

  @override
  String get clearQueue => 'Clear';

  @override
  String get emptyQueue => 'Queue is empty';

  @override
  String get emptyQueuePrompt => 'Play a track to start a playback queue';

  @override
  String get emptyUpNext => 'No upcoming tracks';

  @override
  String get emptyUpNextPrompt => 'Use \"Add to...\" on tracks to queue next';

  @override
  String get notificationAddFiveMinutes => '+5 min';

  @override
  String notificationTimerMinutes(int minutes) {
    return 'Sleep in $minutes min';
  }

  @override
  String get notificationTimerUnderMinute => 'Sleep in under 1 min';

  @override
  String get notificationTimerFading => 'Fading out';

  @override
  String get notificationTimerEndOfSong => 'Sleep after this song';

  @override
  String notificationTimerTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sleep after $count songs',
      one: 'Sleep after 1 song',
    );
    return '$_temp0';
  }

  @override
  String deleteSongsDialogTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count Tracks?',
      one: 'Delete 1 Track?',
    );
    return '$_temp0';
  }

  @override
  String deleteSongsDialogMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Are you sure you want to permanently delete $count tracks from your device storage? This cannot be undone.',
      one:
          'Are you sure you want to permanently delete 1 track from your device storage? This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String permanentlyDeletedTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Permanently deleted $count tracks',
      one: 'Permanently deleted 1 track',
    );
    return '$_temp0';
  }

  @override
  String get enterNewPlaylistName => 'Enter new playlist name';

  @override
  String get deletePlaylistTitle => 'Delete Playlist?';

  @override
  String playingNext(String title) {
    return 'Playing next: $title';
  }

  @override
  String playingPlaylist(String name) {
    return 'Playing playlist \"$name\"';
  }

  @override
  String get addTracks => 'Add Tracks';

  @override
  String get tapBelowToAddSongs => 'Tap below to add songs from your library';

  @override
  String get playlistAction => 'Playlist';

  @override
  String get timerAction => 'Timer';

  @override
  String get favoriteAction => 'Favorite';

  @override
  String get createPlaylistWithSelected =>
      'Create a new playlist with selected tracks';

  @override
  String get noPlaylistsTapAbove =>
      'No playlists yet. Tap above to create one.';

  @override
  String get createAndAdd => 'Create & Add';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String selectSongsForPlaylist(String name) {
    return 'Select songs for \"$name\"';
  }

  @override
  String get noLibrarySongsAvailable => 'No library songs available';

  @override
  String get selectTracksToAdd => 'Select Tracks to Add';

  @override
  String addTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count Tracks',
      one: 'Add 1 Track',
    );
    return '$_temp0';
  }

  @override
  String get addedToFavorites => 'Added to Favorites';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get albumLabel => 'Album';

  @override
  String get fileSizeLabel => 'File Size';

  @override
  String get filePathLabel => 'Path';

  @override
  String get okAction => 'OK';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get moreOptions => 'More options';

  @override
  String get addToFavorites => 'Add to Favorites';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get repeat => 'Repeat';

  @override
  String sleepTimerTracksRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tracks remaining',
      one: '1 track remaining',
    );
    return '$_temp0';
  }

  @override
  String sleepTimerRemaining(String time) {
    return '$time remaining';
  }

  @override
  String get gentleAudioFadeOut => 'Gentle audio fade-out';

  @override
  String get setTimer => 'Set timer';

  @override
  String addedToPlaylistSuccess(String name) {
    return 'Added to $name';
  }

  @override
  String alreadyInPlaylist(String name) {
    return 'Already in $name';
  }

  @override
  String createdPlaylistAndAddedTrack(String name) {
    return 'Created playlist \"$name\" and added track';
  }

  @override
  String get favoritesTitle => 'Favorites';

  @override
  String get alreadyInFavoritesHint => 'Already in Favorites (tap to remove)';

  @override
  String get saveToFavoritesHint => 'Save to favorite tracks';

  @override
  String get playlistsHeader => 'Playlists';

  @override
  String playlistsAvailableCount(int count) {
    return '$count available';
  }

  @override
  String get noPlaylistsCreateBelow => 'No playlists yet. Create one below!';

  @override
  String get addToPlaylistOrFavorites => 'Add to playlist or favorites';

  @override
  String get clearedUpcomingTracks => 'Cleared upcoming tracks';

  @override
  String get close => 'Close';

  @override
  String get removedFromQueue => 'Removed from queue';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get removeFromQueue => 'Remove from queue';

  @override
  String get timerRunningTouchToAdjust => 'Timer running • Touch to adjust';

  @override
  String get setByDurationOrTracks => 'Set by duration or specific tracks';

  @override
  String get activeStatus => 'Active';

  @override
  String tracksRemainingBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tracks Remaining',
      one: '1 Track Remaining',
    );
    return '$_temp0';
  }

  @override
  String get fadingOutOfTrack => 'Fading out at end of this track';

  @override
  String playbackPausesAfterTracks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Playback pauses after $count tracks finish',
      one: 'Playback pauses after 1 track finishes',
    );
    return '$_temp0';
  }

  @override
  String get musicWillGentlyFadeOut => 'Music will gently fade out';

  @override
  String get closeSlider => 'Close Slider';

  @override
  String get adjustWithSlider => 'Adjust with Slider';

  @override
  String get addMore => 'Add More';

  @override
  String get tabDuration => 'Duration';

  @override
  String get tabTracks => 'Tracks';

  @override
  String get lastBadge => 'Last';

  @override
  String get customDuration => 'Custom Duration';

  @override
  String customMinutesLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String customMinutesLabelFull(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get startTimerButton => 'Start Timer';

  @override
  String pausesWhenTrackFinishes(String title) {
    return 'Pauses when \"$title\" finishes';
  }

  @override
  String get pausesWhenCurrentFinishes =>
      'Pauses automatically when track finishes';

  @override
  String get trackCountTimer => 'Track Count Timer';

  @override
  String get countBased => 'Count-based';

  @override
  String startTracksSleepTimer(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Start $count-Track Sleep Timer',
      one: 'Start 1-Track Sleep Timer',
    );
    return '$_temp0';
  }

  @override
  String get pickSpecificSongs => 'Pick Specific Songs';

  @override
  String get selectExactSongsPrompt =>
      'Select exact songs from Queue or Library';

  @override
  String get selectArrow => 'Select >';

  @override
  String get selectSleepTracks => 'Select Sleep Tracks';

  @override
  String get musicWillTurnOffTracksFinish =>
      'Music will turn off once these tracks finish';

  @override
  String get searchSongsOrArtists => 'Search songs or artists...';

  @override
  String get noUpcomingSongsInQueue => 'No upcoming songs in active queue.';

  @override
  String get noMatchingSongsInQueue => 'No matching songs found in queue.';

  @override
  String get noSongsFoundInLibrary => 'No songs found in local library.';

  @override
  String get noMatchingSongsInLibrary => 'No matching songs found in library.';

  @override
  String get selectSongsAction => 'Select Songs';

  @override
  String setTimerTracksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Set Timer ($count Tracks)',
      one: 'Set Timer (1 Track)',
    );
    return '$_temp0';
  }

  @override
  String get libraryAndFiltering => 'Library & Filtering';

  @override
  String get ignoreWhatsappTitle => 'Ignore WhatsApp & Voice Notes';

  @override
  String get ignoreWhatsappSubtitle =>
      'Hide WhatsApp audio clips, voice notes, and sound recordings from your music library.';

  @override
  String get whatsappHiddenSnackbar => 'WhatsApp audios hidden from library';

  @override
  String get whatsappVisibleSnackbar => 'WhatsApp audios visible in library';

  @override
  String get minimumTrackDurationTitle => 'Minimum Track Duration';

  @override
  String get minimumTrackDurationSubtitle =>
      'Audio clips shorter than 30s (ringtones and alert sounds) are automatically hidden.';

  @override
  String get gentleFadeOutDurationTitle => 'Gentle Fade-Out Duration';

  @override
  String get gentleFadeOutDurationSubtitle =>
      'Duration to smoothly lower volume down to zero before music ends.';

  @override
  String get shakeToExtendSubtitle =>
      'Gently shake your device during fade-out to add extra time without unlocking.';

  @override
  String get slowVolumeDeclineSubtitle =>
      'Gradually ease volume down over the duration of your timer.';

  @override
  String get bedtimeAutoTimerSection => 'Bedtime Auto-Timer';

  @override
  String get autoStartSleepTimerTitle => 'Auto-Start Sleep Timer';

  @override
  String get autoStartSleepTimerSubtitle =>
      'Automatically start timer when playing music during your bedtime hours.';

  @override
  String get bedtimeStartsAtTitle => 'Bedtime Starts At';

  @override
  String get bedtimeStartsAtSubtitle =>
      'Timer triggers when music begins between this time and 5:00 AM.';

  @override
  String get autoTimerDurationTitle => 'Auto-Timer Duration';

  @override
  String get autoTimerDurationSubtitle =>
      'Default duration set when bedtime auto-timer triggers.';

  @override
  String appTaglineVersion(String version) {
    return 'Sleep with music, wake up recharged.\nVersion $version';
  }

  @override
  String addTracksToPlaylist(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count tracks to playlist',
      one: 'Add 1 track to playlist',
    );
    return '$_temp0';
  }

  @override
  String upcomingQueueCount(int count) {
    return 'Upcoming Queue ($count)';
  }

  @override
  String allSongsCount(int count) {
    return 'All Songs ($count)';
  }
}
