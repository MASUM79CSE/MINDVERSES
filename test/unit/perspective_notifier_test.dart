import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mindverse/app/router/route_paths.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/perspective/presentation/perspective_screen.dart';
import 'package:mindverse/features/perspective/presentation/providers/perspective_notifier.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class ControlledStorage implements LocalStorageService {
  ControlledStorage(this.delegate);

  final LocalStorageService delegate;
  bool failBeforeCommit = false;
  bool failAfterCommit = false;
  Completer<void>? releaseTransaction;
  Completer<void>? transactionReached;

  @override
  Future<T> runInTransaction<T>(Future<T> Function(LocalStorageTransaction transaction) action) async {
    final result = await delegate.runInTransaction((transaction) async {
      final result = await action(transaction);
      if (transactionReached != null) {
        transactionReached!.complete();
        transactionReached = null;
        await releaseTransaction!.future;
      }
      if (failBeforeCommit) {
        failBeforeCommit = false;
        throw StateError('injected failure before commit');
      }
      return result;
    });
    if (failAfterCommit) {
      failAfterCommit = false;
      throw StateError('injected lost commit response');
    }
    return result;
  }

  @override
  Future<Map<String, dynamic>?> readDocument(String key) => delegate.readDocument(key);

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> data) => delegate.writeDocument(key, data);

  @override
  Future<void> removeDocument(String key) => delegate.removeDocument(key);

  @override
  Future<void> resetUserData() => delegate.resetUserData();

  @override
  Future<void> close() => delegate.close();
}

class CountingDailyRepository implements DailyChallengeRepository {
  CountingDailyRepository(this.delegate);

  final DailyChallengeRepository delegate;
  int completionCalls = 0;

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) {
    completionCalls++;
    return delegate.completeInTransaction(transaction, challenge);
  }

  @override
  Future<DailyChallengeStatus> getStatus(String dateString) => delegate.getStatus(dateString);

  @override
  void invalidateStatus(String dateString) => delegate.invalidateStatus(dateString);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late ControlledStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = ControlledStorage(await createTestLocalStorage(prefs));
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await storage.close();
  });

  Future<void> waitFor(bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue, reason: 'completion did not finish');
  }

  Future<void> pumpUntil(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 200 && !condition(); i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue, reason: 'completion did not finish while pumping frames');
    await tester.pump();
  }

  Future<void> expectNoDailyClaims() async {
    final document = await storage.readDocument(StorageKeys.dailyChallengeFile);
    final claims = document?['claims'];
    if (claims != null) {
      expect(claims, isA<Map>());
      expect(claims, isEmpty);
    }
    expect(document?['lastCompletedDate'], isNull);
  }

  void solveFirstLevel(PerspectiveNotifier notifier, {int extraMoves = 0}) {
    for (var i = 0; i < extraMoves; i++) {
      notifier.rotateShape(0, 0);
    }
    notifier.rotateShape(-0.5, -1.2);
  }

  (DateTime, DailyChallenge) perspectiveDaily() {
    var date = DateTime.utc(2026, 1, 1, 12);
    for (var i = 0; i < 10000; i++) {
      final challenge = DailyChallengeService.generateChallengeForDate(date);
      if (challenge.gameId == 'perspective' && challenge.levelNumber == 1) {
        return (date, challenge);
      }
      date = date.add(const Duration(days: 1));
    }
    throw StateError('No Perspective level 1 daily challenge found');
  }

  ProviderContainer dailyContainer(DailyChallenge challenge, DateTime now) {
    final provider = perspectiveNotifierProvider(1);
    final result = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(container.read(sharedPreferencesProvider)),
      localStorageServiceProvider.overrideWithValue(storage),
      dailyChallengeRepositoryProvider.overrideWith((ref) => CountingDailyRepository(
        DailyChallengeRepositoryImpl(
          storage,
          ref.read(profileRepositoryProvider),
          ref.read(coinEconomyServiceProvider),
          ref.read(achievementRepositoryProvider),
          ref.read(achievementRewardServiceProvider),
          clock: () => now,
        ),
      )),
      provider.overrideWith((ref) => PerspectiveNotifier(ref, 1, challenge: challenge)),
    ]);
    addTearDown(result.dispose);
    return result;
  }

  test('daily win refreshes status and replay awards daily rewards only once', () async {
    final (date, challenge) = perspectiveDaily();
    final daily = dailyContainer(challenge, date);
    final provider = perspectiveNotifierProvider(1);
    final statusProvider = dailyChallengeStatusProvider(challenge.dateString);
    final subscription = daily.listen(statusProvider, (_, _) {}, fireImmediately: true);
    addTearDown(subscription.close);
    expect((await daily.read(statusProvider.future)).isCompleted, isFalse);
    final notifier = daily.read(provider.notifier);
    solveFirstLevel(notifier);
    await waitFor(() => daily.read(provider).isSolved);

    final status = await daily.read(statusProvider.future);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 1);
    expect(status.isCompleted, isTrue);
    expect(status.currentStreak, 1);
    var profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(daily.read(provider).earnedXp, 650);
    expect(daily.read(provider).earnedCoins, 300);
    final achievements = await daily.read(achievementRepositoryProvider).getAchievements();
    expect(achievements['daily_explorer']!.isRewardClaimed, isTrue);

    notifier.reset();
    solveFirstLevel(notifier);
    await waitFor(() => daily.read(provider).isSolved);
    profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 660);
    expect(profile.coinBalance, 400);
    expect(daily.read(provider).earnedXp, 10);
    expect(daily.read(provider).earnedCoins, 0);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 2);
    final ledger = await daily.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnDailyChallenge), hasLength(1));
    expect(ledger.where((entry) => entry.referenceId == '${challenge.dateString}:perspective:1'), hasLength(1));
  });

  test('daily claim rolls back with level win and succeeds once on retry', () async {
    final (date, challenge) = perspectiveDaily();
    final daily = dailyContainer(challenge, date);
    final provider = perspectiveNotifierProvider(1);
    final notifier = daily.read(provider.notifier);
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(challenge.dateString)).isCompleted, isFalse);
    final observedDaily = await storage.readDocument(StorageKeys.dailyChallengeFile);
    expect(observedDaily?['lastObservedUtc'], date.toIso8601String());
    storage.failBeforeCommit = true;
    solveFirstLevel(notifier);
    await waitFor(() => daily.read(provider).completionError != null);
    for (final key in [
      StorageKeys.levelProgressFile,
      StorageKeys.playerProfileFile,
      StorageKeys.coinLedgerFile,
      StorageKeys.achievementsFile,
    ]) {
      expect(await storage.readDocument(key), isNull, reason: key);
    }
    expect(await storage.readDocument(StorageKeys.dailyChallengeFile), observedDaily);
    await expectNoDailyClaims();
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(challenge.dateString)).isCompleted, isFalse);
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitFor(() => daily.read(provider).isSolved);
    expect(daily.read(provider).earnedXp, 650);
    expect(daily.read(provider).earnedCoins, 300);
    final profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 2);
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(challenge.dateString)).isCompleted, isTrue);
  });

  test('lost daily win response retains reward and does not duplicate its claim', () async {
    final (date, challenge) = perspectiveDaily();
    final daily = dailyContainer(challenge, date);
    final provider = perspectiveNotifierProvider(1);
    final notifier = daily.read(provider.notifier);
    storage.failAfterCommit = true;
    solveFirstLevel(notifier);
    await waitFor(() => daily.read(provider).completionError != null);
    notifier.retryCompletion();
    await waitFor(() => daily.read(provider).isSolved);
    final profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(daily.read(provider).earnedXp, 650);
    expect(daily.read(provider).earnedCoins, 300);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 1);
    final result = await daily.read(levelProgressRepositoryProvider).getLevelResult('perspective', 1);
    expect(result!.playCount, 1);
    final ledger = await daily.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnDailyChallenge), hasLength(1));
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(challenge.dateString)).isCompleted, isTrue);
  });

  test('invalid daily game, level or date do not award a claim', () async {
    final (date, challenge) = perspectiveDaily();
    final invalidContexts = [
      challenge.copyWith(gameId: 'cube_logic'),
      challenge.copyWith(levelNumber: 2),
      DailyChallengeService.generateChallengeForDate(date.add(const Duration(days: 1)))
          .copyWith(gameId: 'perspective', levelNumber: 1),
      challenge.copyWith(dateString: 'invalid'),
    ];
    for (var i = 0; i < invalidContexts.length; i++) {
      final daily = dailyContainer(invalidContexts[i], date);
      final provider = perspectiveNotifierProvider(1);
      solveFirstLevel(daily.read(provider.notifier));
      await waitFor(() => daily.read(provider).isSolved);
      expect(daily.read(provider).earnedCoins, i == 0 ? 100 : 0);
      expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, i < 2 ? 0 : 1);
    }
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 380);
    expect(profile.coinBalance, 200);
    expect(profile.currentStreak, 0);
    expect(profile.lastDailyChallengeDate, isNull);
    expect((await dailyContainer(challenge, date).read(dailyChallengeRepositoryProvider)
        .getStatus(challenge.dateString)).isCompleted, isFalse);
    await expectNoDailyClaims();
    final achievements = await container.read(achievementRepositoryProvider).getAchievements();
    expect(achievements['daily_explorer']!.isRewardClaimed, isFalse);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnDailyChallenge), isEmpty);
  });

  test('forged matching context is rejected when it is not the generated daily', () async {
    var date = DateTime.utc(2026, 1, 1, 12);
    var generated = DailyChallengeService.generateChallengeForDate(date);
    while (generated.gameId == 'perspective' && generated.levelNumber == 1) {
      date = date.add(const Duration(days: 1));
      generated = DailyChallengeService.generateChallengeForDate(date);
    }
    final forged = generated.copyWith(gameId: 'perspective', levelNumber: 1);
    final daily = dailyContainer(forged, date);
    final provider = perspectiveNotifierProvider(1);
    solveFirstLevel(daily.read(provider.notifier));
    await waitFor(() => daily.read(provider).isSolved);
    expect(daily.read(provider).earnedXp, 350);
    expect(daily.read(provider).earnedCoins, 100);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 1);
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(forged.dateString)).isCompleted, isFalse);
    await expectNoDailyClaims();
    final profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.currentStreak, 0);
    expect(profile.lastDailyChallengeDate, isNull);
    final ledger = await daily.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnDailyChallenge), isEmpty);
  });

  test('daily context does not apply after loading a different level', () async {
    final (date, challenge) = perspectiveDaily();
    final daily = dailyContainer(challenge, date);
    final provider = perspectiveNotifierProvider(1);
    final notifier = daily.read(provider.notifier);
    notifier.loadLevel(2);
    notifier.rotateShape(-1.5, -2.1);
    notifier.selectShape('s2');
    notifier.rotateShape(-0.8, -1.7);
    await waitFor(() => daily.read(provider).isSolved);
    expect((daily.read(dailyChallengeRepositoryProvider) as CountingDailyRepository).completionCalls, 0);
    expect((await daily.read(dailyChallengeRepositoryProvider).getStatus(challenge.dateString)).isCompleted, isFalse);
    await expectNoDailyClaims();
    final profile = await daily.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 350);
    expect(profile.currentStreak, 0);
    expect(profile.lastDailyChallengeDate, isNull);
    final ledger = await daily.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnDailyChallenge), isEmpty);
  });

  test('completion and replays preserve best result and award incremental rewards once', () async {
    final provider = perspectiveNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    final levels = container.read(levelProgressRepositoryProvider);
    final profiles = container.read(profileRepositoryProvider);
    final achievements = container.read(achievementRepositoryProvider);
    expect((await profiles.getProfile()).totalXp, 0);
    expect((await achievements.getAchievements())['first_victory']!.isRewardClaimed, isFalse);
    expect(await levels.getLevelResult('perspective', 1), isNull);

    solveFirstLevel(notifier, extraMoves: 5);
    await waitFor(() => container.read(provider).isSolved);
    var result = (await levels.getLevelResult('perspective', 1))!;
    final firstCompletedAt = result.firstCompletedAt;
    expect(result.starsEarned, 2);
    expect(result.bestMoveCount, 6);
    expect(result.hintsUsedCount, 0);
    expect(await levels.isLevelUnlocked('perspective', 2), isTrue);
    var profile = await profiles.getProfile();
    expect(profile.totalXp, 200);
    expect(profile.coinBalance, 125);
    expect(profile.totalStars, 2);
    expect(profile.levelsCompletedCount, 1);

    notifier.reset();
    solveFirstLevel(notifier);
    await waitFor(() => container.read(provider).isSolved);
    result = (await levels.getLevelResult('perspective', 1))!;
    expect(result.starsEarned, 3);
    expect(result.bestMoveCount, 1);
    expect(result.firstCompletedAt, firstCompletedAt);
    expect(result.playCount, 2);
    profile = await profiles.getProfile();
    expect(profile.totalXp, 360);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);

    notifier.reset();
    solveFirstLevel(notifier, extraMoves: 5);
    await waitFor(() => container.read(provider).isSolved);
    result = (await levels.getLevelResult('perspective', 1))!;
    profile = await profiles.getProfile();
    expect(result.starsEarned, 3);
    expect(result.bestMoveCount, 1);
    expect(result.firstCompletedAt, firstCompletedAt);
    expect(result.playCount, 3);
    expect(profile.totalXp, 370);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'perspective:1'), hasLength(1));
    final unlocked = await achievements.getAchievements();
    expect(unlocked['first_victory']!.isRewardClaimed, isTrue);
    expect(unlocked['perfect_solver']!.isRewardClaimed, isTrue);
    expect(unlocked['no_hint_champion']!.currentProgress, 1);
  });

  test('duplicate input and level transitions are blocked while saving', () async {
    final provider = perspectiveNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    final reached = Completer<void>();
    final release = Completer<void>();
    storage.transactionReached = reached;
    storage.releaseTransaction = release;

    solveFirstLevel(notifier);
    expect(container.read(provider).isSavingCompletion, isTrue);
    notifier.rotateShape(0, 0);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.togglePause();
    expect(container.read(provider).moveCount, 1);
    expect(container.read(provider).levelNumber, 1);
    expect(container.read(provider).isPaused, isFalse);
    await reached.future.timeout(const Duration(seconds: 5));
    release.complete();
    await waitFor(() => container.read(provider).isSolved);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('perspective', 1);
    expect(result!.playCount, 1);
  });

  test('failed transaction rolls back every reward and retry saves the same attempt', () async {
    final provider = perspectiveNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    storage.failBeforeCommit = true;
    solveFirstLevel(notifier);
    await waitFor(() => container.read(provider).completionError != null);
    expect(container.read(provider).board.isSolved, isTrue);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.rotateShape(1, 1);
    expect(container.read(provider).levelNumber, 1);
    expect(container.read(provider).moveCount, 1);
    expect(await storage.readDocument(StorageKeys.levelProgressFile), isNull);
    expect(await storage.readDocument(StorageKeys.playerProfileFile), isNull);
    expect(await storage.readDocument(StorageKeys.coinLedgerFile), isNull);
    expect(await storage.readDocument(StorageKeys.achievementsFile), isNull);

    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitFor(() => container.read(provider).isSolved);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('perspective', 1);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(result!.playCount, 1);
    expect(profile.totalXp, 350);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
  });

  test('retry after a lost commit response does not award twice', () async {
    final provider = perspectiveNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    storage.failAfterCommit = true;
    solveFirstLevel(notifier);
    await waitFor(() => container.read(provider).completionError != null);
    notifier.retryCompletion();
    await waitFor(() => container.read(provider).isSolved);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('perspective', 1);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(result!.playCount, 1);
    expect(profile.totalXp, 350);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    expect(container.read(provider).earnedXp, 350);
    expect(container.read(provider).earnedCoins, 100);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'perspective:1'), hasLength(1));
  });

  testWidgets('save error is visible and retry reaches victory', (tester) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: PerspectiveScreen(levelNumber: 1)),
    ));
    storage.failBeforeCommit = true;
    final provider = perspectiveNotifierProvider(1);
    solveFirstLevel(container.read(provider.notifier));
    await pumpUntil(tester, () => container.read(provider).completionError != null);
    expect(find.text('Could not save your result. Please try again.'), findsOneWidget);
    expect(find.text('Retry Save'), findsOneWidget);
    expect(find.text('PERSPECTIVE ALIGNED!'), findsNothing);

    await tester.tap(find.text('Retry Save'));
    expect(container.read(provider).completionError, isNull);
    await pumpUntil(tester, () => container.read(provider).isSolved || container.read(provider).completionError != null);
    expect(container.read(provider).isSolved, isTrue, reason: container.read(provider).completionError);
    expect(container.read(provider).earnedXp, 350);
    expect(container.read(provider).earnedCoins, 100);
    expect(find.text('PERSPECTIVE ALIGNED!'), findsOneWidget);
    expect(find.text('Retry Save'), findsNothing);
  });

  testWidgets('final-level exit and back button return to level selection', (tester) async {
    final router = GoRouter(
      initialLocation: RoutePaths.perspectiveLevel(10),
      routes: [
        GoRoute(
          path: RoutePaths.perspective,
          builder: (context, state) => PerspectiveScreen(
            levelNumber: int.parse(state.pathParameters['levelId']!),
          ),
        ),
        GoRoute(
          path: RoutePaths.levelSelect,
          builder: (context, state) => Scaffold(
            body: Text('Levels: ${state.pathParameters['gameId']}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();

    final provider = perspectiveNotifierProvider(10);
    final notifier = container.read(provider.notifier);
    notifier.rotateShape(-1.5, -2.1);
    notifier.selectShape('s2');
    notifier.rotateShape(-0.8, -1.7);
    await pumpUntil(tester, () => container.read(provider).isSolved || container.read(provider).completionError != null);
    expect(container.read(provider).isSolved, isTrue, reason: container.read(provider).completionError);
    expect(find.text('PERSPECTIVE ALIGNED!'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Levels: perspective'), findsOneWidget);

    router.go(RoutePaths.perspectiveLevel(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Levels: perspective'), findsOneWidget);
  });

  test('multi-shape final level completes without unlocking level 11', () async {
    final provider = perspectiveNotifierProvider(10);
    final notifier = container.read(provider.notifier);
    notifier.rotateShape(-1.5, -2.1);
    expect(container.read(provider).board.isSolved, isFalse);
    notifier.selectShape('s2');
    notifier.rotateShape(-0.8, -1.7);
    await waitFor(() => container.read(provider).isSolved);
    final levels = container.read(levelProgressRepositoryProvider);
    expect((await levels.getLevelResult('perspective', 10))!.isCompleted, isTrue);
    expect(await levels.getLevelResult('perspective', 11), isNull);
  });
}
