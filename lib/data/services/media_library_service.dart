import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
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

  /// Checks whether an audio file path or URI belongs to WhatsApp, voice notes,
  /// or messaging recordings that should be excluded from the music library.
  static bool isExcludedAudio(String dataUri) {
    if (dataUri.isEmpty) return false;
    final normalized = dataUri.toLowerCase().replaceAll('\\', '/');

    // Filter paths containing WhatsApp, voice notes, recordings, telegram audio
    if (normalized.contains('/whatsapp/') ||
        normalized.contains('/com.whatsapp') ||
        normalized.contains('/whatsapp audio/') ||
        normalized.contains('/whatsapp voice notes/') ||
        normalized.contains('/voice notes/') ||
        normalized.contains('/voicenotes/') ||
        normalized.contains('/telegram/telegram audio/') ||
        normalized.contains('/callrecordings/') ||
        normalized.contains('/call_rec/') ||
        normalized.contains('/soundrecorder/')) {
      return true;
    }

    // Filter WhatsApp naming patterns: AUD-YYYYMMDD-WA0001, PTT-YYYYMMDD-WA0001
    final fileName = normalized.split('/').last;
    if ((fileName.startsWith('aud-') || fileName.startsWith('ptt-')) &&
        fileName.contains('-wa')) {
      return true;
    }

    return false;
  }

  /// Queries all device songs via native MediaStore ContentResolver,
  /// filters out short clips and non-music files,
  /// and returns an immutable list of [Song] models sorted A to Z by title.
  Future<List<Song>> queryDeviceSongs({bool excludeWhatsapp = true}) async {
    final List<dynamic>? rawList =
        await _channel.invokeMethod<List<dynamic>>('querySongs', {
      'excludeWhatsapp': excludeWhatsapp,
    });

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

      // Filter WhatsApp and voice notes when enabled
      if (excludeWhatsapp && isExcludedAudio(dataUri)) {
        continue;
      }

      final rawTitle = (map['title'] as String?)?.trim() ?? '';
      final rawArtist = (map['artist'] as String?)?.trim() ?? '';
      final album = map['album'] as String?;
      final albumId = (map['albumId'] as num?)?.toInt();
      final size = (map['size'] as num?)?.toInt();
      final dateAdded = (map['dateAdded'] as num?)?.toInt();

      var title = rawTitle.isNotEmpty ? rawTitle : 'Unknown Title';
      var artist =
          (rawArtist.isNotEmpty && rawArtist != '<unknown>')
              ? rawArtist
              : 'Unknown Artist';

      // If artist is unknown and title follows standard "Artist - Track" convention
      if (artist == 'Unknown Artist' && title.contains(' - ')) {
        final parts = title.split(' - ');
        if (parts.length >= 2 &&
            parts[0].trim().isNotEmpty &&
            parts[1].trim().isNotEmpty) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }

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

  /// Queries artwork thumbnail bytes for the given song/album via
  /// direct container ID3 extraction and dedicated album folder lookup.
  /// Returns null if no genuine artwork is available.
  Future<Uint8List?> queryArtwork(int songId, int? albumId, {String? dataUri}) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('queryArtwork', {
        'songId': songId,
        'albumId': albumId ?? 0,
        'dataUri': dataUri ?? '',
      });
      return bytes;
    } catch (e) {
      AppLogger.d(
        'Failed to query artwork for song $songId (may have no embedded art)',
        tag: 'MediaLibraryService',
        error: e,
      );
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
    } catch (e, st) {
      AppLogger.e(
        'Platform deleteSong channel call failed for song $songId',
        tag: 'MediaLibraryService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }

  /// Renames a song title in MediaStore and on device storage.
  /// Returns true if rename succeeded.
  Future<bool> renameSong(int songId, String dataUri, String newTitle) async {
    try {
      final success = await _channel.invokeMethod<bool>('renameSong', {
        'songId': songId,
        'dataUri': dataUri,
        'newTitle': newTitle,
      });
      return success ?? false;
    } catch (e, st) {
      AppLogger.e(
        'Platform renameSong channel call failed for song $songId',
        tag: 'MediaLibraryService',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
