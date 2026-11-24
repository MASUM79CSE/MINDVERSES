import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/kingdom_tile.dart';
import '../../domain/tiny_kingdom_level_factory.dart';
import 'tiny_kingdom_state.dart';

class TinyKingdomNotifier extends StateNotifier<TinyKingdomState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;
  ({int xp, int coins})? _completionReward;

  TinyKingdomNotifier(this._ref, int initialLevelNumber, {this.challenge})
      : super(_createInitialState(initialLevelNumber));

  static TinyKingdomState _createInitialState(int levelNumber) {
    final level = TinyKingdomLevelFactory.build(levelNumber);
    return TinyKingdomState(
      levelNumber: level.levelNumber,
      title: level.title,
      board: level.initialBoard,
      turnCount: 0,
      maxTurns: level.maxTurns,
      targetTurns: level.targetTurns,
    );
  }

  void loadLevel(int levelNumber) {
    if (state.hasPendingCompletion) return;
    _completionId = null;
    _completionReward = null;
    state = _createInitialState(levelNumber);
  }

  void selectBuilding(BuildingType type) {
    if (state.isCompleted || state.isPaused) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(selectedBuilding: type);
  }

  void placeBuilding(int x, int y) {
    if (state.isCompleted || state.isPaused) return;

    final tile = state.board.tileAt(x, y);
    if (tile == null || tile.isLocked || tile.buildingType != BuildingType.empty) return;

    _ref.read(feedbackServiceProvider).mediumImpact();

    final updatedTile = tile.copyWith(buildingType: state.selectedBuilding);
    final updatedBoard = state.board.withTile(updatedTile);
    final nextTurnCount = state.turnCount + 1;

    if (updatedBoard.isSolved) {
      _completionId = const Uuid().v4();
      state = state.copyWith(
        board: updatedBoard,
        turnCount: nextTurnCount,
        isSavingCompletion: true,
      );
      unawaited(_handleLevelComplete());
    } else if (nextTurnCount >= state.maxTurns) {
      _ref.read(feedbackServiceProvider).heavyImpact();
      state = state.copyWith(
        board: updatedBoard,
        turnCount: nextTurnCount,
        isFailed: true,
      );
    } else {
      state = state.copyWith(
        board: updatedBoard,
        turnCount: nextTurnCount,
      );
    }
  }

  Future<void> _handleLevelComplete() async {
    final attempt = state;
    final completionId = _completionId!;
    final score = ScoringFramework.evaluateMoveBased(
      isSolved: true,
      movesTaken: attempt.turnCount,
      targetMoves: attempt.targetTurns,
      hintsUsed: 0,
    );

    try {
      final storage = _ref.read(localStorageServiceProvider);
      final levels = _ref.read(levelProgressRepositoryProvider);
      final profiles = _ref.read(profileRepositoryProvider);
      final achievements = _ref.read(achievementRepositoryProvider);
      final coins = _ref.read(coinEconomyServiceProvider);
      final achievementRewards = _ref.read(achievementRewardServiceProvider);
      final reward = await storage.runInTransaction((transaction) async {
        final claimed = await transaction.claimIdempotencyKey('completion:$completionId', {
          'gameId': 'tiny_kingdom',
          'levelNumber': attempt.levelNumber,
        });
        if (!claimed) return _completionReward ?? (xp: 0, coins: 0);
        final previous = await levels.getLevelResultInTransaction(transaction, 'tiny_kingdom', attempt.levelNumber);
        final isFirstClear = previous?.isCompleted != true;
        final xp = XpService.calculateIncrementalXpReward(
          isFirstClear: isFirstClear,
          star2Efficiency: score.star2Efficiency,
          star3Mastery: score.star3Mastery,
          previouslyEarnedStar2: previous?.star2Efficiency ?? false,
          previouslyEarnedStar3: previous?.star3Mastery ?? false,
        );
        final now = DateTime.now().toUtc();
        final result = await levels.saveLevelResultInTransaction(transaction, LevelResult(
          gameId: 'tiny_kingdom',
          levelNumber: attempt.levelNumber,
          isUnlocked: true,
          isCompleted: true,
          star1Completed: score.star1Completed,
          star2Efficiency: score.star2Efficiency,
          star3Mastery: score.star3Mastery,
          starsEarned: score.starsEarned,
          bestMoveCount: attempt.turnCount,
          hintsUsedCount: 0,
          firstCompletedAt: now,
          lastPlayedAt: now,
        ));
        if (attempt.levelNumber < TinyKingdomLevelFactory.levelCount) {
          await levels.unlockNextLevelInTransaction(transaction, 'tiny_kingdom', attempt.levelNumber);
        }
        await profiles.updateProfileInTransaction(
          transaction,
          xpToAdd: xp,
          starsToAdd: result.starsEarned - (previous?.starsEarned ?? 0),
          levelsCompletedDelta: isFirstClear ? 1 : 0,
        );
        final earnedThreeStarsForFirstTime = score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3;
        var levelCoins = 0;
        if (earnedThreeStarsForFirstTime) {
          final awarded = await coins.recordTransactionInTransaction(
            transaction,
            type: CoinTransactionType.earnLevel3Star,
            amount: 25,
            referenceId: 'tiny_kingdom:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'tiny_kingdom',
          levelNumber: attempt.levelNumber,
          isFirstClear: isFirstClear,
          earnedThreeStarsForFirstTime: earnedThreeStarsForFirstTime,
          earnedNoHintForFirstTime: isFirstClear || previous!.hintsUsedCount > 0,
        );
        final achievementReward = await achievementRewards.grantInTransaction(transaction, unlocked);
        final daily = challenge;
        final dailyReward = daily != null && daily.gameId == 'tiny_kingdom' && daily.levelNumber == attempt.levelNumber
            ? await _ref.read(dailyChallengeRepositoryProvider).completeInTransaction(transaction, daily)
            : null;
        final reward = (
          xp: xp + achievementReward.xp + (dailyReward?.xpEarned ?? 0),
          coins: levelCoins + achievementReward.coins + (dailyReward?.coinsEarned ?? 0),
        );
        _completionReward = reward;
        return reward;
      });
      levels.invalidateCache();
      profiles.invalidateCache();
      achievements.invalidateCache();
      _ref.invalidate(levelResultsProvider);
      if (!mounted) return;
      _ref.invalidate(playerProfileNotifierProvider);
      _ref.invalidate(achievementsListProvider);
      if (challenge != null) _ref.invalidate(dailyChallengeStatusProvider(challenge!.dateString));
      unawaited(_ref.read(feedbackServiceProvider).success().catchError((_) {}));
      state = state.copyWith(
        isSavingCompletion: false,
        isSolved: true,
        earnedStars: score.starsEarned,
        earnedXp: reward.xp,
        earnedCoins: reward.coins,
        clearCompletionError: true,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isSavingCompletion: false,
        completionError: 'Could not save your result. Please try again.',
      );
    }
  }

  void retryCompletion() {
    if (state.completionError == null || state.isSavingCompletion) return;
    state = state.copyWith(isSavingCompletion: true, clearCompletionError: true);
    unawaited(_handleLevelComplete());
  }

  void reset() {
    if (state.hasPendingCompletion) return;
    _ref.read(feedbackServiceProvider).click();
    loadLevel(state.levelNumber);
  }

  void togglePause() {
    if (state.isCompleted) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

final tinyKingdomNotifierProvider =
    StateNotifierProvider.family<TinyKingdomNotifier, TinyKingdomState, int>((ref, levelNumber) {
  return TinyKingdomNotifier(ref, levelNumber);
});
