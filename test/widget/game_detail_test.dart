import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/config/app_constants.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/game_selection/presentation/game_detail_screen.dart';

void main() {
  testWidgets('GameDetailScreen renders Cube Logic details and 3-star scoring rules', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const GameDetailScreen(gameId: AppConstants.gameCubeLogic),
      ),
    );

    expect(find.text('Cube Logic'), findsWidgets);
    expect(find.text('Spatial 3D Logic'), findsOneWidget);
    expect(find.text('20'), findsOneWidget); // 20 Total Levels
    expect(find.text('THREE-STAR SCORING RULES'), findsOneWidget);
    expect(find.text('Star 1: Completion'), findsOneWidget);
    expect(find.text('Star 2: Efficiency'), findsOneWidget);
    expect(find.text('Star 3: Mastery'), findsOneWidget);

    // Scroll down to reveal the action button
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Select Level'), findsOneWidget);
  });
}
