import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Renders a 3-star rating display according to the three-star scoring framework.
class StarDisplay extends StatelessWidget {
  final int earnedStars; // 0 to 3
  final double starSize;
  final double spacing;
  final bool animate;

  const StarDisplay({
    super.key,
    required this.earnedStars,
    this.starSize = 22,
    this.spacing = 4,
    this.animate = false,
  }) : assert(earnedStars >= 0 && earnedStars <= 3, 'earnedStars must be between 0 and 3');

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isFilled = index < earnedStars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing / 2),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: starSize,
            color: isFilled ? AppColors.starGold : AppColors.starEmpty,
          ),
        );
      }),
    );
  }
}
