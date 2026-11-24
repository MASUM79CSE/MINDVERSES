import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/bridge_master/presentation/bridge_master_screen.dart';
import '../../features/bridge_master/presentation/providers/bridge_master_notifier.dart';
import '../../features/cube_logic/presentation/cube_logic_screen.dart';
import '../../features/cube_logic/presentation/providers/cube_logic_notifier.dart';
import '../../features/daily_challenge/presentation/daily_challenge_screen.dart';
import '../../features/gear_theory/presentation/gear_theory_screen.dart';
import '../../features/gear_theory/presentation/providers/gear_theory_notifier.dart';
import '../../features/maze_architect/presentation/maze_architect_screen.dart';
import '../../features/maze_architect/presentation/providers/maze_architect_notifier.dart';
import '../../features/memory_matrix/presentation/memory_matrix_screen.dart';
import '../../features/memory_matrix/presentation/providers/memory_matrix_notifier.dart';
import '../../features/perspective/presentation/perspective_screen.dart';
import '../../features/perspective/presentation/providers/perspective_notifier.dart';
import '../../features/tiny_kingdom/presentation/tiny_kingdom_screen.dart';
import '../../features/tiny_kingdom/presentation/providers/tiny_kingdom_notifier.dart';
import '../../features/game_selection/presentation/game_detail_screen.dart';
import '../../features/game_selection/presentation/level_select_screen.dart';
import '../../features/home/presentation/hub_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/models/daily_challenge.dart';
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
      GoRoute(
        path: RoutePaths.cubeLogic,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null
                ? CubeLogicScreen(levelNumber: levelId)
                : ProviderScope(
                    overrides: [
                      cubeLogicNotifierProvider(levelId).overrideWith(
                        (ref) => CubeLogicNotifier(ref, levelId, challenge: challenge),
                      ),
                    ],
                    child: CubeLogicScreen(levelNumber: levelId),
                  ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.bridgeMaster,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? BridgeMasterScreen(levelNumber: levelId) : ProviderScope(
              overrides: [bridgeMasterNotifierProvider(levelId).overrideWith((ref) => BridgeMasterNotifier(ref, levelId, challenge: challenge))],
              child: BridgeMasterScreen(levelNumber: levelId),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.mazeArchitect,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? MazeArchitectScreen(levelNumber: levelId) : ProviderScope(
              overrides: [mazeArchitectNotifierProvider(levelId).overrideWith((ref) => MazeArchitectNotifier(ref, levelId, challenge: challenge))],
              child: MazeArchitectScreen(levelNumber: levelId),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.gearTheory,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? GearTheoryScreen(levelNumber: levelId) : ProviderScope(
              overrides: [gearTheoryNotifierProvider(levelId).overrideWith((ref) => GearTheoryNotifier(ref, levelId, challenge: challenge))],
              child: GearTheoryScreen(levelNumber: levelId),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.tinyKingdom,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? TinyKingdomScreen(levelNumber: levelId) : ProviderScope(
              overrides: [tinyKingdomNotifierProvider(levelId).overrideWith((ref) => TinyKingdomNotifier(ref, levelId, challenge: challenge))],
              child: TinyKingdomScreen(levelNumber: levelId),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.perspective,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? PerspectiveScreen(levelNumber: levelId) : ProviderScope(
              overrides: [perspectiveNotifierProvider(levelId).overrideWith((ref) => PerspectiveNotifier(ref, levelId, challenge: challenge))],
              child: PerspectiveScreen(levelNumber: levelId),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.memoryMatrix,
        pageBuilder: (context, state) {
          final levelId = int.tryParse(state.pathParameters['levelId'] ?? '1') ?? 1;
          final challenge = state.extra is DailyChallenge ? state.extra as DailyChallenge : null;
          return _buildPageWithTransition(
            context: context,
            state: state,
            child: challenge == null ? MemoryMatrixScreen(levelNumber: levelId) : ProviderScope(
              overrides: [memoryMatrixNotifierProvider(levelId).overrideWith((ref) => MemoryMatrixNotifier(ref, levelId, challenge: challenge))],
              child: MemoryMatrixScreen(levelNumber: levelId),
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.uri.path}'),
      ),
    ),
  );
}
