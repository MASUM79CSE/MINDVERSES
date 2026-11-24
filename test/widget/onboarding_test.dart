import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/onboarding/presentation/onboarding_screen.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  testWidgets('Onboarding advances through slides and sets completion flag', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = (await tester.runAsync(() => createTestLocalStorage(prefs)))!;
    addTearDown(storage.close);

    final testRouter = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/hub',
          builder: (context, state) => const Scaffold(body: Text('Hub Target')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp.router(
          theme: AppTheme.darkTheme,
          routerConfig: testRouter,
        ),
      ),
    );

    // Slide 1: THINK
    expect(find.text('THINK'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Slide 2: SOLVE
    expect(find.text('SOLVE'), findsOneWidget);

    // Tap Continue
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Slide 3: EXPLORE
    expect(find.text('EXPLORE'), findsOneWidget);
    expect(find.text('Enter MINDVERSE'), findsOneWidget);

    // Tap Enter MINDVERSE
    await tester.tap(find.text('Enter MINDVERSE'));
    await tester.pumpAndSettle();

    // Verify flag was saved and router navigated to Hub
    expect(prefs.getBool(StorageKeys.hasCompletedOnboarding), isTrue);
    expect(find.text('Hub Target'), findsOneWidget);
  });
}
