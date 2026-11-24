import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/maze_board.dart';
import '../../domain/maze_level_factory.dart';
import '../../domain/maze_pathfinding_solver.dart';
import 'maze_architect_state.dart';

class MazeArchitectNotifier extends StateNotifier<MazeArchitectState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;

  MazeArchitectNotifier(this._ref, int initialLevelNumber, {this.challenge})
    : super(_createInitialState(initialLevelNumber));

  static MazeArchitectState _createInitialState(int levelNumber) {
    final level = MazeLevelFactory.build(levelNumber);
    return MazeArchitectState(
      levelNumber: level.levelNumber,
      title: level.title,
      board: level.initialBoard,
      moveCount: 0,
      maxMoves: level.maxMoves,
      targetMoves: level.targetMoves,
    );
  }

  void loadLevel(int levelNumber) {
    if (state.isCompletionPending) return;
    _completionId = null;
    state = _createInitialState(levelNumber);
  }

  void tapTile(int x, int y) {
    if (state.isCompleted || state.isPaused) return;

    final tile = state.board.tileAt(x, y);
    if (tile == null || tile.isLocked) return;

    if (state.selectedCoord == null) {
      _ref.read(feedbackServiceProvider).lightImpact();
      state = state.copyWith(selectedCoord: (x, y));
    } else {
      final (sX, sY) = state.selectedCoord!;
      if (sX == x && sY == y) {
        _ref.read(feedbackServiceProvider).click();
        state = state.copyWith(clearSelected: true);
        return;
      }

      // Swap tiles
      _ref.read(feedbackServiceProvider).mediumImpact();
      final updatedBoard = state.board.swapTiles(sX, sY, x, y);
      final isSolved = MazePathfindingSolver.hasValidPath(updatedBoard);
      final nextMoveCount = state.moveCount + 1;
      final history = List<MazeBoard>.from(state.history)..add(state.board);

      if (isSolved) {
        _completionId = const Uuid().v4();
        state = state.copyWith(
          board: updatedBoard,
          moveCount: nextMoveCount,
          history: history,
          isSavingCompletion: true,
          clearSelected: true,
        );
        unawaited(_handleLevelComplete());
      } else if (nextMoveCount >= state.maxMoves) {
        _ref.read(feedbackServiceProvider).heavyImpact();
        state = state.copyWith(
          board: updatedBoard,
          moveCount: nextMoveCount,
          history: history,
          isFailed: true,
          clearSelected: true,
        );
      } else {
        state = state.copyWith(
          board: updatedBoard,
          moveCount: nextMoveCount,
          history: history,
          clearSelected: true,
        );
      }
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
        final claimed = await transaction.claimIdempotencyKey(
          'completion:$completionId',
          {'gameId': 'maze_architect', 'levelNumber': attempt.levelNumber},
        );
        if (!claimed) return (xp: 0, coins: 0);
        final previous = await levels.getLevelResultInTransaction(
          transaction,
          'maze_architect',
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
            gameId: 'maze_architect',
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
          ),
        );
        if (attempt.levelNumber < 15) {
          await levels.unlockNextLevelInTransaction(
            transaction,
            'maze_architect',
            attempt.levelNumber,
          );
        }
        await profiles.updateProfileInTransaction(
          transaction,
          xpToAdd: xp,
          starsToAdd: result.starsEarned - (previous?.starsEarned ?? 0),
          levelsCompletedDelta: isFirstClear ? 1 : 0,
        );
        final earnedThreeStars =
            score.starsEarned == 3 && (previous?.starsEarned ?? 0) < 3;
        var levelCoins = 0;
        if (earnedThreeStars) {
          final awarded = await coins.recordTransactionInTransaction(
            transaction,
            type: CoinTransactionType.earnLevel3Star,
            amount: 25,
            referenceId: 'maze_architect:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'maze_architect',
          levelNumber: attempt.levelNumber,
          isFirstClear: isFirstClear,
          earnedThreeStarsForFirstTime: earnedThreeStars,
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
                daily.gameId == 'maze_architect' &&
                daily.levelNumber == attempt.levelNumber
            ? await _ref
                  .read(dailyChallengeRepositoryProvider)
                  .completeInTransaction(transaction, daily)
            : null;
        return (
          xp: xp + achievementReward.xp + (dailyReward?.xpEarned ?? 0),
          coins:
              levelCoins +
              achievementReward.coins +
              (dailyReward?.coinsEarned ?? 0),
        );
      });
      levels.invalidateCache();
      profiles.invalidateCache();
      achievements.invalidateCache();
      _ref.invalidate(levelResultsProvider);
      if (!mounted) return;
      _ref.invalidate(playerProfileNotifierProvider);
      _ref.invalidate(achievementsListProvider);
      if (challenge != null) {
        _ref.invalidate(dailyChallengeStatusProvider(challenge!.dateString));
      }
      unawaited(
        _ref.read(feedbackServiceProvider).success().catchError((_) {}),
      );
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
    state = state.copyWith(
      isSavingCompletion: true,
      clearCompletionError: true,
    );
    unawaited(_handleLevelComplete());
  }

  void undo() {
    if (!state.canUndo) return;
    _ref.read(feedbackServiceProvider).click();

    final history = List<MazeBoard>.from(state.history);
    final previousBoard = history.removeLast();

    state = state.copyWith(
      board: previousBoard,
      moveCount: (state.moveCount - 1).clamp(0, state.maxMoves),
      history: history,
      clearSelected: true,
    );
  }

  void reset() {
    if (state.isCompletionPending) return;
    _ref.read(feedbackServiceProvider).click();
    loadLevel(state.levelNumber);
  }

  void togglePause() {
    if (state.isCompleted) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

/// Family provider for Maze Architect stateNotifier.
final mazeArchitectNotifierProvider =
    StateNotifierProvider.family<
      MazeArchitectNotifier,
      MazeArchitectState,
      int
    >((ref, levelNumber) {
      return MazeArchitectNotifier(ref, levelNumber);
    });
