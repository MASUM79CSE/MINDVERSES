import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindverse/app/config/app_constants.dart';
import 'package:mindverse/app/theme/app_colors.dart';
import 'package:mindverse/app/theme/app_theme.dart';
import 'package:mindverse/app/theme/app_typography.dart';

void main() {
  group('AppConstants Tests', () {
    test('appName and tagline are configured correctly', () {
      expect(AppConstants.appName, 'MINDVERSE');
      expect(AppConstants.appTagline, 'Think. Solve. Explore.');
      expect(AppConstants.totalMvpLevels, 50);
      expect(AppConstants.cubeLogicTotalLevels, 20);
      expect(AppConstants.bridgeMasterTotalLevels, 15);
      expect(AppConstants.mazeArchitectTotalLevels, 15);
    });
  });

  group('AppTheme Tests', () {
    test('darkTheme initializes with dark brightness and proper color scheme', () {
      final theme = AppTheme.darkTheme;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.useMaterial3, isTrue);
    });

    test('lightTheme initializes with light brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
    });

    test('AppTypography provides non-null styles with correct weights', () {
      expect(AppTypography.displayLarge.fontWeight, FontWeight.w800);
      expect(AppTypography.titleLarge.fontWeight, FontWeight.w700);
      expect(AppTypography.bodyLarge.fontWeight, FontWeight.w400);
    });
  });
}
