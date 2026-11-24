import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/router/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/feedback_service.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/storage/storage_keys.dart';
import '../models/achievement.dart';
import '../models/level_result.dart';
import '../models/player_profile.dart';
import '../repositories/achievement_repository.dart';
import '../repositories/daily_challenge_repository.dart';
import '../repositories/level_progress_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/achievement_reward_service.dart';
import '../services/coin_economy_service.dart';

/// Synchronous SharedPreferences instance provider, overridden in main.dart.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// Central router provider.
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Theme mode state notifier with SharedPreferences persistence and AppColors sync.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadInitialTheme(_prefs)) {
    _updateAppColors(state);
  }

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final value = prefs.getString(StorageKeys.themeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  void setThemeMode(ThemeMode mode, [Brightness? platformBrightness]) {
    state = mode;
    _prefs.setString(StorageKeys.themeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    _updateAppColors(mode, platformBrightness);
  }

  void _updateAppColors(ThemeMode mode, [Brightness? platformBrightness]) {
    final isDark = switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => (platformBrightness ?? Brightness.dark) == Brightness.dark,
    };
    AppColors.isDark = isDark;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Core storage service provider, initialized before the application starts.
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('localStorageServiceProvider must be overridden in ProviderScope');
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

/// Reactive snapshot of every saved level result, keyed by `gameId_level_N`.
final levelResultsProvider = FutureProvider<Map<String, LevelResult>>((ref) async {
  final repository = ref.watch(levelProgressRepositoryProvider);
  return repository.getAllLevelResults();
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

final achievementRewardServiceProvider = Provider<AchievementRewardService>((ref) {
  return AchievementRewardService(
    ref.watch(achievementRepositoryProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(coinEconomyServiceProvider),
  );
});

final dailyChallengeRepositoryProvider = Provider<DailyChallengeRepository>((ref) {
  return DailyChallengeRepositoryImpl(
    ref.watch(localStorageServiceProvider),
    ref.watch(profileRepositoryProvider),
    ref.watch(coinEconomyServiceProvider),
    ref.watch(achievementRepositoryProvider),
    ref.watch(achievementRewardServiceProvider),
  );
});

final dailyChallengeStatusProvider = FutureProvider.family<DailyChallengeStatus, String>((ref, date) {
  return ref.watch(dailyChallengeRepositoryProvider).getStatus(date);
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
