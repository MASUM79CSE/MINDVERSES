import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/home/presentation/hub_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  testWidgets('HubScreen renders status bar, daily challenge, and games without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

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
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HubScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify status elements
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);

    // Verify all seven implemented games are reachable from the hub.
    const games = [
      'Cube Logic',
      'Bridge Master',
      'Maze Architect',
      'Gear Theory',
      'Tiny Kingdom',
      'Perspective',
      'Memory Matrix',
    ];
    for (final game in games) {
      await tester.scrollUntilVisible(
        find.text(game),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(game), findsOneWidget);
    }

    // Unimplemented concepts must not be presented as playable modes.
    expect(find.text('Pattern Matrix'), findsNothing);
    expect(find.text('Gravity Orb'), findsNothing);
  });
}
