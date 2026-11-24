import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import '../domain/memory_board.dart';
import '../domain/memory_matrix_level_factory.dart';
import 'providers/memory_matrix_notifier.dart';
import 'providers/memory_matrix_state.dart';
import 'widgets/memory_canvas_painter.dart';

class MemoryMatrixScreen extends ConsumerWidget {
  final int levelNumber;

  const MemoryMatrixScreen({super.key, required this.levelNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoryMatrixNotifierProvider(levelNumber));
    final notifier = ref.read(
      memoryMatrixNotifierProvider(levelNumber).notifier,
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
                                    memoryMatrixNotifierProvider(levelNumber),
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
                                state.board.phase == MemoryPhase.memorize
                                    ? 'MEMORIZE SEQUENCE'
                                    : 'RECALL SEQUENCE',
                                style: AppTypography.bodyMedium.copyWith(
                                  color:
                                      state.board.phase == MemoryPhase.memorize
                                      ? AppColors.primary
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
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
                      onPressed: state.isCompletionPending
                          ? null
                          : () {
                              if (ref
                                  .read(
                                    memoryMatrixNotifierProvider(levelNumber),
                                  )
                                  .isCompletionPending) {
                                return;
                              }
                              notifier.togglePause();
                              PauseModal.show(
                                context: context,
                                gameTitle: 'Memory Matrix',
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

              // Main Memory Matrix Grid Canvas
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
                                    'Memory grid, ${state.board.gridSize} by ${state.board.gridSize}. Tap the highlighted cells in order.',
                                child: GestureDetector(
                                onTapUp: (details) {
                                  final pos = details.localPosition;
                                  final cw = size.width / state.board.gridSize;
                                  final ch = size.height / state.board.gridSize;
                                  final x = (pos.dx / cw).floor();
                                  final y = (pos.dy / ch).floor();

                                  if (x >= 0 &&
                                      x < state.board.gridSize &&
                                      y >= 0 &&
                                      y < state.board.gridSize) {
                                    notifier.tapCell(x, y);
                                  }
                                },
                                child: CustomPaint(
                                  size: size,
                                  painter: MemoryMatrixCanvasPainter(
                                    board: state.board,
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
                      Container(
                        color: Colors.black.withValues(alpha: 0.75),
                        child: Center(
                          child: state.isSavingCompletion
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      state.completionError!,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    AppButton(
                                      label: 'Retry Save',
                                      variant: AppButtonVariant.primary,
                                      onPressed: notifier.retryCompletion,
                                    ),
                                  ],
                                ),
                        ),
                      ),
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
                child: Center(
                  child: state.board.phase == MemoryPhase.memorize
                      ? AppButton(
                          label: 'Start Recall',
                          icon: Icons.play_arrow_rounded,
                          variant: AppButtonVariant.primary,
                          width: 200,
                          onPressed: notifier.startRecallPhase,
                        )
                      : Text(
                          'Tap the tiles in the order they flashed',
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
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
    MemoryMatrixState state,
    MemoryMatrixNotifier notifier,
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
                'SEQUENCE RECALLED!',
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
                        if (state.levelNumber <
                            MemoryMatrixLevelFactory.levelCount) {
                          context.go('/memory-matrix/${state.levelNumber + 1}');
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
    MemoryMatrixState state,
    MemoryMatrixNotifier notifier,
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
                'INCORRECT SEQUENCE',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tapped incorrect grid tile during recall.',
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
