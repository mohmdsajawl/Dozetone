import 'package:flutter/foundation.dart';
import '../../model/song.dart';

/// Sealed class hierarchy representing the distinct visual states of the Song Library.
///
/// Ensures the View can pattern match and render the exact UI required
/// for every possible runtime condition.
@immutable
sealed class LibraryState {
  const LibraryState();
}

/// State when audio storage permission is not granted yet.
class LibraryPermissionRequired extends LibraryState {
  /// Whether the permission is permanently denied (requiring app settings).
  final bool isPermanentlyDenied;

  const LibraryPermissionRequired({this.isPermanentlyDenied = false});
}

/// State while the app is actively scanning device storage for audio tracks.
class LibraryScanning extends LibraryState {
  const LibraryScanning();
}

/// State when songs were scanned successfully and at least one song was found.
class LibraryLoaded extends LibraryState {
  final List<Song> songs;

  const LibraryLoaded(this.songs);
}

/// State when scanning completed but zero songs matched criteria (> 30s, music).
class LibraryEmpty extends LibraryState {
  const LibraryEmpty();
}

/// State when a device or query error occurred while reading audio files.
class LibraryError extends LibraryState {
  final String message;

  const LibraryError(this.message);
}
