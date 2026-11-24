import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindverse/features/daily_challenge/presentation/daily_challenge_screen.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';

void main() {
  testWidgets('launches the selected daily puzzle with its claim context', (tester) async {
    DailyChallenge? launched;
    final router = GoRouter(initialLocation: '/daily', routes: [
      GoRoute(path: '/daily', builder: (_, _) => const DailyChallengeScreen()),
      GoRoute(path: '/:game/:level', builder: (_, state) {
        launched = state.extra as DailyChallenge;
        return Text('${state.pathParameters['game']}/${state.pathParameters['level']}');
      }),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        dailyChallengeStatusProvider.overrideWith((ref, date) async =>
            const DailyChallengeStatus(isCompleted: false, clockRollbackDetected: false, currentStreak: 2, nextStreak: 3, bestStreak: 2)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    expect(find.text('2 Days'), findsOneWidget);
    await tester.tap(find.text('Begin Challenge'));
    await tester.pumpAndSettle();
    final expected = DailyChallengeService.generateChallengeForDate(DateTime.now());
    expect(launched?.gameId, expected.gameId);
    expect(launched?.levelNumber, expected.levelNumber);
    expect(launched?.dateString, expected.dateString);
  });

  testWidgets('completed and clock-rollback challenges cannot be launched', (tester) async {
    for (final status in [
      const DailyChallengeStatus(isCompleted: true, clockRollbackDetected: false, currentStreak: 1, nextStreak: 1, bestStreak: 1),
      const DailyChallengeStatus(isCompleted: false, currentStreak: 1, clockRollbackDetected: true, nextStreak: 1, bestStreak: 1),
    ]) {
      await tester.pumpWidget(ProviderScope(
        key: UniqueKey(),
        overrides: [dailyChallengeStatusProvider.overrideWith((ref, date) async => status)],
        child: const MaterialApp(home: DailyChallengeScreen()),
      ));
      await tester.pumpAndSettle();
      if (status.isCompleted) {
        expect(find.text('Today’s challenge is complete.'), findsOneWidget);
      } else {
        expect(find.textContaining('Device clock moved backwards'), findsOneWidget);
      }
      final ink = tester.widget<InkWell>(find.ancestor(
        of: find.text('Begin Challenge'), matching: find.byType(InkWell),
      ).first);
      expect(ink.onTap, isNull);
    }
  });
}
