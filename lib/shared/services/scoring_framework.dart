/// Pure domain calculation framework for evaluating three-star scoring criteria.
class ScoringFramework {
  ScoringFramework._();

  /// Evaluates move-based puzzle performance (e.g., Cube Logic, Maze Architect).
  static ({
    bool star1Completed,
    bool star2Efficiency,
    bool star3Mastery,
    int starsEarned,
  }) evaluateMoveBased({
    required bool isSolved,
    required int movesTaken,
    required int targetMoves,
    required int hintsUsed,
  }) {
    if (!isSolved) {
      return (
        star1Completed: false,
        star2Efficiency: false,
        star3Mastery: false,
        starsEarned: 0,
      );
    }

    const star1 = true;
    final star2 = movesTaken <= targetMoves;
    final star3 = hintsUsed == 0;

    int stars = 1;
    if (star2) stars++;
    if (star3) stars++;

    return (
      star1Completed: star1,
      star2Efficiency: star2,
      star3Mastery: star3,
      starsEarned: stars,
    );
  }

  /// Evaluates budget and structural stress performance (e.g., Bridge Master).
  static ({
    bool star1Completed,
    bool star2Efficiency,
    bool star3Mastery,
    int starsEarned,
  }) evaluateBridgeMaster({
    required bool vehicleReachedGoal,
    required int costSpent,
    required int targetBudget,
    required double peakStressRatio, // 0.0 to 1.0 (100% stress threshold)
  }) {
    if (!vehicleReachedGoal) {
      return (
        star1Completed: false,
        star2Efficiency: false,
        star3Mastery: false,
        starsEarned: 0,
      );
    }

    const star1 = true;
    final star2 = costSpent <= targetBudget;
    final star3 = peakStressRatio <= 0.70; // Kept peak member stress under 70%

    int stars = 1;
    if (star2) stars++;
    if (star3) stars++;

    return (
      star1Completed: star1,
      star2Efficiency: star2,
      star3Mastery: star3,
      starsEarned: stars,
    );
  }
}
