import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/l10n/generated/app_localizations.dart';
import 'package:dozetone/view/library/widgets/library_states.dart';
import 'package:dozetone/view/widgets/sound_wave_rings.dart';

Widget _wrapWithLocalization(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Library States Widget Tests', () {
    testWidgets('PermissionRequiredView displays Grant permission button by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          PermissionRequiredView(
            isPermanentlyDenied: false,
            onGrantTap: () {},
            onSettingsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grant permission'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    });

    testWidgets('PermissionRequiredView displays Open settings when permanently denied',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          PermissionRequiredView(
            isPermanentlyDenied: true,
            onGrantTap: () {},
            onSettingsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open settings'), findsOneWidget);
    });

    testWidgets('ScanningSongsView displays SoundWavePulseLoader and scanning text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          const ScanningSongsView(),
        ),
      );
      await tester.pump();

      expect(find.byType(SoundWavePulseLoader), findsOneWidget);
      expect(find.text('Scanning your music...'), findsOneWidget);
    });

    testWidgets('EmptyLibraryView displays empty title and short song hint',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          const EmptyLibraryView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No songs found'), findsOneWidget);
      expect(find.text('Songs shorter than 30 seconds are hidden'), findsOneWidget);
    });

    testWidgets('NoSearchResultsView displays query message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrapWithLocalization(
          const NoSearchResultsView(query: 'Beethoven'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No results for "Beethoven"'), findsOneWidget);
    });

    testWidgets('ErrorLibraryView displays error and retry button',
        (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        _wrapWithLocalization(
          ErrorLibraryView(
            message: 'Failed to access storage',
            onRetry: () {
              retried = true;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to access storage'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });
  });
}
