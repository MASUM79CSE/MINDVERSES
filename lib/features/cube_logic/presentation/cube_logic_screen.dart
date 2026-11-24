import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import 'providers/cube_logic_notifier.dart';
import 'providers/cube_logic_state.dart';
import 'widgets/cube_3d_viewport.dart';

class CubeLogicScreen extends ConsumerWidget {
  final int levelNumber;

  const CubeLogicScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cubeLogicNotifierProvider(levelNumber));
    final notifier = ref.read(cubeLogicNotifierProvider(levelNumber).notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEVEL $levelNumber: ${state.title.toUpperCase()}',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Moves: ${state.moveCount}/${state.maxMoves}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: state.moveCount > state.targetMoves
                                    ? AppColors.stressWarning
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Target: ${state.targetMoves}',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.pause_circle_outline_rounded, color: AppColors.textPrimary, size: 28),
                    tooltip: 'Pause',
                    onPressed: () {
                      notifier.togglePause();
                      PauseModal.show(
                        context: context,
                        gameTitle: 'Cube Logic',
                        levelNumber: levelNumber,
                        onResume: notifier.togglePause,
                        onRestart: notifier.reset,
                        onExit: () => context.go(RoutePaths.hub),
                      );
                    },
                  ),
                ],
              ),
            ),

            Divider(color: AppColors.borderSubtle, height: 1),

            // Main 3D Viewport
            Expanded(
              child: Stack(
                children: [
                  Cube3DViewport(
                    board: state.board,
                    hintTile: state.hintTile,
                    onTileTapped: (x, y, z) {
                      notifier.rotateTile(x, y, z);
                    },
                  ),

                  // Hint indicator badge if active
                  if (state.hintTile != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.stressWarning.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lightbulb_rounded, color: Colors.black, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Hint: Highlighted block should be rotated!',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (state.isSavingCompletion || state.completionError != null)
                    Container(
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Center(
                        child: state.isSavingCompletion
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(state.completionError!, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: 'Retry Save',
                                    onPressed: notifier.retryCompletion,
                                  ),
                                ],
                              ),
                      ),
                    ),

                  // Victory Overlay Modal
                  if (state.isSolved)
                    _buildVictoryOverlay(context, ref, state, notifier),

                  // Defeat Overlay Modal
                  if (state.isFailed && !state.isSolved)
                    _buildDefeatOverlay(context, state, notifier),
                ],
              ),
            ),

            // Bottom Action Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded),
                    color: state.canUndo ? AppColors.primary : AppColors.energyInactive,
                    onPressed: state.canUndo ? notifier.undo : null,
                    tooltip: 'Undo Move',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppColors.textPrimary,
                    onPressed: state.isSavingCompletion || state.completionError != null ? null : notifier.reset,
                    tooltip: 'Reset Level',
                  ),
                  IconButton(
                    icon: const Icon(Icons.lightbulb_outline_rounded),
                    color: AppColors.stressWarning,
                    onPressed: notifier.useHint,
                    tooltip: 'Use Hint',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(
    BuildContext context,
    WidgetRef ref,
    CubeLogicState state,
    CubeLogicNotifier notifier,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.energyActive, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: AppColors.starGold, size: 64),
              const SizedBox(height: 12),
              Text(
                'LEVEL COMPLETE!',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StarDisplay(earnedStars: state.earnedStars, starSize: 36),
              const SizedBox(height: 16),
              Text(
                '+${state.earnedXp} XP   •   +${state.earnedCoins} Coins',
                style: AppTypography.titleMedium.copyWith(color: AppColors.secondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Replay',
                      icon: Icons.refresh_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: notifier.reset,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        if (levelNumber < 20) {
                          context.go('/cube-logic/${levelNumber + 1}');
                        } else {
                          context.pop();
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

  Widget _buildDefeatOverlay(
    BuildContext context,
    CubeLogicState state,
    CubeLogicNotifier notifier,
  ) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.stressCritical, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_off_rounded, color: AppColors.stressCritical, size: 64),
              const SizedBox(height: 12),
              Text(
                'ENERGY DEPLETED',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Exceeded move budget before powering all terminals.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.primary,
                onPressed: notifier.reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
