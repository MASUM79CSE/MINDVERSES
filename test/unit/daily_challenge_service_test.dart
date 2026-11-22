import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';

void main() {
  group('DailyChallengeService Tests', () {
    test('generateChallengeForDate generates deterministic challenge for identical UTC dates', () {
      final date1 = DateTime.utc(2026, 11, 21, 10, 30);
      final date2 = DateTime.utc(2026, 11, 21, 23, 59);

      final c1 = DailyChallengeService.generateChallengeForDate(date1);
      final c2 = DailyChallengeService.generateChallengeForDate(date2);

      expect(c1.dateString, c2.dateString);
      expect(c1.gameId, c2.gameId);
      expect(c1.levelNumber, c2.levelNumber);
      expect(c1.challengeTitle, c2.challengeTitle);
      expect(c1.rewardCoins, c2.rewardCoins);
      expect(c1.dateString, '2026-11-21');
    });

    test('generateChallengeForDate produces different challenge on consecutive days', () {
      final day1 = DateTime.utc(2026, 11, 21);
      final day2 = DateTime.utc(2026, 11, 22);

      final c1 = DailyChallengeService.generateChallengeForDate(day1);
      final c2 = DailyChallengeService.generateChallengeForDate(day2);

      expect(c1.dateString, isNot(c2.dateString));
    });

    test('calculateStreak increments streak on consecutive days', () {
      final newStreak = DailyChallengeService.calculateStreak(
        lastCompletedDate: '2026-11-20',
        todayDate: '2026-11-21',
        currentStreak: 5,
      );

      expect(newStreak, 6);
    });

    test('calculateStreak resets streak when a day is skipped', () {
      final newStreak = DailyChallengeService.calculateStreak(
        lastCompletedDate: '2026-11-19',
        todayDate: '2026-11-21',
        currentStreak: 10,
      );

      expect(newStreak, 1);
    });

    test('calculateStreak preserves streak if already completed today', () {
      final newStreak = DailyChallengeService.calculateStreak(
        lastCompletedDate: '2026-11-21',
        todayDate: '2026-11-21',
        currentStreak: 7,
      );

      expect(newStreak, 7);
    });
  });
}
