import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../model/song.dart';

/// Provider for MediaLibraryService.
final mediaLibraryServiceProvider = Provider<MediaLibraryService>((ref) {
  return const MediaLibraryService();
});

/// Service responsible for querying on-device audio tracks and artwork
/// via native Android MediaStore platform channel.
class MediaLibraryService {
  static const MethodChannel _channel =
      MethodChannel('com.velcruxlab.dozetone/media_store');

  /// Minimum song duration in milliseconds (30 seconds) per requirements.
  static const int minSongDurationMs = 30000;

  const MediaLibraryService();

  /// Queries all device songs via native MediaStore ContentResolver,
  /// filters out short clips and non-music files,
  /// and returns an immutable list of [Song] models sorted A to Z by title.
  Future<List<Song>> queryDeviceSongs() async {
    final List<dynamic>? rawList =
        await _channel.invokeMethod<List<dynamic>>('querySongs');

    if (rawList == null || rawList.isEmpty) {
      return <Song>[];
    }

    final songs = <Song>[];

    for (final item in rawList) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);

      final id = (map['id'] as num?)?.toInt() ?? 0;
      final duration = (map['duration'] as num?)?.toInt() ?? 0;
      final dataUri = (map['dataUri'] as String?) ?? '';

      // Skip files shorter than 30s or invalid paths
      if (duration < minSongDurationMs || dataUri.isEmpty) {
        continue;
      }

      final rawTitle = (map['title'] as String?)?.trim() ?? '';
      final rawArtist = (map['artist'] as String?)?.trim() ?? '';
      final album = map['album'] as String?;
      final albumId = (map['albumId'] as num?)?.toInt();
      final size = (map['size'] as num?)?.toInt();
      final dateAdded = (map['dateAdded'] as num?)?.toInt();

      final title = rawTitle.isNotEmpty ? rawTitle : 'Unknown Title';
      final artist =
          (rawArtist.isNotEmpty && rawArtist != '<unknown>')
              ? rawArtist
              : 'Unknown Artist';

      songs.add(
        Song(
          id: id,
          title: title,
          artist: artist,
          album: album,
          albumId: albumId,
          durationMs: duration,
          dataUri: dataUri,
          sizeBytes: size,
          dateAdded: dateAdded,
        ),
      );
    }

    // Ensure strict alphabetical sorting by title (case-insensitive)
    songs.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    return songs;
  }

  /// Queries artwork thumbnail bytes for the given song/album.
  /// Returns null if no artwork is available.
  Future<Uint8List?> queryArtwork(int songId, int? albumId) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('queryArtwork', {
        'songId': songId,
        'albumId': albumId ?? 0,
      });
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Deletes a song from device storage and MediaStore.
  /// Returns true if deletion succeeded.
  Future<bool> deleteSong(int songId, String dataUri) async {
    try {
      final success = await _channel.invokeMethod<bool>('deleteSong', {
        'songId': songId,
        'dataUri': dataUri,
      });
      return success ?? false;
    } catch (_) {
      return false;
    }
  }
}
