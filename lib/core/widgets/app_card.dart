import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A reusable elevated surface card with subtle 2.5D border and optional glow.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final bool hasGlow;
  final Color? glowColor;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.hasGlow = false,
    this.glowColor,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glowColor ?? AppColors.borderGlow;

    final decoration = BoxDecoration(
      color: AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hasGlow ? effectiveGlow : AppColors.borderSubtle,
        width: 1.2,
      ),
      boxShadow: [
        const BoxShadow(
          color: AppColors.shadowColor,
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
        if (hasGlow)
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
      ],
    );

    final Widget card = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.primary.withValues(alpha: 0.1),
            highlightColor: AppColors.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );

    return card;
  }
}
