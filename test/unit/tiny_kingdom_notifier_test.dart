import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/tiny_kingdom/domain/kingdom_tile.dart';
import 'package:mindverse/features/tiny_kingdom/domain/tiny_kingdom_level_factory.dart';
import 'package:mindverse/features/tiny_kingdom/presentation/providers/tiny_kingdom_notifier.dart';
import 'package:mindverse/features/tiny_kingdom/presentation/tiny_kingdom_screen.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class FailingAchievementRewards extends AchievementRewardService {
  bool failNext = true;
  Completer<void>? gate;

  FailingAchievementRewards(
    super.achievements,
    super.profiles,
    super.coins,
  );

  @override
  Future<AchievementRewardResult> grantInTransaction(
    LocalStorageTransaction transaction,
    List<Achievement> achievements,
  ) async {
    final result = await super.grantInTransaction(transaction, achievements);
    await gate?.future;
    if (failNext) {
      failNext = false;
      throw StateError('Injected failure after all reward writes');
    }
    return result;
  }
}

class LostCommitAcknowledgement implements LocalStorageService {
  final LocalStorageService delegate;
  bool loseNextAcknowledgement = true;

  LostCommitAcknowledgement(this.delegate);

  @override
  Future<T> runInTransaction<T>(Future<T> Function(LocalStorageTransaction) action) async {
    final result = await delegate.runInTransaction(action);
    if (loseNextAcknowledgement) {
      loseNextAcknowledgement = false;
      throw StateError('Injected lost commit acknowledgement');
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

class TrackingDailyRepository implements DailyChallengeRepository {
  final DailyChallengeRepository delegate;
  bool failAfterWrite;
  int completionCalls = 0;

  TrackingDailyRepository(this.delegate, {this.failAfterWrite = false});

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) async {
    completionCalls++;
    final result = await delegate.completeInTransaction(transaction, challenge);
    if (failAfterWrite && result != null) {
      failAfterWrite = false;
      throw StateError('Injected failure after daily writes');
    }
    return result;
  }

  @override
  Future<DailyChallengeStatus> getStatus(String dateString) => delegate.getStatus(dateString);

  @override
  void invalidateStatus(String dateString) => delegate.invalidateStatus(dateString);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late LocalStorageService storage;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = await createTestLocalStorage(prefs);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await storage.close();
  });

  Future<void> waitForCompletion(ProviderContainer current, int level) async {
    final provider = tinyKingdomNotifierProvider(level);
    for (var i = 0; i < 100 && current.read(provider).isSavingCompletion; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(current.read(provider).isSavingCompletion, isFalse);
  }

  void solveWithHouses(TinyKingdomNotifier notifier) {
    notifier.selectBuilding(BuildingType.house);
    for (var i = 0; i < 5; i++) {
      notifier.placeBuilding(i % 3, i ~/ 3);
    }
  }

  void solveWithCastle(TinyKingdomNotifier notifier) {
    notifier.selectBuilding(BuildingType.castle);
    notifier.placeBuilding(0, 0);
  }

  DateTime findDailyDate({required bool matchesLevelOne}) {
    var date = DateTime.utc(2026, 1, 1, 12);
    for (var i = 0; i < 3650; i++) {
      final challenge = DailyChallengeService.generateChallengeForDate(date);
      final matches = challenge.gameId == 'tiny_kingdom' && challenge.levelNumber == 1;
      if (matches == matchesLevelOne) return date;
      date = date.add(const Duration(days: 1));
    }
    throw StateError('Could not find a daily challenge fixture');
  }

  ProviderContainer dailyContainer(
    DailyChallenge challenge,
    DateTime now, {
    bool failAfterWrite = false,
    LocalStorageService? storageOverride,
  }) {
    final provider = tinyKingdomNotifierProvider(1);
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storageOverride ?? storage),
      dailyChallengeRepositoryProvider.overrideWith((ref) => TrackingDailyRepository(
        DailyChallengeRepositoryImpl(
          ref.read(localStorageServiceProvider),
          ref.read(profileRepositoryProvider),
          ref.read(coinEconomyServiceProvider),
          ref.read(achievementRepositoryProvider),
          ref.read(achievementRewardServiceProvider),
          clock: () => now,
        ),
        failAfterWrite: failAfterWrite,
      )),
      provider.overrideWith((ref) => TinyKingdomNotifier(ref, 1, challenge: challenge)),
    ]);
  }

  test('completion merges best results and rewards improvements only once', () async {
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    solveWithHouses(notifier);
    expect(container.read(provider).isSavingCompletion, isTrue);
    expect(container.read(provider).board.isSolved, isTrue);
    notifier.placeBuilding(2, 2);
    notifier.selectBuilding(BuildingType.castle);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.togglePause();
    notifier.retryCompletion();
    expect(container.read(provider).turnCount, 5);
    expect(container.read(provider).levelNumber, 1);
    expect(container.read(provider).selectedBuilding, BuildingType.house);
    expect(container.read(provider).isPaused, isFalse);
    await waitForCompletion(container, 1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedStars, 2);
    var profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 200);
    expect(profile.totalStars, 2);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 125);
    final levels = container.read(levelProgressRepositoryProvider);
    final first = (await levels.getLevelResult('tiny_kingdom', 1))!;
    expect(first.firstCompletedAt, isNotNull);
    expect(first.bestMoveCount, 5);
    expect(first.hintsUsedCount, 0);
    expect(await levels.isLevelUnlocked('tiny_kingdom', 2), isTrue);

    notifier.reset();
    solveWithCastle(notifier);
    await waitForCompletion(container, 1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedStars, 3);
    expect(container.read(provider).earnedXp, 160);
    expect(container.read(provider).earnedCoins, 75);
    profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 360);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);

    notifier.reset();
    solveWithHouses(notifier);
    await waitForCompletion(container, 1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedXp, 10);
    expect(container.read(provider).earnedCoins, 0);
    final best = (await levels.getLevelResult('tiny_kingdom', 1))!;
    expect(best.playCount, 3);
    expect(best.starsEarned, 3);
    expect(best.star2Efficiency, isTrue);
    expect(best.star3Mastery, isTrue);
    expect(best.bestMoveCount, 1);
    expect(best.firstCompletedAt, first.firstCompletedAt);
    expect(best.lastPlayedAt!.isBefore(first.lastPlayedAt!), isFalse);
    profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 370);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'tiny_kingdom:1'), hasLength(1));
    final achievements = await container.read(achievementRepositoryProvider).getAchievements();
    expect(achievements['first_victory']!.isRewardClaimed, isTrue);
    expect(achievements['perfect_solver']!.isRewardClaimed, isTrue);
    expect(achievements['no_hint_champion']!.currentProgress, 1);
  });

  test('failed transaction rolls back every reward and retry saves the same attempt', () async {
    final failing = FailingAchievementRewards(
      container.read(achievementRepositoryProvider),
      container.read(profileRepositoryProvider),
      container.read(coinEconomyServiceProvider),
    );
    final failingContainer = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
      achievementRewardServiceProvider.overrideWithValue(failing),
    ]);
    addTearDown(failingContainer.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = failingContainer.read(provider.notifier);
    solveWithCastle(notifier);
    await waitForCompletion(failingContainer, 1);
    expect(failingContainer.read(provider).completionError, isNotNull);
    expect(failingContainer.read(provider).board.isSolved, isTrue);
    expect(failingContainer.read(provider).isSolved, isFalse);
    expect(await failingContainer.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1), isNull);
    expect(await failingContainer.read(levelProgressRepositoryProvider).isLevelUnlocked('tiny_kingdom', 2), isFalse);
    final profile = await failingContainer.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 0);
    expect(profile.coinBalance, 100);
    expect(profile.totalStars, 0);
    expect(profile.levelsCompletedCount, 0);
    expect(await failingContainer.read(coinEconomyServiceProvider).getTransactionHistory(), isEmpty);
    expect((await failingContainer.read(achievementRepositoryProvider).getAchievements())['first_victory']!.isUnlocked, isFalse);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.placeBuilding(1, 0);
    notifier.togglePause();
    expect(failingContainer.read(provider).turnCount, 1);
    expect(failingContainer.read(provider).levelNumber, 1);
    expect(failingContainer.read(provider).isPaused, isFalse);
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(failingContainer, 1);
    expect(failingContainer.read(provider).isSolved, isTrue);
    expect(failingContainer.read(provider).completionError, isNull);
    final result = (await failingContainer.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1))!;
    expect(result.playCount, 1);
    final savedProfile = await failingContainer.read(profileRepositoryProvider).getProfile();
    expect(savedProfile.totalXp, 350);
    expect(savedProfile.coinBalance, 200);
    expect(savedProfile.totalStars, 3);
    expect(savedProfile.levelsCompletedCount, 1);
  });

  test('retry after a committed transaction does not duplicate its rewards', () async {
    final unreliableStorage = LostCommitAcknowledgement(storage);
    final unreliableContainer = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(unreliableStorage),
    ]);
    addTearDown(unreliableContainer.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = unreliableContainer.read(provider.notifier);
    solveWithCastle(notifier);
    await waitForCompletion(unreliableContainer, 1);
    expect(unreliableContainer.read(provider).completionError, isNotNull);
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(unreliableContainer, 1);
    expect(unreliableContainer.read(provider).isSolved, isTrue);
    expect(unreliableContainer.read(provider).earnedXp, 350);
    expect(unreliableContainer.read(provider).earnedCoins, 100);
    final result = (await unreliableContainer.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1))!;
    expect(result.playCount, 1);
    final profile = await unreliableContainer.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 350);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);
    final ledger = await unreliableContainer.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'tiny_kingdom:1'), hasLength(1));
  });

  test('daily win refreshes status and replay cannot claim daily rewards twice', () async {
    final now = findDailyDate(matchesLevelOne: true);
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    final current = dailyContainer(challenge, now);
    addTearDown(current.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final statusProvider = dailyChallengeStatusProvider(challenge.dateString);
    final subscription = current.listen(statusProvider, (_, _) {}, fireImmediately: true);
    addTearDown(subscription.close);
    expect((await current.read(statusProvider.future)).isCompleted, isFalse);

    final notifier = current.read(provider.notifier);
    solveWithCastle(notifier);
    await waitForCompletion(current, 1);
    expect(current.read(provider).isSolved, isTrue);
    expect(current.read(provider).earnedXp, 650);
    expect(current.read(provider).earnedCoins, 300);
    expect((await current.read(statusProvider.future)).isCompleted, isTrue);
    var profile = await current.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(profile.currentStreak, 1);
    expect(profile.lastDailyChallengeDate, challenge.dateString);
    expect((await current.read(achievementRepositoryProvider).getAchievements())['daily_explorer']!.isRewardClaimed, isTrue);

    notifier.reset();
    solveWithCastle(notifier);
    await waitForCompletion(current, 1);
    expect(current.read(provider).earnedXp, 10);
    expect(current.read(provider).earnedCoins, 0);
    profile = await current.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 660);
    expect(profile.coinBalance, 400);
    expect(profile.currentStreak, 1);
    final ledger = await current.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == '${challenge.dateString}:tiny_kingdom:1'), hasLength(1));
    expect((await current.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1))!.playCount, 2);
  });

  test('daily write failure rolls back the level and all rewards, then retry succeeds', () async {
    final now = findDailyDate(matchesLevelOne: true);
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    final current = dailyContainer(challenge, now, failAfterWrite: true);
    addTearDown(current.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = current.read(provider.notifier);
    solveWithCastle(notifier);
    await waitForCompletion(current, 1);
    expect(current.read(provider).completionError, isNotNull);
    for (final key in [
      StorageKeys.levelProgressFile,
      StorageKeys.playerProfileFile,
      StorageKeys.coinLedgerFile,
      StorageKeys.achievementsFile,
      StorageKeys.dailyChallengeFile,
    ]) {
      expect(await storage.readDocument(key), isNull, reason: key);
    }
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(current, 1);
    expect(current.read(provider).isSolved, isTrue);
    expect(current.read(provider).earnedXp, 650);
    expect(current.read(provider).earnedCoins, 300);
    expect((await current.read(dailyChallengeStatusProvider(challenge.dateString).future)).isCompleted, isTrue);
    expect((await current.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1))!.playCount, 1);
  });

  test('lost acknowledgement retry preserves the combined daily reward', () async {
    final now = findDailyDate(matchesLevelOne: true);
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    final current = dailyContainer(challenge, now, storageOverride: LostCommitAcknowledgement(storage));
    addTearDown(current.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = current.read(provider.notifier);
    solveWithCastle(notifier);
    await waitForCompletion(current, 1);
    expect(current.read(provider).completionError, isNotNull);
    notifier.retryCompletion();
    await waitForCompletion(current, 1);
    expect(current.read(provider).isSolved, isTrue);
    expect(current.read(provider).earnedXp, 650);
    expect(current.read(provider).earnedCoins, 300);
    final profile = await current.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect((await current.read(levelProgressRepositoryProvider).getLevelResult('tiny_kingdom', 1))!.playCount, 1);
  });

  for (final scenario in ['wrong game', 'wrong level', 'stale date', 'forged challenge']) {
    test('$scenario does not grant daily rewards', () async {
      final validDate = findDailyDate(matchesLevelOne: true);
      final valid = DailyChallengeService.generateChallengeForDate(validDate);
      final otherDate = findDailyDate(matchesLevelOne: false);
      final challenge = switch (scenario) {
        'wrong game' => valid.copyWith(gameId: 'cube_logic'),
        'wrong level' => valid.copyWith(levelNumber: 2),
        'forged challenge' => valid.copyWith(dateString: DailyChallengeService.generateChallengeForDate(otherDate).dateString),
        _ => valid,
      };
      final now = switch (scenario) {
        'stale date' => validDate.add(const Duration(days: 1)),
        'forged challenge' => otherDate,
        _ => validDate,
      };
      final current = dailyContainer(challenge, now);
      addTearDown(current.dispose);
      final provider = tinyKingdomNotifierProvider(1);
      solveWithCastle(current.read(provider.notifier));
      await waitForCompletion(current, 1);
      expect(current.read(provider).isSolved, isTrue);
      expect(current.read(provider).earnedXp, 350);
      expect(current.read(provider).earnedCoins, 100);
      final daily = current.read(dailyChallengeRepositoryProvider) as TrackingDailyRepository;
      expect(daily.completionCalls, scenario == 'wrong game' || scenario == 'wrong level' ? 0 : 1);
      final dailyDocument = await storage.readDocument(StorageKeys.dailyChallengeFile) ?? const {};
      expect(dailyDocument['claims'], isNull);
      final profile = await current.read(profileRepositoryProvider).getProfile();
      expect(profile.currentStreak, 0);
      expect(profile.lastDailyChallengeDate, isNull);
    });
  }

  test('changing levels cannot claim a challenge for the original level', () async {
    final now = findDailyDate(matchesLevelOne: true);
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    final current = dailyContainer(challenge, now);
    addTearDown(current.dispose);
    final provider = tinyKingdomNotifierProvider(1);
    final notifier = current.read(provider.notifier);
    notifier.loadLevel(2);
    solveWithCastle(notifier);
    await waitForCompletion(current, 1);
    expect(current.read(provider).levelNumber, 2);
    expect(current.read(provider).isSolved, isTrue);
    expect((current.read(dailyChallengeRepositoryProvider) as TrackingDailyRepository).completionCalls, 0);
    final dailyDocument = await storage.readDocument(StorageKeys.dailyChallengeFile) ?? const {};
    expect(dailyDocument['claims'], isNull);
  });

  test('last level completion does not unlock a nonexistent level', () async {
    const level = TinyKingdomLevelFactory.levelCount;
    final provider = tinyKingdomNotifierProvider(level);
    final notifier = container.read(provider.notifier);
    notifier.selectBuilding(BuildingType.castle);
    for (var i = 0; i < 15; i++) {
      notifier.placeBuilding(i % 6, i ~/ 6);
    }
    await waitForCompletion(container, level);
    expect(container.read(provider).isSolved, isTrue);
    final levels = container.read(levelProgressRepositoryProvider);
    expect((await levels.getLevelResult('tiny_kingdom', level))!.isCompleted, isTrue);
    expect(await levels.getLevelResult('tiny_kingdom', level + 1), isNull);
  });

  testWidgets('save error is visible and blocks navigation until retry succeeds', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final failing = FailingAchievementRewards(
      container.read(achievementRepositoryProvider),
      container.read(profileRepositoryProvider),
      container.read(coinEconomyServiceProvider),
    )..gate = Completer<void>();
    final failingContainer = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
      achievementRewardServiceProvider.overrideWithValue(failing),
    ]);
    addTearDown(failingContainer.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: failingContainer,
      child: const MaterialApp(home: TinyKingdomScreen(levelNumber: 1)),
    ));
    final notifier = failingContainer.read(tinyKingdomNotifierProvider(1).notifier);
    solveWithCastle(notifier);
    await tester.pump();
    expect(find.text('Saving your result...'), findsOneWidget);
    failing.gate!.complete();
    await tester.pump();
    for (var i = 0;
        i < 200 && failingContainer.read(tinyKingdomNotifierProvider(1)).isSavingCompletion;
        i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(failingContainer.read(tinyKingdomNotifierProvider(1)).isSavingCompletion, isFalse);
    await tester.pump();
    expect(find.text('Could not save your result. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    final popScope = tester.widget<PopScope>(find.descendant(
      of: find.byType(TinyKingdomScreen),
      matching: find.byType(PopScope),
    ));
    expect(popScope.canPop, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(TinyKingdomScreen), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    for (var i = 0;
        i < 200 && failingContainer.read(tinyKingdomNotifierProvider(1)).isSavingCompletion;
        i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(failingContainer.read(tinyKingdomNotifierProvider(1)).isSavingCompletion, isFalse);
    await tester.pump();
    expect(find.text('KINGDOM PROSPEROUS!'), findsOneWidget);
    expect(tester.widget<PopScope>(find.descendant(
      of: find.byType(TinyKingdomScreen),
      matching: find.byType(PopScope),
    )).canPop, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}