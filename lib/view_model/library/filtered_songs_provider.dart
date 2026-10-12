import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/song.dart';
import 'library_search_query_provider.dart';
import 'library_sort_provider.dart';
import 'library_state.dart';
import 'library_view_model.dart';

/// Provider returning songs filtered by the active search query and sorted
/// according to the active [SongSortOrder].
final filteredSongsProvider = Provider<List<Song>>((ref) {
  final libraryState = ref.watch(libraryViewModelProvider);
  final searchQuery = ref.watch(libraryQueryProvider).trim().toLowerCase();
  final sortOrder = ref.watch(songSortOrderProvider);

  if (libraryState is! LibraryLoaded) {
    return const <Song>[];
  }

  final allSongs = libraryState.songs;

  final filtered = (searchQuery.isEmpty)
      ? List<Song>.from(allSongs)
      : allSongs.where((song) {
          final titleMatch = song.title.toLowerCase().contains(searchQuery);
          final artistMatch = song.artist.toLowerCase().contains(searchQuery);
          return titleMatch || artistMatch;
        }).toList();

  switch (sortOrder) {
    case SongSortOrder.titleAsc:
      filtered.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
      break;
    case SongSortOrder.artistAsc:
      filtered.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
      break;
    case SongSortOrder.durationDesc:
      filtered.sort(
        (a, b) => b.durationMs.compareTo(a.durationMs),
      );
      break;
    case SongSortOrder.dateAddedDesc:
      filtered.sort(
        (a, b) {
          final aDate = a.dateAdded ?? a.id;
          final bDate = b.dateAdded ?? b.id;
          return bDate.compareTo(aDate);
        },
      );
      break;
  }

  return filtered;
});
