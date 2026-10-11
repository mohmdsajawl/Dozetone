import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/song.dart';
import 'library_search_query_provider.dart';
import 'library_state.dart';
import 'library_view_model.dart';

/// Provider returning songs filtered by the active search query.
///
/// Filters case-insensitively across both song title and artist.
final filteredSongsProvider = Provider<List<Song>>((ref) {
  final libraryState = ref.watch(libraryViewModelProvider);
  final searchQuery = ref.watch(libraryQueryProvider).trim().toLowerCase();

  if (libraryState is! LibraryLoaded) {
    return const <Song>[];
  }

  final allSongs = libraryState.songs;

  if (searchQuery.isEmpty) {
    return allSongs;
  }

  return allSongs.where((song) {
    final titleMatch = song.title.toLowerCase().contains(searchQuery);
    final artistMatch = song.artist.toLowerCase().contains(searchQuery);
    return titleMatch || artistMatch;
  }).toList();
});
