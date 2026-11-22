import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/app_router.dart';
import '../../core/services/feedback_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../models/achievement.dart';
import '../models/player_profile.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/level_progress_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/coin_economy_service.dart';

/// Synchronous SharedPreferences instance provider, overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// Central router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Theme mode provider (defaults to ThemeMode.dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.dark;
});

/// Core storage service provider.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

/// Feedback service provider.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeedbackService(prefs);
});

/// Profile repository provider.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ProfileRepositoryImpl(storage);
});

/// Level progress repository provider.
final levelProgressRepositoryProvider = Provider<LevelProgressRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return LevelProgressRepositoryImpl(storage);
});

/// Achievement repository provider.
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AchievementRepositoryImpl(storage);
});

/// Coin economy service provider.
final coinEconomyServiceProvider = Provider<CoinEconomyService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return CoinEconomyServiceImpl(storage);
});

/// Async notifier managing reactive player profile state.
class PlayerProfileNotifier extends AsyncNotifier<PlayerProfile> {
  @override
  Future<PlayerProfile> build() async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getProfile();
  }

  Future<void> updateUsername(String newName) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(username: newName);
    state = AsyncData(await repo.getProfile());
  }

  Future<void> updateAvatar(String newAvatarId) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(avatarId: newAvatarId);
    state = AsyncData(await repo.getProfile());
  }

  Future<void> addRewards({int? xp, int? coins, int? stars, int? levelsDelta}) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(
      xpToAdd: xp,
      coinsToAdd: coins,
      starsToAdd: stars,
      levelsCompletedDelta: levelsDelta,
    );
    state = AsyncData(await repo.getProfile());
  }

  Future<void> refresh() async {
    final repo = ref.read(profileRepositoryProvider);
    state = AsyncData(await repo.getProfile());
  }
}

final playerProfileNotifierProvider =
    AsyncNotifierProvider<PlayerProfileNotifier, PlayerProfile>(PlayerProfileNotifier.new);

/// Provider exposing achievements reactive list.
final achievementsListProvider = FutureProvider<Map<String, Achievement>>((ref) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getAchievements();
});
