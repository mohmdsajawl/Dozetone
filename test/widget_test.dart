import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/app/app.dart';
import 'package:dozetone/view/splash/splash_view.dart';

void main() {
  testWidgets('DozetoneApp boots and mounts initial SplashView',
      (WidgetTester tester) async {
    // Build Dozetone inside Riverpod ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: DozetoneApp(),
      ),
    );
    await tester.pump();

    // Verify SplashView is mounted on initial boot
    expect(find.byType(SplashView), findsOneWidget);
  });
}
