import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/coin_badge.dart';
import '../../../core/widgets/star_display.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/xp_service.dart';

/// Central Game Hub showcasing all mini-games, reactive player status bar, and daily challenges.
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  static const List<IconData> _avatarIcons = [
    Icons.person_rounded,
    Icons.psychology_rounded,
    Icons.emoji_objects_rounded,
    Icons.rocket_launch_rounded,
    Icons.auto_awesome_rounded,
    Icons.extension_rounded,
  ];

  IconData _resolveAvatar(String avatarId) {
    final digits = avatarId.replaceAll(RegExp(r'[^0-9]'), '');
    final index = digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
    return _avatarIcons[index % _avatarIcons.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(playerProfileNotifierProvider);
    final levelResults = ref.watch(levelResultsProvider).valueOrNull ?? const {};
    int starsFor(String gameId) => levelResults.values
        .where((result) => result.gameId == gameId)
        .fold<int>(0, (sum, result) => sum + result.starsEarned);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top Status Bar (Reactive via Riverpod)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: profileAsync.when(
                  data: (profile) {
                    final xpMetrics = XpService.getLevelProgress(profile.totalXp);
                    return Row(
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
                            child: Icon(_resolveAvatar(profile.avatarId), color: AppColors.primary, size: 24),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Player Level & XP
                        Expanded(
                          child: XpProgressBar(
                            currentXp: xpMetrics.currentXpInLevel,
                            nextLevelXp: xpMetrics.xpForNextLevel,
                            playerLevel: profile.playerLevel,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Coins Badge
                        CoinBadge(
                          coins: profile.coinBalance,
                          onTap: () => context.push(RoutePaths.profile),
                        ),
                      ],
                    );
                  },
                  loading: () => const Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: XpProgressBar(currentXp: 0, nextLevelXp: 150, playerLevel: 1),
                      ),
                      SizedBox(width: 12),
                      CoinBadge(coins: AppConstants.startingCoins),
                    ],
                  ),
                  error: (err, stack) => Row(
                    children: [
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
                      const Expanded(
                        child: XpProgressBar(currentXp: 0, nextLevelXp: 150, playerLevel: 1),
                      ),
                      const SizedBox(width: 12),
                      CoinBadge(
                        coins: AppConstants.startingCoins,
                        onTap: () => context.push(RoutePaths.profile),
                      ),
                    ],
                  ),
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text('DAILY CHALLENGE', style: AppTypography.labelSmall),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('NEW', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary, fontSize: 10)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Solve today\'s puzzle to earn +100 Coins & keep your streak!',
                              style: AppTypography.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Mini-Games Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text('CHOOSE YOUR GAME', style: AppTypography.labelSmall),
                    Text('7 Brain Modes', style: AppTypography.bodySmall),
                  ],
                ),
              ),
            ),

            // 7 Mini-Games Grid / List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _GameHubCard(
                      id: AppConstants.gameCubeLogic,
                      title: 'Cube Logic',
                      tagline: 'Connect 3D conduits in space',
                      category: '3D Spatial Logic',
                      accentColor: AppColors.gameCubeLogic,
                      icon: Icons.view_in_ar_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.cubeLogicTotalLevels,
                      earnedStars: starsFor(AppConstants.gameCubeLogic),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gameBridgeMaster,
                      title: 'Bridge Master',
                      tagline: 'Physics-driven truss construction',
                      category: 'Structural Engineering',
                      accentColor: AppColors.gameBridgeMaster,
                      icon: Icons.architecture_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.bridgeMasterTotalLevels,
                      earnedStars: starsFor(AppConstants.gameBridgeMaster),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gameMazeArchitect,
                      title: 'Maze Architect',
                      tagline: 'Path navigation with sliding rules',
                      category: 'Spatial Pathfinding',
                      accentColor: AppColors.gameMazeArchitect,
                      icon: Icons.grid_goldenratio_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.mazeArchitectTotalLevels,
                      earnedStars: starsFor(AppConstants.gameMazeArchitect),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gameGearTheory,
                      title: 'Gear Theory',
                      tagline: 'Mesh gears to drive the flywheel',
                      category: 'Mechanical Kinematics',
                      accentColor: AppColors.gameGearTheory,
                      icon: Icons.settings_suggest_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.gearTheoryTotalLevels,
                      earnedStars: starsFor(AppConstants.gameGearTheory),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gameTinyKingdom,
                      title: 'Tiny Kingdom',
                      tagline: 'Maximize adjacency synergies',
                      category: 'Adjacency Strategy',
                      accentColor: AppColors.gameTinyKingdom,
                      icon: Icons.castle_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.tinyKingdomTotalLevels,
                      earnedStars: starsFor(AppConstants.gameTinyKingdom),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gamePerspective,
                      title: 'Perspective',
                      tagline: 'Align fragments into one silhouette',
                      category: 'Optical Parallax',
                      accentColor: AppColors.gamePerspective,
                      icon: Icons.remove_red_eye_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.perspectiveTotalLevels,
                      earnedStars: starsFor(AppConstants.gamePerspective),
                    ),
                    const SizedBox(height: 14),
                    _GameHubCard(
                      id: AppConstants.gameMemoryMatrix,
                      title: 'Memory Matrix',
                      tagline: 'Recall fast spatial sequences',
                      category: 'Cognitive Recall',
                      accentColor: AppColors.gameMemoryMatrix,
                      icon: Icons.memory_rounded,
                      isAvailable: true,
                      levelsCount: AppConstants.memoryMatrixTotalLevels,
                      earnedStars: starsFor(AppConstants.gameMemoryMatrix),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
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
    return Semantics(
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameHubCard extends StatelessWidget {
  final String id;
  final String title;
  final String tagline;
  final String category;
  final Color accentColor;
  final IconData icon;
  final bool isAvailable;
  final int levelsCount;
  final int earnedStars;

  const _GameHubCard({
    required this.id,
    required this.title,
    required this.tagline,
    required this.category,
    required this.accentColor,
    required this.icon,
    required this.isAvailable,
    required this.levelsCount,
    required this.earnedStars,
  });

  @override
  Widget build(BuildContext context) {
    void openGame() => context.push(RoutePaths.gameDetailPath(id));

    return Semantics(
      button: true,
      label:
          '$title. $category. $earnedStars of ${levelsCount * 3} stars earned.',
      onTap: openGame,
      excludeSemantics: true,
      child: AppCard(
        hasGlow: isAvailable,
        glowColor: accentColor,
        onTap: openGame,
        child: Row(
        children: [
          // Game Icon Box
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accentColor.withValues(alpha: isAvailable ? 0.6 : 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isAvailable ? accentColor : AppColors.textMuted,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          'PHASE 2',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  category.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: isAvailable ? accentColor : AppColors.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  style: AppTypography.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),

                // Stars & Level Progress
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StarDisplay(
                      earnedStars: earnedStars.clamp(0, 3),
                      starSize: 14,
                    ),
                    Text(
                      '$earnedStars / ${levelsCount * 3}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '$levelsCount Levels',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        ],
        ),
      ),
    );
  }
}
