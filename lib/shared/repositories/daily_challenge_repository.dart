import 'dart:math' as math;

import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/daily_challenge.dart';
import '../models/player_profile.dart';
import '../services/achievement_reward_service.dart';
import '../services/coin_economy_service.dart';
import '../services/daily_challenge_service.dart';
import '../models/coin_transaction.dart';
import 'achievement_repository.dart';
import 'profile_repository.dart';

class DailyChallengeStatus {
  final bool isCompleted;
  final bool clockRollbackDetected;
  final int currentStreak;
  final int nextStreak;
  final int bestStreak;

  const DailyChallengeStatus({
    required this.isCompleted,
    required this.clockRollbackDetected,
    required this.currentStreak,
    required this.nextStreak,
    required this.bestStreak,
  });

  int get streakBonusCoins => (nextStreak - 1).clamp(0, 6) * 10;
}

class DailyChallengeCompletionResult {
  final int streak;
  final int coinsEarned;
  final int xpEarned;

  const DailyChallengeCompletionResult({
    required this.streak,
    required this.coinsEarned,
    required this.xpEarned,
  });
}

abstract class DailyChallengeRepository {
  Future<DailyChallengeStatus> getStatus(String dateString);

  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  );

  void invalidateStatus(String dateString);
}

/// Persists daily claims and streak changes with the associated game completion.
class DailyChallengeRepositoryImpl implements DailyChallengeRepository {
  final LocalStorageService _storage;
  final ProfileRepository _profileRepository;
  final CoinEconomyService _coinEconomyService;
  final AchievementRepository _achievementRepository;
  final AchievementRewardService _achievementRewardService;
  final DateTime Function() _clock;

  DailyChallengeRepositoryImpl(
    this._storage,
    this._profileRepository,
    this._coinEconomyService,
    this._achievementRepository,
    this._achievementRewardService, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  @override
  Future<DailyChallengeStatus> getStatus(String dateString) {
    final now = _clock().toUtc();
    return _storage.runInTransaction((transaction) async {
      final challengeData = await transaction.readDocument(StorageKeys.dailyChallengeFile) ?? {};
      final observedValue = challengeData['lastObservedUtc'];
      final lastObserved = observedValue is String ? DateTime.tryParse(observedValue)?.toUtc() : null;
      final clockRollbackDetected = lastObserved != null && now.isBefore(lastObserved);
      if (!clockRollbackDetected) {
        challengeData['schemaVersion'] = 2;
        challengeData['lastObservedUtc'] = now.toIso8601String();
        await transaction.writeDocument(StorageKeys.dailyChallengeFile, challengeData);
      }

      final profileData = await transaction.readDocument(StorageKeys.playerProfileFile);
      final profile = profileData == null
          ? PlayerProfile.initial(id: 'daily_status')
          : PlayerProfile.fromJson(profileData);
      final claims = _claimsFrom(challengeData);
      final isCompleted = claims.containsKey(dateString) || profile.lastDailyChallengeDate == dateString;
      final nextStreak = clockRollbackDetected
          ? profile.currentStreak.clamp(0, 7)
          : DailyChallengeService.calculateStreak(
              lastCompletedDate: profile.lastDailyChallengeDate,
              todayDate: dateString,
              currentStreak: profile.currentStreak,
            );
      return DailyChallengeStatus(
        isCompleted: isCompleted,
        clockRollbackDetected: clockRollbackDetected,
        currentStreak: profile.currentStreak.clamp(0, 7),
        nextStreak: nextStreak,
        bestStreak: profile.bestStreak.clamp(0, 7),
      );
    });
  }

  @override
  Future<DailyChallengeCompletionResult?> completeInTransaction(
    LocalStorageTransaction transaction,
    DailyChallenge challenge,
  ) async {
    final now = _clock().toUtc();
    if (_dateString(now) != challenge.dateString) return null;

    final challengeDate = DateTime.tryParse('${challenge.dateString}T00:00:00Z');
    if (challengeDate == null) return null;
    final generated = DailyChallengeService.generateChallengeForDate(challengeDate);
    if (generated.gameId != challenge.gameId || generated.levelNumber != challenge.levelNumber) {
      return null;
    }

    final challengeData = await transaction.readDocument(StorageKeys.dailyChallengeFile) ?? {};
    final observedValue = challengeData['lastObservedUtc'];
    final lastObserved = observedValue is String ? DateTime.tryParse(observedValue)?.toUtc() : null;
    if (lastObserved != null && now.isBefore(lastObserved)) return null;

    final claims = _claimsFrom(challengeData);
    if (claims.containsKey(challenge.dateString)) return null;

    final profileData = await transaction.readDocument(StorageKeys.playerProfileFile);
    final profile = profileData == null
        ? PlayerProfile.initial(id: 'daily_${now.microsecondsSinceEpoch}')
        : PlayerProfile.fromJson(profileData);
    final lastCompletedDate = profile.lastDailyChallengeDate;
    if (lastCompletedDate == challenge.dateString) return null;
    if (lastCompletedDate != null && lastCompletedDate.compareTo(challenge.dateString) > 0) {
      return null;
    }

    final streak = DailyChallengeService.calculateStreak(
      lastCompletedDate: lastCompletedDate,
      todayDate: challenge.dateString,
      currentStreak: profile.currentStreak,
    );
    final rewardCoins = generated.rewardCoins + (streak - 1) * 10;
    final claimId = _claimId(challenge);
    final claimed = await transaction.claimIdempotencyKey('daily:$claimId', {
      'claimId': claimId,
      'dateString': challenge.dateString,
      'gameId': challenge.gameId,
      'levelNumber': challenge.levelNumber,
      'claimedAt': now.toIso8601String(),
    });
    if (!claimed) return null;

    await _profileRepository.updateProfileInTransaction(
      transaction,
      xpToAdd: generated.rewardXp,
      currentStreak: streak,
      bestStreak: math.max(profile.bestStreak, streak),
      lastDailyChallengeDate: challenge.dateString,
    );
    await _coinEconomyService.recordTransactionInTransaction(
      transaction,
      type: CoinTransactionType.earnDailyChallenge,
      amount: rewardCoins,
      referenceId: claimId,
    );
    final unlocked = await _achievementRepository.recordDailyChallengeInTransaction(
      transaction,
      claimId: claimId,
    );
    final achievementRewards = await _achievementRewardService.grantInTransaction(
      transaction,
      unlocked,
    );

    claims[challenge.dateString] = {
      'claimId': claimId,
      'gameId': challenge.gameId,
      'levelNumber': challenge.levelNumber,
      'completedAt': now.toIso8601String(),
      'streak': streak,
      'rewardCoins': rewardCoins,
      'rewardXp': generated.rewardXp,
    };
    challengeData['schemaVersion'] = 2;
    challengeData['claims'] = claims;
    challengeData['lastCompletedDate'] = challenge.dateString;
    challengeData['currentStreak'] = streak;
    challengeData['bestStreak'] = math.max(profile.bestStreak, streak);
    challengeData['lastObservedUtc'] = now.toIso8601String();
    await transaction.writeDocument(StorageKeys.dailyChallengeFile, challengeData);

    return DailyChallengeCompletionResult(
      streak: streak,
      coinsEarned: rewardCoins + achievementRewards.coins,
      xpEarned: generated.rewardXp + achievementRewards.xp,
    );
  }

  @override
  void invalidateStatus(String dateString) {}

  Map<String, dynamic> _claimsFrom(Map<String, dynamic> data) {
    final value = data['claims'];
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  String _claimId(DailyChallenge challenge) =>
      '${challenge.dateString}:${challenge.gameId}:${challenge.levelNumber}';

  String _dateString(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
