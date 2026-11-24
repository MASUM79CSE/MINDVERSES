import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import 'providers/maze_architect_notifier.dart';
import 'providers/maze_architect_state.dart';
import 'widgets/maze_board_painter.dart';

class MazeArchitectScreen extends ConsumerWidget {
  final int levelNumber;

  const MazeArchitectScreen({super.key, required this.levelNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mazeArchitectNotifierProvider(levelNumber));
    final notifier = ref.read(
      mazeArchitectNotifierProvider(levelNumber).notifier,
    );

    return PopScope(
      canPop: !state.isCompletionPending,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top HUD Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                      tooltip: 'Back',
                      onPressed: state.isCompletionPending
                          ? null
                          : () {
                              if (!ref
                                  .read(
                                    mazeArchitectNotifierProvider(levelNumber),
                                  )
                                  .isCompletionPending) {
                                context.pop();
                              }
                            },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEVEL $levelNumber: ${state.title.toUpperCase()}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
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
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.pause_circle_outline_rounded,
                        color: AppColors.textPrimary,
                        size: 28,
                      ),
                      tooltip: 'Pause',
                      onPressed: state.isCompleted
                          ? null
                          : () {
                              if (ref
                                  .read(
                                    mazeArchitectNotifierProvider(levelNumber),
                                  )
                                  .isCompleted) {
                                return;
                              }
                              notifier.togglePause();
                              PauseModal.show(
                                context: context,
                                gameTitle: 'Maze Architect',
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

              // Main Maze Grid Canvas
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              return Semantics(
                                label:
                                    'Maze board, ${state.board.width} by ${state.board.height}. Tap two adjacent tiles to swap them.',
                                child: GestureDetector(
                                onTapUp: (details) {
                                  final pos = details.localPosition;
                                  final cw = size.width / state.board.width;
                                  final ch = size.height / state.board.height;
                                  final x = (pos.dx / cw).floor();
                                  final y = (pos.dy / ch).floor();

                                  if (x >= 0 &&
                                      x < state.board.width &&
                                      y >= 0 &&
                                      y < state.board.height) {
                                    notifier.tapTile(x, y);
                                  }
                                },
                                child: CustomPaint(
                                  size: size,
                                  painter: MazeBoardPainter(
                                    board: state.board,
                                    selectedCoord: state.selectedCoord,
                                  ),
                                ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    // Victory Overlay
                    if (state.isSolved)
                      _buildVictoryOverlay(context, state, notifier),

                    // Defeat Overlay
                    if (state.isFailed && !state.isSolved)
                      _buildDefeatOverlay(context, state, notifier),

                    if (state.isCompletionPending)
                      _buildCompletionPendingOverlay(state, notifier),
                  ],
                ),
              ),

              // Bottom Control Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo_rounded),
                      color: state.canUndo
                          ? AppColors.primary
                          : AppColors.energyInactive,
                      onPressed: state.canUndo ? notifier.undo : null,
                      tooltip: 'Undo Move',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppColors.textPrimary,
                      onPressed: state.isCompletionPending
                          ? null
                          : notifier.reset,
                      tooltip: 'Reset Maze',
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

  Widget _buildCompletionPendingOverlay(
    MazeArchitectState state,
    MazeArchitectNotifier notifier,
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isSavingCompletion) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Saving your result...', style: AppTypography.bodyMedium),
              ] else ...[
                Text(
                  state.completionError!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(label: 'Retry', onPressed: notifier.retryCompletion),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(
    BuildContext context,
    MazeArchitectState state,
    MazeArchitectNotifier notifier,
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
              const Icon(
                Icons.stars_rounded,
                color: AppColors.starGold,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'PATH CONNECTED!',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              StarDisplay(earnedStars: state.earnedStars, starSize: 36),
              const SizedBox(height: 16),
              Text(
                '+${state.earnedXp} XP   •   +${state.earnedCoins} Coins',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.secondary,
                ),
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
                        if (levelNumber < 15) {
                          context.go('/maze-architect/${levelNumber + 1}');
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
    MazeArchitectState state,
    MazeArchitectNotifier notifier,
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
              const Icon(
                Icons.block_rounded,
                color: AppColors.stressCritical,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'MOVES EXHAUSTED',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Exceeded maximum move limit before connecting path.',
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
