import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import '../domain/kingdom_tile.dart';
import '../domain/tiny_kingdom_level_factory.dart';
import 'providers/tiny_kingdom_notifier.dart';
import 'providers/tiny_kingdom_state.dart';
import 'widgets/kingdom_canvas_painter.dart';

class TinyKingdomScreen extends ConsumerWidget {
  final int levelNumber;

  const TinyKingdomScreen({
    super.key,
    required this.levelNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tinyKingdomNotifierProvider(levelNumber));
    final notifier = ref.read(tinyKingdomNotifierProvider(levelNumber).notifier);

    return PopScope(
      canPop: !state.hasPendingCompletion,
      child: _buildScaffold(context, state, notifier),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    TinyKingdomState state,
    TinyKingdomNotifier notifier,
  ) {
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
                    onPressed: state.hasPendingCompletion ? null : () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEVEL ${state.levelNumber}: ${state.title.toUpperCase()}',
                          style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 12,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Gold: \$${state.board.gold} / \$${state.board.targetGold}',
                              style: AppTypography.bodyMedium.copyWith(
                                color: state.board.gold >= state.board.targetGold
                                    ? AppColors.energyActive
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              'Turns: ${state.turnCount}/${state.maxTurns}',
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
                        gameTitle: 'Tiny Kingdom',
                        levelNumber: state.levelNumber,
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

            // Building Selection Palette
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              color: AppColors.surfaceCard,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [BuildingType.house, BuildingType.farm, BuildingType.mill, BuildingType.market, BuildingType.castle].map((bType) {
                  final isSelected = state.selectedBuilding == bType;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: '${bType.displayName}, cost \$${bType.cost}',
                    onTap: () => notifier.selectBuilding(bType),
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => notifier.selectBuilding(bType),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            bType.displayName,
                            style: AppTypography.labelLarge.copyWith(
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${bType.cost}',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Main Kingdom Grid Canvas
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
                            final size = Size(constraints.maxWidth, constraints.maxHeight);
                            return Semantics(
                              label:
                                  'Kingdom board, ${state.board.width} by ${state.board.height}. Tap a tile to place the selected building.',
                              child: GestureDetector(
                              onTapUp: (details) {
                                final pos = details.localPosition;
                                final cw = size.width / state.board.width;
                                final ch = size.height / state.board.height;
                                final x = (pos.dx / cw).floor();
                                final y = (pos.dy / ch).floor();

                                if (x >= 0 && x < state.board.width && y >= 0 && y < state.board.height) {
                                  notifier.placeBuilding(x, y);
                                }
                              },
                              child: CustomPaint(
                                size: size,
                                painter: KingdomCanvasPainter(board: state.board),
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

                  if (state.hasPendingCompletion)
                    _buildSavingOverlay(state, notifier),

                  // Defeat Overlay
                  if (state.isFailed && !state.isSolved)
                    _buildDefeatOverlay(context, state, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingOverlay(TinyKingdomState state, TinyKingdomNotifier notifier) {
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
                Text('Saving your result...', style: AppTypography.titleMedium),
              ] else ...[
                Text(
                  state.completionError!,
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: notifier.retryCompletion,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVictoryOverlay(
    BuildContext context,
    TinyKingdomState state,
    TinyKingdomNotifier notifier,
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
                'KINGDOM PROSPEROUS!',
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
                        if (state.levelNumber < TinyKingdomLevelFactory.levelCount) {
                          context.go('/tiny-kingdom/${state.levelNumber + 1}');
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
    TinyKingdomState state,
    TinyKingdomNotifier notifier,
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
                'TURNS EXHAUSTED',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Exceeded maximum turn limit before reaching target gold.',
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
