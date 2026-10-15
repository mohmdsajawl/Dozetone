import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dozetone/core/constants/pref_keys.dart';
import 'package:dozetone/data/repositories/playlist_repository.dart';
import 'package:dozetone/view_model/playlist/favorites_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlaylistRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    repository = PlaylistRepositoryImpl();
  });

  group('PlaylistRepository CRUD Tests', () {
    test('default playlists only include Night Ambience and Deep Sleep', () async {
      final playlists = await repository.getPlaylists();

      expect(playlists.keys, containsAll(<String>['Night Ambience', 'Deep Sleep']));
      expect(playlists.containsKey('Favorites'), isFalse);
      expect(playlists.length, equals(2));
    });

    test('cleans up legacy Favorites playlist if present in storage', () async {
      final initialData = <String, List<int>>{
        'Favorites': <int>[101, 102],
        'Night Ambience': <int>[101],
        'Deep Sleep': <int>[],
      };
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.customPlaylists: jsonEncode(initialData),
      });

      final playlists = await repository.getPlaylists();

      expect(playlists.containsKey('Favorites'), isFalse);
      expect(playlists.keys, containsAll(<String>['Night Ambience', 'Deep Sleep']));

      // Verify persistent storage was also cleaned
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(PrefKeys.customPlaylists);
      final decoded = jsonDecode(savedStr!) as Map<String, dynamic>;
      expect(decoded.containsKey('Favorites'), isFalse);
    });

    test('createPlaylist creates new playlist and prevents duplicate names', () async {
      final created = await repository.createPlaylist('Meditation');
      expect(created, isTrue);

      final playlists = await repository.getPlaylists();
      expect(playlists.containsKey('Meditation'), isTrue);
      expect(playlists['Meditation'], isEmpty);

      // Attempt duplicate creation
      final duplicate = await repository.createPlaylist('Meditation');
      expect(duplicate, isFalse);
    });

    test('createPlaylist rejects empty or blank names', () async {
      final empty = await repository.createPlaylist('   ');
      expect(empty, isFalse);
    });

    test('renamePlaylist renames existing playlist and retains its songs', () async {
      await repository.addSongToPlaylist('Night Ambience', 42);
      await repository.addSongToPlaylist('Night Ambience', 99);

      final renamed = await repository.renamePlaylist('Night Ambience', 'Relaxing Ambience');
      expect(renamed, isTrue);

      final playlists = await repository.getPlaylists();
      expect(playlists.containsKey('Night Ambience'), isFalse);
      expect(playlists.containsKey('Relaxing Ambience'), isTrue);
      expect(playlists['Relaxing Ambience'], equals(<int>[42, 99]));
    });

    test('renamePlaylist fails if new name already exists', () async {
      final renamed = await repository.renamePlaylist('Night Ambience', 'Deep Sleep');
      expect(renamed, isFalse);
    });

    test('deletePlaylist removes playlist from storage', () async {
      final deleted = await repository.deletePlaylist('Night Ambience');
      expect(deleted, isTrue);

      final playlists = await repository.getPlaylists();
      expect(playlists.containsKey('Night Ambience'), isFalse);
      expect(playlists.containsKey('Deep Sleep'), isTrue);

      // Deleting non-existent playlist returns false
      final deletedAgain = await repository.deletePlaylist('Night Ambience');
      expect(deletedAgain, isFalse);
    });

    test('addSongToPlaylist adds unique song IDs', () async {
      final firstAdd = await repository.addSongToPlaylist('Deep Sleep', 7);
      expect(firstAdd, isTrue);

      final duplicateAdd = await repository.addSongToPlaylist('Deep Sleep', 7);
      expect(duplicateAdd, isFalse);

      final playlists = await repository.getPlaylists();
      expect(playlists['Deep Sleep'], equals(<int>[7]));
    });

    test('addSongsToPlaylist batch adds songs avoiding duplicates', () async {
      await repository.addSongToPlaylist('Deep Sleep', 1);

      final addedCount = await repository.addSongsToPlaylist('Deep Sleep', <int>[1, 2, 3]);
      expect(addedCount, equals(2));

      final playlists = await repository.getPlaylists();
      expect(playlists['Deep Sleep'], equals(<int>[1, 2, 3]));
    });

    test('removeSongFromPlaylist removes song from playlist', () async {
      await repository.addSongToPlaylist('Deep Sleep', 10);
      await repository.addSongToPlaylist('Deep Sleep', 20);

      final removed = await repository.removeSongFromPlaylist('Deep Sleep', 10);
      expect(removed, isTrue);

      final playlists = await repository.getPlaylists();
      expect(playlists['Deep Sleep'], equals(<int>[20]));

      final removedAgain = await repository.removeSongFromPlaylist('Deep Sleep', 10);
      expect(removedAgain, isFalse);
    });
  });

  group('PlaylistsNotifier ViewModel Tests', () {
    test('loads playlists and executes CRUD with reactive state updates', () async {
      final notifier = PlaylistsNotifier(repository);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.containsKey('Night Ambience'), isTrue);
      expect(notifier.state.containsKey('Favorites'), isFalse);

      // Create
      await notifier.createPlaylist('Study Focus');
      expect(notifier.state.containsKey('Study Focus'), isTrue);

      // Add songs
      await notifier.addSongsToPlaylist('Study Focus', <int>[100, 200]);
      expect(notifier.state['Study Focus'], equals(<int>[100, 200]));

      // Rename
      await notifier.renamePlaylist('Study Focus', 'Deep Focus');
      expect(notifier.state.containsKey('Study Focus'), isFalse);
      expect(notifier.state['Deep Focus'], equals(<int>[100, 200]));

      // Remove song
      await notifier.removeSongFromPlaylist('Deep Focus', 100);
      expect(notifier.state['Deep Focus'], equals(<int>[200]));

      // Delete
      await notifier.deletePlaylist('Deep Focus');
      expect(notifier.state.containsKey('Deep Focus'), isFalse);
    });
  });
}
