import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindverse/features/bridge_master/domain/bridge_member.dart';
import 'package:mindverse/features/bridge_master/presentation/providers/bridge_master_notifier.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/shared/models/achievement.dart';
import 'package:mindverse/shared/models/daily_challenge.dart';
import 'package:mindverse/shared/providers/shared_providers.dart';
import 'package:mindverse/shared/repositories/achievement_repository.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

class ControlledAchievementRepository extends AchievementRepositoryImpl {
  ControlledAchievementRepository(super.storage);

  Completer<void>? gate;
  bool fail = false;
  int calls = 0;

  @override
  Future<List<Achievement>> recordLevelCompletionInTransaction(
    LocalStorageTransaction transaction, {
    required String gameId,
    required int levelNumber,
    required bool isFirstClear,
    required bool earnedThreeStarsForFirstTime,
    required bool earnedNoHintForFirstTime,
  }) async {
    calls++;
    final unlocked = await super.recordLevelCompletionInTransaction(
      transaction,
      gameId: gameId,
      levelNumber: levelNumber,
      isFirstClear: isFirstClear,
      earnedThreeStarsForFirstTime: earnedThreeStarsForFirstTime,
      earnedNoHintForFirstTime: earnedNoHintForFirstTime,
    );
    if (gate != null) await gate!.future;
    if (fail) throw StateError('injected completion failure');
    return unlocked;
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

  bool fail = true;
  int calls = 0;

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) async {
    calls++;
    final result = await super.completeInTransaction(transaction, challenge);
    if (fail) throw StateError('injected daily failure');
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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

  test('BridgeMasterNotifier initializes with level 1 anchors', () {
    final state = container.read(bridgeMasterNotifierProvider(1));
    expect(state.levelNumber, equals(1));
    expect(state.joints.length, equals(2));
    expect(state.members, isEmpty);
    expect(state.totalCost, equals(0));
  });

  test('Adding members calculates total cost against budget', () {
    final notifier = container.read(bridgeMasterNotifierProvider(1).notifier);
    notifier.selectMaterial(BridgeMaterialType.roadDeck);

    notifier.addMember('a_left', 'a_right');
    final state = container.read(bridgeMasterNotifierProvider(1));

    expect(state.members.length, equals(1));
    expect(state.totalCost, greaterThan(0));
    expect(state.isOverBudget, isFalse);
  });

  test('Clearing bridge resets members and cost', () {
    final notifier = container.read(bridgeMasterNotifierProvider(1).notifier);
    notifier.addMember('a_left', 'a_right');
    notifier.clearAll();

    final state = container.read(bridgeMasterNotifierProvider(1));
    expect(state.members, isEmpty);
    expect(state.totalCost, equals(0));
  });

  Future<void> waitForSave(ProviderContainer scope, int level) async {
    final provider = bridgeMasterNotifierProvider(level);
    for (var i = 0; i < 100 && scope.read(provider).isSavingCompletion; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(scope.read(provider).isSavingCompletion, isFalse);
  }

  void finishBridge(BridgeMasterNotifier notifier, double gap) {
    notifier.startSimulation();
    notifier.stepSimulation(gap);
  }

  test(
    'completion and replay preserve best progress and award improvements once',
    () async {
      final provider = bridgeMasterNotifierProvider(1);
      final notifier = container.read(provider.notifier);
      final target = container.read(provider).targetBudget;

      // A road deck plus enough wood supports to exceed the star-2 budget
      // target while keeping peak stress below the mastery threshold.
      notifier.addMember('a_left', 'a_right');
      notifier.selectMaterial(BridgeMaterialType.woodBeam);
      final supports = <(String, String)>[];
      for (var i = 0; i < 20; i++) {
        final joint = notifier.addJoint(1.0 + i, 8.0);
        supports.add((joint, 'm_a_left_$joint'));
        notifier.addMember('a_left', joint);
        if (container.read(provider).totalCost > target) break;
      }
      final overCost = container.read(provider).totalCost;
      expect(overCost, greaterThan(target));
      finishBridge(notifier, 8);
      await waitForSave(container, 1);
      expect(container.read(provider).earnedStars, 2);
      final levels = container.read(levelProgressRepositoryProvider);
      final first = (await levels.getLevelResult('bridge_master', 1))!;
      expect(first.bestMoveCount, overCost);
      expect(await levels.isLevelUnlocked('bridge_master', 2), isTrue);
      var profile = await container
          .read(profileRepositoryProvider)
          .getProfile();
      expect(profile.totalXp, 200);
      expect(profile.totalStars, 2);
      expect(profile.levelsCompletedCount, 1);

      // Removing the last support brings the build back under the target.
      notifier.stopSimulation();
      expect(container.read(provider).isCompleted, isFalse);
      final removed = supports.removeLast();
      notifier.removeMember(removed.$2);
      final improvedCost = container.read(provider).totalCost;
      expect(improvedCost, lessThanOrEqualTo(target));
      finishBridge(notifier, 8);
      await waitForSave(container, 1);
      expect(container.read(provider).earnedStars, 3);
      final improved = (await levels.getLevelResult('bridge_master', 1))!;
      expect(improved.bestMoveCount, improvedCost);
      expect(improved.firstCompletedAt, first.firstCompletedAt);
      expect(improved.playCount, 2);
      profile = await container.read(profileRepositoryProvider).getProfile();
      expect(profile.totalXp, 360);
      expect(profile.totalStars, 3);
      expect(profile.levelsCompletedCount, 1);
      expect(profile.coinBalance, 200);

      // Re-adding the support makes the replay less efficient again.
      notifier.stopSimulation();
      notifier.selectMaterial(BridgeMaterialType.woodBeam);
      notifier.addMember('a_left', removed.$1);
      finishBridge(notifier, 8);
      await waitForSave(container, 1);
      final replay = (await levels.getLevelResult('bridge_master', 1))!;
      expect(replay.playCount, 3);
      expect(replay.bestMoveCount, improvedCost);
      expect(replay.starsEarned, 3);
      expect(container.read(provider).earnedStars, 2);
      expect(replay.firstCompletedAt, first.firstCompletedAt);
      profile = await container.read(profileRepositoryProvider).getProfile();
      expect(profile.totalXp, 370);
      expect(profile.totalStars, 3);
      expect(profile.coinBalance, 200);
      final ledger = await container
          .read(coinEconomyServiceProvider)
          .getTransactionHistory();
      expect(
        ledger.where((entry) => entry.referenceId == 'bridge_master:1'),
        hasLength(1),
      );
    },
  );

  test('saving guards duplicate ticks and transitions; failure rolls back and retry succeeds', () async {
    final achievements = ControlledAchievementRepository(storage)
      ..gate = Completer<void>()
      ..fail = true;
    final scope = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        localStorageServiceProvider.overrideWithValue(storage),
        achievementRepositoryProvider.overrideWithValue(achievements),
      ],
    );
    addTearDown(scope.dispose);
    final provider = bridgeMasterNotifierProvider(1);
    final notifier = scope.read(provider.notifier);
    notifier.addMember('a_left', 'a_right');
    finishBridge(notifier, 8);
    expect(scope.read(provider).isSavingCompletion, isTrue);
    notifier.stepSimulation(8);
    notifier.clearAll();
    notifier.stopSimulation();
    notifier.loadLevel(2);
    notifier.addJoint(4, 4);
    notifier.addMember('a_left', 'a_right');
    notifier.startSimulation();
    expect(scope.read(provider).levelNumber, 1);
    expect(scope.read(provider).members, hasLength(1));
    expect(scope.read(provider).joints, hasLength(2));
    achievements.gate!.complete();
    await waitForSave(scope, 1);
    expect(scope.read(provider).completionError, isNotNull);
    expect(scope.read(provider).isSolved, isFalse);
    expect(
      await scope
          .read(levelProgressRepositoryProvider)
          .getLevelResult('bridge_master', 1),
      isNull,
    );
    expect(
      (await scope.read(profileRepositoryProvider).getProfile()).totalXp,
      0,
    );
    expect(
      await scope
          .read(levelProgressRepositoryProvider)
          .isLevelUnlocked('bridge_master', 2),
      isFalse,
    );
    expect(
      (await achievements.getAchievements())['first_victory']!.isUnlocked,
      isFalse,
    );
    notifier.loadLevel(2);
    notifier.clearAll();
    notifier.stopSimulation();
    expect(scope.read(provider).levelNumber, 1);
    expect(scope.read(provider).members, hasLength(1));
    achievements.fail = false;
    notifier.retryCompletion();
    notifier.retryCompletion();
    await waitForSave(scope, 1);
    expect(scope.read(provider).isSolved, isTrue);
    expect(scope.read(provider).completionError, isNull);
    expect(achievements.calls, 2);
    expect(
      (await scope
              .read(levelProgressRepositoryProvider)
              .getLevelResult('bridge_master', 1))!
          .playCount,
      1,
    );
    final ledger = await scope
        .read(coinEconomyServiceProvider)
        .getTransactionHistory();
    expect(
      ledger.where((entry) => entry.referenceId == 'bridge_master:1'),
      hasLength(1),
    );
  });

  test('level 15 completes without unlocking level 16', () async {
    final notifier = container.read(bridgeMasterNotifierProvider(15).notifier);
    notifier.addMember('a_left', 'a_right');
    finishBridge(notifier, 32);
    await waitForSave(container, 15);
    expect(container.read(bridgeMasterNotifierProvider(15)).isSolved, isTrue);
    expect(
      await container
          .read(levelProgressRepositoryProvider)
          .getLevelResult('bridge_master', 16),
      isNull,
    );
  });

  test('a failed bridge can be reset and redesigned', () async {
    final provider = bridgeMasterNotifierProvider(1);
    final notifier = container.read(provider.notifier);
    notifier.selectMaterial(BridgeMaterialType.woodBeam);
    notifier.addMember('a_left', 'a_right');
    finishBridge(notifier, 8);
    expect(container.read(provider).isFailed, isTrue);
    notifier.stopSimulation();
    expect(container.read(provider).isCompleted, isFalse);
    notifier.removeMember('m_a_left_a_right');
    notifier.selectMaterial(BridgeMaterialType.roadDeck);
    notifier.addMember('a_left', 'a_right');
    finishBridge(notifier, 8);
    await waitForSave(container, 1);
    expect(container.read(provider).isSolved, isTrue);
  });

  test('daily claim rolls back with completion and is awarded only once on retry and replay', () async {
    var date = DateTime.utc(2026, 1, 1, 12);
    var challenge = DailyChallengeService.generateChallengeForDate(date);
    while (challenge.gameId != 'bridge_master' || challenge.levelNumber != 1) {
      date = date.add(const Duration(days: 1));
      challenge = DailyChallengeService.generateChallengeForDate(date);
    }
    final fixedDate = date;
    final daily = ControlledDailyRepository(
      storage,
      container.read(profileRepositoryProvider),
      container.read(coinEconomyServiceProvider),
      container.read(achievementRepositoryProvider),
      container.read(achievementRewardServiceProvider),
      clock: () => fixedDate,
    );
    final provider = bridgeMasterNotifierProvider(1);
    final scope = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        localStorageServiceProvider.overrideWithValue(storage),
        dailyChallengeRepositoryProvider.overrideWithValue(daily),
        provider.overrideWith(
          (ref) => BridgeMasterNotifier(ref, 1, challenge: challenge),
        ),
      ],
    );
    addTearDown(scope.dispose);
    final notifier = scope.read(provider.notifier);
    notifier.addMember('a_left', 'a_right');
    finishBridge(notifier, 8);
    await waitForSave(scope, 1);
    expect(scope.read(provider).completionError, isNotNull);
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isFalse);
    expect(
      await scope
          .read(levelProgressRepositoryProvider)
          .getLevelResult('bridge_master', 1),
      isNull,
    );
    expect(
      (await scope.read(profileRepositoryProvider).getProfile()).totalXp,
      0,
    );

    daily.fail = false;
    notifier.retryCompletion();
    await waitForSave(scope, 1);
    expect(scope.read(provider).isSolved, isTrue);
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isTrue);
    notifier.stopSimulation();
    finishBridge(notifier, 8);
    await waitForSave(scope, 1);
    final ledger = await scope
        .read(coinEconomyServiceProvider)
        .getTransactionHistory();
    expect(
      ledger.where(
        (entry) =>
            entry.referenceId == '${challenge.dateString}:bridge_master:1',
      ),
      hasLength(1),
    );
    expect(daily.calls, 3);
  });

  test(
    'a mismatched daily context does not claim or block completion',
    () async {
      final daily = ControlledDailyRepository(
        storage,
        container.read(profileRepositoryProvider),
        container.read(coinEconomyServiceProvider),
        container.read(achievementRepositoryProvider),
        container.read(achievementRewardServiceProvider),
      );
      final provider = bridgeMasterNotifierProvider(1);
      for (final challenge in [
        const DailyChallenge(
          dateString: '2026-01-01',
          gameId: 'maze_architect',
          levelNumber: 1,
          challengeTitle: '',
          challengeDescription: '',
        ),
        const DailyChallenge(
          dateString: '2026-01-01',
          gameId: 'bridge_master',
          levelNumber: 2,
          challengeTitle: '',
          challengeDescription: '',
        ),
      ]) {
        final scope = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(
              await SharedPreferences.getInstance(),
            ),
            localStorageServiceProvider.overrideWithValue(storage),
            dailyChallengeRepositoryProvider.overrideWithValue(daily),
            provider.overrideWith(
              (ref) => BridgeMasterNotifier(ref, 1, challenge: challenge),
            ),
          ],
        );
        final notifier = scope.read(provider.notifier);
        notifier.addMember('a_left', 'a_right');
        finishBridge(notifier, 8);
        await waitForSave(scope, 1);
        expect(scope.read(provider).isSolved, isTrue);
        expect(scope.read(provider).completionError, isNull);
        scope.dispose();
      }
      expect(daily.calls, 0);
    },
  );
}
