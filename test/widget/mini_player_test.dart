import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/l10n/generated/app_localizations.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view/player/widgets/mini_player.dart';

import '../unit/player_view_model_test.dart';

Widget _wrapMiniPlayer({
  required Widget child,
  required FakePlayerRepository repository,
}) {
  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('MiniPlayer Widget Tests', () {
    late FakePlayerRepository repository;

    const testSong = Song(
      id: 42,
      title: 'Starlight Serenade',
      artist: 'Lunar Echoes',
      durationMs: 240000,
      dataUri: '/storage/music/starlight.mp3',
    );

    setUp(() {
      repository = FakePlayerRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    testWidgets('MiniPlayer renders SizedBox.shrink when currentSong is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapMiniPlayer(
          child: const MiniPlayer(),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starlight Serenade'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('MiniPlayer displays song title, artist, progress and play button when song is present',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapMiniPlayer(
          child: const MiniPlayer(),
          repository: repository,
        ),
      );

      repository.emitState(const PlayerState(
        currentSong: testSong,
        isPlaying: false,
        position: Duration(seconds: 60),
        duration: Duration(seconds: 240),
      ));
      await tester.pump();

      expect(find.text('Starlight Serenade'), findsOneWidget);
      expect(find.text('Lunar Echoes'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    });

    testWidgets('MiniPlayer shows pause icon when playing and clicking toggles play/pause',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapMiniPlayer(
          child: const MiniPlayer(),
          repository: repository,
        ),
      );

      repository.emitState(const PlayerState(
        currentSong: testSong,
        isPlaying: true,
        position: Duration(seconds: 60),
        duration: Duration(seconds: 240),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(repository.pauseCalled, isTrue);
    });
  });
}
