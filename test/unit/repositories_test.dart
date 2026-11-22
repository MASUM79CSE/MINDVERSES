import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/core/storage/local_storage_service.dart';
import 'package:mindverse/shared/models/level_result.dart';
import 'package:mindverse/shared/repositories/achievement_repository.dart';
import 'package:mindverse/shared/repositories/level_progress_repository.dart';
import 'package:mindverse/shared/repositories/profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Progression Repositories Tests', () {
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
    });

    test('ProfileRepository initializes default profile and persists updates', () async {
      final repo = ProfileRepositoryImpl(storage);

      final initial = await repo.getProfile();
      expect(initial.username, 'Player1234');
      expect(initial.playerLevel, 1);
      expect(initial.coinBalance, 100);

      await repo.updateProfile(
        username: 'Grandmaster',
        avatarId: 'avatar_rocket',
        xpToAdd: 500,
        coinsToAdd: 50,
        starsToAdd: 3,
        levelsCompletedDelta: 1,
      );

      final updated = await repo.getProfile();
      expect(updated.username, 'Grandmaster');
      expect(updated.avatarId, 'avatar_rocket');
      expect(updated.totalXp, 500);
      expect(updated.playerLevel, 2);
      expect(updated.coinBalance, 150);
      expect(updated.totalStars, 3);
      expect(updated.levelsCompletedCount, 1);
    });

    test('LevelProgressRepository saves results and unlocks next level', () async {
      final repo = LevelProgressRepositoryImpl(storage);

      expect(await repo.isLevelUnlocked('cube_logic', 1), isTrue);
      expect(await repo.isLevelUnlocked('cube_logic', 2), isFalse);

      final result1 = LevelResult(
        gameId: 'cube_logic',
        levelNumber: 1,
        isCompleted: true,
        starsEarned: 3,
        star1Completed: true,
        star2Efficiency: true,
        star3Mastery: true,
        bestMoveCount: 8,
        bestTimeSeconds: 22,
        hintsUsedCount: 0,
        firstCompletedAt: DateTime.now(),
        lastPlayedAt: DateTime.now(),
        playCount: 1,
      );

      await repo.saveLevelResult(result1);
      await repo.unlockNextLevel('cube_logic', 1);

      // Verify level 2 is now unlocked
      expect(await repo.isLevelUnlocked('cube_logic', 2), isTrue);

      final savedResult = await repo.getLevelResult('cube_logic', 1);
      expect(savedResult, isNotNull);
      expect(savedResult!.starsEarned, 3);
      expect(savedResult.isCompleted, isTrue);
    });

    test('AchievementRepository unlocks achievements and updates progress', () async {
      final repo = AchievementRepositoryImpl(storage);

      final initialMap = await repo.getAchievements();
      expect(initialMap.containsKey('first_victory'), isTrue);
      expect(initialMap['first_victory']!.isUnlocked, isFalse);

      await repo.unlockAchievement('first_victory');

      final updatedMap = await repo.getAchievements();
      expect(updatedMap['first_victory']!.isUnlocked, isTrue);
      expect(updatedMap['first_victory']!.currentProgress, 1);
    });
  });
}
