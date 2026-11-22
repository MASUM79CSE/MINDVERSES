import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/features/home/presentation/hub_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HubScreen renders status bar, daily challenge, and games without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
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

    // Verify MVP Games
    expect(find.text('Cube Logic'), findsOneWidget);
    expect(find.text('Bridge Master'), findsOneWidget);
    expect(find.text('Maze Architect'), findsOneWidget);
  });
}
