import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/song.dart';

void main() {
  group('PlayerState Unit Tests', () {
    const testSong = Song(
      id: 101,
      title: 'Weightless',
      artist: 'Marconi Union',
      durationMs: 300000,
      dataUri: '/storage/music/weightless.mp3',
    );

    test('default state has expected initial values', () {
      const state = PlayerState();

      expect(state.currentSong, isNull);
      expect(state.isPlaying, isFalse);
      expect(state.isBuffering, isFalse);
      expect(state.position, equals(Duration.zero));
      expect(state.duration, equals(Duration.zero));
      expect(state.isShuffleEnabled, isFalse);
      expect(state.repeatMode, equals(PlayerRepeatMode.off));
      expect(state.queue, isEmpty);
      expect(state.currentIndex, equals(-1));
      expect(state.progressFraction, equals(0.0));
    });

    test('progressFraction calculates correct percentage', () {
      const state = PlayerState(
        position: Duration(seconds: 30),
        duration: Duration(seconds: 120),
      );

      expect(state.progressFraction, equals(0.25));
    });

    test('progressFraction clamps to 1.0 when position exceeds duration', () {
      const state = PlayerState(
        position: Duration(seconds: 150),
        duration: Duration(seconds: 120),
      );

      expect(state.progressFraction, equals(1.0));
    });

    test('progressFraction returns 0.0 when duration is zero', () {
      const state = PlayerState(
        position: Duration(seconds: 10),
        duration: Duration.zero,
      );

      expect(state.progressFraction, equals(0.0));
    });

    test('copyWith properly updates specific properties and preserves others', () {
      const initial = PlayerState(
        currentSong: testSong,
        isPlaying: false,
        repeatMode: PlayerRepeatMode.off,
      );

      final updated = initial.copyWith(
        isPlaying: true,
        repeatMode: PlayerRepeatMode.all,
        position: const Duration(seconds: 15),
      );

      expect(updated.currentSong, equals(testSong));
      expect(updated.isPlaying, isTrue);
      expect(updated.repeatMode, equals(PlayerRepeatMode.all));
      expect(updated.position, equals(const Duration(seconds: 15)));
    });

    test('equality and hashCode match for identical instances', () {
      const stateA = PlayerState(
        currentSong: testSong,
        isPlaying: true,
        repeatMode: PlayerRepeatMode.one,
      );

      const stateB = PlayerState(
        currentSong: testSong,
        isPlaying: true,
        repeatMode: PlayerRepeatMode.one,
      );

      expect(stateA, equals(stateB));
      expect(stateA.hashCode, equals(stateB.hashCode));
    });
  });
}
