import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/pref_keys.dart';
import '../../model/song.dart';
import '../services/media_library_service.dart';

/// Provider for accessing the SongRepository.
final songRepositoryProvider = Provider<SongRepository>((ref) {
  final mediaLibraryService = ref.watch(mediaLibraryServiceProvider);
  return SongRepositoryImpl(mediaLibraryService);
});

/// Abstract repository defining data contract for song access.
abstract class SongRepository {
  /// Fetches the list of all playable music tracks from device storage.
  Future<List<Song>> fetchSongs();

  /// Deletes a song from device storage and updates MediaStore.
  Future<bool> deleteSong(Song song);

  /// Renames a song title in MediaStore and on device storage.
  Future<bool> renameSong(Song song, String newTitle);
}

/// Implementation of SongRepository that talks to MediaLibraryService.
class SongRepositoryImpl implements SongRepository {
  final MediaLibraryService _mediaLibraryService;

  SongRepositoryImpl(this._mediaLibraryService);

  @override
  Future<List<Song>> fetchSongs() async {
    bool excludeWhatsapp = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      excludeWhatsapp = prefs.getBool(PrefKeys.excludeWhatsappAudio) ?? true;
    } catch (_) {}

    final songs = await _mediaLibraryService.queryDeviceSongs(
      excludeWhatsapp: excludeWhatsapp,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(PrefKeys.customSongTitles);
      if (rawJson != null) {
        final titlesMap =
            Map<String, dynamic>.from(jsonDecode(rawJson) as Map);
        if (titlesMap.isNotEmpty) {
          for (int i = 0; i < songs.length; i++) {
            final customTitle = titlesMap[songs[i].id.toString()] as String?;
            if (customTitle != null && customTitle.isNotEmpty) {
              songs[i] = songs[i].copyWith(title: customTitle);
            }
          }
          songs.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        }
      }
    } catch (_) {}

    return songs;
  }

  @override
  Future<bool> deleteSong(Song song) async {
    final deleted = await _mediaLibraryService.deleteSong(song.id, song.dataUri);
    if (deleted) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawJson = prefs.getString(PrefKeys.customSongTitles);
        if (rawJson != null) {
          final titlesMap =
              Map<String, dynamic>.from(jsonDecode(rawJson) as Map);
          if (titlesMap.remove(song.id.toString()) != null) {
            await prefs.setString(
              PrefKeys.customSongTitles,
              jsonEncode(titlesMap),
            );
          }
        }
      } catch (_) {}
    }
    return deleted;
  }

  @override
  Future<bool> renameSong(Song song, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return false;

    // 1. Persist to local storage for 100% reliable offline persistence across rescans
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(PrefKeys.customSongTitles);
      final titlesMap = rawJson != null
          ? Map<String, dynamic>.from(jsonDecode(rawJson) as Map)
          : <String, dynamic>{};

      titlesMap[song.id.toString()] = trimmed;
      await prefs.setString(PrefKeys.customSongTitles, jsonEncode(titlesMap));
    } catch (_) {}

    // 2. Best-effort native MediaStore & physical file rename
    try {
      await _mediaLibraryService.renameSong(song.id, song.dataUri, trimmed);
    } catch (_) {}

    return true;
  }
}
