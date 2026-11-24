import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/pause_modal.dart';
import '../../../core/widgets/star_display.dart';
import '../domain/bridge_member.dart';
import 'providers/bridge_master_notifier.dart';
import 'providers/bridge_master_state.dart';
import 'widgets/bridge_canvas_painter.dart';

class BridgeMasterScreen extends ConsumerStatefulWidget {
  final int levelNumber;

  const BridgeMasterScreen({super.key, required this.levelNumber});

  @override
  ConsumerState<BridgeMasterScreen> createState() => _BridgeMasterScreenState();
}

class _BridgeMasterScreenState extends ConsumerState<BridgeMasterScreen> {
  String? _selectedJointId;
  Timer? _simTimer;

  @override
  void dispose() {
    _simTimer?.cancel();
    super.dispose();
  }

  void _startSimLoop() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      final notifier = ref.read(
        bridgeMasterNotifierProvider(widget.levelNumber).notifier,
      );
      final state = ref.read(bridgeMasterNotifierProvider(widget.levelNumber));

      if (state.isSimulating && !state.isCompleted) {
        notifier.stepSimulation(0.15);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bridgeMasterNotifierProvider(widget.levelNumber));
    final notifier = ref.read(
      bridgeMasterNotifierProvider(widget.levelNumber).notifier,
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
                          : () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LEVEL ${widget.levelNumber}: ${state.title.toUpperCase()}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Cost: \$${state.totalCost} / \$${state.budget}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: state.isOverBudget
                                      ? AppColors.stressCritical
                                      : (state.totalCost > state.targetBudget
                                            ? AppColors.stressWarning
                                            : AppColors.energyActive),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Target: \$${state.targetBudget}',
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
                      onPressed: state.isCompletionPending
                          ? null
                          : () {
                              notifier.togglePause();
                              PauseModal.show(
                                context: context,
                                gameTitle: 'Bridge Master',
                                levelNumber: widget.levelNumber,
                                onResume: notifier.togglePause,
                                onRestart: notifier.clearAll,
                                onExit: () => context.go(RoutePaths.hub),
                              );
                            },
                    ),
                  ],
                ),
              ),

              Divider(color: AppColors.borderSubtle, height: 1),

              // Material Selection Palette (Build Mode Only)
              if (!state.isSimulating && !state.isCompletionPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  color: AppColors.surfaceCard,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: BridgeMaterialType.values.map((mat) {
                      final isSelected = state.selectedMaterial == mat;
                      return Semantics(
                        button: true,
                        selected: isSelected,
                        label: mat.displayName,
                        onTap: () => notifier.selectMaterial(mat),
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: () => notifier.selectMaterial(mat),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                mat.displayName,
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '\$${mat.costPerMeter}/m',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Main Interactive Bridge Canvas
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final scaleX = size.width / (state.gapWidth + 4.0);
                        final scaleY = size.height / 10.0;
                        final offsetX = scaleX * 2.0;

                        return GestureDetector(
                          onTapUp: (details) {
                            if (state.isSimulating || state.isCompletionPending) {
                              return;
                            }

                            final pos = details.localPosition;
                            final worldX = (pos.dx - offsetX) / scaleX;
                            final worldY = pos.dy / scaleY;

                            if (worldX < 0 ||
                                worldX > state.gapWidth ||
                                worldY < 1 ||
                                worldY > 8) {
                              setState(() => _selectedJointId = null);
                              return;
                            }

                            final tappedJointId = notifier.addJoint(
                              worldX,
                              worldY,
                            );

                            if (_selectedJointId == null) {
                              setState(() => _selectedJointId = tappedJointId);
                            } else if (_selectedJointId != tappedJointId) {
                              notifier.addMember(
                                _selectedJointId!,
                                tappedJointId,
                              );
                              setState(() => _selectedJointId = tappedJointId);
                            } else {
                              setState(() => _selectedJointId = null);
                            }
                          },
                          child: CustomPaint(
                            size: size,
                            painter: BridgeCanvasPainter(
                              joints: state.joints,
                              members: state.members,
                              gapWidth: state.gapWidth,
                              vehicleX: state.vehicleX,
                              isSimulating: state.isSimulating,
                              selectedJointId: _selectedJointId,
                            ),
                          ),
                        );
                      },
                    ),

                    // Victory Overlay
                    if (state.isSolved)
                      _buildVictoryOverlay(context, state, notifier),

                    // Defeat Overlay
                    if (state.isFailed && !state.isSolved)
                      _buildDefeatOverlay(context, state, notifier),

                    if (state.isCompletionPending)
                      _buildSavingOverlay(state, notifier),
                  ],
                ),
              ),

              // Bottom Control Toolbar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  border: Border(
                    top: BorderSide(color: AppColors.borderSubtle),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.stressCritical,
                      ),
                      onPressed: state.isSimulating || state.isCompletionPending
                          ? null
                          : notifier.clearAll,
                      tooltip: 'Clear Bridge',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.stop_rounded,
                        color: AppColors.textPrimary,
                      ),
                      onPressed: state.isSimulating
                          ? notifier.stopSimulation
                          : null,
                      tooltip: 'Reset Simulation',
                    ),
                    const Spacer(),
                    AppButton(
                      label: state.isSimulating
                          ? 'SIMULATING...'
                          : 'TEST BRIDGE',
                      icon: Icons.play_arrow_rounded,
                      variant: AppButtonVariant.primary,
                      width: 180,
                      onPressed:
                          state.isSimulating ||
                              state.isCompletionPending ||
                              state.members.isEmpty
                          ? null
                          : () {
                              notifier.startSimulation();
                              _startSimLoop();
                            },
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

  Widget _buildSavingOverlay(
    BridgeMasterState state,
    BridgeMasterNotifier notifier,
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
            border: Border.all(color: AppColors.borderSubtle),
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
                AppButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  variant: AppButtonVariant.primary,
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
    BridgeMasterState state,
    BridgeMasterNotifier notifier,
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
                'BRIDGE HELD!',
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
                      label: 'Modify',
                      icon: Icons.edit_rounded,
                      variant: AppButtonVariant.outline,
                      onPressed: notifier.stopSimulation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () {
                        if (widget.levelNumber < 15) {
                          context.go(
                            '/bridge-master/${widget.levelNumber + 1}',
                          );
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
    BridgeMasterState state,
    BridgeMasterNotifier notifier,
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
                Icons.broken_image_rounded,
                color: AppColors.stressCritical,
                size: 64,
              ),
              const SizedBox(height: 12),
              Text(
                'BRIDGE COLLAPSED',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Structural members exceeded maximum tension/compression capacity.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Redesign Bridge',
                icon: Icons.refresh_rounded,
                variant: AppButtonVariant.primary,
                onPressed: notifier.stopSimulation,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
