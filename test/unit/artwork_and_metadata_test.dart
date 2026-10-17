import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/data/services/media_library_service.dart';
import 'package:dozetone/view/library/widgets/song_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SongArtworkCache', () {
    setUp(() {
      SongArtworkCache.clear();
    });

    test('put, get, contains, and clear work as expected', () {
      expect(SongArtworkCache.contains(101), isFalse);
      expect(SongArtworkCache.get(101), isNull);

      final dummyBytes = Uint8List.fromList([1, 2, 3, 4]);
      SongArtworkCache.put(101, dummyBytes);

      expect(SongArtworkCache.contains(101), isTrue);
      expect(SongArtworkCache.get(101), equals(dummyBytes));

      SongArtworkCache.clear();
      expect(SongArtworkCache.contains(101), isFalse);
      expect(SongArtworkCache.get(101), isNull);
    });
  });

  group('MediaLibraryService metadata parsing and artwork channel', () {
    test('queryDeviceSongs parses hyphenated Artist - Title when artist is unknown', () async {
      final binding = TestDefaultBinaryMessengerBinding.instance;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.velcruxlab.dozetone/media_store'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'querySongs') {
            return [
              {
                'id': 1,
                'title': 'Atif Aslam - Dil Diyan Gallan',
                'artist': '<unknown>',
                'album': 'Download',
                'albumId': 10,
                'duration': 210000,
                'dataUri': '/storage/emulated/0/Download/atif.mp3',
                'size': 5000000,
                'dateAdded': 1600000000,
              },
              {
                'id': 2,
                'title': 'Coldplay - Yellow (Live)',
                'artist': 'Coldplay',
                'album': 'Parachutes',
                'albumId': 20,
                'duration': 240000,
                'dataUri': '/storage/emulated/0/Music/yellow.mp3',
                'size': 6000000,
                'dateAdded': 1600000001,
              },
            ];
          }
          if (methodCall.method == 'queryArtwork') {
            final args = methodCall.arguments as Map;
            if (args['dataUri'] == '/storage/emulated/0/Music/yellow.mp3') {
              return Uint8List.fromList([9, 8, 7]);
            }
            return null;
          }
          return null;
        },
      );

      const service = MediaLibraryService();
      final songs = await service.queryDeviceSongs();

      expect(songs.length, equals(2));

      // Song 1 had <unknown> artist and "Atif Aslam - Dil Diyan Gallan"
      final song1 = songs.firstWhere((s) => s.id == 1);
      expect(song1.artist, equals('Atif Aslam'));
      expect(song1.title, equals('Dil Diyan Gallan'));

      // Song 2 had known artist 'Coldplay' -> retains known artist
      final song2 = songs.firstWhere((s) => s.id == 2);
      expect(song2.artist, equals('Coldplay'));
      expect(song2.title, equals('Coldplay - Yellow (Live)'));

      // Query artwork with dataUri
      final art2 = await service.queryArtwork(2, 20, dataUri: song2.dataUri);
      expect(art2, isNotNull);
      expect(art2!.length, equals(3));

      // Query artwork for track without embedded art returns null
      final art1 = await service.queryArtwork(1, 10, dataUri: song1.dataUri);
      expect(art1, isNull);
    });
  });
}
