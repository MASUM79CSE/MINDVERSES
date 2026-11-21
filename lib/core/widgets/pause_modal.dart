import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';

/// In-game pause modal allowing resuming, restarting, adjusting audio, or exiting.
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderSubtle, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(Icons.pause_circle_outline_rounded, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text(
              'GAME PAUSED',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              '$gameTitle — Level $levelNumber',
              style: AppTypography.bodyLarge,
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
