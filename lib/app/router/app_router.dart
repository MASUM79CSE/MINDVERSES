import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/game_selection/presentation/game_detail_screen.dart';
import '../../features/game_selection/presentation/level_select_screen.dart';
import '../../features/home/presentation/hub_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_paths.dart';

/// Central GoRouter configuration for the MINDVERSE application.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.hub,
        builder: (context, state) => const HubScreen(),
      ),
      GoRoute(
        path: RoutePaths.gameDetail,
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return GameDetailScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: RoutePaths.levelSelect,
        builder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return LevelSelectScreen(gameId: gameId);
        },
      ),
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RoutePaths.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: RoutePaths.dailyChallenge,
        builder: (context, state) => const DailyChallengeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
