import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/app.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_storage.dart';

void main() {
  testWidgets('App launches to Splash and navigates to Hub smoke test', (WidgetTester tester) async {
    // Seed onboarding as completed so splash navigates directly to Hub
    SharedPreferences.setMockInitialValues({
      StorageKeys.hasCompletedOnboarding: true,
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = (await tester.runAsync(() => createTestLocalStorage(prefs)))!;
    addTearDown(storage.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
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
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.text('Cube Logic'), findsOneWidget);
    expect(find.text('Bridge Master'), findsOneWidget);
    expect(find.text('Maze Architect'), findsOneWidget);
  });
}
