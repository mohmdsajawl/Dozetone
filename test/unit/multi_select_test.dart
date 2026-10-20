import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/timer_notification_action.dart';
import 'package:dozetone/view_model/library/multi_select_provider.dart';
import 'package:dozetone/view_model/library/library_view_model.dart';
import 'package:dozetone/view_model/library/library_state.dart';
import 'package:dozetone/view_model/playlist/favorites_provider.dart';
import 'package:dozetone/view_model/player/player_view_model.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/data/repositories/song_repository.dart';
import 'package:dozetone/data/repositories/playlist_repository.dart';
import 'package:dozetone/data/services/permission_service.dart';
import 'package:dozetone/view/library/widgets/song_list_tile.dart';
import 'package:permission_handler/permission_handler.dart';

class FakeSongRepository implements SongRepository {
  List<Song> songs = [];
  List<int> deletedSongIds = [];

  @override
  Future<List<Song>> fetchSongs() async => List<Song>.from(songs);

  @override
  Future<bool> deleteSong(Song song) async {
    deletedSongIds.add(song.id);
    songs.removeWhere((s) => s.id == song.id);
    return true;
  }

  @override
  Future<bool> renameSong(Song song, String newTitle) async => true;
}

class FakePermissionService implements PermissionService {
  @override
  Future<bool> isAudioPermissionGranted() async => true;
  @override
  Future<bool> isPermanentlyDenied() async => false;
  @override
  Future<PermissionStatus> requestAudioPermission() async =>
      PermissionStatus.granted;
  @override
  Future<bool> openSettings() async => true;
  @override
  Future<bool> ensureNotificationPermission() async => true;
}

class FakePlaylistRepository implements PlaylistRepository {
  Set<int> favorites = {};
  Map<String, List<int>> playlists = {};

  @override
  Future<Set<int>> getFavoriteSongIds() async => Set<int>.from(favorites);

  @override
  Future<bool> toggleFavorite(int songId) async {
    if (favorites.contains(songId)) {
      favorites.remove(songId);
      return false;
    } else {
      favorites.add(songId);
      return true;
    }
  }

  @override
  Future<bool> isFavorite(int songId) async => favorites.contains(songId);

  @override
  Future<Map<String, List<int>>> getPlaylists() async => playlists;

  @override
  Future<bool> createPlaylist(String name) async {
    playlists[name] = [];
    return true;
  }

  @override
  Future<bool> renamePlaylist(String oldName, String newName) async {
    final songs = playlists.remove(oldName) ?? [];
    playlists[newName] = songs;
    return true;
  }

  @override
  Future<bool> deletePlaylist(String name) async {
    playlists.remove(name);
    return true;
  }

  @override
  Future<bool> addSongToPlaylist(String name, int songId) async {
    playlists.putIfAbsent(name, () => []).add(songId);
    return true;
  }

  @override
  Future<int> addSongsToPlaylist(String name, List<int> songIds) async {
    playlists.putIfAbsent(name, () => []).addAll(songIds);
    return songIds.length;
  }

  @override
  Future<bool> removeSongFromPlaylist(String name, int songId) async {
    playlists[name]?.remove(songId);
    return true;
  }
}

class FakePlayerRepo implements PlayerRepository {
  List<Song> activeQueue = [];
  final StreamController<PlayerState> _controller =
      StreamController<PlayerState>.broadcast();
  final StreamController<void> _trackCompletedController =
      StreamController<void>.broadcast();

  @override
  Stream<PlayerState> get playerStateStream => _controller.stream;
  @override
  Stream<void> get trackCompletedStream => _trackCompletedController.stream;

  @override
  Stream<TimerNotificationAction> get timerNotificationActions =>
      const Stream.empty();

  @override
  void setTimerActionVisible(bool visible) {}

  @override
  void setTimerNotificationText(String? text) {}

  @override
  void addToQueue(Song song) {
    activeQueue.add(song);
  }

  @override
  void addSongsToQueue(List<Song> songs) {
    activeQueue.addAll(songs);
  }

  @override
  Future<void> playSong(Song song, List<Song> queue) async {
    activeQueue = List<Song>.from(queue);
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> skipToNext() async {}
  @override
  Future<void> skipToPrevious() async {}
  @override
  void toggleShuffle() {}
  @override
  void cycleRepeatMode() {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  void insertNext(Song song) {}
  @override
  void reorderQueue(int oldIndex, int newIndex) {}
  @override
  Future<void> removeFromQueue(int index) async {}
  @override
  void clearUpNext() {}
  @override
  Future<void> skipToQueueIndex(int index) async {}
  @override
  void updatePlaybackQueue(List<Song> newQueue) {}
  @override
  Future<void> removeSongFromPlayback(int songId) async {
    activeQueue.removeWhere((s) => s.id == songId);
  }
  @override
  void updateSongMetadata(int songId, String newTitle) {}
  @override
  void setPauseOnTrackEnd(bool pause) {}
  @override
  void setLoopForSleepTimer(bool loop) {}
  @override
  Future<void> saveLastPlaybackSession(int songId, int positionMs) async {}
  @override
  Future<({int? songId, int? positionMs})> getLastPlaybackSession() async =>
      (songId: null, positionMs: null);
  @override
  Future<void> restoreLastSession({
    required Song song,
    required Duration position,
    required List<Song> queue,
  }) async {}
}

void main() {
  final song1 = Song(
    id: 1,
    title: 'Song One',
    artist: 'Artist A',
    album: 'Album X',
    durationMs: 180000,
    dataUri: '/song1.mp3',
    sizeBytes: 1024,
    dateAdded: 100,
  );
  final song2 = Song(
    id: 2,
    title: 'Song Two',
    artist: 'Artist B',
    album: 'Album Y',
    durationMs: 200000,
    dataUri: '/song2.mp3',
    sizeBytes: 2048,
    dateAdded: 200,
  );
  final song3 = Song(
    id: 3,
    title: 'Song Three',
    artist: 'Artist C',
    album: 'Album Z',
    durationMs: 220000,
    dataUri: '/song3.mp3',
    sizeBytes: 3072,
    dateAdded: 300,
  );

  group('MultiSelectNotifier tests', () {
    test('initial state is empty and inactive', () {
      final notifier = MultiSelectNotifier();
      expect(notifier.state.isEmpty, true);
      expect(notifier.isActive, false);
    });

    test('toggle adds and removes song ID accurately', () {
      final notifier = MultiSelectNotifier();
      notifier.toggle(1);
      expect(notifier.isActive, true);
      expect(notifier.isSelected(1), true);
      expect(notifier.state.contains(1), true);

      notifier.toggle(1);
      expect(notifier.isActive, false);
      expect(notifier.isSelected(1), false);
      expect(notifier.state.isEmpty, true);
    });

    test('selectAll and clear work correctly', () {
      final notifier = MultiSelectNotifier();
      notifier.selectAll([1, 2, 3]);
      expect(notifier.state.length, 3);
      expect(notifier.isSelected(2), true);

      notifier.clear();
      expect(notifier.state.isEmpty, true);
      expect(notifier.isActive, false);
    });
  });

  group('Batch operations in ViewModels', () {
    test('LibraryViewModel deleteSongs deletes multiple songs', () async {
      final repo = FakeSongRepository()..songs = [song1, song2, song3];
      final vm = LibraryViewModel(repo, FakePermissionService());
      await vm.scanSongs();

      expect(vm.state, isA<LibraryLoaded>());
      final loaded = vm.state as LibraryLoaded;
      expect(loaded.songs.length, 3);

      final deletedCount = await vm.deleteSongs([song1, song3]);
      expect(deletedCount, 2);
      expect(repo.deletedSongIds, containsAll([1, 3]));

      final after = vm.state as LibraryLoaded;
      expect(after.songs.length, 1);
      expect(after.songs.first.id, 2);
    });

    test('FavoritesNotifier addFavorites batch adds IDs', () async {
      final playlistRepo = FakePlaylistRepository();
      final favoritesVm = FavoritesNotifier(playlistRepo);
      await favoritesVm.loadFavorites();

      expect(favoritesVm.state.isEmpty, true);
      await favoritesVm.addFavorites([1, 2, 3]);

      expect(favoritesVm.state.length, 3);
      expect(favoritesVm.isFavorite(1), true);
      expect(favoritesVm.isFavorite(2), true);
      expect(favoritesVm.isFavorite(3), true);
    });

    test('PlayerViewModel addSongsToQueue appends multiple tracks', () async {
      final playerRepo = FakePlayerRepo();
      final playerVm = PlayerViewModel(playerRepo);

      playerVm.addSongsToQueue([song1, song2]);
      expect(playerRepo.activeQueue.length, 2);
      expect(playerRepo.activeQueue.first.title, 'Song One');
      expect(playerRepo.activeQueue.last.title, 'Song Two');

      playerVm.addSongsToQueue([song3]);
      expect(playerRepo.activeQueue.length, 3);
    });
  });

  group('SongListTile selection mode widget tests', () {
    testWidgets('renders check icon when isSelectionMode and isSelected are true',
        (tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SongListTile(
                song: song1,
                isSelectionMode: true,
                isSelected: true,
                onTap: () => tapped = true,
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.more_vert_rounded), findsNothing);

      await tester.tap(find.byType(SongListTile));
      expect(tapped, true);

      await tester.longPress(find.byType(SongListTile));
      expect(longPressed, true);
    });
  });
}
