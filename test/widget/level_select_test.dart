import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/config/app_constants.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/game_selection/presentation/level_select_screen.dart';
import 'package:mindverse/shared/models/level_result.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/level_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  testWidgets('LevelSelectScreen renders level grid and opens preview on tap', (tester) async {
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
          home: const LevelSelectScreen(gameId: AppConstants.gameCubeLogic),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cube Logic Levels'), findsOneWidget);
    expect(find.text('CAMPAIGN PROGRESS'), findsOneWidget);
    expect(find.text('1 of 20 Unlocked'), findsOneWidget);
    expect(find.text('0 / 60 Stars'), findsOneWidget);
    expect(find.text('1'), findsWidgets); // Level 1

    // Tap level 1 (unlocked)
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();

    // Verify Level Preview Dialog is presented
    expect(find.text('Cube Logic — Level 1'), findsOneWidget);
    expect(find.text('Start Puzzle'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Start Puzzle'), findsNothing);
  });

  testWidgets('LevelSelectScreen renders saved stars and unlock state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = (await tester.runAsync(() => createTestLocalStorage(prefs)))!;
    addTearDown(storage.close);

    // Storage work must run outside the widget-test fake-async zone, otherwise
    // the Sembast transaction never completes.
    await tester.runAsync(() async {
      final levels = LevelProgressRepositoryImpl(storage);
      await levels.saveLevelResult(const LevelResult(
        gameId: AppConstants.gameCubeLogic,
        levelNumber: 1,
        isUnlocked: true,
        isCompleted: true,
        starsEarned: 2,
        star1Completed: true,
        star2Efficiency: true,
      ));
      await levels.saveLevelResult(const LevelResult(
        gameId: AppConstants.gameCubeLogic,
        levelNumber: 2,
        isUnlocked: true,
      ));
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LevelSelectScreen(gameId: AppConstants.gameCubeLogic),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 of 20 Unlocked'), findsOneWidget);
    expect(find.text('2 / 60 Stars'), findsOneWidget);
  });
}
