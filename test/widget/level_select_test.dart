import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/config/app_constants.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/game_selection/presentation/level_select_screen.dart';

void main() {
  testWidgets('LevelSelectScreen renders level grid and opens preview on tap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const LevelSelectScreen(gameId: AppConstants.gameCubeLogic),
      ),
    );

    expect(find.text('Cube Logic Levels'), findsOneWidget);
    expect(find.text('CAMPAIGN PROGRESS'), findsOneWidget);
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
}
