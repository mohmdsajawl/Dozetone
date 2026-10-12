import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view_model/library/filtered_songs_provider.dart';
import 'package:dozetone/view_model/library/library_search_query_provider.dart';
import 'package:dozetone/view_model/library/library_sort_provider.dart';
import 'package:dozetone/view_model/library/library_state.dart';
import 'package:dozetone/view_model/library/library_view_model.dart';

void main() {
  group('Filtered Songs Provider Tests', () {
    const testSongs = <Song>[
      Song(
        id: 1,
        title: 'Starboy',
        artist: 'The Weeknd',
        durationMs: 230000,
        dataUri: '/path/1.mp3',
      ),
      Song(
        id: 2,
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        durationMs: 200000,
        dataUri: '/path/2.mp3',
      ),
      Song(
        id: 3,
        title: 'Yellow',
        artist: 'Coldplay',
        durationMs: 260000,
        dataUri: '/path/3.mp3',
      ),
    ];

    test('returns all songs when search query is empty', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => ''),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.length, equals(3));
    });

    test('filters songs by title case-insensitively', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => 'star'),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.length, equals(1));
      expect(songs.first.title, equals('Starboy'));
    });

    test('filters songs by artist case-insensitively', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => 'coldplay'),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.length, equals(1));
      expect(songs.first.title, equals('Yellow'));
    });

    test('returns empty list when no songs match query', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => 'NonExistentArtist'),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs, isEmpty);
    });

    test('sorts songs by artist ascending when artistAsc is selected', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => ''),
          songSortOrderProvider.overrideWith((ref) => SongSortOrder.artistAsc),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.first.artist, equals('Coldplay'));
    });

    test('sorts songs by duration descending when durationDesc is selected', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => ''),
          songSortOrderProvider.overrideWith((ref) => SongSortOrder.durationDesc),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.first.durationMs, equals(260000));
      expect(songs.last.durationMs, equals(200000));
    });

    test('sorts songs by date added descending when dateAddedDesc is selected', () {
      final container = ProviderContainer(
        overrides: [
          libraryViewModelProvider.overrideWith(
            (ref) => _FakeLibraryViewModel(const LibraryLoaded(testSongs)),
          ),
          libraryQueryProvider.overrideWith((ref) => ''),
          songSortOrderProvider.overrideWith((ref) => SongSortOrder.dateAddedDesc),
        ],
      );
      addTearDown(container.dispose);

      final songs = container.read(filteredSongsProvider);
      expect(songs.first.id, equals(3));
      expect(songs.last.id, equals(1));
    });
  });
}

class _FakeLibraryViewModel extends StateNotifier<LibraryState>
    implements LibraryViewModel {
  _FakeLibraryViewModel(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
