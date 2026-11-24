import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';

/// Screen detailing mechanics, scoring criteria, and level access for any of the 7 mini-games.
class GameDetailScreen extends StatelessWidget {
  final String gameId;

  const GameDetailScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final (
      title,
      description,
      genre,
      totalLevels,
      icon,
      color,
      isMvp,
      star2Criterion,
      star3Criterion,
    ) = switch (gameId) {
      AppConstants.gameCubeLogic => (
          'Cube Logic',
          'Manipulate an isometric simulated 3D cube structure. Rotate the 3D viewport to inspect all 6 faces and tap individual blocks to align internal glowing conduits, delivering power from sources to every terminal node.',
          'Spatial 3D Logic',
          AppConstants.cubeLogicTotalLevels,
          Icons.view_in_ar_rounded,
          AppColors.primary,
          true,
          'Beat Target Move Limit',
          'Solve without Pulse Trace Hint',
        ),
      AppConstants.gameBridgeMaster => (
          'Bridge Master',
          'Design load-bearing trusses and suspension spans across ravines under strict material budgets. Test your design in live 2D physics as vehicular convoys traverse the bridge.',
          'Physics Simulation',
          AppConstants.bridgeMasterTotalLevels,
          Icons.architecture_rounded,
          AppColors.secondary,
          true,
          'Stay under 75% Budget',
          'Keep peak member stress under 70%',
        ),
      AppConstants.gameMazeArchitect => (
          'Maze Architect',
          'Slide modular labyrinth tiles, collect color-coded keys, navigate pressure plates, and open a clear route from the starting portal to the destination gate.',
          'Sliding Grid Puzzle',
          AppConstants.mazeArchitectTotalLevels,
          Icons.grid_view_rounded,
          AppColors.energyActive,
          true,
          'Solve within Slide Budget',
          'Solve without Pathfinder Hint',
        ),
      AppConstants.gameGearTheory => (
          'Gear Theory',
          'Solve mechanical gear mesh puzzles. Connect driving motors to destination flywheels using varying gear radii to achieve target RPM and rotation directions.',
          'Mechanical Kinematics',
          AppConstants.gearTheoryTotalLevels,
          Icons.settings_suggest_rounded,
          AppColors.gameGearTheory,
          true,
          'Optimal Gear Ratio',
          'Zero Redundant Meshes',
        ),
      AppConstants.gameTinyKingdom => (
          'Tiny Kingdom',
          'Place limited hex land and building tiles to maximize resource synergies and settlement growth bonuses under strict adjacency rules.',
          'Adjacency Strategy',
          AppConstants.tinyKingdomTotalLevels,
          Icons.castle_rounded,
          AppColors.gameTinyKingdom,
          true,
          'Achieve Gold Settlement Tier',
          'Zero Resource Waste',
        ),
      AppConstants.gamePerspective => (
          'Perspective',
          'Solve optical alignment and forced perspective puzzles by rotating floating 3D spatial fragments until their silhouettes visually converge into a target symbol.',
          'Optical Parallax',
          AppConstants.perspectiveTotalLevels,
          Icons.remove_red_eye_rounded,
          AppColors.gamePerspective,
          true,
          'Align under Time Target',
          'Single Smooth Camera Path',
        ),
      AppConstants.gameMemoryMatrix => (
          'Memory Matrix',
          'Memorize and reproduce fast-paced rhythmic patterns and spatial coordinate sequences with temporal delays and distractor phases.',
          'Cognitive Recall',
          AppConstants.memoryMatrixTotalLevels,
          Icons.memory_rounded,
          AppColors.gameMemoryMatrix,
          true,
          'Flawless Sequence Recall',
          'Complete Reverse Playback',
        ),
      _ => (
          'Unknown Mini-Game',
          'Game description unavailable.',
          'Puzzle',
          0,
          Icons.help_outline_rounded,
          AppColors.textMuted,
          false,
          'Standard Target',
          'No Hints',
        ),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            // Hero Icon & Title
            Center(
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 48),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTypography.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(genre, style: AppTypography.labelSmall.copyWith(color: color)),
              ),
            ),
            const SizedBox(height: 16),
            Text(description, style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 24),

            // Quick Stats Row
            AppCard(
              child: Row(
                children: [
                  Expanded(child: _StatItem(label: 'Total Levels', value: '$totalLevels')),
                  const Expanded(child: _StatItem(label: 'Max Stars', value: '3 / level')),
                  Expanded(child: _StatItem(label: 'Status', value: isMvp ? 'Playable' : 'Preview')),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scoring Rules Breakdown Card
            Text('THREE-STAR SCORING RULES', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  const _StarRuleRow(
                    starNumber: 1,
                    title: 'Star 1: Completion',
                    description: 'Solve the primary puzzle objective.',
                  ),
                  const Divider(height: 20),
                  _StarRuleRow(
                    starNumber: 2,
                    title: 'Star 2: Efficiency',
                    description: star2Criterion,
                  ),
                  const Divider(height: 20),
                  _StarRuleRow(
                    starNumber: 3,
                    title: 'Star 3: Mastery',
                    description: star3Criterion,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Button
            if (isMvp) ...[
              AppButton(
                label: 'Select Level',
                icon: Icons.grid_view_rounded,
                variant: AppButtonVariant.primary,
                onPressed: () => context.push(RoutePaths.levelSelectPath(gameId)),
              ),
            ] else ...[
              AppButton(
                label: 'View Engine Specification',
                icon: Icons.info_outline_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () {
                  AppDialog.showConfirmation(
                    context: context,
                    title: '$title Engine',
                    message:
                        'This game is architecturally specified in the Game Design Document and will be implemented in Phase 9 following the MVP release.\n\n$description',
                    confirmLabel: 'Understood',
                    cancelLabel: 'Close',
                    icon: icon,
                    iconColor: color,
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
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
        Text(
          value,
          style: AppTypography.titleMedium,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StarRuleRow extends StatelessWidget {
  final int starNumber;
  final String title;
  final String description;

  const _StarRuleRow({
    required this.starNumber,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.star_rounded, size: 20, color: AppColors.starGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(description, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
