import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/features/memory_matrix/domain/memory_board.dart';
import 'package:mindverse/features/memory_matrix/domain/memory_matrix_level_factory.dart';
import 'package:mindverse/features/memory_matrix/presentation/providers/memory_matrix_notifier.dart';
import 'package:mindverse/shared/models/coin_transaction.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/models/level_result.dart';
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
  Completer<void>? gate;

  @override
  Future<T> runInTransaction<T>(
    Future<T> Function(LocalStorageTransaction) action,
  ) async {
    final result = await delegate.runInTransaction((transaction) async {
      final pendingGate = gate;
      if (pendingGate != null) await pendingGate.future;
      final result = await action(transaction);
      if (failBeforeCommit) {
        failBeforeCommit = false;
        throw StateError('Injected failure before commit');
      }
      return result;
    });
    if (failAfterCommit) {
      failAfterCommit = false;
      throw StateError('Injected failure after commit');
    }
    return result;
  }

  @override
  Future<void> writeDocument(String key, Map<String, dynamic> data) =>
      delegate.writeDocument(key, data);

  @override
  Future<Map<String, dynamic>?> readDocument(String key) =>
      delegate.readDocument(key);

  @override
  Future<void> removeDocument(String key) => delegate.removeDocument(key);

  @override
  Future<void> resetUserData() => delegate.resetUserData();

  @override
  Future<void> close() => delegate.close();
}

class TrackingDailyRepository implements DailyChallengeRepository {
  TrackingDailyRepository(this.delegate, this.onCompletion);

  final DailyChallengeRepository delegate;
  final void Function() onCompletion;

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) {
    onCompletion();
    return delegate.completeInTransaction(transaction, challenge);
  }

  @override
  Future<DailyChallengeStatus> getStatus(String dateString) =>
      delegate.getStatus(dateString);

  @override
  void invalidateStatus(String dateString) =>
      delegate.invalidateStatus(dateString);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ControlledStorage storage;
  late ProviderContainer container;
  late int dailyCalls;

  setUp(() async {
    dailyCalls = 0;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = ControlledStorage(await createTestLocalStorage(prefs));
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

  void solve(int level) {
    final provider = memoryMatrixNotifierProvider(level);
    final notifier = container.read(provider.notifier);
    final sequence = container.read(provider).board.sequence;
    notifier.startRecallPhase();
    for (final (x, y) in sequence) {
      notifier.tapCell(x, y);
    }
  }

  Future<void> waitForSave(int level) async {
    final provider = memoryMatrixNotifierProvider(level);
    for (
      var i = 0;
      i < 100 && container.read(provider).isSavingCompletion;
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(provider).isSavingCompletion, isFalse);
  }

  ({DateTime date, DailyChallenge challenge}) matchingDaily() {
    var date = DateTime.utc(2026, 1, 1, 12);
    var challenge = DailyChallengeService.generateChallengeForDate(date);
    while (challenge.gameId != 'memory_matrix' || challenge.levelNumber != 1) {
      date = date.add(const Duration(days: 1));
      challenge = DailyChallengeService.generateChallengeForDate(date);
    }
    return (date: date, challenge: challenge);
  }

  Future<void> configureDaily(DailyChallenge challenge, DateTime now) async {
    container.dispose();
    final prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageServiceProvider.overrideWithValue(storage),
        dailyChallengeRepositoryProvider.overrideWith(
          (ref) => TrackingDailyRepository(
            DailyChallengeRepositoryImpl(
              ref.watch(localStorageServiceProvider),
              ref.watch(profileRepositoryProvider),
              ref.watch(coinEconomyServiceProvider),
              ref.watch(achievementRepositoryProvider),
              ref.watch(achievementRewardServiceProvider),
              clock: () => now,
            ),
            () => dailyCalls++,
          ),
        ),
        memoryMatrixNotifierProvider(1).overrideWith(
          (ref) => MemoryMatrixNotifier(ref, 1, challenge: challenge),
        ),
      ],
    );
  }

  test(
    'daily win refreshes status and awards daily rewards once on replay',
    () async {
      final daily = matchingDaily();
      await configureDaily(daily.challenge, daily.date);
      final status = dailyChallengeStatusProvider(daily.challenge.dateString);
      final subscription = container.listen(status, (_, _) {});
      addTearDown(subscription.close);
      expect((await container.read(status.future)).isCompleted, isFalse);

      solve(1);
      await waitForSave(1);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedXp, 650);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedCoins, 300);
      final completedStatus = await container.read(status.future);
      expect(completedStatus.isCompleted, isTrue);
      expect(completedStatus.currentStreak, 1);
      final profile = await container
          .read(profileRepositoryProvider)
          .getProfile();
      expect(profile.totalXp, 650);
      expect(profile.coinBalance, 400);
      expect(profile.lastDailyChallengeDate, daily.challenge.dateString);
      expect(
        (await container
                .read(achievementRepositoryProvider)
                .getAchievements())['daily_explorer']!
            .isRewardClaimed,
        isTrue,
      );

      container.read(memoryMatrixNotifierProvider(1).notifier).reset();
      solve(1);
      await waitForSave(1);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedXp, 10);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedCoins, 0);
      expect(dailyCalls, 2);
      final history = await container
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        history.where(
          (entry) => entry.type == CoinTransactionType.earnDailyChallenge,
        ),
        hasLength(1),
      );
      expect(
        (await container.read(profileRepositoryProvider).getProfile()).totalXp,
        660,
      );
    },
  );

  for (final scenario in [
    'wrong game',
    'wrong level',
    'stale date',
    'forged date',
  ]) {
    test('$scenario challenge does not award daily rewards', () async {
      final daily = matchingDaily();
      var nextDate = daily.date.add(const Duration(days: 1));
      while (true) {
        final generated = DailyChallengeService.generateChallengeForDate(
          nextDate,
        );
        if (generated.gameId != 'memory_matrix' || generated.levelNumber != 1) {
          break;
        }
        nextDate = nextDate.add(const Duration(days: 1));
      }
      final challenge = switch (scenario) {
        'wrong game' => daily.challenge.copyWith(gameId: 'cube_logic'),
        'wrong level' => daily.challenge.copyWith(levelNumber: 2),
        'forged date' => daily.challenge.copyWith(
          dateString: DailyChallengeService.generateChallengeForDate(nextDate)
              .dateString,
        ),
        _ => daily.challenge,
      };
      final now = scenario == 'stale date' || scenario == 'forged date'
          ? nextDate
          : daily.date;
      await configureDaily(challenge, now);
      solve(1);
      await waitForSave(1);
      expect(container.read(memoryMatrixNotifierProvider(1)).isSolved, isTrue);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedXp, 350);
      expect(container.read(memoryMatrixNotifierProvider(1)).earnedCoins, 100);
      expect(
        dailyCalls,
        scenario == 'wrong game' || scenario == 'wrong level' ? 0 : 1,
      );
      expect(
        (await container.read(profileRepositoryProvider).getProfile())
            .lastDailyChallengeDate,
        isNull,
      );
      final history = await container
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        history.where(
          (entry) => entry.type == CoinTransactionType.earnDailyChallenge,
        ),
        isEmpty,
      );
    });
  }

  for (final afterCommit in [false, true]) {
    test(
      'daily completion retry after ${afterCommit ? 'unacknowledged commit' : 'rollback'} is atomic',
      () async {
        final daily = matchingDaily();
        await configureDaily(daily.challenge, daily.date);
        final status = dailyChallengeStatusProvider(daily.challenge.dateString);
        expect((await container.read(status.future)).isCompleted, isFalse);
        if (afterCommit) {
          storage.failAfterCommit = true;
        } else {
          storage.failBeforeCommit = true;
        }
        solve(1);
        await waitForSave(1);
        expect(
          container.read(memoryMatrixNotifierProvider(1)).completionError,
          isNotNull,
        );
        if (!afterCommit) {
          final data = await storage.readDocument(
            StorageKeys.dailyChallengeFile,
          );
          expect(data?['claims'], isNull);
          expect(
            await container
                .read(levelProgressRepositoryProvider)
                .getLevelResult('memory_matrix', 1),
            isNull,
          );
          expect(
            (await container.read(profileRepositoryProvider).getProfile())
                .totalXp,
            0,
          );
          expect(
            await container
                .read(coinEconomyServiceProvider)
                .getTransactionHistory(),
            isEmpty,
          );
          expect(
            (await container
                    .read(achievementRepositoryProvider)
                    .getAchievements())['daily_explorer']!
                .isUnlocked,
            isFalse,
          );
        }
        final notifier = container.read(
          memoryMatrixNotifierProvider(1).notifier,
        );
        notifier.retryCompletion();
        notifier.retryCompletion();
        await waitForSave(1);
        expect(
          container.read(memoryMatrixNotifierProvider(1)).isSolved,
          isTrue,
        );
        expect(container.read(memoryMatrixNotifierProvider(1)).earnedXp, 650);
        expect(
          container.read(memoryMatrixNotifierProvider(1)).earnedCoins,
          300,
        );
        expect(dailyCalls, afterCommit ? 1 : 2);
        expect((await container.read(status.future)).isCompleted, isTrue);
        expect(
          (await container
                  .read(levelProgressRepositoryProvider)
                  .getLevelResult('memory_matrix', 1))!
              .playCount,
          1,
        );
        final profile = await container
            .read(profileRepositoryProvider)
            .getProfile();
        expect(profile.totalXp, 650);
        expect(profile.coinBalance, 400);
        final history = await container
            .read(coinEconomyServiceProvider)
            .getTransactionHistory();
        expect(
          history.where(
            (entry) => entry.type == CoinTransactionType.earnDailyChallenge,
          ),
          hasLength(1),
        );
      },
    );
  }

  test('completion and replay award progress, achievements and three-star coins once', () async {
    final provider = memoryMatrixNotifierProvider(1);
    solve(1);
    await waitForSave(1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).earnedXp, 350);
    expect(container.read(provider).earnedCoins, 100);
    final levels = container.read(levelProgressRepositoryProvider);
    final first = (await levels.getLevelResult('memory_matrix', 1))!;
    expect(first.starsEarned, 3);
    expect(first.bestMoveCount, 3);
    expect(first.hintsUsedCount, 0);
    expect(await levels.isLevelUnlocked('memory_matrix', 2), isTrue);
    final achievements = await container
        .read(achievementRepositoryProvider)
        .getAchievements();
    expect(achievements['first_victory']!.isRewardClaimed, isTrue);
    expect(achievements['perfect_solver']!.isRewardClaimed, isTrue);
    expect(achievements['no_hint_champion']!.currentProgress, 1);

    container.read(provider.notifier).reset();
    solve(1);
    await waitForSave(1);
    expect(container.read(provider).earnedXp, 10);
    expect(container.read(provider).earnedCoins, 0);
    final replay = (await levels.getLevelResult('memory_matrix', 1))!;
    expect(replay.playCount, 2);
    expect(replay.firstCompletedAt, first.firstCompletedAt);
    expect(replay.bestMoveCount, first.bestMoveCount);
    final profile = await container
        .read(profileRepositoryProvider)
        .getProfile();
    expect(profile.totalXp, 360);
    expect(profile.coinBalance, 200);
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    final history = await container
        .read(coinEconomyServiceProvider)
        .getTransactionHistory();
    expect(
      history.where(
        (entry) =>
            entry.type == CoinTransactionType.earnLevel3Star &&
            entry.referenceId == 'memory_matrix:1',
      ),
      hasLength(1),
    );
    expect(
      (await container
              .read(achievementRepositoryProvider)
              .getAchievements())['no_hint_champion']!
          .currentProgress,
      1,
    );
  });

  test('replay improvements preserve best result and add only newly earned rewards', () async {
    final firstDate = DateTime.utc(2020);
    final levels = container.read(levelProgressRepositoryProvider);
    await levels.saveLevelResult(
      LevelResult(
        gameId: 'memory_matrix',
        levelNumber: 1,
        isUnlocked: true,
        isCompleted: true,
        star1Completed: true,
        star2Efficiency: true,
        starsEarned: 2,
        bestMoveCount: 2,
        hintsUsedCount: 1,
        firstCompletedAt: firstDate,
      ),
    );
    await container
        .read(profileRepositoryProvider)
        .updateProfile(starsToAdd: 2, levelsCompletedDelta: 1);
    solve(1);
    await waitForSave(1);
    final state = container.read(memoryMatrixNotifierProvider(1));
    expect(state.isSolved, isTrue);
    expect(state.earnedXp, 160);
    expect(state.earnedCoins, 75);
    final result = (await levels.getLevelResult('memory_matrix', 1))!;
    expect(result.firstCompletedAt, firstDate);
    expect(result.bestMoveCount, 2);
    expect(result.hintsUsedCount, 0);
    expect(result.playCount, 2);
    final profile = await container
        .read(profileRepositoryProvider)
        .getProfile();
    expect(profile.totalStars, 3);
    expect(profile.levelsCompletedCount, 1);
    expect(
      (await container
              .read(achievementRepositoryProvider)
              .getAchievements())['no_hint_champion']!
          .currentProgress,
      1,
    );
  });

  test('pending completion ignores duplicate input, pause, reset and level changes', () async {
    storage.gate = Completer<void>();
    final provider = memoryMatrixNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    solve(1);
    final pending = container.read(provider);
    expect(pending.isSavingCompletion, isTrue);
    expect(pending.board.phase, MemoryPhase.success);
    notifier.tapCell(2, 2);
    notifier.startRecallPhase();
    notifier.togglePause();
    notifier.reset();
    notifier.loadLevel(2);
    notifier.retryCompletion();
    expect(container.read(provider), same(pending));
    storage.gate!.complete();
    storage.gate = null;
    await waitForSave(1);
    expect(container.read(provider).isSolved, isTrue);
    expect(
      (await container
              .read(levelProgressRepositoryProvider)
              .getLevelResult('memory_matrix', 1))!
          .playCount,
      1,
    );
  });

  test('transaction failure rolls back everything and retry keeps the solved attempt', () async {
    storage.failBeforeCommit = true;
    final provider = memoryMatrixNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    solve(1);
    await waitForSave(1);
    final failed = container.read(provider);
    expect(failed.completionError, isNotNull);
    expect(failed.isSolved, isFalse);
    expect(
      await container
          .read(levelProgressRepositoryProvider)
          .getLevelResult('memory_matrix', 1),
      isNull,
    );
    expect(
      await container
          .read(levelProgressRepositoryProvider)
          .isLevelUnlocked('memory_matrix', 2),
      isFalse,
    );
    expect(
      await container.read(coinEconomyServiceProvider).getTransactionHistory(),
      isEmpty,
    );
    expect(
      (await container
              .read(achievementRepositoryProvider)
              .getAchievements())['first_victory']!
          .isUnlocked,
      isFalse,
    );
    final profile = await container
        .read(profileRepositoryProvider)
        .getProfile();
    expect(profile.totalXp, 0);
    expect(profile.coinBalance, 100);
    notifier.reset();
    notifier.loadLevel(2);
    notifier.togglePause();
    notifier.startRecallPhase();
    notifier.tapCell(2, 2);
    expect(container.read(provider), same(failed));
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForSave(1);
    expect(container.read(provider).isSolved, isTrue);
    expect(container.read(provider).completionError, isNull);
    expect(
      (await container
              .read(levelProgressRepositoryProvider)
              .getLevelResult('memory_matrix', 1))!
          .playCount,
      1,
    );
    expect(
      (await container.read(profileRepositoryProvider).getProfile()).totalXp,
      350,
    );
  });

  test(
    'retry after an unacknowledged commit does not duplicate rewards',
    () async {
      storage.failAfterCommit = true;
      final provider = memoryMatrixNotifierProvider(1);
      solve(1);
      await waitForSave(1);
      expect(container.read(provider).completionError, isNotNull);
      container.read(provider.notifier).retryCompletion();
      await waitForSave(1);
      expect(container.read(provider).isSolved, isTrue);
      expect(container.read(provider).earnedXp, 350);
      expect(container.read(provider).earnedCoins, 100);
      final result = (await container
          .read(levelProgressRepositoryProvider)
          .getLevelResult('memory_matrix', 1))!;
      final profile = await container
          .read(profileRepositoryProvider)
          .getProfile();
      expect(result.playCount, 1);
      expect(profile.totalXp, 350);
      expect(profile.coinBalance, 200);
      expect(profile.totalStars, 3);
      final history = await container
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        history.where((entry) => entry.referenceId == 'memory_matrix:1'),
        hasLength(1),
      );
    },
  );

  test('final level does not unlock a nonexistent level', () async {
    solve(MemoryMatrixLevelFactory.levelCount);
    await waitForSave(MemoryMatrixLevelFactory.levelCount);
    expect(
      container
          .read(
            memoryMatrixNotifierProvider(MemoryMatrixLevelFactory.levelCount),
          )
          .isSolved,
      isTrue,
    );
    expect(
      await container
          .read(levelProgressRepositoryProvider)
          .getLevelResult(
            'memory_matrix',
            MemoryMatrixLevelFactory.levelCount + 1,
          ),
      isNull,
    );
  });
}
