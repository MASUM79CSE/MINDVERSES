import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
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
    final status = ref.watch(dailyChallengeStatusProvider(challenge.dateString));

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
                          '${status.asData?.value.currentStreak ?? 0} Days',
                          style: AppTypography.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('Current Streak', style: AppTypography.labelSmall),
                      ],
                    ),
                    Column(
                      children: [
                        Text('+${challenge.rewardCoins + (status.asData?.value.streakBonusCoins ?? 0)}', style: AppTypography.titleLarge),
                        const SizedBox(height: 4),
                        Text('Reward Coins', style: AppTypography.labelSmall),
                      ],
                    ),
                    Column(
                      children: [
                        Text('+${challenge.rewardXp}', style: AppTypography.titleLarge),
                        const SizedBox(height: 4),
                        Text('Reward XP', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (status.hasError)
                const Text('Could not load challenge status. Please try again.')
              else if (status.asData?.value.clockRollbackDetected == true)
                const Text('Device clock moved backwards. Restore the correct time to claim a challenge.')
              else if (status.asData?.value.isCompleted == true)
                const Text('Today’s challenge is complete.', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              AppButton(
                label: status.hasError ? 'Retry' : 'Begin Challenge',
                icon: Icons.play_arrow_rounded,
                variant: AppButtonVariant.secondary,
                isLoading: status.isLoading,
                onPressed: status.hasError
                    ? () => ref.invalidate(dailyChallengeStatusProvider(challenge.dateString))
                    : status.asData?.value.isCompleted == false &&
                            status.asData?.value.clockRollbackDetected == false
                        ? () async {
                            final path = switch (challenge.gameId) {
                              AppConstants.gameCubeLogic => RoutePaths.cubeLogicLevel(challenge.levelNumber),
                              AppConstants.gameBridgeMaster => RoutePaths.bridgeMasterLevel(challenge.levelNumber),
                              AppConstants.gameMazeArchitect => RoutePaths.mazeArchitectLevel(challenge.levelNumber),
                              AppConstants.gameGearTheory => RoutePaths.gearTheoryLevel(challenge.levelNumber),
                              AppConstants.gameTinyKingdom => RoutePaths.tinyKingdomLevel(challenge.levelNumber),
                              AppConstants.gamePerspective => RoutePaths.perspectiveLevel(challenge.levelNumber),
                              AppConstants.gameMemoryMatrix => RoutePaths.memoryMatrixLevel(challenge.levelNumber),
                              _ => null,
                            };
                            if (path == null) return;
                            await context.push(path, extra: challenge);
                            if (context.mounted) {
                              ref.invalidate(dailyChallengeStatusProvider(challenge.dateString));
                            }
                          }
                        : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
