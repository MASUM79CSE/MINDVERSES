import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/player_profile.dart';
import '../services/xp_service.dart';

abstract class ProfileRepository {
  Future<PlayerProfile> getProfile();
  Future<void> saveProfile(PlayerProfile profile);
  Future<void> updateProfile({
    String? username,
    String? avatarId,
    int? xpToAdd,
    int? coinsToAdd,
    int? starsToAdd,
    int? levelsCompletedDelta,
    int? currentStreak,
    int? bestStreak,
    String? lastDailyChallengeDate,
  });
  Future<void> resetProfile();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final LocalStorageService _storage;
  PlayerProfile? _cachedProfile;

  ProfileRepositoryImpl(this._storage);

  @override
  Future<PlayerProfile> getProfile() async {
    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    final data = await _storage.readDocument(StorageKeys.playerProfileFile);
    if (data != null) {
      _cachedProfile = PlayerProfile.fromJson(data);
      return _cachedProfile!;
    }

    // Create default guest profile
    final initial = PlayerProfile.initial(id: 'usr_${DateTime.now().millisecondsSinceEpoch}');
    await saveProfile(initial);
    _cachedProfile = initial;
    return initial;
  }

  @override
  Future<void> saveProfile(PlayerProfile profile) async {
    final updated = profile.copyWith(lastActiveAt: DateTime.now().toUtc());
    await _storage.writeDocument(StorageKeys.playerProfileFile, updated.toJson());
    _cachedProfile = updated;
  }

  @override
  Future<void> updateProfile({
    String? username,
    String? avatarId,
    int? xpToAdd,
    int? coinsToAdd,
    int? starsToAdd,
    int? levelsCompletedDelta,
    int? currentStreak,
    int? bestStreak,
    String? lastDailyChallengeDate,
  }) async {
    final current = await getProfile();
    final newXp = current.totalXp + (xpToAdd ?? 0);
    final newCoins = (current.coinBalance + (coinsToAdd ?? 0)).clamp(0, 999999);
    final newStars = current.totalStars + (starsToAdd ?? 0);
    final newCompleted = current.levelsCompletedCount + (levelsCompletedDelta ?? 0);
    final newLevel = XpService.calculateLevelFromXp(newXp);

    final updated = current.copyWith(
      username: username ?? current.username,
      avatarId: avatarId ?? current.avatarId,
      totalXp: newXp,
      playerLevel: newLevel,
      coinBalance: newCoins,
      totalStars: newStars,
      levelsCompletedCount: newCompleted,
      currentStreak: currentStreak ?? current.currentStreak,
      bestStreak: bestStreak ?? current.bestStreak,
      lastDailyChallengeDate: lastDailyChallengeDate ?? current.lastDailyChallengeDate,
    );

    await saveProfile(updated);
  }

  @override
  Future<void> resetProfile() async {
    await _storage.removeDocument(StorageKeys.playerProfileFile);
    _cachedProfile = null;
  }
}
