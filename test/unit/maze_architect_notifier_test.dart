import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/maze_architect/domain/maze_level_factory.dart';
import 'package:mindverse/features/maze_architect/domain/maze_pathfinding_solver.dart';
import 'package:mindverse/features/maze_architect/presentation/providers/maze_architect_notifier.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class FailingAchievementRewards extends AchievementRewardService {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool fail = true;

  FailingAchievementRewards(super.achievements, super.profiles, super.coins);

  @override
  Future<AchievementRewardResult> grantInTransaction(
    LocalStorageTransaction transaction,
    List<Achievement> achievements,
  ) async {
    final result = await super.grantInTransaction(transaction, achievements);
    if (fail) {
      entered.complete();
      await release.future;
      fail = false;
      throw StateError('injected failure after all reward writes');
    }
    return result;
  }
}

class ControlledDailyRepository extends DailyChallengeRepositoryImpl {
  ControlledDailyRepository(
    super.storage,
    super.profileRepository,
    super.coinEconomyService,
    super.achievementRepository,
    super.achievementRewardService, {
    super.clock,
  });

  bool fail = false;
  int calls = 0;
  DailyChallengeCompletionResult? lastResult;

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) async {
    calls++;
    final result = await super.completeInTransaction(transaction, challenge);
    lastResult = result;
    if (fail) throw StateError('injected failure after daily writes');
    return result;
  }
}

DateTime mazeLevelOneDate() {
  var date = DateTime.utc(2026, 1, 1, 12);
  for (var i = 0; i < 5000; i++) {
    final challenge = DailyChallengeService.generateChallengeForDate(date);
    if (challenge.gameId == 'maze_architect' && challenge.levelNumber == 1) {
      return date;
    }
    date = date.add(const Duration(days: 1));
  }
  throw StateError('No daily challenge found for Maze level 1');
}

void swap(MazeArchitectNotifier notifier, (int, int) a, (int, int) b) {
  notifier.tapTile(a.$1, a.$2);
  notifier.tapTile(b.$1, b.$2);
}

void solveLevel(MazeArchitectNotifier notifier, MazeLevel level) {
  for (final move in level.solution) {
    swap(notifier, (move.fromX, move.fromY), (move.toX, move.toY));
  }
}

void solveLevelOne(MazeArchitectNotifier notifier, {bool slow = false}) {
  if (slow) {
    // Burn four moves with a canceling swap pair that keeps the board
    // unsolved, so the attempt is valid but misses the efficiency target.
    final board = notifier.state.board;
    final cells = <(int, int)>[
      for (var y = 0; y < board.height; y++)
        for (var x = 0; x < board.width; x++)
          if (board.tileAt(x, y)?.isLocked == false) (x, y),
    ];
    outer:
    for (final a in cells) {
      for (final b in cells) {
        if (a == b) continue;
        final swapped = board.swapTiles(a.$1, a.$2, b.$1, b.$2);
        if (MazePathfindingSolver.hasValidPath(swapped)) continue;
        for (var i = 0; i < 4; i++) {
          swap(notifier, a, b);
        }
        break outer;
      }
    }
  }
  solveLevel(notifier, MazeLevelFactory.build(1));
}

Future<void> waitForCompletion(ProviderContainer container, int level) async {
  final provider = mazeArchitectNotifierProvider(level);
  for (var i = 0; i < 200 && container.read(provider).isSavingCompletion; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(container.read(provider).isSavingCompletion, isFalse);
}

Future<void> expectNoDailyClaim(
  ProviderContainer scope,
  LocalStorageService storage,
  String dateString,
) async {
  final status = await scope.read(
    dailyChallengeStatusProvider(dateString).future,
  );
  expect(status.isCompleted, isFalse);
  expect(status.clockRollbackDetected, isFalse);
  expect(status.currentStreak, 0);
  expect(status.bestStreak, 0);
  final data = await storage.readDocument(StorageKeys.dailyChallengeFile);
  expect(data, isNotNull);
  expect(data!['claims'] ?? <String, dynamic>{}, isEmpty);
  expect(data['lastCompletedDate'], isNull);
  final profile = await scope.read(profileRepositoryProvider).getProfile();
  expect(profile.currentStreak, 0);
  expect(profile.bestStreak, 0);
  expect(profile.lastDailyChallengeDate, isNull);
  final ledger = await scope
      .read(coinEconomyServiceProvider)
      .getTransactionHistory();
  expect(
    ledger.where(
      (entry) => entry.type == CoinTransactionType.earnDailyChallenge,
    ),
    isEmpty,
  );
  expect(
    ledger.where(
      (entry) =>
          entry.type == CoinTransactionType.earnAchievement &&
          entry.referenceId == 'daily_explorer',
    ),
    isEmpty,
  );
  final achievement = (await scope
      .read(achievementRepositoryProvider)
      .getAchievements())['daily_explorer']!;
  expect(achievement.currentProgress, 0);
  expect(achievement.isRewardClaimed, isFalse);
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
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageServiceProvider.overrideWithValue(storage),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await storage.close();
  });

  test('first clear, improved and worse replays preserve bests and reward only new stars', () async {
    final provider = mazeArchitectNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    final levels = container.read(levelProgressRepositoryProvider);
    final profiles = container.read(profileRepositoryProvider);
    final achievements = container.read(achievementRepositoryProvider);
    await levels.getAllLevelResults();
    await profiles.getProfile();
    await achievements.getAchievements();

    solveLevelOne(notifier, slow: true);
    await waitForCompletion(container, 1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedStars, 2);
    expect(container.read(provider).earnedXp, 200);
    expect(container.read(provider).earnedCoins, 25);
    final first = (await levels.getLevelResult('maze_architect', 1))!;
    expect(first.bestMoveCount, 6);
    expect(first.hintsUsedCount, 0);
    expect(first.playCount, 1);
    expect(await levels.isLevelUnlocked('maze_architect', 2), isTrue);
    var profile = await profiles.getProfile();
    expect(profile.totalXp, 200);
    expect(profile.totalStars, 2);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 125);
    expect(
      (await achievements.getAchievements())['no_hint_champion']!
          .currentProgress,
      1,
    );

    notifier.reset();
    solveLevelOne(notifier);
    await waitForCompletion(container, 1);
    expect(container.read(provider).earnedStars, 3);
    expect(container.read(provider).earnedXp, 160);
    expect(container.read(provider).earnedCoins, 75);
    var result = (await levels.getLevelResult('maze_architect', 1))!;
    expect(result.starsEarned, 3);
    expect(result.bestMoveCount, 2);
    expect(result.firstCompletedAt, first.firstCompletedAt);
    expect(result.playCount, 2);
    profile = await profiles.getProfile();
    expect(profile.totalXp, 360);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);

    notifier.reset();
    solveLevelOne(notifier, slow: true);
    await waitForCompletion(container, 1);
    expect(container.read(provider).earnedStars, 2);
    expect(container.read(provider).earnedXp, 10);
    expect(container.read(provider).earnedCoins, 0);
    result = (await levels.getLevelResult('maze_architect', 1))!;
    expect(result.starsEarned, 3);
    expect(result.bestMoveCount, 2);
    expect(result.firstCompletedAt, first.firstCompletedAt);
    expect(result.playCount, 3);
    profile = await profiles.getProfile();
    expect(profile.totalXp, 370);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);
    final ledger = await container
        .read(coinEconomyServiceProvider)
        .getTransactionHistory();
    expect(
      ledger.where(
        (entry) =>
            entry.type == CoinTransactionType.earnLevel3Star &&
            entry.referenceId == 'maze_architect:1',
      ),
      hasLength(1),
    );
    final earned = await achievements.getAchievements();
    expect(earned['first_victory']!.isRewardClaimed, isTrue);
    expect(earned['perfect_solver']!.isRewardClaimed, isTrue);
    expect(earned['no_hint_champion']!.currentProgress, 1);
    expect(earned['puzzle_master_10']!.currentProgress, 1);
  });

  test(
    'failure rolls back all writes and retry keeps the solved attempt locked',
    () async {
      late FailingAchievementRewards rewards;
      final failingContainer = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
          achievementRewardServiceProvider.overrideWith((ref) {
            return rewards = FailingAchievementRewards(
              ref.read(achievementRepositoryProvider),
              ref.read(profileRepositoryProvider),
              ref.read(coinEconomyServiceProvider),
            );
          }),
        ],
      );
      addTearDown(failingContainer.dispose);
      final provider = mazeArchitectNotifierProvider(1);
      final notifier = failingContainer.read(provider.notifier);
      solveLevelOne(notifier);
      final pending = failingContainer.read(provider);
      expect(pending.isSavingCompletion, isTrue);
      expect(pending.moveCount, 2);
      expect(pending.canUndo, isFalse);
      notifier.tapTile(0, 1);
      notifier.undo();
      notifier.reset();
      notifier.loadLevel(15);
      notifier.togglePause();
      notifier.retryCompletion();
      expect(identical(failingContainer.read(provider), pending), isTrue);
      await rewards.entered.future;
      rewards.release.complete();
      await waitForCompletion(failingContainer, 1);
      final failed = failingContainer.read(provider);
      expect(failed.isSolved, isFalse);
      expect(failed.completionError, isNotNull);
      expect(failed.moveCount, 2);
      expect(failed.canUndo, isFalse);
      notifier.tapTile(0, 1);
      notifier.undo();
      notifier.reset();
      notifier.loadLevel(15);
      notifier.togglePause();
      expect(identical(failingContainer.read(provider), failed), isTrue);
      for (final key in [
        StorageKeys.levelProgressFile,
        StorageKeys.playerProfileFile,
        StorageKeys.achievementsFile,
        StorageKeys.coinLedgerFile,
      ]) {
        expect(await storage.readDocument(key), isNull);
      }

      notifier.retryCompletion();
      notifier.retryCompletion();
      expect(failingContainer.read(provider).isSavingCompletion, isTrue);
      await waitForCompletion(failingContainer, 1);
      final completed = failingContainer.read(provider);
      expect(completed.isSolved, isTrue);
      expect(completed.completionError, isNull);
      expect(completed.earnedXp, 350);
      expect(completed.earnedCoins, 100);
      final result = await failingContainer
          .read(levelProgressRepositoryProvider)
          .getLevelResult('maze_architect', 1);
      expect(result!.playCount, 1);
      final profile = await failingContainer
          .read(profileRepositoryProvider)
          .getProfile();
      expect(profile.totalXp, 350);
      expect(profile.totalStars, 3);
      expect(profile.levelsCompletedCount, 1);
      expect(profile.coinBalance, 200);
      final ledger = await failingContainer
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        ledger.where((entry) => entry.referenceId == 'maze_architect:1'),
        hasLength(1),
      );
    },
  );

  test(
    'concurrent attempts award first-clear and three-star rewards only once',
    () async {
      final other = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageServiceProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(other.dispose);
      solveLevelOne(container.read(mazeArchitectNotifierProvider(1).notifier));
      solveLevelOne(other.read(mazeArchitectNotifierProvider(1).notifier));
      await Future.wait([
        waitForCompletion(container, 1),
        waitForCompletion(other, 1),
      ]);
      expect(container.read(mazeArchitectNotifierProvider(1)).isSolved, isTrue);
      expect(other.read(mazeArchitectNotifierProvider(1)).isSolved, isTrue);
      final result = await container
          .read(levelProgressRepositoryProvider)
          .getLevelResult('maze_architect', 1);
      expect(result!.playCount, 2);
      final profile = await container
          .read(profileRepositoryProvider)
          .getProfile();
      expect(profile.totalXp, 360);
      expect(profile.totalStars, 3);
      expect(profile.levelsCompletedCount, 1);
      expect(profile.coinBalance, 200);
      final ledger = await container
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        ledger.where((entry) => entry.referenceId == 'maze_architect:1'),
        hasLength(1),
      );
    },
  );

  test('daily writes roll back with the level and retry and replay claim only once', () async {
    final date = mazeLevelOneDate();
    final challenge = DailyChallengeService.generateChallengeForDate(date);
    late ControlledDailyRepository daily;
    final provider = mazeArchitectNotifierProvider(1);
    final statusProvider = dailyChallengeStatusProvider(challenge.dateString);
    final scope = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageServiceProvider.overrideWithValue(storage),
        dailyChallengeRepositoryProvider.overrideWith((ref) {
          return daily = ControlledDailyRepository(
            storage,
            ref.read(profileRepositoryProvider),
            ref.read(coinEconomyServiceProvider),
            ref.read(achievementRepositoryProvider),
            ref.read(achievementRewardServiceProvider),
            clock: () => date,
          )..fail = true;
        }),
        provider.overrideWith(
          (ref) => MazeArchitectNotifier(ref, 1, challenge: challenge),
        ),
      ],
    );
    addTearDown(scope.dispose);
    final subscription = scope.listen(statusProvider, (_, _) {});
    addTearDown(subscription.close);
    expect((await scope.read(statusProvider.future)).isCompleted, isFalse);
    final beforeCompletion = await storage.readDocument(
      StorageKeys.dailyChallengeFile,
    );
    expect(beforeCompletion, isNotNull);
    expect(beforeCompletion!['lastObservedUtc'], date.toIso8601String());
    expect(beforeCompletion['claims'], isNull);

    final notifier = scope.read(provider.notifier);
    solveLevelOne(notifier);
    await waitForCompletion(scope, 1);
    expect(scope.read(provider).completionError, isNotNull);
    expect(scope.read(provider).isSolved, isFalse);
    expect((await scope.read(statusProvider.future)).isCompleted, isFalse);
    final dailyData = await storage.readDocument(
      StorageKeys.dailyChallengeFile,
    );
    expect(daily.calls, 1);
    expect(daily.lastResult, isNotNull);
    expect(dailyData, beforeCompletion);
    expect(dailyData?['claims'], isNull);
    for (final key in [
      StorageKeys.levelProgressFile,
      StorageKeys.playerProfileFile,
      StorageKeys.achievementsFile,
      StorageKeys.coinLedgerFile,
    ]) {
      expect(await storage.readDocument(key), isNull);
    }

    daily.fail = false;
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForCompletion(scope, 1);
    final completed = scope.read(provider);
    expect(completed.isSolved, isTrue);
    expect(completed.completionError, isNull);
    expect(completed.earnedXp, 650);
    expect(completed.earnedCoins, 300);
    expect((await scope.read(statusProvider.future)).isCompleted, isTrue);
    final claimedData = await storage.readDocument(
      StorageKeys.dailyChallengeFile,
    );
    final claims = Map<String, dynamic>.from(claimedData!['claims'] as Map);
    expect(claims.keys, [challenge.dateString]);
    expect(
      (claims[challenge.dateString] as Map)['claimId'],
      '${challenge.dateString}:maze_architect:1',
    );
    final profile = await scope.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 650);
    expect(profile.coinBalance, 400);
    expect(profile.currentStreak, 1);
    expect(profile.lastDailyChallengeDate, challenge.dateString);
    final achievements = await scope
        .read(achievementRepositoryProvider)
        .getAchievements();
    expect(achievements['daily_explorer']!.isRewardClaimed, isTrue);

    notifier.reset();
    solveLevelOne(notifier);
    await waitForCompletion(scope, 1);
    expect(scope.read(provider).earnedXp, 10);
    expect(scope.read(provider).earnedCoins, 0);
    expect(daily.calls, 3);
    expect(
      await storage.readDocument(StorageKeys.dailyChallengeFile),
      claimedData,
    );
    expect(
      (await scope.read(profileRepositoryProvider).getProfile()).totalXp,
      660,
    );
    expect(
      (await scope
              .read(levelProgressRepositoryProvider)
              .getLevelResult('maze_architect', 1))!
          .playCount,
      2,
    );
    final ledger = await scope
        .read(coinEconomyServiceProvider)
        .getTransactionHistory();
    expect(
      ledger.where(
        (entry) =>
            entry.type == CoinTransactionType.earnDailyChallenge &&
            entry.referenceId == '${challenge.dateString}:maze_architect:1',
      ),
      hasLength(1),
    );
  });

  test(
    'mismatched daily game or level and later level transitions cannot claim',
    () async {
      final date = mazeLevelOneDate();
      final challenge = DailyChallengeService.generateChallengeForDate(date);
      var calls = 0;
      for (final (context, changeLevel, expectedXp, expectedCoins) in [
        (challenge.copyWith(gameId: 'cube_logic'), false, 350, 100),
        (challenge.copyWith(levelNumber: 2), false, 10, 0),
        (challenge, true, 200, 25),
      ]) {
        late ControlledDailyRepository daily;
        final provider = mazeArchitectNotifierProvider(1);
        final scope = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(storage),
            dailyChallengeRepositoryProvider.overrideWith((ref) {
              return daily = ControlledDailyRepository(
                storage,
                ref.read(profileRepositoryProvider),
                ref.read(coinEconomyServiceProvider),
                ref.read(achievementRepositoryProvider),
                ref.read(achievementRewardServiceProvider),
                clock: () => date,
              );
            }),
            provider.overrideWith(
              (ref) => MazeArchitectNotifier(ref, 1, challenge: context),
            ),
          ],
        );
        final statusProvider = dailyChallengeStatusProvider(context.dateString);
        final subscription = scope.listen(statusProvider, (_, _) {});
        expect((await scope.read(statusProvider.future)).isCompleted, isFalse);
        final notifier = scope.read(provider.notifier);
        if (changeLevel) {
          notifier.loadLevel(2);
          solveLevel(notifier, MazeLevelFactory.build(2));
        } else {
          solveLevelOne(notifier);
        }
        await waitForCompletion(scope, 1);
        expect(scope.read(provider).isSolved, isTrue);
        expect(scope.read(provider).completionError, isNull);
        expect(scope.read(provider).earnedXp, expectedXp);
        expect(scope.read(provider).earnedCoins, expectedCoins);
        await expectNoDailyClaim(scope, storage, context.dateString);
        calls += daily.calls;
        subscription.close();
        scope.dispose();
      }
      expect(calls, 0);
    },
  );

  test(
    'expired and invalid daily contexts do not prevent level completion',
    () async {
      final date = mazeLevelOneDate();
      final challenge = DailyChallengeService.generateChallengeForDate(date);
      // Use a different date whose generated challenge is not Maze level 1.
      var otherDate = date.add(const Duration(days: 1));
      while (true) {
        final generated = DailyChallengeService.generateChallengeForDate(
          otherDate,
        );
        if (generated.gameId != 'maze_architect' ||
            generated.levelNumber != 1) {
          break;
        }
        otherDate = otherDate.add(const Duration(days: 1));
      }
      final invalid = DailyChallengeService.generateChallengeForDate(otherDate)
          .copyWith(gameId: 'maze_architect', levelNumber: 1);
      for (final (context, clock, expectedXp, expectedCoins) in [
        (challenge, otherDate, 350, 100),
        (invalid, otherDate, 10, 0),
      ]) {
        late ControlledDailyRepository daily;
        final provider = mazeArchitectNotifierProvider(1);
        final scope = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localStorageServiceProvider.overrideWithValue(storage),
            dailyChallengeRepositoryProvider.overrideWith((ref) {
              return daily = ControlledDailyRepository(
                storage,
                ref.read(profileRepositoryProvider),
                ref.read(coinEconomyServiceProvider),
                ref.read(achievementRepositoryProvider),
                ref.read(achievementRewardServiceProvider),
                clock: () => clock,
              );
            }),
            provider.overrideWith(
              (ref) => MazeArchitectNotifier(ref, 1, challenge: context),
            ),
          ],
        );
        final statusProvider = dailyChallengeStatusProvider(context.dateString);
        final subscription = scope.listen(statusProvider, (_, _) {});
        expect((await scope.read(statusProvider.future)).isCompleted, isFalse);
        solveLevelOne(scope.read(provider.notifier));
        await waitForCompletion(scope, 1);
        expect(scope.read(provider).isSolved, isTrue);
        expect(scope.read(provider).completionError, isNull);
        expect(scope.read(provider).earnedXp, expectedXp);
        expect(scope.read(provider).earnedCoins, expectedCoins);
        expect(daily.calls, 1);
        expect(daily.lastResult, isNull);
        await expectNoDailyClaim(scope, storage, context.dateString);
        subscription.close();
        scope.dispose();
      }
    },
  );

  test('level 15 completes without unlocking a nonexistent level 16', () async {
    final provider = mazeArchitectNotifierProvider(15);
    final notifier = container.read(provider.notifier);
    solveLevel(notifier, MazeLevelFactory.build(15));
    await waitForCompletion(container, 15);
    expect(container.read(provider).isSolved, isTrue);
    final levels = container.read(levelProgressRepositoryProvider);
    expect(
      (await levels.getLevelResult('maze_architect', 15))!.isCompleted,
      isTrue,
    );
    expect(await levels.getLevelResult('maze_architect', 16), isNull);
    expect(await levels.isLevelUnlocked('maze_architect', 16), isFalse);
  });
}
