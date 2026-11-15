import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

/// Screen listing unlockable player achievements.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _AchievementTile(
              title: 'First Victory',
              description: 'Solve your very first puzzle level.',
              isUnlocked: false,
              rewardCoins: 25,
            ),
            SizedBox(height: 12),
            _AchievementTile(
              title: 'Perfect Solver',
              description: 'Earn 3 stars on any single level.',
              isUnlocked: false,
              rewardCoins: 50,
            ),
            SizedBox(height: 12),
            _AchievementTile(
              title: 'Daily Explorer',
              description: 'Complete your first daily challenge.',
              isUnlocked: false,
              rewardCoins: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String description;
  final bool isUnlocked;
  final int rewardCoins;

  const _AchievementTile({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.rewardCoins,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.secondary.withValues(alpha: 0.15) : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              color: isUnlocked ? AppColors.secondary : AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodyMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+$rewardCoins Coins', style: AppTypography.labelSmall.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );
  }
}
