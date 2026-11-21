import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/game_selection/presentation/game_detail_screen.dart';
import '../../features/game_selection/presentation/level_select_screen.dart';
import '../../features/home/presentation/hub_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'route_paths.dart';

/// Central GoRouter configuration with custom animated transitions for MINDVERSE.
class AppRouter {
  AppRouter._();

  static Page<dynamic> _buildPageWithTransition({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.hub,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const HubScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.gameDetail,
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: GameDetailScreen(gameId: gameId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.levelSelect,
        pageBuilder: (context, state) {
          final gameId = state.pathParameters['gameId'] ?? '';
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: LevelSelectScreen(gameId: gameId),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.profile,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const ProfileScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.achievements,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AchievementsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.dailyChallenge,
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const DailyChallengeScreen(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
