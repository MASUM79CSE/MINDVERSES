import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/widgets/app_button.dart';
import '../../../shared/providers/shared_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.psychology_rounded,
      accentColor: AppColors.primary,
      title: 'THINK',
      subtitle: 'Spatial, Logic & Structural Challenges',
      description:
          'Rotate simulated 3D cubes in Cube Logic, test load-bearing physics in Bridge Master, and solve modular sliding mazes in Maze Architect.',
    ),
    _OnboardingPageData(
      icon: Icons.star_half_rounded,
      accentColor: AppColors.secondary,
      title: 'SOLVE',
      subtitle: 'The Three-Star Mastery System',
      description:
          'Earn your Completion Star for finding the solution, your Efficiency Star for beating move/budget targets, and your Mastery Star for solving without hints.',
    ),
    _OnboardingPageData(
      icon: Icons.public_rounded,
      accentColor: AppColors.energyActive,
      title: 'EXPLORE',
      subtitle: 'One Unified Game Ecosystem',
      description:
          'Build daily challenge streaks, level up your player profile, earn coins, and conquer 50 progressively challenging MVP levels.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(StorageKeys.hasCompletedOnboarding, true);
    if (mounted) {
      context.go(RoutePaths.hub);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: _completeOnboarding,
              child: Text(
                'Skip',
                style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: data.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: data.accentColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: data.accentColor.withValues(alpha: 0.25),
                                blurRadius: 28,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(data.icon, size: 58, color: data.accentColor),
                        ),
                        const SizedBox(height: 36),
                        Text(data.title, style: AppTypography.displayLarge),
                        const SizedBox(height: 8),
                        Text(
                          data.subtitle,
                          style: AppTypography.titleMedium.copyWith(color: data.accentColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          data.description,
                          style: AppTypography.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final isSelected = index == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            // Bottom Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: AppButton(
                label: isLastPage ? 'Enter ${AppConstants.appName}' : 'Continue',
                icon: isLastPage ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                onPressed: () {
                  if (isLastPage) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingPageData({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
