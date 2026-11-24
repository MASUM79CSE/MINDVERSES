import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/core/storage/storage_keys.dart';
import 'package:mindverse/shared/repositories/achievement_repository.dart';
import 'package:mindverse/shared/repositories/daily_challenge_repository.dart';
import 'package:mindverse/shared/repositories/profile_repository.dart';
import 'package:mindverse/shared/services/achievement_reward_service.dart';
import 'package:mindverse/shared/services/coin_economy_service.dart';
import 'package:mindverse/shared/services/daily_challenge_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalStorageService storage;
  late ProfileRepositoryImpl profiles;
  late AchievementRepositoryImpl achievements;
  late CoinEconomyServiceImpl economy;
  late DailyChallengeRepositoryImpl daily;
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await createTestLocalStorage(await SharedPreferences.getInstance());
    profiles = ProfileRepositoryImpl(storage);
    achievements = AchievementRepositoryImpl(storage);
    economy = CoinEconomyServiceImpl(storage);
    now = DateTime.utc(2026, 11, 1, 12);
    daily = DailyChallengeRepositoryImpl(
      storage,
      profiles,
      economy,
      achievements,
      AchievementRewardService(achievements, profiles, economy),
      clock: () => now,
    );
  });

  tearDown(() => storage.close());

  test('concurrent claims grant daily and achievement rewards only once', () async {
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    final results = await Future.wait(List.generate(5, (_) => storage.runInTransaction(
      (transaction) => daily.completeInTransaction(transaction, challenge),
    )));
    expect(results.where((result) => result != null), hasLength(1));
    expect(results.whereType<DailyChallengeCompletionResult>().single.coinsEarned, 200);
    expect(results.whereType<DailyChallengeCompletionResult>().single.xpEarned, 300);
    expect(await economy.getBalance(), 300);
    final profile = await profiles.getProfile();
    expect(profile.currentStreak, 1);
    expect(profile.totalXp, 300);
    final unlocked = await achievements.getAchievements();
    expect(unlocked['daily_explorer']!.isRewardClaimed, isTrue);
    expect((await daily.getStatus(challenge.dateString)).isCompleted, isTrue);
  });

  test('consecutive daily bonus caps at seven days', () async {
    for (var day = 1; day <= 9; day++) {
      now = DateTime.utc(2026, 11, day, 12);
      final challenge = DailyChallengeService.generateChallengeForDate(now);
      final result = await storage.runInTransaction(
        (transaction) => daily.completeInTransaction(transaction, challenge),
      );
      expect(result, isNotNull);
      expect(result!.streak, day.clamp(1, 7));
      expect(result.coinsEarned, 100 + (day.clamp(1, 7) - 1) * 10 + (day == 1 ? 100 : 0));
    }
  });

  test('rollback prevents claims without losing previously recorded data', () async {
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    await daily.getStatus(challenge.dateString);
    now = now.subtract(const Duration(days: 1));
    final earlier = DailyChallengeService.generateChallengeForDate(now);
    expect((await daily.getStatus(earlier.dateString)).clockRollbackDetected, isTrue);
    expect(await storage.runInTransaction(
      (transaction) => daily.completeInTransaction(transaction, earlier),
    ), isNull);
    expect(await economy.getBalance(), 100);
  });

  test('failed enclosing transaction does not commit any claim or rewards', () async {
    final challenge = DailyChallengeService.generateChallengeForDate(now);
    await expectLater(storage.runInTransaction((transaction) async {
      await daily.completeInTransaction(transaction, challenge);
      throw StateError('abort');
    }), throwsA(anything));
    expect(await storage.readDocument(StorageKeys.dailyChallengeFile), isNull);
    expect(await economy.getBalance(), 100);
    expect(await storage.readDocument(StorageKeys.achievementsFile), isNull);
  });
}
