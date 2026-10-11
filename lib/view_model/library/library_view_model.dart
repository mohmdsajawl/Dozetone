import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/repositories/song_repository.dart';
import '../../data/services/permission_service.dart';
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

    await scanSongs();
  }

  /// Triggers a storage permission request from user interaction.
  Future<void> requestPermission() async {
    final status = await _permissionService.requestAudioPermission();

    if (status.isGranted || status.isLimited) {
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
    } catch (e) {
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
}
