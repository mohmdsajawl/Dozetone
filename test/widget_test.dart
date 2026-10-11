import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dozetone/app/app.dart';

void main() {
  testWidgets('DozetoneApp boots and displays initial themed screen',
      (WidgetTester tester) async {
    // Build Dozetone inside Riverpod ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: DozetoneApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify brand title and foundation status text are displayed
    expect(find.text('Dozetone'), findsOneWidget);
    expect(find.text('Phase 0: Foundation Ready'), findsOneWidget);
  });
}
