import 'package:flutter/material.dart';

/// Cupertino / iOS 27 inspired design system color palette.
class AppColors {
  AppColors._();

  static bool isDark = true;

  // OLED Canvas & Backgrounds
  static Color get background => isDark ? const Color(0xFF020408) : const Color(0xFFF2F4F7);
  static Color get surface => isDark ? const Color(0xFF0F172A) : Colors.white;
  static Color get surfaceCard => isDark ? const Color(0xFF162032) : Colors.white;
  static Color get surfaceElevated => isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

  // iOS / Cupertino System Accents
  static const Color primary = Color(0xFF0A84FF); // iOS System Blue
  static const Color primaryDark = Color(0xFF0056B3);
  static const Color secondary = Color(0xFFFF9F0A); // iOS System Orange
  static const Color secondaryDark = Color(0xFFC67A00);

  // Gameplay Accents
  static const Color energyActive = Color(0xFF30D158); // iOS System Mint / Green
  static const Color energyInactive = Color(0xFF48484A); // System Gray
  static const Color stressWarning = Color(0xFFFFD60A); // iOS System Yellow
  static const Color stressCritical = Color(0xFFFF453A); // iOS System Red
  static const Color starGold = Color(0xFFFFD60A);
  static const Color starEmpty = Color(0xFF2C2C2E);

  // Mini-game theme colors (Vibrant iOS 27 gradients)
  static const Color gameCubeLogic = Color(0xFF0A84FF);
  static const Color gameBridgeMaster = Color(0xFFFF9F0A);
  static const Color gameMazeArchitect = Color(0xFF30D158);
  static const Color gamePatternMatrix = Color(0xFF5E5CE6);
  static const Color gameGravityOrb = Color(0xFFFF375F);
  static const Color gameQuantumLock = Color(0xFFBF5AF2);
  static const Color gameChronoShift = Color(0xFF64D2FF);
  static const Color gameGearTheory = Color(0xFF5E5CE6);
  static const Color gameTinyKingdom = Color(0xFFFF9F0A);
  static const Color gamePerspective = Color(0xFFFF375F);
  static const Color gameMemoryMatrix = Color(0xFF64D2FF);

  // Typography
  static Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  static Color get textSecondary => isDark ? const Color(0xFFEBEBF5) : const Color(0xFF3C3C43);
  static Color get textMuted => isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);
  static const Color textInverse = Color(0xFF000000);

  // Borders & Glass Dividers
  static Color get borderSubtle => isDark ? const Color(0x26FFFFFF) : const Color(0x1A000000);
  static const Color borderGlow = Color(0x660A84FF);
  static const Color glassFill = Color(0x331C1C1E);

  // Shadows
  static const Color shadowColor = Color(0x66000000);
}
