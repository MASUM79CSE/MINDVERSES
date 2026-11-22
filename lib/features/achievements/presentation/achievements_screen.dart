import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/providers/shared_providers.dart';

/// Screen listing unlockable player achievements wired to AchievementRepository.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ACHIEVEMENTS'),
      ),
      body: SafeArea(
        child: achievementsAsync.when(
          data: (achievementsMap) {
            final list = achievementsMap.values.toList();
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final achievement = list[index];
                return _AchievementTile(
                  title: achievement.title,
                  description: achievement.description,
                  isUnlocked: achievement.isUnlocked,
                  rewardCoins: achievement.rewardCoins,
                  currentProgress: achievement.currentProgress,
                  targetProgress: achievement.targetProgress,
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, _) => Center(
            child: Text('Error loading achievements: $err', style: AppTypography.bodyMedium),
          ),
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
  final int currentProgress;
  final int targetProgress;

  const _AchievementTile({
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.rewardCoins,
    required this.currentProgress,
    required this.targetProgress,
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
                if (!isUnlocked && targetProgress > 1) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Progress: $currentProgress / $targetProgress',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
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
