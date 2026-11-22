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
                            Row(
                              children: [
                                const Text('DAILY CHALLENGE', style: AppTypography.labelSmall),
                                const SizedBox(width: 8),
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
                            const Text(
                              'Solve today\'s puzzle to earn +100 Coins & keep your streak!',
                              style: AppTypography.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Mini-Games Section Title
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Text('CHOOSE YOUR GAME', style: AppTypography.labelSmall),
                    Spacer(),
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
                    const _GameHubCard(
                      id: AppConstants.gameCubeLogic,
                      title: 'Cube Logic',
                      tagline: 'Connect 3D conduits in space',
                      category: '3D Spatial Logic',
                      accentColor: AppColors.gameCubeLogic,
                      icon: Icons.view_in_ar_rounded,
                      isAvailable: true,
                      levelsCount: 20,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gameBridgeMaster,
                      title: 'Bridge Master',
                      tagline: 'Physics-driven truss construction',
                      category: 'Structural Engineering',
                      accentColor: AppColors.gameBridgeMaster,
                      icon: Icons.architecture_rounded,
                      isAvailable: true,
                      levelsCount: 15,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gameMazeArchitect,
                      title: 'Maze Architect',
                      tagline: 'Path navigation with sliding rules',
                      category: 'Spatial Pathfinding',
                      accentColor: AppColors.gameMazeArchitect,
                      icon: Icons.grid_goldenratio_rounded,
                      isAvailable: true,
                      levelsCount: 15,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gamePatternMatrix,
                      title: 'Pattern Matrix',
                      tagline: 'Algorithmic pattern completion',
                      category: 'Raven\'s Matrices',
                      accentColor: AppColors.gamePatternMatrix,
                      icon: Icons.pattern_rounded,
                      isAvailable: false,
                      levelsCount: 10,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gameGravityOrb,
                      title: 'Gravity Orb',
                      tagline: 'Momentum, gravity wells & ricochets',
                      category: 'Physics Puzzle',
                      accentColor: AppColors.gameGravityOrb,
                      icon: Icons.blur_circular_rounded,
                      isAvailable: false,
                      levelsCount: 10,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gameQuantumLock,
                      title: 'Quantum Lock',
                      tagline: 'Multi-layer deduction & binary state',
                      category: 'Cryptic Deduction',
                      accentColor: AppColors.gameQuantumLock,
                      icon: Icons.lock_clock_rounded,
                      isAvailable: false,
                      levelsCount: 10,
                      earnedStars: 0,
                    ),
                    const SizedBox(height: 14),
                    const _GameHubCard(
                      id: AppConstants.gameChronoShift,
                      title: 'Chrono Shift',
                      tagline: 'Temporal recording & dual puzzle state',
                      category: 'Time Paradox Logic',
                      accentColor: AppColors.gameChronoShift,
                      icon: Icons.history_toggle_off_rounded,
                      isAvailable: false,
                      levelsCount: 10,
                      earnedStars: 0,
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
    return AppCard(
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
    return AppCard(
      hasGlow: isAvailable,
      glowColor: accentColor,
      onTap: () {
        context.push('${RoutePaths.gameDetail}/$id');
      },
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
                Row(
                  children: [
                    StarDisplay(
                      earnedStars: earnedStars > 0 ? 1 : 0,
                      starSize: 14,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$earnedStars / ${levelsCount * 3}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
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
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
