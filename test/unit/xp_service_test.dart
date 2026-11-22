import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/shared/services/xp_service.dart';

void main() {
  group('XpService Tests', () {
    test('xpRequiredForLevel matches formula 150 * L^1.65', () {
      expect(XpService.xpRequiredForLevel(1), 0);
      expect(XpService.xpRequiredForLevel(2), 471);
      expect(XpService.xpRequiredForLevel(3), 919);
    });

    test('calculateLevelFromXp correctly evaluates player level from total XP', () {
      expect(XpService.calculateLevelFromXp(0), 1);
      expect(XpService.calculateLevelFromXp(470), 1);
      expect(XpService.calculateLevelFromXp(471), 2);
      expect(XpService.calculateLevelFromXp(919), 3);
    });

    test('getLevelProgress calculates current XP progress within level', () {
      final progress1 = XpService.getLevelProgress(0);
      expect(progress1.level, 1);
      expect(progress1.currentXpInLevel, 0);
      expect(progress1.xpForNextLevel, 471);

      final progressMid = XpService.getLevelProgress(235);
      expect(progressMid.level, 1);
      expect(progressMid.currentXpInLevel, 235);

      final progressLvl2 = XpService.getLevelProgress(471);
      expect(progressLvl2.level, 2);
      expect(progressLvl2.currentXpInLevel, 0);
    });

    test('calculateXpReward rewards first clear and prevents replay grinding', () {
      final firstClear3Star = XpService.calculateXpReward(
        isFirstClear: true,
        star1Completed: true,
        star2Efficiency: true,
        star3Mastery: true,
      );
      // 100 + 50 + 50 = 200 XP
      expect(firstClear3Star, 200);

      final replayXp = XpService.calculateXpReward(
        isFirstClear: false,
        star1Completed: true,
        star2Efficiency: true,
        star3Mastery: true,
      );
      // Anti-grind flat 10 XP
      expect(replayXp, 10);

      final incompleteXp = XpService.calculateXpReward(
        isFirstClear: true,
        star1Completed: false,
        star2Efficiency: false,
        star3Mastery: false,
      );
      expect(incompleteXp, 0);
    });

    test('getLevelTitle returns progressive title tiers', () {
      expect(XpService.getLevelTitle(1), 'Novice Thinker');
      expect(XpService.getLevelTitle(2), 'Curious Mind');
      expect(XpService.getLevelTitle(3), 'Apprentice Solver');
      expect(XpService.getLevelTitle(4), 'Strategic Mind');
      expect(XpService.getLevelTitle(5), 'Logic Adept');
      expect(XpService.getLevelTitle(15), 'Master Architect');
      expect(XpService.getLevelTitle(25), 'Grandmaster Strategist');
    });
  });
}
