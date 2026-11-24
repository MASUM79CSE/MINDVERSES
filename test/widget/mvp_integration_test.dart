import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindverse/features/home/presentation/hub_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MVP Integration: Hub screen renders all three MVP mini-games', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = (await tester.runAsync(() => createTestLocalStorage(prefs)))!;
    addTearDown(storage.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const MaterialApp(
          home: HubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Hub displays Cube Logic, Bridge Master, and Maze Architect
    expect(find.text('Cube Logic'), findsWidgets);
    expect(find.text('Bridge Master'), findsWidgets);
    expect(find.text('Maze Architect'), findsWidgets);
  });
}
