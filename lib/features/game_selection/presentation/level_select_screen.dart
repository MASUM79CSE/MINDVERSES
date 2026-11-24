import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/star_display.dart';
import '../../../shared/providers/shared_providers.dart';

/// Interactive grid displaying playable levels with star ratings and locked states.
class LevelSelectScreen extends ConsumerWidget {
  final String gameId;

  const LevelSelectScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (gameTitle, totalLevels, accentColor) = switch (gameId) {
      AppConstants.gameCubeLogic => ('Cube Logic', AppConstants.cubeLogicTotalLevels, AppColors.primary),
      AppConstants.gameBridgeMaster => ('Bridge Master', AppConstants.bridgeMasterTotalLevels, AppColors.secondary),
      AppConstants.gameMazeArchitect => ('Maze Architect', AppConstants.mazeArchitectTotalLevels, AppColors.energyActive),
      AppConstants.gameGearTheory => ('Gear Theory', AppConstants.gearTheoryTotalLevels, AppColors.gameGearTheory),
      AppConstants.gameTinyKingdom => ('Tiny Kingdom', AppConstants.tinyKingdomTotalLevels, AppColors.gameTinyKingdom),
      AppConstants.gamePerspective => ('Perspective', AppConstants.perspectiveTotalLevels, AppColors.gamePerspective),
      AppConstants.gameMemoryMatrix => ('Memory Matrix', AppConstants.memoryMatrixTotalLevels, AppColors.gameMemoryMatrix),
      _ => ('Puzzles', 15, AppColors.primary),
    };

    final results = ref.watch(levelResultsProvider).valueOrNull ?? const {};
    final gameResults = results.values
        .where((result) => result.gameId == gameId && result.levelNumber <= totalLevels)
        .toList();
    final totalStars = gameResults.fold<int>(0, (sum, result) => sum + result.starsEarned);
    final unlockedLevels = <int>{1};
    for (final result in gameResults) {
      if (result.isUnlocked) unlockedLevels.add(result.levelNumber);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '$gameTitle Levels',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Level Progress Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AppCard(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('CAMPAIGN PROGRESS', style: AppTypography.labelSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${unlockedLevels.length} of $totalLevels Unlocked',
                            style: AppTypography.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.starGold, size: 22),
                          const SizedBox(width: 4),
                          Text(
                            '$totalStars / ${totalLevels * 3} Stars',
                            style: AppTypography.labelLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Grid of Levels
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 100,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: totalLevels,
                itemBuilder: (context, index) {
                  final levelNumber = index + 1;
                  final result = results['${gameId}_level_$levelNumber'];
                  final isUnlocked = levelNumber == 1 || (result?.isUnlocked ?? false);
                  final isCompleted = result?.isCompleted ?? false;
                  final earnedStars = result?.starsEarned ?? 0;

                  void handleTap() {
                    if (isUnlocked) {
                      _showLevelPreviewDialog(
                        context: context,
                        gameTitle: gameTitle,
                        levelNumber: levelNumber,
                        accentColor: accentColor,
                        earnedStars: earnedStars,
                        isCompleted: isCompleted,
                      );
                    } else {
                      AppDialog.showConfirmation(
                        context: context,
                        title: 'Level Locked',
                        message:
                            'Complete Level ${levelNumber - 1} to unlock this challenge.',
                        confirmLabel: 'Understood',
                        cancelLabel: 'Close',
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.textMuted,
                      );
                    }
                  }

                  final status = isUnlocked
                      ? (isCompleted ? 'completed' : 'unlocked')
                      : 'locked';

                  return Semantics(
                    button: true,
                    label:
                        'Level $levelNumber, $status, $earnedStars of 3 stars',
                    onTap: handleTap,
                    excludeSemantics: true,
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      hasGlow: isUnlocked && !isCompleted,
                      glowColor: accentColor,
                      onTap: handleTap,
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$levelNumber',
                            style: AppTypography.titleLarge.copyWith(
                              color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isUnlocked)
                          StarDisplay(earnedStars: earnedStars, starSize: 13, spacing: 1)
                        else
                          Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelPreviewDialog({
    required BuildContext context,
    required String gameTitle,
    required int levelNumber,
    required Color accentColor,
    required int earnedStars,
    required bool isCompleted,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowColor,
                blurRadius: 28,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$levelNumber',
                      style: AppTypography.displayMedium.copyWith(color: accentColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$gameTitle — Level $levelNumber',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Objective: Complete the puzzle challenge within the move limit to earn maximum stars.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              StarDisplay(earnedStars: earnedStars, starSize: 24),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Back',
                      variant: AppButtonVariant.outline,
                      height: 46,
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: isCompleted ? 'Replay Puzzle' : 'Start Puzzle',
                      variant: AppButtonVariant.primary,
                      height: 46,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (gameId == AppConstants.gameCubeLogic) {
                          context.go(RoutePaths.cubeLogicLevel(levelNumber));
                        } else if (gameId == AppConstants.gameBridgeMaster) {
                          context.go(RoutePaths.bridgeMasterLevel(levelNumber));
                        } else if (gameId == AppConstants.gameMazeArchitect) {
                          context.go(RoutePaths.mazeArchitectLevel(levelNumber));
                        } else if (gameId == AppConstants.gameGearTheory) {
                          context.go(RoutePaths.gearTheoryLevel(levelNumber));
                        } else if (gameId == AppConstants.gameTinyKingdom) {
                          context.go(RoutePaths.tinyKingdomLevel(levelNumber));
                        } else if (gameId == AppConstants.gamePerspective) {
                          context.go(RoutePaths.perspectiveLevel(levelNumber));
                        } else if (gameId == AppConstants.gameMemoryMatrix) {
                          context.go(RoutePaths.memoryMatrixLevel(levelNumber));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$gameTitle Level $levelNumber engine engages in future phase'),
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
