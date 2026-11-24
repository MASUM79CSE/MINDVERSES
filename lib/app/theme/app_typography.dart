import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Typography hierarchy for MINDVERSE.
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleLarge => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
    height: 1.35,
  );

  static TextStyle get labelLarge => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.primary,
  );
}
