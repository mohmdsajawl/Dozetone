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

  /// Notification media control button label to extend sleep timer by 5 minutes
  ///
  /// In en, this message translates to:
  /// **'+5 min'**
  String get notificationAddFiveMinutes;

  /// Timer status in notification when more than 1 minute remains
  ///
  /// In en, this message translates to:
  /// **'Sleep in {minutes} min'**
  String notificationTimerMinutes(int minutes);

  /// Timer status in notification when under 60 seconds remain
  ///
  /// In en, this message translates to:
  /// **'Sleep in under 1 min'**
  String get notificationTimerUnderMinute;

  /// Timer status in notification during volume fade-out
  ///
  /// In en, this message translates to:
  /// **'Fading out'**
  String get notificationTimerFading;

  /// Timer status in notification for end-of-current-song timer
  ///
  /// In en, this message translates to:
  /// **'Sleep after this song'**
  String get notificationTimerEndOfSong;

  /// Timer status in notification for track-based sleep timer
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Sleep after 1 song} other{Sleep after {count} songs}}'**
  String notificationTimerTracks(int count);

  /// Title for dialog confirming deletion of multiple tracks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete 1 Track?} other{Delete {count} Tracks?}}'**
  String deleteSongsDialogTitle(int count);

  /// Confirmation message for batch deletion of songs
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Are you sure you want to permanently delete 1 track from your device storage? This cannot be undone.} other{Are you sure you want to permanently delete {count} tracks from your device storage? This cannot be undone.}}'**
  String deleteSongsDialogMessage(int count);

  /// Snackbar message when tracks are permanently deleted
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Permanently deleted 1 track} other{Permanently deleted {count} tracks}}'**
  String permanentlyDeletedTracks(int count);

  /// Hint text for renaming a playlist
  ///
  /// In en, this message translates to:
  /// **'Enter new playlist name'**
  String get enterNewPlaylistName;

  /// Dialog title when confirming playlist deletion
  ///
  /// In en, this message translates to:
  /// **'Delete Playlist?'**
  String get deletePlaylistTitle;

  /// Feedback when a song is set to play next
  ///
  /// In en, this message translates to:
  /// **'Playing next: {title}'**
  String playingNext(String title);

  /// Feedback when a playlist is started
  ///
  /// In en, this message translates to:
  /// **'Playing playlist \"{name}\"'**
  String playingPlaylist(String name);

  /// Button or tooltip to add tracks to a playlist
  ///
  /// In en, this message translates to:
  /// **'Add Tracks'**
  String get addTracks;

  /// Empty playlist hint prompt
  ///
  /// In en, this message translates to:
  /// **'Tap below to add songs from your library'**
  String get tapBelowToAddSongs;

  /// Action bar label for playlist operations
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlistAction;

  /// Action bar label for timer operations
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get timerAction;

  /// Action bar label for favorite operations
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favoriteAction;

  /// Subtitle when creating playlist with preselected tracks
  ///
  /// In en, this message translates to:
  /// **'Create a new playlist with selected tracks'**
  String get createPlaylistWithSelected;

  /// Empty playlists state in batch modal
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Tap above to create one.'**
  String get noPlaylistsTapAbove;

  /// Button label to create playlist and add selected tracks
  ///
  /// In en, this message translates to:
  /// **'Create & Add'**
  String get createAndAdd;

  /// Count of selected items in multi-selection mode
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Action button to select all songs
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// Action button to deselect all songs
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Header subtitle when selecting songs for a playlist
  ///
  /// In en, this message translates to:
  /// **'Select songs for \"{name}\"'**
  String selectSongsForPlaylist(String name);

  /// Message when local library is empty
  ///
  /// In en, this message translates to:
  /// **'No library songs available'**
  String get noLibrarySongsAvailable;

  /// Button text when no tracks have been selected yet
  ///
  /// In en, this message translates to:
  /// **'Select Tracks to Add'**
  String get selectTracksToAdd;

  /// Button text showing how many tracks will be added
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 Track} other{Add {count} Tracks}}'**
  String addTracksCount(int count);

  /// Snackbar text when a song is marked as favorite
  ///
  /// In en, this message translates to:
  /// **'Added to Favorites'**
  String get addedToFavorites;

  /// Generic fallback for unknown metadata values
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownValue;

  /// Label for album in song details
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get albumLabel;

  /// Label for file size in song details
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get fileSizeLabel;

  /// Label for file path in song details
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get filePathLabel;

  /// Generic OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okAction;

  /// Tooltip or button label to dismiss a screen or dialog
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// Tooltip for 3-dots overflow menu
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Tooltip or action to add current track to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get addToFavorites;

  /// Tooltip for skip previous button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Tooltip for skip next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Tooltip for repeat mode button
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Text on now playing card showing remaining tracks in timer
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track remaining} other{{count} tracks remaining}}'**
  String sleepTimerTracksRemaining(int count);

  /// Text on now playing card showing remaining time in timer
  ///
  /// In en, this message translates to:
  /// **'{time} remaining'**
  String sleepTimerRemaining(String time);

  /// Subtitle under sleep timer button when timer is idle
  ///
  /// In en, this message translates to:
  /// **'Gentle audio fade-out'**
  String get gentleAudioFadeOut;

  /// Button label to open sleep timer modal
  ///
  /// In en, this message translates to:
  /// **'Set timer'**
  String get setTimer;

  /// Feedback when a song is added to a playlist
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToPlaylistSuccess(String name);

  /// Feedback when a song is already present in a playlist
  ///
  /// In en, this message translates to:
  /// **'Already in {name}'**
  String alreadyInPlaylist(String name);

  /// Feedback when creating a playlist and inserting the track
  ///
  /// In en, this message translates to:
  /// **'Created playlist \"{name}\" and added track'**
  String createdPlaylistAndAddedTrack(String name);

  /// Title for Favorites option
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesTitle;

  /// Subtitle when track is already in favorites
  ///
  /// In en, this message translates to:
  /// **'Already in Favorites (tap to remove)'**
  String get alreadyInFavoritesHint;

  /// Subtitle when track is not yet in favorites
  ///
  /// In en, this message translates to:
  /// **'Save to favorite tracks'**
  String get saveToFavoritesHint;

  /// Section header for playlists list
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlistsHeader;

  /// Counter label showing number of playlists available
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String playlistsAvailableCount(int count);

  /// Placeholder when no playlists exist yet
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Create one below!'**
  String get noPlaylistsCreateBelow;

  /// Tooltip on mini player add button
  ///
  /// In en, this message translates to:
  /// **'Add to playlist or favorites'**
  String get addToPlaylistOrFavorites;

  /// Feedback when queue is cleared
  ///
  /// In en, this message translates to:
  /// **'Cleared upcoming tracks'**
  String get clearedUpcomingTracks;

  /// Close button tooltip or label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Feedback when a track is removed from playback queue
  ///
  /// In en, this message translates to:
  /// **'Removed from queue'**
  String get removedFromQueue;

  /// Play action label
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause action label
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Tooltip or label to remove an item from the queue
  ///
  /// In en, this message translates to:
  /// **'Remove from queue'**
  String get removeFromQueue;

  /// Header subtitle when sleep timer is active
  ///
  /// In en, this message translates to:
  /// **'Timer running • Touch to adjust'**
  String get timerRunningTouchToAdjust;

  /// Header subtitle when sleep timer is inactive
  ///
  /// In en, this message translates to:
  /// **'Set by duration or specific tracks'**
  String get setByDurationOrTracks;

  /// Active badge text
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// Remaining tracks counter in sleep timer modal
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 Track Remaining} other{{count} Tracks Remaining}}'**
  String tracksRemainingBadge(int count);

  /// Notice when fading out on the final track
  ///
  /// In en, this message translates to:
  /// **'Fading out at end of this track'**
  String get fadingOutOfTrack;

  /// Explanation of track-based timer ending
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Playback pauses after 1 track finishes} other{Playback pauses after {count} tracks finish}}'**
  String playbackPausesAfterTracks(int count);

  /// Subtitle in timer modal explaining fade-out behavior
  ///
  /// In en, this message translates to:
  /// **'Music will gently fade out'**
  String get musicWillGentlyFadeOut;

  /// Button label to collapse slider
  ///
  /// In en, this message translates to:
  /// **'Close Slider'**
  String get closeSlider;

  /// Button label to expand slider
  ///
  /// In en, this message translates to:
  /// **'Adjust with Slider'**
  String get adjustWithSlider;

  /// Button label to add more time to active timer
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// Duration tab label in sleep timer modal
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tabDuration;

  /// Tracks tab label in sleep timer modal
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tabTracks;

  /// Badge on last track
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get lastBadge;

  /// Section title for custom duration timer
  ///
  /// In en, this message translates to:
  /// **'Custom Duration'**
  String get customDuration;

  /// Short minutes label
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String customMinutesLabel(int minutes);

  /// Full minutes label
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String customMinutesLabelFull(int minutes);

  /// Button to start a timer
  ///
  /// In en, this message translates to:
  /// **'Start Timer'**
  String get startTimerButton;

  /// Status for end-of-specific-song timer
  ///
  /// In en, this message translates to:
  /// **'Pauses when \"{title}\" finishes'**
  String pausesWhenTrackFinishes(String title);

  /// Status for end-of-song timer fallback
  ///
  /// In en, this message translates to:
  /// **'Pauses automatically when track finishes'**
  String get pausesWhenCurrentFinishes;

  /// Card title for track-count sleep timer
  ///
  /// In en, this message translates to:
  /// **'Track Count Timer'**
  String get trackCountTimer;

  /// Badge for count-based sleep timer
  ///
  /// In en, this message translates to:
  /// **'Count-based'**
  String get countBased;

  /// Button label to start a track count sleep timer
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Start 1-Track Sleep Timer} other{Start {count}-Track Sleep Timer}}'**
  String startTracksSleepTimer(int count);

  /// Card title for choosing exact songs for sleep timer
  ///
  /// In en, this message translates to:
  /// **'Pick Specific Songs'**
  String get pickSpecificSongs;

  /// Subtitle for choosing exact songs
  ///
  /// In en, this message translates to:
  /// **'Select exact songs from Queue or Library'**
  String get selectExactSongsPrompt;

  /// Button label with arrow to open selection
  ///
  /// In en, this message translates to:
  /// **'Select >'**
  String get selectArrow;

  /// Screen title for sleep tracks picker
  ///
  /// In en, this message translates to:
  /// **'Select Sleep Tracks'**
  String get selectSleepTracks;

  /// Subtitle in sleep tracks picker
  ///
  /// In en, this message translates to:
  /// **'Music will turn off once these tracks finish'**
  String get musicWillTurnOffTracksFinish;

  /// Hint text in search field for sleep tracks
  ///
  /// In en, this message translates to:
  /// **'Search songs or artists...'**
  String get searchSongsOrArtists;

  /// Empty queue state in sleep tracks picker
  ///
  /// In en, this message translates to:
  /// **'No upcoming songs in active queue.'**
  String get noUpcomingSongsInQueue;

  /// No match search in queue
  ///
  /// In en, this message translates to:
  /// **'No matching songs found in queue.'**
  String get noMatchingSongsInQueue;

  /// Empty local library state
  ///
  /// In en, this message translates to:
  /// **'No songs found in local library.'**
  String get noSongsFoundInLibrary;

  /// No match search in library
  ///
  /// In en, this message translates to:
  /// **'No matching songs found in library.'**
  String get noMatchingSongsInLibrary;

  /// Button text when 0 songs selected in picker
  ///
  /// In en, this message translates to:
  /// **'Select Songs'**
  String get selectSongsAction;

  /// Button text showing number of selected sleep tracks
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Set Timer (1 Track)} other{Set Timer ({count} Tracks)}}'**
  String setTimerTracksCount(int count);

  /// Settings section header for library & audio filtering
  ///
  /// In en, this message translates to:
  /// **'Library & Filtering'**
  String get libraryAndFiltering;

  /// Settings tile title for WhatsApp filtering
  ///
  /// In en, this message translates to:
  /// **'Ignore WhatsApp & Voice Notes'**
  String get ignoreWhatsappTitle;

  /// Settings tile subtitle for WhatsApp filtering
  ///
  /// In en, this message translates to:
  /// **'Hide WhatsApp audio clips, voice notes, and sound recordings from your music library.'**
  String get ignoreWhatsappSubtitle;

  /// Snackbar shown when WhatsApp audio is hidden
  ///
  /// In en, this message translates to:
  /// **'WhatsApp audios hidden from library'**
  String get whatsappHiddenSnackbar;

  /// Snackbar shown when WhatsApp audio is made visible
  ///
  /// In en, this message translates to:
  /// **'WhatsApp audios visible in library'**
  String get whatsappVisibleSnackbar;

  /// Settings tile title for minimum track duration
  ///
  /// In en, this message translates to:
  /// **'Minimum Track Duration'**
  String get minimumTrackDurationTitle;

  /// Settings tile subtitle for minimum track duration
  ///
  /// In en, this message translates to:
  /// **'Audio clips shorter than 30s (ringtones and alert sounds) are automatically hidden.'**
  String get minimumTrackDurationSubtitle;

  /// Settings tile title for fade-out duration
  ///
  /// In en, this message translates to:
  /// **'Gentle Fade-Out Duration'**
  String get gentleFadeOutDurationTitle;

  /// Settings tile subtitle for fade-out duration
  ///
  /// In en, this message translates to:
  /// **'Duration to smoothly lower volume down to zero before music ends.'**
  String get gentleFadeOutDurationSubtitle;

  /// Settings tile subtitle for shake to extend
  ///
  /// In en, this message translates to:
  /// **'Gently shake your device during fade-out to add extra time without unlocking.'**
  String get shakeToExtendSubtitle;

  /// Settings tile subtitle for slow volume decline
  ///
  /// In en, this message translates to:
  /// **'Gradually ease volume down over the duration of your timer.'**
  String get slowVolumeDeclineSubtitle;

  /// Settings section header for bedtime auto-timer
  ///
  /// In en, this message translates to:
  /// **'Bedtime Auto-Timer'**
  String get bedtimeAutoTimerSection;

  /// Settings tile title for auto-starting sleep timer
  ///
  /// In en, this message translates to:
  /// **'Auto-Start Sleep Timer'**
  String get autoStartSleepTimerTitle;

  /// Settings tile subtitle for auto-starting sleep timer
  ///
  /// In en, this message translates to:
  /// **'Automatically start timer when playing music during your bedtime hours.'**
  String get autoStartSleepTimerSubtitle;

  /// Settings tile title for bedtime start time
  ///
  /// In en, this message translates to:
  /// **'Bedtime Starts At'**
  String get bedtimeStartsAtTitle;

  /// Settings tile subtitle for bedtime start time
  ///
  /// In en, this message translates to:
  /// **'Timer triggers when music begins between this time and 5:00 AM.'**
  String get bedtimeStartsAtSubtitle;

  /// Settings tile title for auto-timer duration
  ///
  /// In en, this message translates to:
  /// **'Auto-Timer Duration'**
  String get autoTimerDurationTitle;

  /// Settings tile subtitle for auto-timer duration
  ///
  /// In en, this message translates to:
  /// **'Default duration set when bedtime auto-timer triggers.'**
  String get autoTimerDurationSubtitle;

  /// Tagline and version display in settings about card
  ///
  /// In en, this message translates to:
  /// **'Sleep with music, wake up recharged.\nVersion {version}'**
  String appTaglineVersion(String version);

  /// Modal title for adding tracks to playlist
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 track to playlist} other{Add {count} tracks to playlist}}'**
  String addTracksToPlaylist(int count);

  /// Tab title for upcoming queue with track count
  ///
  /// In en, this message translates to:
  /// **'Upcoming Queue ({count})'**
  String upcomingQueueCount(int count);

  /// Tab title for all songs with track count
  ///
  /// In en, this message translates to:
  /// **'All Songs ({count})'**
  String allSongsCount(int count);
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
