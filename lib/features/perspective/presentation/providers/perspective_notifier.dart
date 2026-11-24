import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/perspective_level_factory.dart';
import 'perspective_state.dart';

class PerspectiveNotifier extends StateNotifier<PerspectiveState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;
  ({int xp, int coins})? _completionReward;

  PerspectiveNotifier(this._ref, int initialLevelNumber, {this.challenge})
      : super(_createInitialState(initialLevelNumber));

  static PerspectiveState _createInitialState(int levelNumber) {
    final level = PerspectiveLevelFactory.build(levelNumber);
    final firstShapeId = level.initialBoard.shapes.keys.first;
    return PerspectiveState(
      levelNumber: level.levelNumber,
      title: level.title,
      board: level.initialBoard,
      moveCount: 0,
      maxMoves: level.maxMoves,
      targetMoves: level.targetMoves,
      selectedShapeId: firstShapeId,
    );
  }

  void loadLevel(int levelNumber) {
    if (state.isSavingCompletion || state.completionError != null) return;
    _completionId = null;
    _completionReward = null;
    state = _createInitialState(levelNumber);
  }

  void selectShape(String shapeId) {
    if (state.isCompleted || state.isPaused || !state.board.shapes.containsKey(shapeId)) return;
    state = state.copyWith(selectedShapeId: shapeId);
  }

  void rotateShape(double deltaX, double deltaY) {
    if (state.isCompleted || state.isPaused) return;

    final shape = state.board.shapes[state.selectedShapeId];
    if (shape == null) return;

    _ref.read(feedbackServiceProvider).lightImpact();

    final updatedShape = shape.copyWith(
      angleX: shape.angleX + deltaX,
      angleY: shape.angleY + deltaY,
    );

    final updatedBoard = state.board.withShape(updatedShape);
    final nextMoveCount = state.moveCount + 1;

    if (updatedBoard.isSolved) {
      _completionId = const Uuid().v4();
      state = state.copyWith(
        board: updatedBoard,
        moveCount: nextMoveCount,
        isSavingCompletion: true,
      );
      unawaited(_handleLevelComplete());
    } else if (nextMoveCount >= state.maxMoves) {
      _ref.read(feedbackServiceProvider).heavyImpact();
      state = state.copyWith(
        board: updatedBoard,
        moveCount: nextMoveCount,
        isFailed: true,
      );
    } else {
      state = state.copyWith(
        board: updatedBoard,
        moveCount: nextMoveCount,
      );
    }
  }

  Future<void> _handleLevelComplete() async {
    final attempt = state;
    final completionId = _completionId!;
    final score = ScoringFramework.evaluateMoveBased(
      isSolved: true,
      movesTaken: attempt.moveCount,
      targetMoves: attempt.targetMoves,
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
          'gameId': 'perspective',
          'levelNumber': attempt.levelNumber,
        });
        if (!claimed) return _completionReward ?? (xp: 0, coins: 0);
        final previous = await levels.getLevelResultInTransaction(transaction, 'perspective', attempt.levelNumber);
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
          gameId: 'perspective',
          levelNumber: attempt.levelNumber,
          isUnlocked: true,
          isCompleted: true,
          star1Completed: score.star1Completed,
          star2Efficiency: score.star2Efficiency,
          star3Mastery: score.star3Mastery,
          starsEarned: score.starsEarned,
          bestMoveCount: attempt.moveCount,
          hintsUsedCount: 0,
          firstCompletedAt: now,
          lastPlayedAt: now,
        ));
        if (attempt.levelNumber < PerspectiveLevelFactory.levelCount) {
          await levels.unlockNextLevelInTransaction(transaction, 'perspective', attempt.levelNumber);
        }
        await profiles.updateProfileInTransaction(
          transaction,
          xpToAdd: xp,
          starsToAdd: result.starsEarned - (previous?.starsEarned ?? 0),
          levelsCompletedDelta: isFirstClear ? 1 : 0,
        );
        final firstThreeStars = score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3;
        var levelCoins = 0;
        if (firstThreeStars) {
          final awarded = await coins.recordTransactionInTransaction(
            transaction,
            type: CoinTransactionType.earnLevel3Star,
            amount: 25,
            referenceId: 'perspective:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'perspective',
          levelNumber: attempt.levelNumber,
          isFirstClear: isFirstClear,
          earnedThreeStarsForFirstTime: firstThreeStars,
          earnedNoHintForFirstTime: isFirstClear || previous!.hintsUsedCount > 0,
        );
        final achievementReward = await achievementRewards.grantInTransaction(transaction, unlocked);
        final daily = challenge;
        final dailyReward = daily != null && daily.gameId == 'perspective' && daily.levelNumber == attempt.levelNumber
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
    if (state.isSavingCompletion || state.completionError != null) return;
    _ref.read(feedbackServiceProvider).click();
    loadLevel(state.levelNumber);
  }

  void togglePause() {
    if (state.isCompleted) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

final perspectiveNotifierProvider =
    StateNotifierProvider.family<PerspectiveNotifier, PerspectiveState, int>((ref, levelNumber) {
  return PerspectiveNotifier(ref, levelNumber);
});
