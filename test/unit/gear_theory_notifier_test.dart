import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/features/gear_theory/domain/gear.dart';
import 'package:mindverse/features/gear_theory/domain/gear_board.dart';
import 'package:mindverse/features/gear_theory/domain/gear_level_factory.dart';
import 'package:mindverse/features/gear_theory/presentation/providers/gear_theory_notifier.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/achievement_repository.dart';
import 'package:mindverse/shared/repositories/profile_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class TestGearTheoryNotifier extends GearTheoryNotifier {
  TestGearTheoryNotifier(super.ref, super.initialLevelNumber);

  void prepareConnectedBoard({int moves = 0}) {
    state = state.copyWith(
      moveCount: moves,
      board: const GearBoard(
        width: 10,
        height: 10,
        gears: {
          'driver': Gear(id: 'driver', x: 1, y: 5, teeth: 16, isDriver: true),
          'target': Gear(id: 'target', x: 9, y: 5, teeth: 16, isTarget: true),
        },
        inventory: [],
      ),
    );
  }
}

class FailingAchievementRewardService extends AchievementRewardService {
  bool fail = true;

  FailingAchievementRewardService(
    AchievementRepository achievements,
    ProfileRepository profiles,
    CoinEconomyService coins,
  ) : super(achievements, profiles, coins);

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

  ProviderContainer makeContainer(int level, {LocalStorageService? storageOverride, bool failRewards = false}) {
    final provider = gearTheoryNotifierProvider(level);
    return ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      localStorageServiceProvider.overrideWithValue(storageOverride ?? storage),
      provider.overrideWith((ref) => TestGearTheoryNotifier(ref, level)),
      if (failRewards)
        achievementRewardServiceProvider.overrideWith((ref) => FailingAchievementRewardService(
          ref.read(achievementRepositoryProvider),
          ref.read(profileRepositoryProvider),
          ref.read(coinEconomyServiceProvider),
        )),
    ]);
  }

  Future<void> waitForCompletion(int level) async {
    final provider = gearTheoryNotifierProvider(level);
    for (var i = 0; i < 100 && container.read(provider).isSavingCompletion; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSavingCompletion, isFalse);
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
    expect((await container.read(achievementRepositoryProvider).getAchievements())['first_victory']!.isUnlocked, isFalse);
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
    expect((await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', 1))!.playCount, 1);
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

  test('final level does not unlock a nonexistent level', () async {
    const level = GearLevelFactory.levelCount;
    final provider = gearTheoryNotifierProvider(level);
    container = makeContainer(level);
    final notifier = container.read(provider.notifier) as TestGearTheoryNotifier;
    notifier.prepareConnectedBoard();
    notifier.rotateDriver(0.5);
    await waitForCompletion(level);
    expect(container.read(provider).isSolved, isTrue);
    expect(await container.read(levelProgressRepositoryProvider).getLevelResult('gear_theory', level + 1), isNull);
  });
}
