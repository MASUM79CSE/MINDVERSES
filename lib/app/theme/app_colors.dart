import 'package:flutter/material.dart';

/// Palette definition for the MINDVERSE 2.5D visual design system.
class AppColors {
  AppColors._();

  // Dark Canvas & Background
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF131B2B);
  static const Color surfaceCard = Color(0xFF1C273D);
  static const Color surfaceElevated = Color(0xFF24324D);

  // Brand Accents
  static const Color primary = Color(0xFF00E5FF); // Electric Cyan
  static const Color primaryDark = Color(0xFF0097A7);
  static const Color secondary = Color(0xFFFFB703); // Solar Amber
  static const Color secondaryDark = Color(0xFFFB8500);

  // Gameplay Accents
  static const Color energyActive = Color(0xFF10B981); // Emerald Jade
  static const Color energyInactive = Color(0xFF475569); // Slate Gray
  static const Color stressWarning = Color(0xFFF59E0B); // Amber
  static const Color stressCritical = Color(0xFFEF4444); // Crimson
  static const Color starGold = Color(0xFFFFD166);
  static const Color starEmpty = Color(0xFF334155);

  // Typography
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textInverse = Color(0xFF0B0F19);

  // Borders & Dividers
  static const Color borderSubtle = Color(0x1AFFFFFF); // 10% white
  static const Color borderGlow = Color(0x4000E5FF); // 25% primary glow
  static const Color glassFill = Color(0x1F1E293B);

  // Shadows
  static const Color shadowColor = Color(0x80000000);
}
