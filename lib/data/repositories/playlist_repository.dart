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

  /// Renames an existing playlist from [oldName] to [newName].
  Future<bool> renamePlaylist(String oldName, String newName);

  /// Deletes a playlist with [name].
  Future<bool> deletePlaylist(String name);

  /// Adds [songId] to [playlistName].
  Future<bool> addSongToPlaylist(String playlistName, int songId);

  /// Adds multiple [songIds] to [playlistName].
  Future<int> addSongsToPlaylist(String playlistName, List<int> songIds);

  /// Removes [songId] from [playlistName].
  Future<bool> removeSongFromPlaylist(String playlistName, int songId);
}

/// Implementation using SharedPreferences for instant offline persistence.
class PlaylistRepositoryImpl implements PlaylistRepository {
  static const List<String> _defaultPlaylists = <String>[
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
      final result = decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e as int).toList(),
        ),
      );

      // Clean up legacy 'Favorites' playlist if present in storage
      if (result.containsKey('Favorites')) {
        result.remove('Favorites');
        await prefs.setString(PrefKeys.customPlaylists, jsonEncode(result));
      }

      return result;
    } catch (_) {
      final fallback = <String, List<int>>{
        for (final name in _defaultPlaylists) name: <int>[],
      };
      await prefs.setString(PrefKeys.customPlaylists, jsonEncode(fallback));
      return fallback;
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
  Future<bool> renamePlaylist(String oldName, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    if (oldName == trimmed) return true;

    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    if (!playlists.containsKey(oldName)) return false;
    if (playlists.containsKey(trimmed)) return false;

    final updated = <String, List<int>>{};
    for (final entry in playlists.entries) {
      if (entry.key == oldName) {
        updated[trimmed] = entry.value;
      } else {
        updated[entry.key] = entry.value;
      }
    }

    await prefs.setString(PrefKeys.customPlaylists, jsonEncode(updated));
    return true;
  }

  @override
  Future<bool> deletePlaylist(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    if (!playlists.containsKey(name)) return false;

    playlists.remove(name);
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

  @override
  Future<int> addSongsToPlaylist(String playlistName, List<int> songIds) async {
    if (songIds.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    final currentIds = playlists[playlistName] ?? <int>[];
    int addedCount = 0;

    for (final id in songIds) {
      if (!currentIds.contains(id)) {
        currentIds.add(id);
        addedCount++;
      }
    }

    if (addedCount > 0) {
      playlists[playlistName] = currentIds;
      await prefs.setString(PrefKeys.customPlaylists, jsonEncode(playlists));
    }
    return addedCount;
  }

  @override
  Future<bool> removeSongFromPlaylist(String playlistName, int songId) async {
    final prefs = await SharedPreferences.getInstance();
    final playlists = await getPlaylists();

    final songIds = playlists[playlistName];
    if (songIds == null) return false;

    final removed = songIds.remove(songId);
    if (removed) {
      playlists[playlistName] = songIds;
      await prefs.setString(PrefKeys.customPlaylists, jsonEncode(playlists));
      return true;
    }
    return false;
  }
}
