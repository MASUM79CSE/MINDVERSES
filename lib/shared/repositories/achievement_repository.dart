import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/achievement.dart';

abstract class AchievementRepository {
  Future<Map<String, Achievement>> getAchievements();
  Future<void> updateProgress(String achievementId, int progressIncrement);
  Future<void> unlockAchievement(String achievementId);
  Future<void> markRewardClaimed(String achievementId);
  Future<List<Achievement>> recordLevelCompletionInTransaction(
    LocalStorageTransaction transaction, {
    required String gameId,
    required int levelNumber,
    required bool isFirstClear,
    required bool earnedThreeStarsForFirstTime,
    required bool earnedNoHintForFirstTime,
  });
  Future<List<Achievement>> recordDailyChallengeInTransaction(
    LocalStorageTransaction transaction, {
    required String claimId,
  });
  Future<bool> markRewardClaimedInTransaction(
    LocalStorageTransaction transaction,
    String achievementId,
  );
  void invalidateCache();
  Future<void> resetAchievements();
}

class AchievementRepositoryImpl implements AchievementRepository {
  final LocalStorageService _storage;

  static final Map<String, Achievement> _defaultAchievements = {
    'first_victory': const Achievement(
      id: 'first_victory',
      title: 'First Victory',
      description: 'Solve your very first puzzle level.',
      rewardCoins: 25,
      rewardXp: 50,
      targetProgress: 1,
    ),
    'perfect_solver': const Achievement(
      id: 'perfect_solver',
      title: 'Perfect Solver',
      description: 'Earn 3 stars on any single level.',
      rewardCoins: 50,
      rewardXp: 100,
      targetProgress: 1,
    ),
    'daily_explorer': const Achievement(
      id: 'daily_explorer',
      title: 'Daily Explorer',
      description: 'Complete your first daily challenge.',
      rewardCoins: 100,
      rewardXp: 150,
      targetProgress: 1,
    ),
    'puzzle_master_10': const Achievement(
      id: 'puzzle_master_10',
      title: 'Puzzle Master',
      description: 'Complete 10 puzzle levels.',
      rewardCoins: 150,
      rewardXp: 300,
      targetProgress: 10,
    ),
    'no_hint_champion': const Achievement(
      id: 'no_hint_champion',
      title: 'No-Hint Champion',
      description: 'Complete 5 levels without using any hints.',
      rewardCoins: 120,
      rewardXp: 250,
      targetProgress: 5,
    ),
  };

  AchievementRepositoryImpl(this._storage);

  @override
  Future<Map<String, Achievement>> getAchievements() async {
    // Always read the persisted document so concurrent completions in another
    // repository instance are never masked by a stale in-memory cache.
    return _decodeAchievements(await _storage.readDocument(StorageKeys.achievementsFile));
  }

  @override
  Future<void> updateProgress(String achievementId, int progressIncrement) async {
    await _mutateAchievement(achievementId, (achievement) {
      if (achievement.isUnlocked) return achievement;
      final newProgress = achievement.currentProgress + progressIncrement;
      final isUnlocked = newProgress >= achievement.targetProgress;
      return achievement.copyWith(
        currentProgress: newProgress.clamp(0, achievement.targetProgress),
        isUnlocked: isUnlocked,
        unlockedAt: isUnlocked ? DateTime.now().toUtc() : null,
      );
    });
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    await _mutateAchievement(achievementId, (achievement) {
      if (achievement.isUnlocked) return achievement;
      return achievement.copyWith(
        currentProgress: achievement.targetProgress,
        isUnlocked: true,
        unlockedAt: DateTime.now().toUtc(),
      );
    });
  }

  @override
  Future<void> markRewardClaimed(String achievementId) async {
    await _mutateAchievement(achievementId, (achievement) {
      if (!achievement.isUnlocked || achievement.isRewardClaimed) return achievement;
      return achievement.copyWith(isRewardClaimed: true);
    });
  }

  @override
  Future<List<Achievement>> recordLevelCompletionInTransaction(
    LocalStorageTransaction transaction, {
    required String gameId,
    required int levelNumber,
    required bool isFirstClear,
    required bool earnedThreeStarsForFirstTime,
    required bool earnedNoHintForFirstTime,
  }) async {
    final unlocked = <Achievement>[];
    if (isFirstClear) {
      final firstVictory = await _updateProgressInTransaction(
        transaction,
        achievementId: 'first_victory',
        eventId: 'first-victory',
        increment: 1,
      );
      if (firstVictory != null) unlocked.add(firstVictory);

      final levelMilestone = await _updateProgressInTransaction(
        transaction,
        achievementId: 'puzzle_master_10',
        eventId: 'level-clear:$gameId:$levelNumber',
        increment: 1,
      );
      if (levelMilestone != null) unlocked.add(levelMilestone);
    }

    if (earnedThreeStarsForFirstTime) {
      final perfectSolver = await _updateProgressInTransaction(
        transaction,
        achievementId: 'perfect_solver',
        eventId: 'perfect-level:$gameId:$levelNumber',
        increment: 1,
      );
      if (perfectSolver != null) unlocked.add(perfectSolver);
    }

    if (earnedNoHintForFirstTime) {
      final noHintChampion = await _updateProgressInTransaction(
        transaction,
        achievementId: 'no_hint_champion',
        eventId: 'no-hint-level:$gameId:$levelNumber',
        increment: 1,
      );
      if (noHintChampion != null) unlocked.add(noHintChampion);
    }
    return unlocked;
  }

  @override
  Future<List<Achievement>> recordDailyChallengeInTransaction(
    LocalStorageTransaction transaction, {
    required String claimId,
  }) async {
    final achievement = await _updateProgressInTransaction(
      transaction,
      achievementId: 'daily_explorer',
      eventId: 'daily-challenge:$claimId',
      increment: 1,
    );
    return achievement == null ? [] : [achievement];
  }

  @override
  Future<bool> markRewardClaimedInTransaction(
    LocalStorageTransaction transaction,
    String achievementId,
  ) async {
    final data = await transaction.readDocument(StorageKeys.achievementsFile);
    final achievements = _decodeAchievements(data);
    final achievement = achievements[achievementId];
    if (achievement == null || !achievement.isUnlocked || achievement.isRewardClaimed) {
      return false;
    }
    achievements[achievementId] = achievement.copyWith(isRewardClaimed: true);
    await transaction.writeDocument(StorageKeys.achievementsFile, _encodeAchievements(achievements));
    return true;
  }

  Future<Achievement?> _updateProgressInTransaction(
    LocalStorageTransaction transaction, {
    required String achievementId,
    required String eventId,
    required int increment,
  }) async {
    if (increment <= 0) return null;
    final claimed = await transaction.claimIdempotencyKey('achievement:$eventId', {
      'achievementId': achievementId,
      'eventId': eventId,
      'claimedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (!claimed) return null;

    final data = await transaction.readDocument(StorageKeys.achievementsFile);
    final achievements = _decodeAchievements(data);
    final achievement = achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return null;

    final newProgress = (achievement.currentProgress + increment).clamp(0, achievement.targetProgress);
    final isUnlocked = newProgress >= achievement.targetProgress;
    final updated = achievement.copyWith(
      currentProgress: newProgress,
      isUnlocked: isUnlocked,
      unlockedAt: isUnlocked ? DateTime.now().toUtc() : null,
    );
    achievements[achievementId] = updated;
    await transaction.writeDocument(StorageKeys.achievementsFile, _encodeAchievements(achievements));
    return isUnlocked ? updated : null;
  }

  @override
  void invalidateCache() {
    // Reads are always served from storage; retained for interface compatibility.
  }

  @override
  Future<void> resetAchievements() async {
    await _storage.runInTransaction(
      (transaction) => transaction.removeDocument(StorageKeys.achievementsFile),
    );
    invalidateCache();
  }

  Future<void> _mutateAchievement(
    String achievementId,
    Achievement Function(Achievement achievement) update,
  ) async {
    await _storage.runInTransaction((transaction) async {
      final data = await transaction.readDocument(StorageKeys.achievementsFile);
      final achievements = _decodeAchievements(data);
      final achievement = achievements[achievementId];
      if (achievement == null) return achievements;

      final next = update(achievement);
      if (identical(next, achievement)) return achievements;
      achievements[achievementId] = next;
      await transaction.writeDocument(StorageKeys.achievementsFile, _encodeAchievements(achievements));
      return achievements;
    });
  }

  Map<String, Achievement> _decodeAchievements(Map<String, dynamic>? data) {
    final rawAchievements = data?['achievements'];
    final rawMap = rawAchievements is Map ? Map<String, dynamic>.from(rawAchievements) : <String, dynamic>{};
    return _defaultAchievements.map((id, defaultValue) {
      final stored = rawMap[id];
      return MapEntry(
        id,
        stored is Map ? Achievement.fromJson(Map<String, dynamic>.from(stored)) : defaultValue,
      );
    });
  }

  Map<String, dynamic> _encodeAchievements(Map<String, Achievement> achievements) {
    return {
      'schemaVersion': 1,
      'achievements': achievements.map((key, value) => MapEntry(key, value.toJson())),
    };
  }
}
