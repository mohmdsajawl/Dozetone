import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import '../../model/song.dart';

/// Provider for accessing the underlying OnAudioQuery instance.
final onAudioQueryProvider = Provider<OnAudioQuery>((ref) {
  return OnAudioQuery();
});

/// Provider for MediaLibraryService.
final mediaLibraryServiceProvider = Provider<MediaLibraryService>((ref) {
  final audioQuery = ref.watch(onAudioQueryProvider);
  return MediaLibraryService(audioQuery);
});

/// Service responsible for scanning and querying on-device audio tracks.
class MediaLibraryService {
  final OnAudioQuery _audioQuery;

  /// Minimum song duration in milliseconds (30 seconds) per requirements.
  static const int minSongDurationMs = 30000;

  const MediaLibraryService(this._audioQuery);

  /// Queries all device songs, filters out short clips and non-music files,
  /// and returns an immutable list of [Song] models sorted A to Z by title.
  Future<List<Song>> queryDeviceSongs() async {
    final rawSongs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final filteredSongs = <Song>[];

    for (final raw in rawSongs) {
      // Rule 1: Exclude audio shorter than 30 seconds (voice notes, UI sounds)
      final duration = raw.duration ?? 0;
      if (duration < minSongDurationMs) {
        continue;
      }

      // Rule 2: Exclude ringtones, notifications, and alarms
      final isRingtone = raw.isRingtone ?? false;
      final isNotification = raw.isNotification ?? false;
      final isAlarm = raw.isAlarm ?? false;
      if (isRingtone || isNotification || isAlarm) {
        continue;
      }

      // Rule 3: Ensure valid file path
      final dataPath = raw.data;
      if (dataPath.isEmpty) {
        continue;
      }

      final song = Song(
        id: raw.id,
        title: raw.title.trim().isNotEmpty ? raw.title.trim() : 'Unknown Title',
        artist: (raw.artist != null && raw.artist!.trim().isNotEmpty && raw.artist != '<unknown>')
            ? raw.artist!.trim()
            : 'Unknown Artist',
        album: raw.album,
        albumId: raw.albumId,
        durationMs: duration,
        dataUri: dataPath,
        sizeBytes: raw.size,
      );

      filteredSongs.add(song);
    }

    // Ensure strict alphabetical sorting by title (case-insensitive)
    filteredSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    return filteredSongs;
  }
}
