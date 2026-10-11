import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

/// Implementation of SongRepository that talks to MediaLibraryService.
class SongRepositoryImpl implements SongRepository {
  final MediaLibraryService _mediaLibraryService;

  SongRepositoryImpl(this._mediaLibraryService);

  @override
  Future<List<Song>> fetchSongs() async {
    return _mediaLibraryService.queryDeviceSongs();
  }
}
