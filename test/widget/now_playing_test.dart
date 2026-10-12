import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/l10n/generated/app_localizations.dart';
import 'package:dozetone/model/player_state.dart';
import 'package:dozetone/model/song.dart';
import 'package:dozetone/view/player/now_playing_view.dart';

import '../unit/player_view_model_test.dart';

Widget _wrapNowPlayingView({
  required FakePlayerRepository repository,
}) {
  return ProviderScope(
    overrides: [
      playerRepositoryProvider.overrideWithValue(repository),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NowPlayingView(),
    ),
  );
}

void main() {
  group('NowPlayingView Widget Tests', () {
    late FakePlayerRepository repository;

    const testSong = Song(
      id: 99,
      title: 'Cosmic Drift',
      artist: 'Stellar Wind',
      durationMs: 180000,
      dataUri: '/storage/music/cosmic.mp3',
    );

    setUp(() {
      repository = FakePlayerRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    testWidgets('NowPlayingView displays no songs found when currentSong is null',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapNowPlayingView(repository: repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('No songs found'), findsOneWidget);
    });

    testWidgets('NowPlayingView displays track title, artist, seek slider, and controls when active',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapNowPlayingView(repository: repository),
      );

      repository.emitState(const PlayerState(
        currentSong: testSong,
        isPlaying: false,
        position: Duration(seconds: 45),
        duration: Duration(seconds: 180),
      ));
      await tester.pump();

      expect(find.text('Cosmic Drift'), findsOneWidget);
      expect(find.text('Stellar Wind'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
    });

    testWidgets('Tapping play/pause button triggers togglePlayPause',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapNowPlayingView(repository: repository),
      );

      repository.emitState(const PlayerState(
        currentSong: testSong,
        isPlaying: true,
        position: Duration(seconds: 45),
        duration: Duration(seconds: 180),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.pause_rounded));
      await tester.pump();

      expect(repository.pauseCalled, isTrue);
    });

    testWidgets('Tapping shuffle and repeat buttons updates state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapNowPlayingView(repository: repository),
      );

      repository.emitState(const PlayerState(
        currentSong: testSong,
        isPlaying: false,
        position: Duration.zero,
        duration: Duration(seconds: 180),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.shuffle_rounded));
      await tester.pump();
      expect(repository.toggleShuffleCalled, isTrue);

      await tester.tap(find.byIcon(Icons.repeat_rounded));
      await tester.pump();
      expect(repository.cycleRepeatCalled, isTrue);
    });
  });
}
