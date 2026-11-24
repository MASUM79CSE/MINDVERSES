import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import 'app_button.dart';
import 'glass_container.dart';

/// A consistent iOS 27 glassmorphic dialog for MINDVERSE.
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final Widget? customContent;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.customContent,
  });

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        primaryActionLabel: confirmLabel,
        onPrimaryAction: () => Navigator.of(ctx).pop(true),
        secondaryActionLabel: cancelLabel,
        onSecondaryAction: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassContainer(
        borderRadius: 24,
        blur: 24,
        padding: const EdgeInsets.all(24),
        color: AppColors.surfaceCard.withValues(alpha: 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null) ...[
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.primary).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 30,
                    color: iconColor ?? AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            Text(
              title,
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (customContent != null) ...[
              const SizedBox(height: 16),
              customContent!,
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                if (secondaryActionLabel != null) ...[
                  Expanded(
                    child: AppButton(
                      label: secondaryActionLabel!,
                      variant: AppButtonVariant.outline,
                      height: 48,
                      onPressed: onSecondaryAction ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AppButton(
                    label: primaryActionLabel,
                    variant: AppButtonVariant.primary,
                    height: 48,
                    onPressed: onPrimaryAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
