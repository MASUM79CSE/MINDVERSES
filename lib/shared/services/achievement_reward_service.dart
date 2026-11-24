import '../models/achievement.dart';
import '../models/coin_transaction.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/profile_repository.dart';
import '../../core/storage/local_storage_service.dart';
import 'coin_economy_service.dart';

class AchievementRewardResult {
  final int coins;
  final int xp;

  const AchievementRewardResult({this.coins = 0, this.xp = 0});
}

/// Grants newly unlocked achievement rewards within the triggering transaction.
class AchievementRewardService {
  final AchievementRepository _achievementRepository;
  final ProfileRepository _profileRepository;
  final CoinEconomyService _coinEconomyService;

  AchievementRewardService(
    this._achievementRepository,
    this._profileRepository,
    this._coinEconomyService,
  );

  Future<AchievementRewardResult> grantInTransaction(
    LocalStorageTransaction transaction,
    List<Achievement> achievements,
  ) async {
    var coins = 0;
    var xp = 0;
    for (final achievement in achievements) {
      final claimed = await _achievementRepository.markRewardClaimedInTransaction(
        transaction,
        achievement.id,
      );
      if (!claimed) continue;

      if (achievement.rewardCoins > 0) {
        final recorded = await _coinEconomyService.recordTransactionInTransaction(
          transaction,
          type: CoinTransactionType.earnAchievement,
          amount: achievement.rewardCoins,
          referenceId: achievement.id,
        );
        if (recorded) coins += achievement.rewardCoins;
      }
      if (achievement.rewardXp > 0) {
        await _profileRepository.updateProfileInTransaction(
          transaction,
          xpToAdd: achievement.rewardXp,
        );
        xp += achievement.rewardXp;
      }
    }
    return AchievementRewardResult(coins: coins, xp: xp);
  }
}
