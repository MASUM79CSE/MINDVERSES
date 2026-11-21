import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/star_display.dart';
import '../../../core/widgets/xp_progress_bar.dart';

/// Central Game Hub showcasing all mini-games, player status bar, and daily challenges.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Status Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    // Avatar (Tappable to Profile)
                    InkWell(
                      onTap: () => context.push(RoutePaths.profile),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Player Level & XP
                    const Expanded(
                      child: XpProgressBar(
                        currentXp: 0,
                        nextLevelXp: 150,
                        playerLevel: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Coins Badge
                    CoinBadge(
                      coins: AppConstants.startingCoins,
                      onTap: () => context.push(RoutePaths.profile),
                    ),
                  ],
                ),
              ),
            ),

            // Top Quick Navigation Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.emoji_events_rounded,
                        label: 'Badges',
                        onTap: () => context.push(RoutePaths.achievements),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionButton(
                        icon: Icons.tune_rounded,
                        label: 'Settings',
                        onTap: () => context.push(RoutePaths.settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Daily Challenge Hero Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: AppCard(
                  hasGlow: true,
                  glowColor: AppColors.secondary,
                  onTap: () => context.push(RoutePaths.dailyChallenge),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Flexible(
                                  child: Text(
                                    'DAILY CHALLENGE',
                                    style: AppTypography.labelSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.secondary),
                                Text('0', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Today\'s Challenge',
                              style: AppTypography.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+100',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // MVP Games Section Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'MVP MINI-GAMES',
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('50 Levels', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ),

            // 3 MVP Mini-Games List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Game 1: Cube Logic
                  _GameHubCard(
                    title: 'Cube Logic',
                    tagline: 'Simulated 3D Energy Conduit Puzzles',
                    genre: 'Spatial Logic',
                    icon: Icons.view_in_ar_rounded,
                    accentColor: AppColors.primary,
                    totalLevels: AppConstants.cubeLogicTotalLevels,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: true,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameCubeLogic)),
                  ),
                  const SizedBox(height: 12),

                  // Game 2: Bridge Master
                  _GameHubCard(
                    title: 'Bridge Master',
                    tagline: '2D Physics Structural Engineering',
                    genre: 'Physics',
                    icon: Icons.architecture_rounded,
                    accentColor: AppColors.secondary,
                    totalLevels: AppConstants.bridgeMasterTotalLevels,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: true,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameBridgeMaster)),
                  ),
                  const SizedBox(height: 12),

                  // Game 3: Maze Architect
                  _GameHubCard(
                    title: 'Maze Architect',
                    tagline: 'Dynamic Sliding Path Labyrinths',
                    genre: 'Grid Strategy',
                    icon: Icons.grid_view_rounded,
                    accentColor: AppColors.energyActive,
                    totalLevels: AppConstants.mazeArchitectTotalLevels,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: true,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameMazeArchitect)),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // Post-MVP Games Section Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'EXPANSION GAMES',
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Phase 9', style: AppTypography.labelSmall),
                  ],
                ),
              ),
            ),

            // 4 Post-MVP Mini-Games List
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Game 4: Gear Theory
                  _GameHubCard(
                    title: 'Gear Theory',
                    tagline: 'Mechanical Rotation & Transmission Solvers',
                    genre: 'Kinematics',
                    icon: Icons.settings_suggest_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    totalLevels: 15,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: false,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameGearTheory)),
                  ),
                  const SizedBox(height: 12),

                  // Game 5: Tiny Kingdom
                  _GameHubCard(
                    title: 'Tiny Kingdom',
                    tagline: 'Tile-Based Adjacency Settlement Strategy',
                    genre: 'Resource',
                    icon: Icons.castle_rounded,
                    accentColor: const Color(0xFFF97316),
                    totalLevels: 15,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: false,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameTinyKingdom)),
                  ),
                  const SizedBox(height: 12),

                  // Game 6: Perspective
                  _GameHubCard(
                    title: 'Perspective',
                    tagline: 'Optical Parallax & Silhouette Alignment',
                    genre: 'Optical',
                    icon: Icons.remove_red_eye_rounded,
                    accentColor: const Color(0xFFEC4899),
                    totalLevels: 15,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: false,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gamePerspective)),
                  ),
                  const SizedBox(height: 12),

                  // Game 7: Memory Matrix
                  _GameHubCard(
                    title: 'Memory Matrix',
                    tagline: 'Rhythmic Sequence & Spatial Recall',
                    genre: 'Recall',
                    icon: Icons.memory_rounded,
                    accentColor: const Color(0xFF06B6D4),
                    totalLevels: 15,
                    completedLevels: 0,
                    starsEarned: 0,
                    isMvp: false,
                    onTap: () => context.push(RoutePaths.gameDetailPath(AppConstants.gameMemoryMatrix)),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: AppTypography.titleMedium.copyWith(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameHubCard extends StatelessWidget {
  final String title;
  final String tagline;
  final String genre;
  final IconData icon;
  final Color accentColor;
  final int totalLevels;
  final int completedLevels;
  final int starsEarned;
  final bool isMvp;
  final VoidCallback onTap;

  const _GameHubCard({
    required this.title,
    required this.tagline,
    required this.genre,
    required this.icon,
    required this.accentColor,
    required this.totalLevels,
    required this.completedLevels,
    required this.starsEarned,
    required this.isMvp,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasGlow: isMvp,
      glowColor: accentColor,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        genre,
                        style: AppTypography.labelSmall.copyWith(color: accentColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tagline,
                  style: AppTypography.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      isMvp ? '$completedLevels/$totalLevels Levels' : 'Phase 9 Preview',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 10),
                    if (isMvp)
                      StarDisplay(earnedStars: starsEarned > 0 ? 1 : 0, starSize: 13)
                    else
                      const Icon(Icons.hourglass_empty_rounded, size: 13, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
