import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';
import 'glass_container.dart';

/// In-game iOS 27 glassmorphic pause modal.
class PauseModal extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final VoidCallback? onSettings;
  final String gameTitle;
  final int levelNumber;

  const PauseModal({
    super.key,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    this.onSettings,
    required this.gameTitle,
    required this.levelNumber,
  });

  static Future<void> show({
    required BuildContext context,
    required String gameTitle,
    required int levelNumber,
    required VoidCallback onResume,
    required VoidCallback onRestart,
    required VoidCallback onExit,
    VoidCallback? onSettings,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PauseModal(
        gameTitle: gameTitle,
        levelNumber: levelNumber,
        onResume: () {
          Navigator.of(ctx).pop();
          onResume();
        },
        onRestart: () {
          Navigator.of(ctx).pop();
          onRestart();
        },
        onExit: () {
          Navigator.of(ctx).pop();
          onExit();
        },
        onSettings: onSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: GlassContainer(
        borderRadius: 28,
        blur: 24,
        padding: const EdgeInsets.all(28),
        color: AppColors.surfaceCard.withValues(alpha: 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause_rounded, size: 32, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'GAME PAUSED',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '$gameTitle — Level $levelNumber',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              variant: AppButtonVariant.primary,
              onPressed: onResume,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Restart Level',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.outline,
              onPressed: onRestart,
            ),
            if (onSettings != null) ...[
              const SizedBox(height: 12),
              AppButton(
                label: 'Audio & Haptics',
                icon: Icons.tune_rounded,
                variant: AppButtonVariant.outline,
                onPressed: onSettings,
              ),
            ],
            const SizedBox(height: 12),
            AppButton(
              label: 'Exit to Levels',
              icon: Icons.arrow_back_rounded,
              variant: AppButtonVariant.text,
              onPressed: onExit,
            ),
          ],
        ),
      ),
    );
  }
}
