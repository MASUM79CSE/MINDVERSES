import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/glass_container.dart';
import '../../../shared/providers/shared_providers.dart';

/// Settings screen for audio, haptics, theme mode, and privacy controls, embedding the full Developer Profile & About section.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late bool _soundEnabled;
  late bool _musicEnabled;
  late bool _hapticEnabled;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _soundEnabled = prefs.getBool(StorageKeys.soundEnabled) ?? true;
    _musicEnabled = prefs.getBool(StorageKeys.musicEnabled) ?? true;
    _hapticEnabled = prefs.getBool(StorageKeys.hapticEnabled) ?? true;
  }

  Future<void> _updatePref(String key, bool value, void Function(bool) updateState) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(key, value);
    setState(() => updateState(value));
  }

  void _showPrivacyDialog() {
    AppDialog.showConfirmation(
      context: context,
      title: 'Data Safety & Privacy',
      message:
          'MINDVERSE operates locally on your device. We do not transmit or sell personal gameplay data. Optional analytics and crash reports require explicit user consent.',
      confirmLabel: 'Understood',
      cancelLabel: 'Close',
      icon: Icons.security_rounded,
      iconColor: AppColors.energyActive,
    );
  }

  Future<void> _copyToClipboard(String label, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    await Clipboard.setData(ClipboardData(text: urlString));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening link: $urlString'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await AppDialog.showConfirmation(
      context: context,
      title: 'Reset All Progress?',
      message:
          'This will permanently reset your player level, XP, stars, and unlocked levels. This action cannot be undone.',
      confirmLabel: 'Reset Everything',
      cancelLabel: 'Cancel',
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.stressCritical,
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(localStorageServiceProvider).resetUserData();
      ref.read(profileRepositoryProvider).invalidateCache();
      ref.read(levelProgressRepositoryProvider).invalidateCache();
      ref.read(achievementRepositoryProvider).invalidateCache();
      await ref.read(sharedPreferencesProvider).remove(StorageKeys.hasCompletedOnboarding);

      ref.invalidate(playerProfileNotifierProvider);
      ref.invalidate(achievementsListProvider);
      ref.invalidate(levelResultsProvider);
      ref.invalidate(dailyChallengeStatusProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All local progress reset successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not reset progress. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS & ABOUT'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Audio & Haptics Section
            Text('AUDIO & HAPTICS', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text('Sound Effects', style: AppTypography.titleMedium),
                    subtitle: Text('Rotations, node links, and fractures', style: AppTypography.bodyMedium),
                    value: _soundEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => _updatePref(StorageKeys.soundEnabled, val, (v) => _soundEnabled = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Music Ambiance', style: AppTypography.titleMedium),
                    subtitle: Text('Focus soundscape for puzzle solving', style: AppTypography.bodyMedium),
                    value: _musicEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => _updatePref(StorageKeys.musicEnabled, val, (v) => _musicEnabled = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text('Tactile Haptic Feedback', style: AppTypography.titleMedium),
                    subtitle: Text('Vibrate on taps, grid snaps, and wins', style: AppTypography.bodyMedium),
                    value: _hapticEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => _updatePref(StorageKeys.hapticEnabled, val, (v) => _hapticEnabled = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Appearance Section
            Text('APPEARANCE & THEME', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme Mode', style: AppTypography.titleMedium),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                    ],
                    selected: {currentThemeMode},
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: AppColors.primary.withValues(alpha: 0.25),
                      selectedForegroundColor: AppColors.primary,
                      foregroundColor: AppColors.textSecondary,
                    ),
                    onSelectionChanged: (newSelection) {
                      ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & System Section
            Text('PRIVACY & DATA', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.energyActive),
                    title: Text('Data Safety & Privacy', style: AppTypography.titleMedium),
                    trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onTap: _showPrivacyDialog,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded, color: AppColors.stressCritical),
                    title: Text(
                      'Reset All Progress',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.stressCritical),
                    ),
                    onTap: _confirmResetProgress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── ABOUT MINDVERSE & DEVELOPER PROFILE SECTION ───
            Text('ABOUT MINDVERSE & DEVELOPER', style: AppTypography.labelSmall),
            const SizedBox(height: 10),

            // App Identity Header Card
            GlassContainer(
              borderRadius: 24,
              blur: 20,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A84FF), Color(0xFF0056B3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(Icons.psychology_rounded, size: 28, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppConstants.appName, style: AppTypography.titleLarge),
                            const SizedBox(height: 2),
                            Text('Version ${AppConstants.appVersion}', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Think. Solve. Explore. A unified cognitive strategy and brain puzzle game collection with local-first offline resilience.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Developer Profile Card
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'MM',
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mir Md. Masum', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text('Lead Developer & Architect', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(
                          'Passionate cross-platform software engineer & UI/UX architect.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact & Socials Card
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
                      onPressed: () => _copyToClipboard('Email', 'mirmasum@mail.com'),
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
                      onPressed: () => _openUrl('https://www.instagram.com/mirmd_masum/'),
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
                      onPressed: () => _copyToClipboard('Discord handle', 'mir_masum'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Footer Credit
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
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
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
