import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/star_display.dart';

/// Central Game Hub showcasing all mini-games, player summary, and daily challenges.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('MINDVERSE HUB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            onPressed: () => context.push(RoutePaths.profile),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(RoutePaths.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Daily Challenge Banner
            AppCard(
              hasGlow: true,
              glowColor: AppColors.secondary,
              onTap: () => context.push(RoutePaths.dailyChallenge),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAILY CHALLENGE', style: AppTypography.labelSmall),
                        SizedBox(height: 2),
                        Text('Solve Today\'s Puzzle', style: AppTypography.titleMedium),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Game Cards Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MINI-GAMES', style: AppTypography.titleLarge),
                Text('50 Levels in MVP', style: AppTypography.labelSmall),
              ],
            ),
            const SizedBox(height: 14),

            // Game 1: Cube Logic
            _GameHubCard(
              title: 'Cube Logic',
              tagline: 'Simulated 3D Energy Conduit Puzzles',
              icon: Icons.view_in_ar_rounded,
              accentColor: AppColors.primary,
              totalLevels: AppConstants.cubeLogicTotalLevels,
              completedLevels: 0,
              starsEarned: 0,
              onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameCubeLogic)),
            ),
            const SizedBox(height: 12),

            // Game 2: Bridge Master
            _GameHubCard(
              title: 'Bridge Master',
              tagline: '2D Physics Structural Engineering',
              icon: Icons.architecture_rounded,
              accentColor: AppColors.secondary,
              totalLevels: AppConstants.bridgeMasterTotalLevels,
              completedLevels: 0,
              starsEarned: 0,
              onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameBridgeMaster)),
            ),
            const SizedBox(height: 12),

            // Game 3: Maze Architect
            _GameHubCard(
              title: 'Maze Architect',
              tagline: 'Dynamic Sliding Path Labyrinths',
              icon: Icons.grid_view_rounded,
              accentColor: AppColors.energyActive,
              totalLevels: AppConstants.mazeArchitectTotalLevels,
              completedLevels: 0,
              starsEarned: 0,
              onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameMazeArchitect)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHubCard extends StatelessWidget {
  final String title;
  final String tagline;
  final IconData icon;
  final Color accentColor;
  final int totalLevels;
  final int completedLevels;
  final int starsEarned;
  final VoidCallback onTap;

  const _GameHubCard({
    required this.title,
    required this.tagline,
    required this.icon,
    required this.accentColor,
    required this.totalLevels,
    required this.completedLevels,
    required this.starsEarned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasGlow: false,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: accentColor, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 3),
                Text(tagline, style: AppTypography.bodyMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '$completedLevels/$totalLevels Levels',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    StarDisplay(earnedStars: starsEarned > 0 ? 1 : 0, starSize: 14),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
