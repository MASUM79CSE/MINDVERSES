import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/shared/services/scoring_framework.dart';

void main() {
  group('ScoringFramework Tests', () {
    test('evaluateMoveBased evaluates 3 stars on perfect efficiency and no hints', () {
      final result = ScoringFramework.evaluateMoveBased(
        isSolved: true,
        movesTaken: 8,
        targetMoves: 10,
        hintsUsed: 0,
      );
      expect(result.starsEarned, 3);
      expect(result.star1Completed, isTrue);
      expect(result.star2Efficiency, isTrue);
      expect(result.star3Mastery, isTrue);
    });

    test('evaluateMoveBased evaluates 2 stars when moves exceed target or hint used', () {
      final overMoves = ScoringFramework.evaluateMoveBased(
        isSolved: true,
        movesTaken: 12,
        targetMoves: 10,
        hintsUsed: 0,
      );
      expect(overMoves.starsEarned, 2);
      expect(overMoves.star1Completed, isTrue);
      expect(overMoves.star2Efficiency, isFalse);
      expect(overMoves.star3Mastery, isTrue);

      final hintUsed = ScoringFramework.evaluateMoveBased(
        isSolved: true,
        movesTaken: 8,
        targetMoves: 10,
        hintsUsed: 1,
      );
      expect(hintUsed.starsEarned, 2);
      expect(hintUsed.star1Completed, isTrue);
      expect(hintUsed.star2Efficiency, isTrue);
      expect(hintUsed.star3Mastery, isFalse);
    });

    test('evaluateMoveBased evaluates 0 stars when unsolved', () {
      final unsolved = ScoringFramework.evaluateMoveBased(
        isSolved: false,
        movesTaken: 5,
        targetMoves: 10,
        hintsUsed: 0,
      );
      expect(unsolved.starsEarned, 0);
      expect(unsolved.star1Completed, isFalse);
    });

    test('evaluateBridgeMaster evaluates bridge completion, budget, and peak stress', () {
      final perfect = ScoringFramework.evaluateBridgeMaster(
        vehicleReachedGoal: true,
        costSpent: 80,
        targetBudget: 100,
        peakStressRatio: 0.65,
      );
      expect(perfect.starsEarned, 3);

      final overBudget = ScoringFramework.evaluateBridgeMaster(
        vehicleReachedGoal: true,
        costSpent: 120,
        targetBudget: 100,
        peakStressRatio: 0.65,
      );
      expect(overBudget.starsEarned, 2);

      final failed = ScoringFramework.evaluateBridgeMaster(
        vehicleReachedGoal: false,
        costSpent: 80,
        targetBudget: 100,
        peakStressRatio: 1.0,
      );
      expect(failed.starsEarned, 0);
    });
  });
}
