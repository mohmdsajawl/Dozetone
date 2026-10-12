import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';

/// Provider for accessing PlaylistRepository singleton.
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl();
});

/// Contract for managing user favorites, custom playlists, and queues.
abstract class PlaylistRepository {
  /// Returns list of favorite song IDs.
  Future<Set<int>> getFavoriteSongIds();

  /// Toggles favorite status for [songId] and returns whether now favorite.
  Future<bool> toggleFavorite(int songId);

  /// Checks if [songId] is marked as favorite.
  Future<bool> isFavorite(int songId);

  /// Retrieves map of playlist names to their song IDs.
  Future<Map<String, List<int>>> getPlaylists();

  /// Creates a new playlist with [name].
  Future<bool> createPlaylist(String name);

  /// Adds [songId] to [playlistName].
  Future<bool> addSongToPlaylist(String playlistName, int songId);
}

/// Implementation using SharedPreferences for instant offline persistence.
class PlaylistRepositoryImpl implements PlaylistRepository {
  static const List<String> _defaultPlaylists = <String>[
    'Favorites',
    'Night Ambience',
    'Deep Sleep',
  ];

  @override
  Future<Set<int>> getFavoriteSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(PrefKeys.favoriteSongIds) ?? <String>[];
    return list.map((e) => int.tryParse(e)).whereType<int>().toSet();
  }

  @override
  Future<bool> isFavorite(int songId) async {
    final favorites = await getFavoriteSongIds();
    return favorites.contains(songId);
  }

  @override
  Future<bool> toggleFavorite(int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteSongIds();
    final isFav = favorites.contains(songId);

    if (isFav) {
      favorites.remove(songId);
    } else {
      favorites.add(songId);
    }

    await prefs.setStringList(
      PrefKeys.favoriteSongIds,
      favorites.map((e) => e.toString()).toList(),
    );
    return !isFav;
  }

  @override
  Future<Map<String, List<int>>> getPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(PrefKeys.customPlaylists);

    if (jsonStr == null || jsonStr.isEmpty) {
      // Initialize with default playlists
      final initial = <String, List<int>>{
        for (final name in _defaultPlaylists) name: <int>[],
      };
      await prefs.setString(PrefKeys.customPlaylists, jsonEncode(initial));
      return initial;
    }

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e as int).toList(),
        ),
      );
    } catch (_) {
      return <String, List<int>>{
        for (final name in _defaultPlaylists) name: <int>[],
      };
    }
  }

  @override
  Future<bool> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    if (playlists.containsKey(trimmed)) return false;

    playlists[trimmed] = <int>[];
    await prefs.setString(PrefKeys.customPlaylists, jsonEncode(playlists));
    return true;
  }

  @override
  Future<bool> addSongToPlaylist(String playlistName, int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    final songIds = playlists[playlistName] ?? <int>[];
    if (!songIds.contains(songId)) {
      songIds.add(songId);
      playlists[playlistName] = songIds;
      await prefs.setString(PrefKeys.customPlaylists, jsonEncode(playlists));
      return true;
    }
    return false;
  }
}
