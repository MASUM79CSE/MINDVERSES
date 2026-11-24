import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/bridge_joint.dart';
import '../../domain/bridge_level_factory.dart';
import '../../domain/bridge_member.dart';
import '../../domain/bridge_physics_solver.dart';
import 'bridge_master_state.dart';

class BridgeMasterNotifier extends StateNotifier<BridgeMasterState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;

  BridgeMasterNotifier(this._ref, int initialLevelNumber, {this.challenge})
    : super(_createInitialState(initialLevelNumber));

  static BridgeMasterState _createInitialState(int levelNumber) {
    final level = BridgeLevelFactory.build(levelNumber);
    return BridgeMasterState(
      levelNumber: level.levelNumber,
      title: level.title,
      budget: level.budget,
      targetBudget: level.targetBudget,
      gapWidth: level.gapWidth,
      vehicleWeight: level.vehicleWeight,
      joints: Map.from(level.anchors),
      members: const [],
    );
  }

  void loadLevel(int levelNumber) {
    if (state.isCompletionPending) return;
    _completionId = null;
    state = _createInitialState(levelNumber);
  }

  void selectMaterial(BridgeMaterialType type) {
    if (state.isCompletionPending || state.isSimulating || state.isPaused) {
      return;
    }
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(selectedMaterial: type);
  }

  String addJoint(double x, double y) {
    // Snap to 1-meter grid
    final snappedX = (x / 1.0).roundToDouble();
    final snappedY = (y / 1.0).roundToDouble();
    final id = 'j_${snappedX.toInt()}_${snappedY.toInt()}';

    if (state.isCompletionPending || state.isSimulating || state.isPaused) {
      return id;
    }
    if (state.joints.containsKey(id)) {
      return id;
    }

    final newJoint = BridgeJoint(id: id, x: snappedX, y: snappedY);
    final updatedJoints = Map<String, BridgeJoint>.from(state.joints)
      ..[id] = newJoint;
    state = state.copyWith(joints: updatedJoints);
    return id;
  }

  void addMember(String jAId, String jBId) {
    if (jAId == jBId ||
        state.isSimulating ||
        state.isCompletionPending ||
        state.isPaused) {
      return;
    }

    // Check if member already exists
    for (final m in state.members) {
      if ((m.jointAId == jAId && m.jointBId == jBId) ||
          (m.jointAId == jBId && m.jointBId == jAId)) {
        return;
      }
    }

    final id = 'm_${jAId}_$jBId';
    final newMember = BridgeMember(
      id: id,
      jointAId: jAId,
      jointBId: jBId,
      materialType: state.selectedMaterial,
    );

    final updatedMembers = List<BridgeMember>.from(state.members)
      ..add(newMember);
    final tempState = state.copyWith(members: updatedMembers);

    if (tempState.isOverBudget) {
      _ref.read(feedbackServiceProvider).mediumImpact();
    } else {
      _ref.read(feedbackServiceProvider).lightImpact();
    }

    state = tempState;
  }

  void removeMember(String memberId) {
    if (state.isSimulating || state.isCompletionPending || state.isPaused) {
      return;
    }
    _ref.read(feedbackServiceProvider).click();
    final updatedMembers = state.members
        .where((m) => m.id != memberId)
        .toList();
    state = state.copyWith(members: updatedMembers);
  }

  void clearAll() {
    if (state.isCompletionPending) return;
    _completionId = null;
    _ref.read(feedbackServiceProvider).click();
    final level = BridgeLevelFactory.build(state.levelNumber);
    state = state.copyWith(
      joints: Map.from(level.anchors),
      members: const [],
      isSimulating: false,
      vehicleX: 0.0,
      peakStressRatio: 0.0,
      isSolved: false,
      isFailed: false,
      isPaused: false,
      earnedStars: 0,
      earnedXp: 0,
      earnedCoins: 0,
    );
  }

  void startSimulation() {
    if (state.members.isEmpty ||
        state.isSimulating ||
        state.isCompletionPending ||
        state.isPaused) {
      return;
    }
    _completionId = null;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(
      isSimulating: true,
      vehicleX: 0.0,
      peakStressRatio: 0.0,
      isSolved: false,
      isFailed: false,
    );
  }

  void stepSimulation(double deltaX) {
    if (!state.isSimulating ||
        state.isCompleted ||
        state.isCompletionPending ||
        state.isPaused) {
      return;
    }

    final nextVehicleX = state.vehicleX + deltaX;
    final evaluationX = nextVehicleX.clamp(0.0, state.gapWidth);
    final physResult = BridgePhysicsSolver.evaluate(
      joints: state.joints,
      members: state.members,
      vehicleX: evaluationX,
      vehicleWeight: state.vehicleWeight,
    );

    final maxStress = math.max(
      state.peakStressRatio,
      physResult.peakStressRatio,
    );

    if (physResult.isCollapsed) {
      _ref.read(feedbackServiceProvider).heavyImpact();
      state = state.copyWith(
        members: physResult.members,
        vehicleX: nextVehicleX,
        peakStressRatio: maxStress,
        isSimulating: false,
        isFailed: true,
      );
    } else if (nextVehicleX >= state.gapWidth) {
      _completionId = const Uuid().v4();
      state = state.copyWith(
        members: physResult.members,
        vehicleX: state.gapWidth,
        peakStressRatio: maxStress,
        isSimulating: false,
        isSavingCompletion: true,
      );
      unawaited(_handleLevelComplete());
    } else {
      state = state.copyWith(
        members: physResult.members,
        vehicleX: nextVehicleX,
        peakStressRatio: maxStress,
      );
    }
  }

  void stopSimulation() {
    if (state.isCompletionPending) return;
    _completionId = null;
    _ref.read(feedbackServiceProvider).click();
    final restoredMembers = state.members
        .map((m) => m.copyWith(stressRatio: 0.0, isSnapped: false))
        .toList();
    state = state.copyWith(
      isSimulating: false,
      vehicleX: 0.0,
      members: restoredMembers,
      peakStressRatio: 0.0,
      isSolved: false,
      isFailed: false,
      earnedStars: 0,
      earnedXp: 0,
      earnedCoins: 0,
    );
  }

  Future<void> _handleLevelComplete() async {
    final attempt = state;
    final completionId = _completionId!;
    final score = ScoringFramework.evaluateBridgeMaster(
      vehicleReachedGoal: true,
      costSpent: attempt.totalCost,
      targetBudget: attempt.targetBudget,
      peakStressRatio: attempt.peakStressRatio,
    );
    ({int xp, int coins}) reward;
    late void Function() invalidateCaches;
    try {
      final storage = _ref.read(localStorageServiceProvider);
      final levels = _ref.read(levelProgressRepositoryProvider);
      final profiles = _ref.read(profileRepositoryProvider);
      final achievements = _ref.read(achievementRepositoryProvider);
      final coins = _ref.read(coinEconomyServiceProvider);
      final achievementRewards = _ref.read(achievementRewardServiceProvider);
      final dailyRepository = challenge == null
          ? null
          : _ref.read(dailyChallengeRepositoryProvider);
      invalidateCaches = () {
        levels.invalidateCache();
        profiles.invalidateCache();
        achievements.invalidateCache();
        _ref.invalidate(levelResultsProvider);
      };
      reward = await storage.runInTransaction((transaction) async {
        final claimed = await transaction.claimIdempotencyKey(
          'completion:$completionId',
          {'gameId': 'bridge_master', 'levelNumber': attempt.levelNumber},
        );
        if (!claimed) return (xp: 0, coins: 0);
        final previous = await levels.getLevelResultInTransaction(
          transaction,
          'bridge_master',
          attempt.levelNumber,
        );
        final isFirstClear = previous?.isCompleted != true;
        final xp = XpService.calculateIncrementalXpReward(
          isFirstClear: isFirstClear,
          star2Efficiency: score.star2Efficiency,
          star3Mastery: score.star3Mastery,
          previouslyEarnedStar2: previous?.star2Efficiency ?? false,
          previouslyEarnedStar3: previous?.star3Mastery ?? false,
        );
        final now = DateTime.now().toUtc();
        final result = await levels.saveLevelResultInTransaction(
          transaction,
          LevelResult(
            gameId: 'bridge_master',
            levelNumber: attempt.levelNumber,
            isUnlocked: true,
            isCompleted: true,
            star1Completed: score.star1Completed,
            star2Efficiency: score.star2Efficiency,
            star3Mastery: score.star3Mastery,
            starsEarned: score.starsEarned,
            bestMoveCount: attempt.totalCost,
            hintsUsedCount: 0,
            firstCompletedAt: now,
            lastPlayedAt: now,
          ),
        );
        if (attempt.levelNumber < 15) {
          await levels.unlockNextLevelInTransaction(
            transaction,
            'bridge_master',
            attempt.levelNumber,
          );
        }
        await profiles.updateProfileInTransaction(
          transaction,
          xpToAdd: xp,
          starsToAdd: result.starsEarned - (previous?.starsEarned ?? 0),
          levelsCompletedDelta: isFirstClear ? 1 : 0,
        );
        final firstThreeStars =
            score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3;
        var levelCoins = 0;
        if (firstThreeStars) {
          final awarded = await coins.recordTransactionInTransaction(
            transaction,
            type: CoinTransactionType.earnLevel3Star,
            amount: 25,
            referenceId: 'bridge_master:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'bridge_master',
          levelNumber: attempt.levelNumber,
          isFirstClear: isFirstClear,
          earnedThreeStarsForFirstTime: firstThreeStars,
          earnedNoHintForFirstTime:
              isFirstClear || previous!.hintsUsedCount > 0,
        );
        final achievementReward = await achievementRewards.grantInTransaction(
          transaction,
          unlocked,
        );
        final daily = challenge;
        final dailyReward =
            daily != null &&
                daily.gameId == 'bridge_master' &&
                daily.levelNumber == attempt.levelNumber
            ? await dailyRepository!.completeInTransaction(transaction, daily)
            : null;
        return (
          xp: xp + achievementReward.xp + (dailyReward?.xpEarned ?? 0),
          coins:
              levelCoins +
              achievementReward.coins +
              (dailyReward?.coinsEarned ?? 0),
        );
      });
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSavingCompletion: false,
        completionError: 'Could not save your result. Please try again.',
      );
      return;
    }
    invalidateCaches();
    if (!mounted) return;
    _ref.invalidate(playerProfileNotifierProvider);
    _ref.invalidate(achievementsListProvider);
    if (challenge != null) {
      _ref.invalidate(dailyChallengeStatusProvider(challenge!.dateString));
    }
    state = state.copyWith(
      isSavingCompletion: false,
      isSolved: true,
      earnedStars: score.starsEarned,
      earnedXp: reward.xp,
      earnedCoins: reward.coins,
      clearCompletionError: true,
    );
    unawaited(_ref.read(feedbackServiceProvider).success().catchError((_) {}));
  }

  void retryCompletion() {
    if (state.completionError == null || state.isSavingCompletion) return;
    state = state.copyWith(
      isSavingCompletion: true,
      clearCompletionError: true,
    );
    unawaited(_handleLevelComplete());
  }

  void togglePause() {
    if (state.isCompletionPending) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

/// Family provider for Bridge Master stateNotifier.
final bridgeMasterNotifierProvider =
    StateNotifierProvider.family<BridgeMasterNotifier, BridgeMasterState, int>((
      ref,
      levelNumber,
    ) {
      return BridgeMasterNotifier(ref, levelNumber);
    });
