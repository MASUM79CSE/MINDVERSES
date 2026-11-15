import 'package:flutter/material.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/star_display.dart';

/// Grid view displaying playable levels with star ratings and locked states.
class LevelSelectScreen extends StatelessWidget {
  final String gameId;

  const LevelSelectScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    final totalLevels = switch (gameId) {
      AppConstants.gameCubeLogic => AppConstants.cubeLogicTotalLevels,
      AppConstants.gameBridgeMaster => AppConstants.bridgeMasterTotalLevels,
      AppConstants.gameMazeArchitect => AppConstants.mazeArchitectTotalLevels,
      _ => 10,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SELECT LEVEL'),
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: totalLevels,
          itemBuilder: (context, index) {
            final levelNumber = index + 1;
            final isUnlocked = levelNumber == 1; // Level 1 unlocked by default in foundation

            return AppCard(
              padding: const EdgeInsets.all(8),
              onTap: isUnlocked
                  ? () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Level $levelNumber gameplay engine initializes in Phase 5'),
                          duration: const Duration(milliseconds: 1500),
                        ),
                      );
                    }
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$levelNumber',
                    style: AppTypography.titleLarge.copyWith(
                      color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isUnlocked)
                    const StarDisplay(earnedStars: 0, starSize: 12, spacing: 2)
                  else
                    const Icon(Icons.lock_rounded, size: 16, color: AppColors.textMuted),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
