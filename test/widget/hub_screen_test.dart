import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/home/presentation/hub_screen.dart';

void main() {
  testWidgets('HubScreen renders status bar, daily challenge, and all 7 games without overflow', (tester) async {
    // Test on a phone resolution
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HubScreen(),
      ),
    );

    // Verify status elements
    expect(find.text('DAILY CHALLENGE'), findsOneWidget);
    expect(find.text('MVP MINI-GAMES'), findsOneWidget);
    expect(find.text('EXPANSION GAMES'), findsOneWidget);

    // Verify 3 MVP Games
    expect(find.text('Cube Logic'), findsOneWidget);
    expect(find.text('Bridge Master'), findsOneWidget);
    expect(find.text('Maze Architect'), findsOneWidget);

    // Scroll down to verify the expansion games
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify 4 Expansion Games
    expect(find.text('Gear Theory'), findsOneWidget);
    expect(find.text('Tiny Kingdom'), findsOneWidget);
    expect(find.text('Perspective'), findsOneWidget);
    expect(find.text('Memory Matrix'), findsOneWidget);
  });
}
