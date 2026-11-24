import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/coin_transaction.dart';
import '../../../../shared/models/daily_challenge.dart';
import '../../../../shared/models/level_result.dart';
import '../../../../shared/providers/shared_providers.dart';
import '../../../../shared/services/scoring_framework.dart';
import '../../../../shared/services/xp_service.dart';
import '../../domain/memory_board.dart';
import '../../domain/memory_matrix_level_factory.dart';
import 'memory_matrix_state.dart';

class MemoryMatrixNotifier extends StateNotifier<MemoryMatrixState> {
  final Ref _ref;
  final DailyChallenge? challenge;
  String? _completionId;
  ({int xp, int coins})? _completionReward;

  MemoryMatrixNotifier(this._ref, int initialLevelNumber, {this.challenge})
    : super(_createInitialState(initialLevelNumber));

  static MemoryMatrixState _createInitialState(int levelNumber) {
    final level = MemoryMatrixLevelFactory.build(levelNumber);
    return MemoryMatrixState(
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
    _completionReward = null;
    state = _createInitialState(levelNumber);
  }

  void startRecallPhase() {
    if (state.isCompleted ||
        state.isPaused ||
        state.board.phase != MemoryPhase.memorize) {
      return;
    }
    _ref.read(feedbackServiceProvider).click();
    final updatedBoard = state.board.copyWith(phase: MemoryPhase.recall);
    state = state.copyWith(board: updatedBoard);
  }

  void tapCell(int x, int y) {
    if (state.isCompleted ||
        state.isPaused ||
        state.board.phase != MemoryPhase.recall) {
      return;
    }

    _ref.read(feedbackServiceProvider).lightImpact();

    final currentInput = List<(int, int)>.from(state.board.playerInput)
      ..add((x, y));
    final expectedIndex = currentInput.length - 1;

    // Validate correct tile in sequence
    if (expectedIndex < state.board.sequence.length) {
      final expected = state.board.sequence[expectedIndex];
      if (expected != (x, y)) {
        // Wrong cell tapped -> failure
        _ref.read(feedbackServiceProvider).heavyImpact();
        final failedBoard = state.board.copyWith(
          playerInput: currentInput,
          phase: MemoryPhase.failure,
        );
        state = state.copyWith(board: failedBoard, isFailed: true);
        return;
      }
    }

    final nextMoveCount = state.moveCount + 1;

    if (currentInput.length >= state.board.sequence.length) {
      // Completed sequence successfully!
      final solvedBoard = state.board.copyWith(
        playerInput: currentInput,
        phase: MemoryPhase.success,
        isSolved: true,
      );
      _completionId = const Uuid().v4();
      _completionReward = null;
      state = state.copyWith(
        board: solvedBoard,
        moveCount: nextMoveCount,
        isSavingCompletion: true,
      );
      unawaited(_handleLevelComplete());
    } else {
      final updatedBoard = state.board.copyWith(playerInput: currentInput);
      state = state.copyWith(board: updatedBoard, moveCount: nextMoveCount);
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
          {'gameId': 'memory_matrix', 'levelNumber': attempt.levelNumber},
        );
        if (!claimed) return _completionReward ?? (xp: 0, coins: 0);

        final previous = await levels.getLevelResultInTransaction(
          transaction,
          'memory_matrix',
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
            gameId: 'memory_matrix',
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
        if (attempt.levelNumber < MemoryMatrixLevelFactory.levelCount) {
          await levels.unlockNextLevelInTransaction(
            transaction,
            'memory_matrix',
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
            referenceId: 'memory_matrix:${attempt.levelNumber}',
          );
          if (awarded) levelCoins = 25;
        }
        final unlocked = await achievements.recordLevelCompletionInTransaction(
          transaction,
          gameId: 'memory_matrix',
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
                daily.gameId == 'memory_matrix' &&
                daily.levelNumber == attempt.levelNumber
            ? await _ref
                  .read(dailyChallengeRepositoryProvider)
                  .completeInTransaction(transaction, daily)
            : null;
        _completionReward = (
          xp: xp + achievementReward.xp + (dailyReward?.xpEarned ?? 0),
          coins:
              levelCoins +
              achievementReward.coins +
              (dailyReward?.coinsEarned ?? 0),
        );
        return _completionReward!;
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

  void reset() {
    if (state.isCompletionPending) return;
    _completionId = null;
    _completionReward = null;
    _ref.read(feedbackServiceProvider).click();
    loadLevel(state.levelNumber);
  }

  void togglePause() {
    if (state.isCompletionPending) return;
    _ref.read(feedbackServiceProvider).click();
    state = state.copyWith(isPaused: !state.isPaused);
  }
}

final memoryMatrixNotifierProvider =
    StateNotifierProvider.family<MemoryMatrixNotifier, MemoryMatrixState, int>((
      ref,
      levelNumber,
    ) {
      return MemoryMatrixNotifier(ref, levelNumber);
    });
