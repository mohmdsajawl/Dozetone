import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Application display name
  ///
  /// In en, this message translates to:
  /// **'Dozetone'**
  String get appTitle;

  /// Library view header title
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// Search field hint text
  ///
  /// In en, this message translates to:
  /// **'Search by title or artist...'**
  String get searchPlaceholder;

  /// Loading state label while searching for audio files
  ///
  /// In en, this message translates to:
  /// **'Scanning your music...'**
  String get scanningMusic;

  /// Button to start playback from the beginning of all songs
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// Button to shuffle all songs
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// Pluralized count of songs in the library
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Track} other{{count} Tracks}}'**
  String songsCount(int count);

  /// Label for sorting dialog or sheet
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Sort by track title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// Sort by artist name
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// Sort by track length
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// Sort by date added newest first
  ///
  /// In en, this message translates to:
  /// **'Date added (Newest first)'**
  String get sortDateAdded;

  /// Header for track details sheet
  ///
  /// In en, this message translates to:
  /// **'Track Details'**
  String get songDetails;

  /// Queue song next option
  ///
  /// In en, this message translates to:
  /// **'Play next'**
  String get playNext;

  /// Option to append track to playback queue
  ///
  /// In en, this message translates to:
  /// **'Add to queue'**
  String get addToQueue;

  /// Option to add track to a user playlist
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// Generic delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Dialog title for deleting a song
  ///
  /// In en, this message translates to:
  /// **'Delete song?'**
  String get deleteSongTitle;

  /// Confirmation message before deleting audio file
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\" from your device? This cannot be undone.'**
  String deleteSongMessage(String title);

  /// Snackbar message after song deletion
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String songDeleted(String title);

  /// Snackbar message if song deletion fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete \"{title}\"'**
  String songDeleteFailed(String title);

  /// Button to rename song title
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameSong;

  /// Dialog title for renaming song
  ///
  /// In en, this message translates to:
  /// **'Rename song'**
  String get renameSongDialogTitle;

  /// Input field label for new song title
  ///
  /// In en, this message translates to:
  /// **'Song title'**
  String get renameSongFieldLabel;

  /// Snackbar message when song rename succeeds
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{title}\"'**
  String renameSongSuccess(String title);

  /// Snackbar message when song rename fails
  ///
  /// In en, this message translates to:
  /// **'Could not rename song'**
  String get renameSongFailed;

  /// Label for date added field in track details
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get dateAdded;

  /// Empty library headline
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get noSongsFound;

  /// Empty library explanatory caption
  ///
  /// In en, this message translates to:
  /// **'Songs shorter than 30 seconds are hidden'**
  String get shortSongsHiddenHint;

  /// No search results label
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noSearchResults(String query);

  /// Explanation when audio storage permission is not granted
  ///
  /// In en, this message translates to:
  /// **'Audio permission is required to play local songs'**
  String get permissionRequired;

  /// Button to request audio permissions
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermission;

  /// Button to open device application settings
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Generic retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Fallback when audio track has no title
  ///
  /// In en, this message translates to:
  /// **'Unknown Title'**
  String get unknownTitle;

  /// Fallback when audio track has no artist
  ///
  /// In en, this message translates to:
  /// **'Unknown Artist'**
  String get unknownArtist;

  /// Top bar title on the player screen
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlayingTitle;

  /// Sleep timer button and header label
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// 5 minutes preset
  ///
  /// In en, this message translates to:
  /// **'5 minutes'**
  String get timerPreset5Min;

  /// 10 minutes preset
  ///
  /// In en, this message translates to:
  /// **'10 minutes'**
  String get timerPreset10Min;

  /// 15 minutes preset
  ///
  /// In en, this message translates to:
  /// **'15 minutes'**
  String get timerPreset15Min;

  /// 30 minutes preset
  ///
  /// In en, this message translates to:
  /// **'30 minutes'**
  String get timerPreset30Min;

  /// 45 minutes preset
  ///
  /// In en, this message translates to:
  /// **'45 minutes'**
  String get timerPreset45Min;

  /// 60 minutes preset
  ///
  /// In en, this message translates to:
  /// **'60 minutes'**
  String get timerPreset60Min;

  /// Custom timer duration picker option
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get timerCustom;

  /// Option to pause after current track completes
  ///
  /// In en, this message translates to:
  /// **'End of current track'**
  String get timerEndOfSong;

  /// Badge indicator on last used timer choice
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get lastUsed;

  /// Snackbar message when a sleep timer is activated
  ///
  /// In en, this message translates to:
  /// **'Sleep timer set for {duration}'**
  String timerSetSnackbar(String duration);

  /// Action button to extend sleep timer by five minutes
  ///
  /// In en, this message translates to:
  /// **'Add 5 min'**
  String get add5Min;

  /// Action button to cancel active sleep timer
  ///
  /// In en, this message translates to:
  /// **'Cancel timer'**
  String get cancelTimer;

  /// Status text while audio volume fade-out is active
  ///
  /// In en, this message translates to:
  /// **'Fading out'**
  String get fadingOut;

  /// Settings view title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section header for sleep timer options
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimerSection;

  /// Fade duration setting title
  ///
  /// In en, this message translates to:
  /// **'Fade length'**
  String get fadeLength;

  /// Formatted seconds
  ///
  /// In en, this message translates to:
  /// **'{seconds} seconds'**
  String secondsUnit(int seconds);

  /// Setting title for gradual volume lowering
  ///
  /// In en, this message translates to:
  /// **'Slow volume decline'**
  String get slowVolumeDeclineTitle;

  /// Setting explanation for gradual volume lowering
  ///
  /// In en, this message translates to:
  /// **'Volume lowers gently to 60% before the fade'**
  String get slowVolumeDeclineHint;

  /// Setting title for accelerometer shake extension
  ///
  /// In en, this message translates to:
  /// **'Shake to extend'**
  String get shakeToExtendTitle;

  /// Setting explanation for accelerometer shake extension
  ///
  /// In en, this message translates to:
  /// **'Shake your phone during the fade to add 5 minutes'**
  String get shakeToExtendHint;

  /// Setting title for automatic night timer
  ///
  /// In en, this message translates to:
  /// **'Bedtime auto-timer'**
  String get bedtimeAutoTimerTitle;

  /// Bedtime schedule start time
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get bedtimeStartTime;

  /// Bedtime timer default duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get bedtimeDuration;

  /// Snackbar alert when bedtime auto timer starts
  ///
  /// In en, this message translates to:
  /// **'Bedtime timer started: {duration}'**
  String bedtimeStartedSnackbar(String duration);

  /// Generic cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Settings section header for about info
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// App version display
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// Privacy promise text in settings
  ///
  /// In en, this message translates to:
  /// **'Dozetone works offline and collects no data'**
  String get privacyNotice;

  /// Button to view third party open source licenses
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// Title and button for creating a new playlist
  ///
  /// In en, this message translates to:
  /// **'Create New Playlist'**
  String get createNewPlaylist;

  /// Subtitle description under create playlist
  ///
  /// In en, this message translates to:
  /// **'Group songs by mood, sleep, or genre'**
  String get playlistSubtitle;

  /// Dialog title for new playlist
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// Hint text for playlist name field
  ///
  /// In en, this message translates to:
  /// **'Enter playlist name'**
  String get enterPlaylistName;

  /// Dialog title and menu item for renaming a playlist
  ///
  /// In en, this message translates to:
  /// **'Rename Playlist'**
  String get renamePlaylist;

  /// Dialog title and menu item for deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist'**
  String get deletePlaylist;

  /// Confirmation message when deleting a playlist
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? The songs will remain on your device.'**
  String deletePlaylistConfirm(String name);

  /// Snackbar message when playlist is created
  ///
  /// In en, this message translates to:
  /// **'Created playlist \"{name}\"'**
  String playlistCreated(String name);

  /// Snackbar message when playlist is renamed
  ///
  /// In en, this message translates to:
  /// **'Renamed to \"{name}\"'**
  String playlistRenamed(String name);

  /// Snackbar message when playlist is deleted
  ///
  /// In en, this message translates to:
  /// **'Deleted playlist \"{name}\"'**
  String playlistDeleted(String name);

  /// Snackbar message when playlist name already exists
  ///
  /// In en, this message translates to:
  /// **'Playlist \"{name}\" already exists'**
  String playlistAlreadyExists(String name);

  /// Button to add songs to a playlist
  ///
  /// In en, this message translates to:
  /// **'Add Songs'**
  String get addSongs;

  /// Action to remove a song from a playlist
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeSongFromPlaylist;

  /// Snackbar message when song is removed from playlist
  ///
  /// In en, this message translates to:
  /// **'Removed from \"{name}\"'**
  String songRemovedFromPlaylist(String name);

  /// Empty state title inside playlist details
  ///
  /// In en, this message translates to:
  /// **'No songs in this playlist yet'**
  String get noSongsInPlaylist;

  /// Empty state caption inside playlist details
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Songs\" to add tracks from your library'**
  String get emptyPlaylistPrompt;

  /// Pluralized count of tracks in a playlist
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String tracksCount(int count);

  /// Create button label
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Rename button label
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Option to add a track to playlists, queue, or favorites
  ///
  /// In en, this message translates to:
  /// **'Add to...'**
  String get addTo;

  /// Option to remove a song from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get removeFromFavorites;

  /// Snackbar message when a song is removed from favorites
  ///
  /// In en, this message translates to:
  /// **'Removed \"{title}\" from Favorites'**
  String removedFromFavorites(String title);

  /// Header title for the playback queue sheet
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queueTitle;

  /// Section header for the actively playing track
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlayingHeader;

  /// Section header for upcoming queued tracks
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNextHeader;

  /// Action to clear upcoming tracks in the queue
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearQueue;

  /// Title when playback queue has no songs
  ///
  /// In en, this message translates to:
  /// **'Queue is empty'**
  String get emptyQueue;

  /// Prompt when playback queue is empty
  ///
  /// In en, this message translates to:
  /// **'Play a track to start a playback queue'**
  String get emptyQueuePrompt;

  /// Title when there are no upcoming tracks in queue
  ///
  /// In en, this message translates to:
  /// **'No upcoming tracks'**
  String get emptyUpNext;

  /// Prompt explaining how to queue tracks
  ///
  /// In en, this message translates to:
  /// **'Use \"Add to...\" on tracks to queue next'**
  String get emptyUpNextPrompt;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
