import 'package:flutter/material.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/star_display.dart';

/// Interactive grid displaying playable levels with star ratings and locked states.
class LevelSelectScreen extends StatelessWidget {
  final String gameId;

  const LevelSelectScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final (gameTitle, totalLevels, accentColor) = switch (gameId) {
      AppConstants.gameCubeLogic => ('Cube Logic', AppConstants.cubeLogicTotalLevels, AppColors.primary),
      AppConstants.gameBridgeMaster => ('Bridge Master', AppConstants.bridgeMasterTotalLevels, AppColors.secondary),
      AppConstants.gameMazeArchitect => ('Maze Architect', AppConstants.mazeArchitectTotalLevels, AppColors.energyActive),
      _ => ('Puzzles', 15, AppColors.primary),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$gameTitle Levels'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Level Progress Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CAMPAIGN PROGRESS', style: AppTypography.labelSmall),
                        const SizedBox(height: 4),
                        Text('1 of $totalLevels Unlocked', style: AppTypography.titleMedium),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: AppColors.starGold, size: 22),
                        SizedBox(width: 4),
                        Text('0 / 60 Stars', style: AppTypography.labelLarge),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Grid of Levels
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: totalLevels,
                itemBuilder: (context, index) {
                  final levelNumber = index + 1;
                  // Level 1 is unlocked by default in foundation shell
                  final isUnlocked = levelNumber <= 2;
                  final isCompleted = levelNumber == 1;
                  final earnedStars = levelNumber == 1 ? 3 : 0;

                  return AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    hasGlow: isUnlocked && !isCompleted,
                    glowColor: accentColor,
                    onTap: () {
                      if (isUnlocked) {
                        _showLevelPreviewDialog(
                          context: context,
                          gameTitle: gameTitle,
                          levelNumber: levelNumber,
                          accentColor: accentColor,
                        );
                      } else {
                        AppDialog.showConfirmation(
                          context: context,
                          title: 'Level Locked',
                          message: 'Complete Level ${levelNumber - 1} to unlock this challenge.',
                          confirmLabel: 'Understood',
                          cancelLabel: 'Close',
                          icon: Icons.lock_outline_rounded,
                          iconColor: AppColors.textMuted,
                        );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$levelNumber',
                          style: AppTypography.titleLarge.copyWith(
                            color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (isUnlocked)
                          StarDisplay(earnedStars: earnedStars, starSize: 13, spacing: 1)
                        else
                          const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                      ],
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
              const Text(
                'Objective: Connect all energy conduits within the move limit to earn maximum stars.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const StarDisplay(earnedStars: 0, starSize: 24),
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
                      label: 'Start Puzzle',
                      variant: AppButtonVariant.primary,
                      height: 46,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$gameTitle Level $levelNumber engine engages in Phase 5'),
                            duration: const Duration(milliseconds: 1500),
                          ),
                        );
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
