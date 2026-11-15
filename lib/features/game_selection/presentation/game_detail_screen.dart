import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Screen detailing mechanics and instructions for a selected mini-game.
class GameDetailScreen extends StatelessWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final (title, description, totalLevels, icon, color) = switch (gameId) {
      AppConstants.gameCubeLogic => (
          'Cube Logic',
          'Rotate the simulated 3D cube and manipulate internal blocks to create continuous energy paths connecting power sources to all terminals.',
          AppConstants.cubeLogicTotalLevels,
          Icons.view_in_ar_rounded,
          AppColors.primary,
        ),
      AppConstants.gameBridgeMaster => (
          'Bridge Master',
          'Engineer load-bearing bridges across treacherous ravines. Manage materials and budgets, then test real-time structural stress under vehicular loads.',
          AppConstants.bridgeMasterTotalLevels,
          Icons.architecture_rounded,
          AppColors.secondary,
        ),
      AppConstants.gameMazeArchitect => (
          'Maze Architect',
          'Slide modular labyrinth tiles, collect color-coded keys, navigate pressure plates, and open a clear route to the exit portal.',
          AppConstants.mazeArchitectTotalLevels,
          Icons.grid_view_rounded,
          AppColors.energyActive,
        ),
      _ => (
          'Unknown Mini-Game',
          'Game description unavailable.',
          0,
          Icons.help_outline_rounded,
          AppColors.textMuted,
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 44),
                ),
              ),
              const SizedBox(height: 24),
              Text(title, style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(description, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(label: 'Total Levels', value: '$totalLevels'),
                    const _StatItem(label: 'Max Stars', value: '3 / level'),
                    const _StatItem(label: 'Efficiency', value: 'Move Target'),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Select Level',
                icon: Icons.list_rounded,
                onPressed: () => context.push(RoutePaths.levelSelectPath(gameId)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleMedium),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
