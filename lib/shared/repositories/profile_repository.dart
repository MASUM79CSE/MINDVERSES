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
  Future<PlayerProfile> updateProfileInTransaction(
    LocalStorageTransaction transaction, {
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
  void invalidateCache();
  Future<void> resetProfile();
}

class ProfileRepositoryImpl implements ProfileRepository {
  final LocalStorageService _storage;

  ProfileRepositoryImpl(this._storage);

  @override
  Future<PlayerProfile> getProfile() async {
    // Always read the persisted document so concurrent completions in another
    // repository instance are never masked by a stale in-memory profile.
    return _storage.runInTransaction((transaction) async {
      final data = await transaction.readDocument(StorageKeys.playerProfileFile);
      if (data != null) return PlayerProfile.fromJson(data);

      final initial = PlayerProfile.initial(id: 'usr_${DateTime.now().millisecondsSinceEpoch}');
      await transaction.writeDocument(StorageKeys.playerProfileFile, initial.toJson());
      return initial;
    });
  }

  @override
  Future<void> saveProfile(PlayerProfile profile) async {
    final updated = profile.copyWith(lastActiveAt: DateTime.now().toUtc());
    await _storage.runInTransaction(
      (transaction) => transaction.writeDocument(StorageKeys.playerProfileFile, updated.toJson()),
    );
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
    await _storage.runInTransaction((transaction) {
      return updateProfileInTransaction(
        transaction,
        username: username,
        avatarId: avatarId,
        xpToAdd: xpToAdd,
        coinsToAdd: coinsToAdd,
        starsToAdd: starsToAdd,
        levelsCompletedDelta: levelsCompletedDelta,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        lastDailyChallengeDate: lastDailyChallengeDate,
      );
    });
  }

  @override
  Future<PlayerProfile> updateProfileInTransaction(
    LocalStorageTransaction transaction, {
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
    final data = await transaction.readDocument(StorageKeys.playerProfileFile);
    final current = data == null
        ? PlayerProfile.initial(id: 'usr_${DateTime.now().millisecondsSinceEpoch}')
        : PlayerProfile.fromJson(data);
    final newXp = current.totalXp + (xpToAdd ?? 0);
    final newCoins = (current.coinBalance + (coinsToAdd ?? 0)).clamp(0, 999999);
    final newStars = current.totalStars + (starsToAdd ?? 0);
    final newCompleted = current.levelsCompletedCount + (levelsCompletedDelta ?? 0);
    final newLevel = XpService.calculateLevelFromXp(newXp);
    final next = current.copyWith(
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
      lastActiveAt: DateTime.now().toUtc(),
    );
    await transaction.writeDocument(StorageKeys.playerProfileFile, next.toJson());
    return next;
  }

  @override
  void invalidateCache() {
    // Reads are always served from storage; retained for interface compatibility.
  }

  @override
  Future<void> resetProfile() async {
    await _storage.runInTransaction(
      (transaction) => transaction.removeDocument(StorageKeys.playerProfileFile),
    );
    invalidateCache();
  }
}
