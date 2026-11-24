import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/features/gear_theory/domain/gear.dart';
import 'package:mindverse/features/gear_theory/domain/gear_board.dart';
import 'package:mindverse/features/gear_theory/domain/gear_level_factory.dart';
import 'package:mindverse/features/gear_theory/presentation/gear_theory_screen.dart';
import 'package:mindverse/features/gear_theory/presentation/providers/gear_theory_notifier.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class TestGearTheoryNotifier extends GearTheoryNotifier {
  TestGearTheoryNotifier(super.ref, super.initialLevelNumber, {super.challenge});

  void prepareConnectedBoard({int moves = 0}) {
    state = state.copyWith(
      moveCount: moves,
      board: const GearBoard(
        width: 10,
        height: 10,
        gears: {
          'driver': Gear(id: 'driver', x: 2, y: 5, teeth: 16, isDriver: true),
          'target': Gear(id: 'target', x: 6, y: 5, teeth: 16, isTarget: true),
        },
        inventory: [],
      ),
    );
  }
}

class FailingAchievementRewardService extends AchievementRewardService {
  bool fail = true;

  FailingAchievementRewardService(super.achievements, super.profiles, super.coins);

  @override
  Future<AchievementRewardResult> grantInTransaction(
    LocalStorageTransaction transaction,
    List<Achievement> achievements,
  ) async {
    final reward = await super.grantInTransaction(transaction, achievements);
    if (fail) throw StateError('injected failure after rewards');
    return reward;
  }
}

class TestDailyChallengeRepository implements DailyChallengeRepository {
  final DailyChallengeRepository delegate;
  bool failAfterCompletion = false;
  int completionCalls = 0;

  TestDailyChallengeRepository(this.delegate);

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) async {
    completionCalls++;
    final result = await delegate.completeInTransaction(transaction, challenge);
    if (failAfterCompletion) throw StateError('injected failure after daily completion');
    return result;
  }

  @override
  Future<DailyChallengeStatus> getStatus(String dateString) => delegate.getStatus(dateString);

  @override
  void invalidateStatus(String dateString) => delegate.invalidateStatus(dateString);
}

class FailAfterCommitStorage implements LocalStorageService {
  final LocalStorageService delegate;
  bool failNextCommit = false;

  FailAfterCommitStorage(this.delegate);

  @override
  Future<T> runInTransaction<T>(Future<T> Function(LocalStorageTransaction) action) async {
    final result = await delegate.runInTransaction(action);
    if (failNextCommit) {
      failNextCommit = false;
      throw StateError('injected lost commit acknowledgement');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late LocalStorageService storage;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = await createTestLocalStorage(prefs);
  });

  tearDown(() async {
    container.dispose();
    await storage.close();
  });

  ProviderContainer makeContainer(
    int level, {
    LocalStorageService? storageOverride,
    bool failRewards = false,
    DailyChallenge? challenge,
    DateTime? dailyClock,
  }) {
    final provider = gearTheoryNotifierProvider(level);
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageServiceProvider.overrideWithValue(storageOverride ?? storage),
        provider.overrideWith((ref) => TestGearTheoryNotifier(ref, level, challenge: challenge)),
        if (dailyClock != null)
          dailyChallengeRepositoryProvider.overrideWith(
            (ref) => TestDailyChallengeRepository(
              DailyChallengeRepositoryImpl(
                ref.read(localStorageServiceProvider),
                ref.read(profileRepositoryProvider),
                ref.read(coinEconomyServiceProvider),
                ref.read(achievementRepositoryProvider),
                ref.read(achievementRewardServiceProvider),
                clock: () => dailyClock,
              ),
            ),
          ),
        if (failRewards)
          achievementRewardServiceProvider.overrideWith(
            (ref) => FailingAchievementRewardService(
              ref.read(achievementRepositoryProvider),
              ref.read(profileRepositoryProvider),
              ref.read(coinEconomyServiceProvider),
            ),
          ),
      ],
    );
  }

  Future<void> waitForCompletion(int level) async {
    final provider = gearTheoryNotifierProvider(level);
    for (var i = 0; i < 100 && container.read(provider).isSavingCompletion; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSavingCompletion, isFalse);
  }

  /// Advances the widget-test fake clock until the completion transaction settles.
  ///
  /// Completion futures started from a tap handler live in the fake-async zone,
  /// so `tester.runAsync` cannot drive them; repeated pumps can.
  Future<void> pumpUntilSaved(WidgetTester tester, int level) async {
    final provider = gearTheoryNotifierProvider(level);
    for (var i = 0; i < 200 && container.read(provider).isSavingCompletion; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSavingCompletion, isFalse);
  }

  Finder screenPopScope() => find.descendant(
        of: find.byType(GearTheoryScreen),
        matching: find.byType(PopScope),
      );

  void usePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('first clear, improved and lower replay preserve best results and award once', () async {
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard(moves: 3);
    notifier.rotateDriver(0.5);
    expect(container.read(provider).isSavingCompletion, isTrue);
    await waitForCompletion(level);
    expect(container.read(provider).earnedStars, 2);
    expect(container.read(provider).earnedXp, 200);
    expect(container.read(provider).earnedCoins, 25);
    final levels = container.read(levelProgressRepositoryProvider);
    final first = (await levels.getLevelResult('gear_theory', level))!;
    expect(await levels.isLevelUnlocked('gear_theory', 2), isTrue);

    notifier.reset();
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).earnedStars, 3);
    expect(container.read(provider).earnedXp, 160);
    expect(container.read(provider).earnedCoins, 75);

    notifier.reset();
    notifier.prepareConnectedBoard(moves: 4);
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).earnedStars, 2);
    expect(container.read(provider).earnedXp, 10);
    expect(container.read(provider).earnedCoins, 0);
    final result = (await levels.getLevelResult('gear_theory', level))!;
    expect(result.starsEarned, 3);
    expect(result.star2Efficiency, isTrue);
    expect(result.star3Mastery, isTrue);
    expect(result.bestMoveCount, 1);
    expect(result.hintsUsedCount, 0);
    expect(result.firstCompletedAt, first.firstCompletedAt);
    expect(result.playCount, 3);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 370);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    final achievements = await container.read(achievementRepositoryProvider).getAchievements();
    expect(achievements['first_victory']!.isRewardClaimed, isTrue);
    expect(achievements['perfect_solver']!.isRewardClaimed, isTrue);
    expect(achievements['no_hint_champion']!.currentProgress, 1);
    expect(achievements['puzzle_master_10']!.currentProgress, 1);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'gear_theory:1'), hasLength(1));
  });

  test('failed transaction rolls back and retry preserves attempt while guarding transitions', () async {
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level, failRewards: true);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    notifier.rotateDriver(0.5);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.togglePause();
    expect(container.read(provider).moveCount, 1);
    expect(container.read(provider).levelNumber, 1);
    expect(container.read(provider).isPaused, isFalse);
    await waitForCompletion(level);
    final failed = container.read(provider);
    expect(failed.isSolved, isFalse);
    expect(failed.board.isSolved, isTrue);
    expect(failed.completionError, isNotNull);
    expect(await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', 1), isNull);
    expect(await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', 2), isNull);
    final beforeRetry = await container.read(profileRepositoryProvider).getProfile();
    expect(beforeRetry.totalXp, 0);
    expect(beforeRetry.coinBalance, 100);
    expect((await container.read(coinEconomyServiceProvider).getTransactionHistory()), isEmpty);
    expect(
      (await container.read(achievementRepositoryProvider).getAchievements())['first_victory']!.isUnlocked,
      isFalse,
    );
    notifier.rotateDriver(0.5);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.togglePause();
    expect(container.read(provider).moveCount, 1);
    expect(container.read(provider).levelNumber, 1);
    expect(container.read(provider).isPaused, isFalse);
    (container.read(achievementRewardServiceProvider) as FailingAchievementRewardService).fail = false;
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).completionError, isNull);
    expect(
      (await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', 1))!.playCount,
      1,
    );
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 350);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
  });

  test('retry after lost commit acknowledgement does not repeat the transaction', () async {
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    final unreliableStorage = FailAfterCommitStorage(storage);
    container = makeContainer(level, storageOverride: unreliableStorage);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    unreliableStorage.failNextCommit = true;
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).completionError, isNotNull);
    notifier.retryCompletion();
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level);
    expect(result!.playCount, 1);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 350);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'gear_theory:1'), hasLength(1));
  });

  testWidgets('save error is visible and retry restores victory', (tester) async {
    usePhoneViewport(tester);
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level, failRewards: true);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GearTheoryScreen(levelNumber: level)),
      ),
    );
    notifier.prepareConnectedBoard();
    await tester.runAsync(() async {
      notifier.rotateDriver(0.5);
      await waitForCompletion(level);
    });
    await tester.pump();
    expect(find.text('Could not save your result. Please try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(tester.widget<PopScope>(screenPopScope()).canPop, isFalse);

    (container.read(achievementRewardServiceProvider) as FailingAchievementRewardService).fail = false;
    await tester.tap(find.text('Retry'));
    await pumpUntilSaved(tester, level);
    await tester.pump();
    expect(find.text('MECHANISM ENGAGED!'), findsOneWidget);
    expect(tester.widget<PopScope>(screenPopScope()).canPop, isTrue);
  });

  (DateTime, DailyChallenge) gearDailyChallenge() {
    var date = DateTime.utc(2026, 1, 1, 12);
    for (var i = 0; i < 1000; i++) {
      final challenge = DailyChallengeService.generateChallengeForDate(date);
      if (challenge.gameId == 'gear_theory' && challenge.levelNumber == 1) {
        return (date, challenge);
      }
      date = date.add(const Duration(days: 1));
    }
    throw StateError('No Gear Theory level 1 daily challenge found');
  }

  test('daily completion refreshes status and replay does not repeat daily rewards', () async {
    const level = 1;
    final (date, challenge) = gearDailyChallenge();
    final provider = gearTheoryNotifierProvider(level);
    final statusProvider = dailyChallengeStatusProvider(challenge.dateString);
    container = makeContainer(level, challenge: challenge, dailyClock: date);
    expect((await container.read(statusProvider.future)).isCompleted, isFalse);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedXp, 650);
    expect(container.read(provider).earnedCoins, 300);
    final status = await container.read(statusProvider.future);
    expect(status.isCompleted, isTrue);
    expect(status.currentStreak, 1);
    var profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(profile.lastDailyChallengeDate, challenge.dateString);
    final achievements = await container.read(achievementRepositoryProvider).getAchievements();
    expect(achievements['daily_explorer']!.isRewardClaimed, isTrue);

    notifier.reset();
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).earnedXp, 10);
    expect(container.read(provider).earnedCoins, 0);
    profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 660);
    expect(profile.coinBalance, 400);
    expect(profile.currentStreak, 1);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(
      ledger.where((entry) => entry.referenceId == '${challenge.dateString}:gear_theory:1'),
      hasLength(1),
    );
    expect(
      (await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level))!.playCount,
      2,
    );
  });

  for (final scenario in ['wrong game', 'wrong level', 'expired', 'not generated']) {
    test('daily context $scenario does not award a daily claim', () async {
      const level = 1;
      final (date, validChallenge) = gearDailyChallenge();
      var clock = date;
      var challenge = validChallenge;
      if (scenario == 'wrong game') {
        challenge = challenge.copyWith(gameId: 'cube_logic');
      } else if (scenario == 'wrong level') {
        challenge = challenge.copyWith(levelNumber: 2);
      } else if (scenario == 'expired') {
        clock = date.add(const Duration(days: 1));
      } else {
        clock = date.add(const Duration(days: 1));
        var generated = DailyChallengeService.generateChallengeForDate(clock);
        while (generated.gameId == 'gear_theory' && generated.levelNumber == level) {
          clock = clock.add(const Duration(days: 1));
          generated = DailyChallengeService.generateChallengeForDate(clock);
        }
        challenge = generated.copyWith(gameId: 'gear_theory', levelNumber: level);
      }
      container = makeContainer(level, challenge: challenge, dailyClock: clock);
      final provider = gearTheoryNotifierProvider(level);
      final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
      notifier.prepareConnectedBoard();
      notifier.rotateDriver(0.5);
      await waitForCompletion(level);
      expect(container.read(provider).isSolved, isTrue);
      expect(container.read(provider).earnedXp, 350);
      expect(container.read(provider).earnedCoins, 100);
      final daily = container.read(dailyChallengeRepositoryProvider) as TestDailyChallengeRepository;
      expect(daily.completionCalls, scenario == 'wrong game' || scenario == 'wrong level' ? 0 : 1);
      expect((await daily.getStatus(challenge.dateString)).isCompleted, isFalse);
      final profile = await container.read(profileRepositoryProvider).getProfile();
      expect(profile.lastDailyChallengeDate, isNull);
      expect(profile.totalXp, 350);
      expect(profile.coinBalance, 200);
    });
  }

  test('changing levels does not claim the original daily challenge', () async {
    final (date, challenge) = gearDailyChallenge();
    final provider = gearTheoryNotifierProvider(1);
    container = makeContainer(1, challenge: challenge, dailyClock: date);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.loadLevel(2);
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).levelNumber, 2);
    final daily = container.read(dailyChallengeRepositoryProvider) as TestDailyChallengeRepository;
    expect(daily.completionCalls, 0);
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isFalse);
    expect(await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', 2), isNotNull);
  });

  test('failure after daily writes rolls back level and daily rewards, then retry succeeds', () async {
    const level = 1;
    final (date, challenge) = gearDailyChallenge();
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level, challenge: challenge, dailyClock: date);
    final daily = container.read(dailyChallengeRepositoryProvider) as TestDailyChallengeRepository;
    daily.failAfterCompletion = true;
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).completionError, isNotNull);
    expect(container.read(provider).isSolved, isFalse);
    expect(
      await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level),
      isNull,
    );
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isFalse);
    var profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 0);
    expect(profile.coinBalance, 100);
    expect(profile.currentStreak, 0);
    expect(await container.read(coinEconomyServiceProvider).getTransactionHistory(), isEmpty);
    expect(
      (await container.read(achievementRepositoryProvider).getAchievements())['daily_explorer']!.isUnlocked,
      isFalse,
    );

    daily.failAfterCompletion = false;
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedXp, 650);
    expect(container.read(provider).earnedCoins, 300);
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isTrue);
    profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(
      (await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level))!.playCount,
      1,
    );
  });

  test('daily claim is not repeated after a lost commit acknowledgement', () async {
    const level = 1;
    final (date, challenge) = gearDailyChallenge();
    final provider = gearTheoryNotifierProvider(level);
    final unreliableStorage = FailAfterCommitStorage(storage);
    container = makeContainer(
      level,
      storageOverride: unreliableStorage,
      challenge: challenge,
      dailyClock: date,
    );
    final statusProvider = dailyChallengeStatusProvider(challenge.dateString);
    expect((await container.read(statusProvider.future)).isCompleted, isFalse);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    unreliableStorage.failNextCommit = true;
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).completionError, isNotNull);
    notifier.retryCompletion();
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    final daily = container.read(dailyChallengeRepositoryProvider) as TestDailyChallengeRepository;
    expect(daily.completionCalls, 1);
    expect((await container.read(statusProvider.future)).isCompleted, isTrue);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(
      ledger.where((entry) => entry.referenceId == '${challenge.dateString}:gear_theory:1'),
      hasLength(1),
    );
    expect(
      (await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level))!.playCount,
      1,
    );
  });

  for (var level = 1; level <= GearLevelFactory.levelCount; level++) {
    test('level $level is playable through inventory, peg and rotation actions', () async {
      final provider = gearTheoryNotifierProvider(level);
      container = makeContainer(level);
      final notifier = container.read(provider.notifier);
      final initial = container.read(provider);
      final gear = initial.board.inventory.first;
      notifier.selectGear(gear.id);
      notifier.tapPeg('bridge');
      expect(container.read(provider).board.gears.containsKey(gear.id), isTrue);
      expect(container.read(provider).moveCount, 0);
      notifier.rotateDriver(0.5);
      await waitForCompletion(level);
      expect(container.read(provider).isSolved, isTrue);
      expect(container.read(provider).moveCount, 1);
      expect(
        (await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level))!
            .isCompleted,
        isTrue,
      );
    });
  }

  test('placement and removal respect pause, invalid selections, completion and reset', () async {
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level);
    final notifier = container.read(provider.notifier);
    notifier.selectGear('missing');
    notifier.tapPeg('bridge');
    expect(container.read(provider).board.inventory, hasLength(1));
    notifier.selectGear('g_mid');
    notifier.togglePause();
    notifier.tapPeg('bridge');
    expect(container.read(provider).board.inventory, hasLength(1));
    notifier.togglePause();
    notifier.tapPeg('upper');
    expect(container.read(provider).board.inventory, isEmpty);
    notifier.tapPeg('upper');
    expect(container.read(provider).board.inventory.single.id, 'g_mid');
    notifier.selectGear('g_mid');
    notifier.tapPeg('bridge');
    notifier.rotateDriver(0.5);
    notifier.tapPeg('bridge');
    expect(container.read(provider).board.gears.containsKey('g_mid'), isTrue);
    await waitForCompletion(level);
    notifier.tapPeg('bridge');
    expect(container.read(provider).board.gears.containsKey('g_mid'), isTrue);
    notifier.reset();
    expect(container.read(provider).board.inventory.single.id, 'g_mid');
    expect(container.read(provider).selectedGearId, isNull);
  });

  testWidgets('screen can select, place, remove and rotate a gear', (tester) async {
    usePhoneViewport(tester);
    const level = 1;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: GearTheoryScreen(levelNumber: level)),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('gear-inventory-g_mid')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gear-peg-bridge')));
    await tester.pump();
    expect(container.read(provider).board.gears.containsKey('g_mid'), isTrue);
    await tester.tap(find.byKey(const ValueKey('gear-peg-bridge')));
    await tester.pump();
    expect(container.read(provider).board.inventory.single.id, 'g_mid');
    await tester.tap(find.byKey(const ValueKey('gear-inventory-g_mid')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gear-peg-bridge')));
    await tester.pump();
    await tester.tap(find.text('Rotate Right'));
    await pumpUntilSaved(tester, level);
    await tester.pump();
    expect(container.read(provider).isSolved, isTrue);
    expect(find.text('MECHANISM ENGAGED!'), findsOneWidget);
  });

  test('final level does not unlock a nonexistent level', () async {
    const level = GearLevelFactory.levelCount;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    expect(
      await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level + 1),
      isNull,
    );
  });
}
