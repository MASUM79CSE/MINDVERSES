import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// A reusable Cupertino / iOS 27 glassmorphic card with subtle glow and spring press response.
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
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.hasGlow = false,
    this.glowColor,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGlow = glowColor ?? AppColors.borderGlow;

    final decoration = BoxDecoration(
      color: AppColors.surfaceCard.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: hasGlow ? effectiveGlow : AppColors.borderSubtle,
        width: hasGlow ? 1.5 : 1.0,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.1),
          Colors.white.withValues(alpha: 0.03),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        if (hasGlow)
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 0),
          ),
      ],
    );

    final Widget card = Container(
      margin: margin,
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: AppColors.primary.withValues(alpha: 0.15),
              highlightColor: AppColors.primary.withValues(alpha: 0.08),
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    if (onTap != null) {
      return Semantics(
        button: true,
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
