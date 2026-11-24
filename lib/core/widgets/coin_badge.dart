import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

/// A compact coin balance badge with tactile solar amber styling.
class CoinBadge extends StatelessWidget {
  final int coins;
  final VoidCallback? onTap;

  const CoinBadge({
    super.key,
    required this.coins,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$coins coins',
      button: onTap != null,
      enabled: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.secondary.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.monetization_on_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$coins',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
