import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import '../domain/gear_level_factory.dart';
import 'providers/gear_theory_notifier.dart';
import 'providers/gear_theory_state.dart';
import 'widgets/gear_canvas_painter.dart';

class GearTheoryScreen extends ConsumerWidget {
  final int levelNumber;

  const GearTheoryScreen({super.key, required this.levelNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gearTheoryNotifierProvider(levelNumber));
    final notifier = ref.read(gearTheoryNotifierProvider(levelNumber).notifier);

    return PopScope(
      canPop: !state.isCompletionPending,
      child: Scaffold(
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
                      onPressed: state.isCompletionPending ? null : () => context.pop(),
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 2,
                            children: [
                              Text(
                                'Moves: ${state.moveCount}/${state.maxMoves}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: state.moveCount > state.targetMoves
                                      ? AppColors.stressWarning
                                      : AppColors.textSecondary,
                                ),
                              ),
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
                      onPressed: state.isCompletionPending
                          ? null
                          : () {
                              notifier.togglePause();
                              PauseModal.show(
                                context: context,
                                gameTitle: 'Gear Theory',
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

              // Main Gear Canvas
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: AspectRatio(
                          aspectRatio: state.board.width / state.board.height,
                          child: LayoutBuilder(
                            builder: (context, constraints) => Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(painter: GearCanvasPainter(board: state.board)),
                                ),
                                for (final peg in state.board.pegs)
                                  Positioned(
                                    left: peg.x / state.board.width * constraints.maxWidth - 24,
                                    top: peg.y / state.board.height * constraints.maxHeight - 24,
                                    width: 48,
                                    height: 48,
                                    child: IconButton(
                                      key: ValueKey('gear-peg-${peg.id}'),
                                      tooltip: state.board.gearAt(peg) == null
                                          ? 'Place gear at ${peg.id} peg'
                                          : 'Remove gear from ${peg.id} peg',
                                      icon: Icon(
                                        state.board.gearAt(peg) == null
                                            ? Icons.add_circle
                                            : Icons.remove_circle,
                                        color: AppColors.primary,
                                      ),
                                      onPressed:
                                          state.isCompleted ||
                                              state.isPaused ||
                                              (state.board.gearAt(peg) == null &&
                                                  state.selectedGearId == null)
                                          ? null
                                          : () => notifier.tapPeg(peg.id),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Victory Overlay
                    if (state.isSolved) _buildVictoryOverlay(context, state, notifier),

                    // Defeat Overlay
                    if (state.isFailed && !state.isSolved) _buildDefeatOverlay(context, state, notifier),

                    if (state.isCompletionPending) _buildCompletionPendingOverlay(state, notifier),
                  ],
                ),
              ),

              // Bottom Control Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Connect the cyan motor to the amber target. Select a gear and tap a peg; tap again to remove it.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final gear in state.board.inventory)
                          ChoiceChip(
                            key: ValueKey('gear-inventory-${gear.id}'),
                            label: Text('Radius ${gear.teeth ~/ 8}'),
                            selected: state.selectedGearId == gear.id,
                            onSelected: state.isCompleted || state.isPaused
                                ? null
                                : (_) => notifier.selectGear(gear.id),
                          ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: AppButton(
                              label: 'Rotate Left',
                              icon: Icons.rotate_left_rounded,
                              variant: AppButtonVariant.outline,
                              onPressed: state.isCompleted || state.isPaused
                                  ? null
                                  : () => notifier.rotateDriver(-0.5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            child: AppButton(
                              label: 'Rotate Right',
                              icon: Icons.rotate_right_rounded,
                              variant: AppButtonVariant.primary,
                              onPressed: state.isCompleted || state.isPaused
                                  ? null
                                  : () => notifier.rotateDriver(0.5),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCompletionPendingOverlay(GearTheoryState state, GearTheoryNotifier notifier) {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.isSavingCompletion) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Saving result...', style: AppTypography.bodyMedium),
              ] else ...[
                Text(state.completionError!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                AppButton(label: 'Retry', onPressed: notifier.retryCompletion),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(BuildContext context, GearTheoryState state, GearTheoryNotifier notifier) {
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
              Text('MECHANISM ENGAGED!', style: AppTypography.displayMedium, textAlign: TextAlign.center),
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
                        if (state.levelNumber < GearLevelFactory.levelCount) {
                          context.go('/gear-theory/${state.levelNumber + 1}');
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

  Widget _buildDefeatOverlay(BuildContext context, GearTheoryState state, GearTheoryNotifier notifier) {
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
              Text('MOVES EXHAUSTED', style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Exceeded maximum rotation moves before engaging target gear.',
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
