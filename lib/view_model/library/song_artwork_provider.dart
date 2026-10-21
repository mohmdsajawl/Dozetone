import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/song_repository.dart';

/// Function signature for querying song artwork thumbnail bytes.
typedef SongArtworkQuery = Future<Uint8List?> Function(
  int songId,
  int? albumId, {
  String? dataUri,
});

/// Provider exposing artwork fetching capability to UI widgets
/// without exposing data layer services directly.
final songArtworkQueryProvider = Provider<SongArtworkQuery>((ref) {
  final songRepo = ref.watch(songRepositoryProvider);
  return (int songId, int? albumId, {String? dataUri}) {
    return songRepo.getArtwork(songId, albumId, dataUri: dataUri);
  };
});
