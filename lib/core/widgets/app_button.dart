import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, text }

/// A high-end Cupertino / iOS 27 button component with blur, spring press states, and glowing gradients.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;
    Gradient? gradient;

    switch (variant) {
      case AppButtonVariant.primary:
        foregroundColor = isEnabled ? Colors.white : AppColors.textMuted;
        gradient = isEnabled
            ? const LinearGradient(
                colors: [Color(0xFF0A84FF), Color(0xFF0056B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null;
        break;
      case AppButtonVariant.secondary:
        foregroundColor = isEnabled ? Colors.white : AppColors.textMuted;
        gradient = isEnabled
            ? const LinearGradient(
                colors: [Color(0xFFFF9F0A), Color(0xFFC67A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null;
        break;
      case AppButtonVariant.outline:
        foregroundColor = isEnabled ? AppColors.primary : AppColors.textMuted;
        borderSide = BorderSide(
          color: isEnabled ? AppColors.primary.withValues(alpha: 0.6) : AppColors.borderSubtle,
          width: 1.5,
        );
        break;
      case AppButtonVariant.text:
        foregroundColor = isEnabled ? AppColors.primary : AppColors.textMuted;
        break;
    }

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 20, color: foregroundColor),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(color: foregroundColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: isLoading ? '$label, loading' : label,
      onTap: isEnabled ? onPressed : null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: gradient,
            color: gradient == null ? (isEnabled ? AppColors.surfaceElevated : AppColors.surfaceCard) : null,
            border: borderSide != BorderSide.none ? Border.fromBorderSide(borderSide) : null,
            boxShadow: (variant == AppButtonVariant.primary && isEnabled)
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              borderRadius: BorderRadius.circular(26),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
