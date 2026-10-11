import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/model/song.dart';

void main() {
  group('Song Model Tests', () {
    test('formattedDuration formats mm:ss correctly for standard tracks', () {
      const song = Song(
        id: 1,
        title: 'Midnight Rain',
        artist: 'Taylor Swift',
        durationMs: 174000, // 2 minutes 54 seconds
        dataUri: '/storage/emulated/0/Music/song1.mp3',
      );

      expect(song.formattedDuration, equals('02:54'));
    });

    test('formattedDuration formats h:mm:ss correctly for long tracks over 60 mins', () {
      const longSong = Song(
        id: 2,
        title: 'Deep Sleep Ambient Audio',
        artist: 'Nature Sounds',
        durationMs: 3725000, // 1 hour 2 minutes 5 seconds
        dataUri: '/storage/emulated/0/Music/ambient.mp3',
      );

      expect(longSong.formattedDuration, equals('1:02:05'));
    });

    test('copyWith properly updates specified fields while retaining others', () {
      const original = Song(
        id: 1,
        title: 'Original Title',
        artist: 'Original Artist',
        durationMs: 200000,
        dataUri: '/path/song.mp3',
      );

      final updated = original.copyWith(title: 'Updated Title');

      expect(updated.id, equals(1));
      expect(updated.title, equals('Updated Title'));
      expect(updated.artist, equals('Original Artist'));
    });

    test('Songs with same id are equal', () {
      const songA = Song(
        id: 42,
        title: 'Track A',
        artist: 'Artist',
        durationMs: 180000,
        dataUri: '/path/a.mp3',
      );

      const songB = Song(
        id: 42,
        title: 'Track B',
        artist: 'Different Artist',
        durationMs: 180000,
        dataUri: '/path/b.mp3',
      );

      expect(songA, equals(songB));
      expect(songA.hashCode, equals(songB.hashCode));
    });
  });
}
