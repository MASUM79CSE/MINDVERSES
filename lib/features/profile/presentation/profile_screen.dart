import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

/// Player Profile screen displaying stats, level, XP, and badges.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, size: 54, color: AppColors.primary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Lv. 1', style: AppTypography.labelSmall),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Novice Thinker', style: AppTypography.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Member since November 2026', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            const AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(label: 'Total XP', value: '0'),
                  _StatColumn(label: 'Coins', value: '100'),
                  _StatColumn(label: 'Stars', value: '0 / 150'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(label: 'Levels Won', value: '0'),
                  _StatColumn(label: 'Daily Streak', value: '0 days'),
                  _StatColumn(label: 'Win Rate', value: '0%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
