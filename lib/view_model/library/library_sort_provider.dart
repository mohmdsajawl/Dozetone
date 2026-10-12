import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Available sorting options for the song library.
enum SongSortOrder {
  /// Sorted alphabetically by title from A to Z.
  titleAsc,

  /// Sorted alphabetically by artist from A to Z.
  artistAsc,

  /// Sorted by duration from longest to shortest.
  durationDesc,

  /// Sorted by date added, newest first.
  dateAddedDesc,
}

/// Provider managing active sort order for the library.
final songSortOrderProvider = StateProvider<SongSortOrder>((ref) {
  return SongSortOrder.titleAsc;
});
