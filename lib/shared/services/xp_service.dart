import 'dart:math' as math;

/// Domain calculation service for player leveling, XP progression, and level rewards.
class XpService {
  XpService._();

  /// Calculates cumulative XP required to reach level [level].
  /// Formula: XP = 150 * level^1.65 (rounded to nearest integer).
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    return (150 * math.pow(level, 1.65)).round();
  }

  /// Calculates current player level given [totalXp].
  static int calculateLevelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;
    int level = 1;
    while (xpRequiredForLevel(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  /// Returns current XP progression metrics within the current level.
  /// Returns (currentLevel, currentLevelProgressXp, xpNeededForNextLevel).
  static ({int level, int currentXpInLevel, int xpForNextLevel}) getLevelProgress(int totalXp) {
    final level = calculateLevelFromXp(totalXp);
    final currentLevelBaseXp = xpRequiredForLevel(level);
    final nextLevelBaseXp = xpRequiredForLevel(level + 1);

    final currentXpInLevel = totalXp - currentLevelBaseXp;
    final xpForNextLevel = nextLevelBaseXp - currentLevelBaseXp;

    return (
      level: level,
      currentXpInLevel: currentXpInLevel,
      xpForNextLevel: xpForNextLevel,
    );
  }

  /// Calculates XP awarded for completing a level given star achievements.
  /// [isFirstClear]: whether the player is completing this level for the first time.
  static int calculateXpReward({
    required bool isFirstClear,
    required bool star1Completed,
    required bool star2Efficiency,
    required bool star3Mastery,
  }) {
    if (!star1Completed) return 0;

    if (!isFirstClear) {
      return 10; // Flat anti-grind replay XP
    }

    int xp = 100; // Base completion XP
    if (star2Efficiency) xp += 50;
    if (star3Mastery) xp += 50;

    return xp;
  }

  /// Awards base/replay XP plus bonuses only for stars earned on this attempt.
  static int calculateIncrementalXpReward({
    required bool isFirstClear,
    required bool star2Efficiency,
    required bool star3Mastery,
    required bool previouslyEarnedStar2,
    required bool previouslyEarnedStar3,
  }) {
    var xp = isFirstClear ? 100 : 10;
    if (star2Efficiency && !previouslyEarnedStar2) xp += 50;
    if (star3Mastery && !previouslyEarnedStar3) xp += 50;
    return xp;
  }

  /// Returns level title based on player level.
  static String getLevelTitle(int level) {
    if (level < 2) return 'Novice Thinker';
    if (level < 3) return 'Curious Mind';
    if (level < 4) return 'Apprentice Solver';
    if (level < 5) return 'Strategic Mind';
    if (level < 10) return 'Logic Adept';
    if (level < 20) return 'Master Architect';
    return 'Grandmaster Strategist';
  }
}
