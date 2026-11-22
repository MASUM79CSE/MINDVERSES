import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/achievement.dart';

abstract class AchievementRepository {
  Future<Map<String, Achievement>> getAchievements();
  Future<void> updateProgress(String achievementId, int progressIncrement);
  Future<void> unlockAchievement(String achievementId);
  Future<void> markRewardClaimed(String achievementId);
  Future<void> resetAchievements();
}

class AchievementRepositoryImpl implements AchievementRepository {
  final LocalStorageService _storage;
  Map<String, Achievement>? _cache;

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
    if (_cache != null) return _cache!;

    final data = await _storage.readDocument(StorageKeys.achievementsFile);
    if (data != null && data['achievements'] != null) {
      final rawMap = data['achievements'] as Map<String, dynamic>;
      _cache = {};
      // Ensure all default achievements are present
      for (final entry in _defaultAchievements.entries) {
        if (rawMap.containsKey(entry.key)) {
          _cache![entry.key] = Achievement.fromJson(rawMap[entry.key] as Map<String, dynamic>);
        } else {
          _cache![entry.key] = entry.value;
        }
      }
    } else {
      _cache = Map.from(_defaultAchievements);
    }
    return _cache!;
  }

  @override
  Future<void> updateProgress(String achievementId, int progressIncrement) async {
    final achievements = await getAchievements();
    final achievement = achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return;

    final newProgress = achievement.currentProgress + progressIncrement;
    final isUnlocked = newProgress >= achievement.targetProgress;

    achievements[achievementId] = achievement.copyWith(
      currentProgress: newProgress.clamp(0, achievement.targetProgress),
      isUnlocked: isUnlocked,
      unlockedAt: isUnlocked ? DateTime.now().toUtc() : null,
    );

    await _persist(achievements);
  }

  @override
  Future<void> unlockAchievement(String achievementId) async {
    final achievements = await getAchievements();
    final achievement = achievements[achievementId];
    if (achievement == null || achievement.isUnlocked) return;

    achievements[achievementId] = achievement.copyWith(
      currentProgress: achievement.targetProgress,
      isUnlocked: true,
      unlockedAt: DateTime.now().toUtc(),
    );

    await _persist(achievements);
  }

  @override
  Future<void> markRewardClaimed(String achievementId) async {
    final achievements = await getAchievements();
    final achievement = achievements[achievementId];
    if (achievement == null || !achievement.isUnlocked) return;

    achievements[achievementId] = achievement.copyWith(isRewardClaimed: true);
    await _persist(achievements);
  }

  @override
  Future<void> resetAchievements() async {
    await _storage.removeDocument(StorageKeys.achievementsFile);
    _cache = null;
  }

  Future<void> _persist(Map<String, Achievement> achievements) async {
    final serialized = {
      'schemaVersion': 1,
      'achievements': achievements.map((key, val) => MapEntry(key, val.toJson())),
    };
    await _storage.writeDocument(StorageKeys.achievementsFile, serialized);
  }
}
