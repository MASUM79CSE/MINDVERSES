import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import '../domain/perspective_level_factory.dart';
import 'providers/perspective_notifier.dart';
import 'providers/perspective_state.dart';
import 'widgets/perspective_canvas_painter.dart';

class PerspectiveScreen extends ConsumerWidget {
  final int levelNumber;

  const PerspectiveScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(perspectiveNotifierProvider(levelNumber));
    final notifier = ref.read(perspectiveNotifierProvider(levelNumber).notifier);

    final savingBlocked = state.isSavingCompletion || state.completionError != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PopScope(
        canPop: !savingBlocked,
        child: SafeArea(
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
                    onPressed: savingBlocked
                        ? null
                        : () => context.go(RoutePaths.levelSelectPath('perspective')),
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
                    onPressed: state.isCompleted ? null : () {
                      notifier.togglePause();
                      PauseModal.show(
                        context: context,
                        gameTitle: 'Perspective',
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

            // Main Perspective Canvas
            Expanded(
              child: Stack(
                children: [
                  Semantics(
                    label: 'Perspective canvas. Drag to rotate the shape.',
                    child: GestureDetector(
                    onPanUpdate: (details) {
                      notifier.rotateShape(details.delta.dx * 0.01, details.delta.dy * 0.01);
                    },
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: CustomPaint(
                            painter: PerspectiveCanvasPainter(board: state.board),
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                  if (savingBlocked)
                    Container(
                      color: Colors.black.withValues(alpha: 0.75),
                      child: Center(
                        child: state.isSavingCompletion
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      state.completionError!,
                                      style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: 'Retry Save',
                                    onPressed: notifier.retryCompletion,
                                  ),
                                ],
                              ),
                      ),
                    ),

                  // Victory Overlay
                  if (state.isSolved)
                    _buildVictoryOverlay(context, state, notifier),

                  // Defeat Overlay
                  if (state.isFailed && !state.isSolved)
                    _buildDefeatOverlay(context, state, notifier),
                ],
              ),
            ),

            // Bottom Instructions Toolbar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.board.shapes.length > 1)
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final shapeId in state.board.shapes.keys)
                          ChoiceChip(
                            label: Text('Shape ${state.board.shapes.keys.toList().indexOf(shapeId) + 1}'),
                            selected: state.selectedShapeId == shapeId,
                            onSelected: state.isCompleted || state.isPaused
                                ? null
                                : (_) => notifier.selectShape(shapeId),
                          ),
                      ],
                    ),
                  Text(
                    'Drag anywhere to rotate perspective and align the wireframe',
                    style: AppTypography.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(
    BuildContext context,
    PerspectiveState state,
    PerspectiveNotifier notifier,
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
                'PERSPECTIVE ALIGNED!',
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
                        if (state.levelNumber < PerspectiveLevelFactory.levelCount) {
                          context.go(RoutePaths.perspectiveLevel(state.levelNumber + 1));
                        } else {
                          context.go(RoutePaths.levelSelectPath('perspective'));
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
    PerspectiveState state,
    PerspectiveNotifier notifier,
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
              const Icon(Icons.block_rounded, color: AppColors.stressCritical, size: 64),
              const SizedBox(height: 12),
              Text(
                'MOVES EXHAUSTED',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Exceeded maximum rotation moves before aligning shape.',
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
