import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/data/repositories/player_repository.dart';
import 'package:dozetone/l10n/generated/app_localizations.dart';
import 'package:dozetone/view/library/widgets/library_action_bar.dart';
import 'package:dozetone/view/player/widgets/sleep_timer_modal.dart';
import 'package:dozetone/view_model/sleep_timer/sleep_timer_view_model.dart';

import '../unit/player_view_model_test.dart';

Widget _wrapActionBar({
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
  group('LibraryActionBar Widget Tests', () {
    late FakePlayerRepository repository;

    setUp(() {
      repository = FakePlayerRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    testWidgets('LibraryActionBar displays Play All, Sleep Timer bar, and Shuffle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapActionBar(
          child: LibraryActionBar(
            songCount: 10,
            onPlayAllTap: () {},
            onShuffleTap: () {},
          ),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Sleep timer'), findsOneWidget);
      expect(find.text('Set timer'), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_rounded), findsOneWidget);
    });

    testWidgets('LibraryActionBar updates countdown when sleep timer is started',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapActionBar(
          child: LibraryActionBar(
            songCount: 10,
            onPlayAllTap: () {},
            onShuffleTap: () {},
          ),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(LibraryActionBar));
      final container = ProviderScope.containerOf(element);
      await container.read(sleepTimerProvider.notifier).startTimer(
            const Duration(minutes: 30),
            choiceLabel: '30 min',
          );
      await tester.pumpAndSettle();

      expect(find.text('30:00'), findsOneWidget);
    });

    testWidgets('Tapping Sleep Timer bar opens SleepTimerModal bottom sheet',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapActionBar(
          child: LibraryActionBar(
            songCount: 10,
            onPlayAllTap: () {},
            onShuffleTap: () {},
          ),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sleep timer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(SleepTimerModal), findsOneWidget);
    });
  });
}
