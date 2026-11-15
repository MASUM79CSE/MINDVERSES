import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/app.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App launches to Splash and navigates to Hub smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MindverseApp(),
      ),
    );

    // Initial render on Splash screen
    await tester.pump();
    expect(find.text('MINDVERSE'), findsOneWidget);
    expect(find.text('Think. Solve. Explore.'), findsOneWidget);
    expect(find.text('Enter Universe'), findsOneWidget);

    // Tap to navigate to Hub
    await tester.tap(find.text('Enter Universe'));
    await tester.pumpAndSettle();

    // Verify Hub is presented
    expect(find.text('MINDVERSE HUB'), findsOneWidget);
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.text('Cube Logic'), findsOneWidget);
    expect(find.text('Bridge Master'), findsOneWidget);
    expect(find.text('Maze Architect'), findsOneWidget);
  });
}
