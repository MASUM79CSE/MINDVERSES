import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';

/// Screen presenting the UTC-deterministic daily challenge puzzle.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Text('Today\'s Puzzle', style: AppTypography.displayMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text(
                'Complete one unique puzzle every 24 hours to build your streak and earn bonus coins.',
                style: AppTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              const AppCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Day 1', style: AppTypography.titleLarge),
                        SizedBox(height: 4),
                        Text('Current Streak', style: AppTypography.labelSmall),
                      ],
                    ),
                    Column(
                      children: [
                        Text('+100', style: AppTypography.titleLarge),
                        SizedBox(height: 4),
                        Text('Reward Coins', style: AppTypography.labelSmall),
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
                    const SnackBar(
                      content: Text('Daily challenge logic activates in Phase 4'),
                      duration: Duration(milliseconds: 1500),
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
