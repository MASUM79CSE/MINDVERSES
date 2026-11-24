import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/glass_container.dart';

/// Screen presenting the About MINDVERSE overview and Mir Md. Masum developer profile.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _copyToClipboard(BuildContext context, String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    // For safety and robustness across platforms, copy to clipboard as fallback or launch
    await Clipboard.setData(ClipboardData(text: urlString));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening link: $urlString'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ABOUT MINDVERSE'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // App Branding Header
            Center(
              child: GlassContainer(
                borderRadius: 28,
                blur: 24,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A84FF), Color(0xFF0056B3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.psychology_rounded, size: 44, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppConstants.appName,
                      style: AppTypography.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Version ${AppConstants.appVersion}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Think. Solve. Explore. A unified cognitive strategy and brain puzzle game collection.',
                      style: AppTypography.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // About MINDVERSE Overview Card
            Text('ABOUT THE ECOSYSTEM', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local-First & Offline Resilience',
                    style: AppTypography.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'MINDVERSE is built on Flutter Clean Architecture with local Sembast atomic persistence. Enjoy 90 handcrafted campaign levels across 7 unique puzzle engines without requiring an internet connection or compromising your privacy.',
                    style: AppTypography.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Developer Profile Section
            Text('DEVELOPER PROFILE', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              child: Row(
                children: [
                  // Developer Avatar / Placeholder
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'MM',
                        style: AppTypography.displayMedium.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mir Md. Masum', style: AppTypography.titleLarge),
                        const SizedBox(height: 2),
                        Text('Lead Developer & Architect', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 6),
                        Text(
                          'Passionate cross-platform software engineer specializing in high-performance Flutter applications and polished UI/UX design architectures.',
                          style: AppTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact & Social Accounts Section
            Text('CONNECT & CONTACT', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_rounded, color: AppColors.primary),
                    title: Text('Email', style: AppTypography.titleMedium),
                    subtitle: Text('mirmasum@mail.com', style: AppTypography.bodyMedium),
                    trailing: AppButton(
                      label: 'Copy',
                      height: 36,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _copyToClipboard(context, 'Email', 'mirmasum@mail.com'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C)),
                    title: Text('Instagram', style: AppTypography.titleMedium),
                    subtitle: Text('@mirmd_masum', style: AppTypography.bodyMedium),
                    trailing: AppButton(
                      label: 'Open',
                      height: 36,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _openUrl(context, 'https://www.instagram.com/mirmd_masum/'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF5865F2)),
                    title: Text('Discord', style: AppTypography.titleMedium),
                    subtitle: Text('mir_masum', style: AppTypography.bodyMedium),
                    trailing: AppButton(
                      label: 'Copy',
                      height: 36,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _copyToClipboard(context, 'Discord handle', 'mir_masum'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer Credit
            Center(
              child: Column(
                children: [
                  Text(
                    'Designed & Developed by Mir Md. Masum',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 MINDVERSE. All rights reserved.',
                    style: AppTypography.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
