import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/maze_architect/presentation/providers/maze_architect_notifier.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/achievement_repository.dart';
import 'package:mindverse/shared/repositories/profile_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class FailingAchievementRewards extends AchievementRewardService {
  final entered = Completer<void>();
  final release = Completer<void>();
  bool fail = true;

  FailingAchievementRewards(
    AchievementRepository achievements,
    ProfileRepository profiles,
    CoinEconomyService coins,
  ) : super(achievements, profiles, coins);

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

void swap(MazeArchitectNotifier notifier, (int, int) a, (int, int) b) {
  notifier.tapTile(a.$1, a.$2);
  notifier.tapTile(b.$1, b.$2);
}

void solveLevelOne(MazeArchitectNotifier notifier, {bool slow = false}) {
  swap(notifier, (1, 0), (0, 1));
  if (slow) {
    for (var i = 0; i < 4; i++) {
      swap(notifier, (1, 1), (1, 2));
    }
  }
  swap(notifier, (1, 0), (0, 1));
}

Future<void> waitForCompletion(ProviderContainer container, int level) async {
  final provider = mazeArchitectNotifierProvider(level);
  for (var i = 0; i < 200 && container.read(provider).isSavingCompletion; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(container.read(provider).isSavingCompletion, isFalse);
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
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
    ]);
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
    expect((await achievements.getAchievements())['no_hint_champion']!.currentProgress, 1);

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
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.type == CoinTransactionType.earnLevel3Star &&
        entry.referenceId == 'maze_architect:1'), hasLength(1));
    final earned = await achievements.getAchievements();
    expect(earned['first_victory']!.isRewardClaimed, isTrue);
    expect(earned['perfect_solver']!.isRewardClaimed, isTrue);
    expect(earned['no_hint_champion']!.currentProgress, 1);
    expect(earned['puzzle_master_10']!.currentProgress, 1);
  });

  test('failure rolls back all writes and retry keeps the solved attempt locked', () async {
    late FailingAchievementRewards rewards;
    final failingContainer = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
      achievementRewardServiceProvider.overrideWith((ref) {
        return rewards = FailingAchievementRewards(
          ref.read(achievementRepositoryProvider),
          ref.read(profileRepositoryProvider),
          ref.read(coinEconomyServiceProvider),
        );
      }),
    ]);
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
    final result = await failingContainer.read(levelProgressRepositoryProvider).getLevelResult('maze_architect', 1);
    expect(result!.playCount, 1);
    final profile = await failingContainer.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 350);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);
    final ledger = await failingContainer.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'maze_architect:1'), hasLength(1));
  });

  test('concurrent attempts award first-clear and three-star rewards only once', () async {
    final other = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storage),
    ]);
    addTearDown(other.dispose);
    solveLevelOne(container.read(mazeArchitectNotifierProvider(1).notifier));
    solveLevelOne(other.read(mazeArchitectNotifierProvider(1).notifier));
    await Future.wait([waitForCompletion(container, 1), waitForCompletion(other, 1)]);
    expect(container.read(mazeArchitectNotifierProvider(1)).isSolved, isTrue);
    expect(other.read(mazeArchitectNotifierProvider(1)).isSolved, isTrue);
    final result = await container.read(levelProgressRepositoryProvider).getLevelResult('maze_architect', 1);
    expect(result!.playCount, 2);
    final profile = await container.read(profileRepositoryProvider).getProfile();
    expect(profile.totalXp, 360);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(profile.coinBalance, 200);
    final ledger = await container.read(coinEconomyServiceProvider).getTransactionHistory();
    expect(ledger.where((entry) => entry.referenceId == 'maze_architect:1'), hasLength(1));
  });

  test('level 15 completes without unlocking a nonexistent level 16', () async {
    final provider = mazeArchitectNotifierProvider(15);
    final notifier = container.read(provider.notifier);
    swap(notifier, (1, 0), (2, 0));
    await waitForCompletion(container, 15);
    expect(container.read(provider).isSolved, isTrue);
    final levels = container.read(levelProgressRepositoryProvider);
    expect((await levels.getLevelResult('maze_architect', 15))!.isCompleted, isTrue);
    expect(await levels.getLevelResult('maze_architect', 16), isNull);
    expect(await levels.isLevelUnlocked('maze_architect', 16), isFalse);
  });
}
