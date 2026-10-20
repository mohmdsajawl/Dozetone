import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/services/permission_service.dart';
import '../../model/song.dart';
import 'library_state.dart';

/// Provider exposing the LibraryViewModel and its state.
final libraryViewModelProvider =
    StateNotifierProvider<LibraryViewModel, LibraryState>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final permissionService = ref.watch(permissionServiceProvider);
  return LibraryViewModel(repository, permissionService);
});

/// ViewModel managing Song Library state transitions and interactions.
///
/// Pure logic class; never holds BuildContext or builds UI widgets directly.
class LibraryViewModel extends StateNotifier<LibraryState> {
  final SongRepository _repository;
  final PermissionService _permissionService;

  LibraryViewModel(this._repository, this._permissionService)
      : super(const LibraryScanning()) {
    initialize();
  }

  /// Checks permissions on startup and begins song scanning if granted.
  Future<void> initialize() async {
    final hasPermission = await _permissionService.isAudioPermissionGranted();

    if (!hasPermission) {
      final isPermanentlyDenied = await _permissionService.isPermanentlyDenied();
      state = LibraryPermissionRequired(isPermanentlyDenied: isPermanentlyDenied);
      return;
    }

    unawaited(_permissionService.ensureNotificationPermission());
    await scanSongs();
  }

  /// Triggers a storage permission request from user interaction.
  Future<void> requestPermission() async {
    final status = await _permissionService.requestAudioPermission();

    if (status.isGranted || status.isLimited) {
      unawaited(_permissionService.ensureNotificationPermission());
      await scanSongs();
    } else {
      final isPermanentlyDenied = await _permissionService.isPermanentlyDenied();
      state = LibraryPermissionRequired(isPermanentlyDenied: isPermanentlyDenied);
    }
  }

  /// Opens application settings when permission was permanently denied.
  Future<void> openSettings() async {
    await _permissionService.openSettings();
  }

  /// Scans device audio tracks and transitions into Loaded, Empty, or Error.
  Future<void> scanSongs() async {
    state = const LibraryScanning();

    try {
      final songs = await _repository.fetchSongs();

      if (songs.isEmpty) {
        state = const LibraryEmpty();
      } else {
        state = LibraryLoaded(songs);
      }
    } catch (e, st) {
      AppLogger.e(
        'Failed to load music library',
        tag: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      state = LibraryError(e.toString());
    }
  }

  /// Pull to refresh handler that rescans audio files.
  Future<void> rescan() async {
    final hasPermission = await _permissionService.isAudioPermissionGranted();
    if (!hasPermission) {
      final isPermanentlyDenied = await _permissionService.isPermanentlyDenied();
      state = LibraryPermissionRequired(isPermanentlyDenied: isPermanentlyDenied);
      return;
    }

    await scanSongs();
  }

  /// Deletes a song from device storage and updates library state immediately.
  Future<bool> deleteSong(Song song) async {
    final deleted = await _repository.deleteSong(song);
    if (deleted && state is LibraryLoaded) {
      final currentSongs = (state as LibraryLoaded).songs;
      final updatedList = currentSongs.where((s) => s.id != song.id).toList();
      if (updatedList.isEmpty) {
        state = const LibraryEmpty();
      } else {
        state = LibraryLoaded(updatedList);
      }
    }
    return deleted;
  }

  /// Deletes multiple songs from device storage and updates library state immediately.
  Future<int> deleteSongs(List<Song> songs) async {
    int deletedCount = 0;
    final deletedIds = <int>{};
    for (final song in songs) {
      final ok = await _repository.deleteSong(song);
      if (ok) {
        deletedCount++;
        deletedIds.add(song.id);
      }
    }
    if (deletedIds.isNotEmpty && state is LibraryLoaded) {
      final currentSongs = (state as LibraryLoaded).songs;
      final updatedList =
          currentSongs.where((s) => !deletedIds.contains(s.id)).toList();
      if (updatedList.isEmpty) {
        state = const LibraryEmpty();
      } else {
        state = LibraryLoaded(updatedList);
      }
    }
    return deletedCount;
  }

  /// Renames a song title on storage and updates library state immediately.
  Future<bool> renameSong(Song song, String newTitle) async {
    final trimmed = newTitle.trim();
    if (trimmed.isEmpty) return false;

    final renamed = await _repository.renameSong(song, trimmed);
    if (renamed && state is LibraryLoaded) {
      final currentSongs = (state as LibraryLoaded).songs;
      final updatedList = currentSongs.map((s) {
        if (s.id == song.id) {
          return s.copyWith(title: trimmed);
        }
        return s;
      }).toList();

      updatedList.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

      state = LibraryLoaded(updatedList);
    }
    return renamed;
  }
}
