import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/daily_challenge_service.dart';

/// Screen presenting the UTC-deterministic daily challenge puzzle.
class DailyChallengeScreen extends ConsumerWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = DailyChallengeService.generateChallengeForDate(DateTime.now());
    final profileAsync = ref.watch(playerProfileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('DAILY CHALLENGE'),
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
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.secondary, width: 2),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, color: AppColors.secondary, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Text(challenge.challengeTitle, style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                challenge.challengeDescription,
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '${profileAsync.asData?.value.currentStreak ?? 0} Days',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        const Text('Current Streak', style: AppTypography.labelSmall),
                      ],
                    ),
                    Column(
                      children: [
                        Text('+${challenge.rewardCoins}', style: AppTypography.titleLarge),
                        const SizedBox(height: 4),
                        const Text('Reward Coins', style: AppTypography.labelSmall),
                      ],
                    ),
                    Column(
                      children: [
                        Text('+${challenge.rewardXp}', style: AppTypography.titleLarge),
                        const SizedBox(height: 4),
                        const Text('Reward XP', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Begin Challenge',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Starting ${challenge.challengeTitle}... Level gameplay launches in Phase 5!'),
                      duration: const Duration(milliseconds: 2000),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
