import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// Interactive XP progress bar displaying current player level and progress to next level.
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int nextLevelXp;
  final int playerLevel;
  final double height;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.playerLevel,
    this.height = 10,
  });

  @override
  Widget build(BuildContext context) {
    final progress = nextLevelXp > 0
        ? (currentXp / nextLevelXp).clamp(0.0, 1.0)
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Level $playerLevel',
                style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                '$currentXp / $nextLevelXp XP',
                style: AppTypography.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: AppColors.surfaceElevated,
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primaryDark, AppColors.primary],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6600E5FF),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
