import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dozetone/data/repositories/song_repository.dart';
import 'package:dozetone/data/services/permission_service.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/library/library_state.dart';
import 'package:dozetone/view_model/library/library_view_model.dart';

class FakeSongRepository implements SongRepository {
  List<Song> songs = <Song>[];
  bool deleteResult = true;
  bool renameResult = true;

  @override
  Future<List<Song>> fetchSongs() async => songs;

  @override
  Future<bool> deleteSong(Song song) async {
    if (deleteResult) {
      songs.removeWhere((s) => s.id == song.id);
    }
    return deleteResult;
  }

  @override
  Future<bool> renameSong(Song song, String newTitle) async {
    if (renameResult) {
      final index = songs.indexWhere((s) => s.id == song.id);
      if (index != -1) {
        songs[index] = songs[index].copyWith(title: newTitle);
      }
    }
    return renameResult;
  }
}

class FakePermissionService implements PermissionService {
  bool granted = true;
  bool permanentlyDenied = false;

  @override
  Future<bool> isAudioPermissionGranted() async => granted;

  @override
  Future<PermissionStatus> requestAudioPermission() async =>
      granted ? PermissionStatus.granted : PermissionStatus.denied;

  @override
  Future<bool> isPermanentlyDenied() async => permanentlyDenied;

  @override
  Future<bool> openSettings() async => true;
}

void main() {
  const song1 = Song(
    id: 1,
    title: 'Alpha Song',
    artist: 'Artist A',
    durationMs: 180000,
    dataUri: '/storage/emulated/0/Music/alpha.mp3',
  );

  const song2 = Song(
    id: 2,
    title: 'Beta Song',
    artist: 'Artist B',
    durationMs: 210000,
    dataUri: '/storage/emulated/0/Music/beta.mp3',
  );

  group('LibraryViewModel Unit Tests', () {
    late FakeSongRepository repository;
    late FakePermissionService permissionService;
    late LibraryViewModel viewModel;

    setUp(() {
      repository = FakeSongRepository();
      permissionService = FakePermissionService();
      viewModel = LibraryViewModel(repository, permissionService);
    });

    test('scanSongs updates state to LibraryLoaded with fetched songs', () async {
      repository.songs = <Song>[song1, song2];
      await viewModel.scanSongs();

      expect(viewModel.state, isA<LibraryLoaded>());
      final loadedState = viewModel.state as LibraryLoaded;
      expect(loadedState.songs.length, equals(2));
      expect(loadedState.songs.first.title, equals('Alpha Song'));
    });

    test('deleteSong removes song from library state', () async {
      repository.songs = <Song>[song1, song2];
      await viewModel.scanSongs();

      final result = await viewModel.deleteSong(song1);
      expect(result, isTrue);

      final loadedState = viewModel.state as LibraryLoaded;
      expect(loadedState.songs.length, equals(1));
      expect(loadedState.songs.first.id, equals(2));
    });

    test('renameSong updates song title and maintains alphabetical order', () async {
      repository.songs = <Song>[song1, song2];
      await viewModel.scanSongs();

      final result = await viewModel.renameSong(song1, 'Zeta Song');
      expect(result, isTrue);

      final loadedState = viewModel.state as LibraryLoaded;
      expect(loadedState.songs.length, equals(2));
      expect(loadedState.songs[0].title, equals('Beta Song'));
      expect(loadedState.songs[1].title, equals('Zeta Song'));
    });

    test('renameSong rejects empty or blank title', () async {
      repository.songs = <Song>[song1];
      await viewModel.scanSongs();

      final result = await viewModel.renameSong(song1, '   ');
      expect(result, isFalse);

      final loadedState = viewModel.state as LibraryLoaded;
      expect(loadedState.songs.first.title, equals('Alpha Song'));
    });
  });
}
