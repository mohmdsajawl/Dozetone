import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/playlist_repository.dart';

/// Active navigation tab within the Library screen.
enum LibraryTab {
  /// All local audio files on device.
  all,

  /// Tracks starred or saved as favorites.
  favorites,

  /// Custom user playlists and albums.
  playlists,
}

/// Provider managing active LibraryTab selection.
final libraryTabProvider = StateProvider<LibraryTab>((ref) => LibraryTab.all);

/// Provider exposing real-time set of favorite song IDs.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return FavoritesNotifier(repository);
});

/// ViewModel managing favorite song ID persistence and reactive updates.
class FavoritesNotifier extends StateNotifier<Set<int>> {
  final PlaylistRepository _repository;

  FavoritesNotifier(this._repository) : super(<int>{}) {
    loadFavorites();
  }

  /// Reloads favorite IDs from persistent storage.
  Future<void> loadFavorites() async {
    final favs = await _repository.getFavoriteSongIds();
    state = favs;
  }

  /// Toggles favorite status and returns whether track is now favorite.
  Future<bool> toggleFavorite(int songId) async {
    final isFav = await _repository.toggleFavorite(songId);
    final updated = Set<int>.from(state);
    if (isFav) {
      updated.add(songId);
    } else {
      updated.remove(songId);
    }
    state = updated;
    return isFav;
  }

  /// Whether [songId] is currently marked as favorite.
  bool isFavorite(int songId) => state.contains(songId);
}

/// Provider exposing custom playlists and their songs.
final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, Map<String, List<int>>>((ref) {
  final repository = ref.watch(playlistRepositoryProvider);
  return PlaylistsNotifier(repository);
});

/// ViewModel managing user playlists and real-time state.
class PlaylistsNotifier extends StateNotifier<Map<String, List<int>>> {
  final PlaylistRepository _repository;

  PlaylistsNotifier(this._repository) : super(<String, List<int>>{}) {
    loadPlaylists();
  }

  /// Reloads playlists map from storage.
  Future<void> loadPlaylists() async {
    final map = await _repository.getPlaylists();
    state = map;
  }

  /// Creates a new playlist with [name].
  Future<bool> createPlaylist(String name) async {
    final created = await _repository.createPlaylist(name);
    if (created) {
      await loadPlaylists();
    }
    return created;
  }

  /// Adds [songId] to [playlistName].
  Future<bool> addSongToPlaylist(String playlistName, int songId) async {
    final added = await _repository.addSongToPlaylist(playlistName, songId);
    if (added) {
      await loadPlaylists();
    }
    return added;
  }
}
