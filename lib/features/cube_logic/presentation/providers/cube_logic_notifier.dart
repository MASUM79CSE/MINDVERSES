import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/cube_board.dart';
import '../../domain/cube_energy_solver.dart';
import '../../domain/cube_level_factory.dart';
import 'cube_logic_state.dart';

class CubeLogicNotifier extends StateNotifier<CubeLogicState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;

  CubeLogicNotifier(this._ref, int initialLevelNumber, {this.challenge})
      : super(_createInitialState(initialLevelNumber));

  static CubeLogicState _createInitialState(int levelNumber) {
    final level = CubeLevelFactory.build(levelNumber);
    return CubeLogicState(
      levelNumber: level.levelNumber,
      title: level.title,
      board: level.initialBoard,
      moveCount: 0,
      maxMoves: level.maxMoves,
      targetMoves: level.targetMoves,
    );
  }

  void loadLevel(int levelNumber) {
    if (state.isSavingCompletion) return;
    _completionId = null;
    state = _createInitialState(levelNumber);
  }

  void rotateTile(int x, int y, int z) {
    if (state.isCompleted || state.isPaused) return;

    final tile = state.board.tileAt(x, y, z);
    if (tile == null || tile.isLocked || tile.connections.isEmpty) return;

    // Trigger light selection feedback
    _ref.read(feedbackServiceProvider).lightImpact();

    final nextRotation = (tile.rotation + 1) % 4;
    final updatedTile = tile.copyWith(rotation: nextRotation);
    final updatedBoard = state.board.withTile(updatedTile);
    final solvedBoard = CubeEnergySolver.solve(updatedBoard);

    final nextMoveCount = state.moveCount + 1;
    final history = List<CubeBoard>.from(state.history)..add(state.board);

    if (solvedBoard.isSolved) {
      _completionId = const Uuid().v4();
      state = state.copyWith(
        board: solvedBoard,
        moveCount: nextMoveCount,
        history: history,
        isSavingCompletion: true,
        clearHint: true,
      );
      _handleLevelComplete();
    } else if (nextMoveCount >= state.maxMoves) {
      _ref.read(feedbackServiceProvider).heavyImpact();
      state = state.copyWith(
        board: solvedBoard,
        moveCount: nextMoveCount,
        history: history,
        isFailed: true,
        clearHint: true,
      );
    } else {
      state = state.copyWith(
        board: solvedBoard,
        moveCount: nextMoveCount,
        history: history,
        clearHint: true,
      );
    }
  }

  Future<void> _handleLevelComplete() async {
    final attempt = state;
    final completionId = _completionId!;
    final storage = _ref.read(localStorageServiceProvider);
    final levels = _ref.read(levelProgressRepositoryProvider);
    final profiles = _ref.read(profileRepositoryProvider);
    final achievements = _ref.read(achievementRepositoryProvider);
    final coins = _ref.read(coinEconomyServiceProvider);
    final achievementRewards = _ref.read(achievementRewardServiceProvider);
    final score = ScoringFramework.evaluateMoveBased(
      isSolved: true,
      movesTaken: attempt.moveCount,
      targetMoves: attempt.targetMoves,
      hintsUsed: attempt.hintsUsedCount,
    );

    try {
      final reward = await storage.runInTransaction((transaction) async {
        final claimed = await transaction.claimIdempotencyKey('completion:$completionId', {
          'gameId': 'cube_logic',
          'levelNumber': attempt.levelNumber,
        });
        if (!claimed) return (xp: 0, coins: 0);
        final previous = await levels.getLevelResultInTransaction(transaction, 'cube_logic', attempt.levelNumber);
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
          gameId: 'cube_logic',
          levelNumber: attempt.levelNumber,
          isUnlocked: true,
          isCompleted: true,
          star1Completed: score.star1Completed,
          star2Efficiency: score.star2Efficiency,
          star3Mastery: score.star3Mastery,
          starsEarned: score.starsEarned,
          bestMoveCount: attempt.moveCount,
          hintsUsedCount: attempt.hintsUsedCount,
          firstCompletedAt: now,
          lastPlayedAt: now,
        ));
        if (attempt.levelNumber < 20) {
          await levels.unlockNextLevelInTransaction(transaction, 'cube_logic', attempt.levelNumber);
        }
        await profiles.updateProfileInTransaction(
          transaction,
          xpToAdd: xp,
          starsToAdd: result.starsEarned - (previous?.starsEarned ?? 0),
          levelsCompletedDelta: isFirstClear ? 1 : 0,
        );
        var levelCoins = 0;
        if (score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3) {
          final awarded = await coins.recordTransactionInTransaction(
            transaction,
            type: CoinTransactionType.earnLevel3Star,
            amount: 25,
            referenceId: 'cube_logic:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'cube_logic',
          levelNumber: attempt.levelNumber,
          isFirstClear: isFirstClear,
          earnedThreeStarsForFirstTime: score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3,
          earnedNoHintForFirstTime: attempt.hintsUsedCount == 0 && (isFirstClear || previous!.hintsUsedCount > 0),
        );
        final achievementReward = await achievementRewards.grantInTransaction(transaction, unlocked);
        final daily = challenge;
        final dailyReward = daily != null && daily.gameId == 'cube_logic' && daily.levelNumber == attempt.levelNumber
            ? await _ref.read(dailyChallengeRepositoryProvider).completeInTransaction(transaction, daily)
            : null;
        return (
          xp: xp + achievementReward.xp + (dailyReward?.xpEarned ?? 0),
          coins: levelCoins + achievementReward.coins + (dailyReward?.coinsEarned ?? 0),
        );
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
    _handleLevelComplete();
  }

  void undo() {
    if (!state.canUndo) return;
    _ref.read(feedbackServiceProvider).click();

    final history = List<CubeBoard>.from(state.history);
    final previousBoard = history.removeLast();

    state = state.copyWith(
      board: previousBoard,
      moveCount: (state.moveCount - 1).clamp(0, state.maxMoves),
      history: history,
      clearHint: true,
    );
  }

  void reset() {
    _ref.read(feedbackServiceProvider).click();
    loadLevel(state.levelNumber);
  }

  void useHint() {
    if (state.isCompleted) return;
    _ref.read(feedbackServiceProvider).click();
    final hint = CubeEnergySolver.findHint(state.board);
    if (hint != null) {
      state = state.copyWith(
        hintTile: hint,
        hintsUsedCount: state.hintsUsedCount + 1,
      );
    }
  }

  void togglePause() {
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

/// Family provider for Cube Logic game state keyed by level number.
final cubeLogicNotifierProvider =
    StateNotifierProvider.family<CubeLogicNotifier, CubeLogicState, int>((ref, levelNumber) {
  return CubeLogicNotifier(ref, levelNumber);
});
