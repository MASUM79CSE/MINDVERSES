import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/config/app_constants.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/core/widgets/app_button.dart';
import 'package:mindverse/core/widgets/star_display.dart';
import 'package:mindverse/features/game_selection/presentation/level_select_screen.dart';
import 'package:mindverse/features/home/presentation/hub_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

Future<void> pumpHub(WidgetTester tester) async {
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
}

Future<void> pumpLevelSelect(WidgetTester tester) async {
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
}

void main() {
  testWidgets('hub game cards expose title, category, and star totals', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpHub(tester);

    expect(
      find.bySemanticsLabel(
        RegExp(r'Cube Logic\. 3D Spatial Logic\. 0 of 60 stars earned\.'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Bridge Master\. Structural Engineering')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('level tiles expose level number, status, and stars', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpLevelSelect(tester);

    expect(
      find.bySemanticsLabel('Level 1, unlocked, 0 of 3 stars'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Level 2, locked, 0 of 3 stars'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('shared buttons and star displays expose semantic labels', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Column(
            children: [
              AppButton(label: 'Start Puzzle', onPressed: () {}),
              const StarDisplay(earnedStars: 2),
            ],
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Start Puzzle'), findsOneWidget);
    expect(find.bySemanticsLabel('2 of 3 stars'), findsOneWidget);
    handle.dispose();
  });

  for (final (label, size, scale) in [
    ('small phone', const Size(320, 568), 1.5),
    ('large phone', const Size(800, 1280), 1.5),
  ]) {
    testWidgets('hub renders on a $label at ${scale}x text without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await pumpHub(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('CHOOSE YOUR GAME'), findsOneWidget);
    });
  }

  testWidgets('level grid renders on a small phone without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpLevelSelect(tester);

    final exception = tester.takeException();
    if (exception is FlutterError) {
      debugPrint(exception.toStringDeep());
      debugDumpRenderTree();
    }
    expect(exception, isNull);
    expect(find.text('Cube Logic Levels'), findsOneWidget);
  });
}
