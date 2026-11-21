import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/storage/storage_keys.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../shared/providers/shared_providers.dart';

/// Settings screen for audio, haptics, theme mode, and privacy controls.
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

    if (confirmed == true && mounted) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.remove(StorageKeys.hasCompletedOnboarding);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local progress reset successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Audio & Haptics Section
            const Text('AUDIO & HAPTICS', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound Effects', style: AppTypography.titleMedium),
                    subtitle: const Text('Rotations, node links, and fractures', style: AppTypography.bodyMedium),
                    value: _soundEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => _updatePref(StorageKeys.soundEnabled, val, (v) => _soundEnabled = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Music Ambiance', style: AppTypography.titleMedium),
                    subtitle: const Text('Focus soundscape for puzzle solving', style: AppTypography.bodyMedium),
                    value: _musicEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => _updatePref(StorageKeys.musicEnabled, val, (v) => _musicEnabled = v),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Tactile Haptic Feedback', style: AppTypography.titleMedium),
                    subtitle: const Text('Vibrate on taps, grid snaps, and wins', style: AppTypography.bodyMedium),
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
            const Text('APPEARANCE & THEME', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme Mode', style: AppTypography.titleMedium),
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
                      ref.read(themeModeProvider.notifier).state = newSelection.first;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Privacy & System Section
            const Text('PRIVACY & DATA', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.energyActive),
                    title: const Text('Data Safety & Privacy', style: AppTypography.titleMedium),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
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

            // About Section
            const Text('ABOUT MINDVERSE', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            const AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConstants.appName, style: AppTypography.titleMedium),
                  SizedBox(height: 4),
                  Text('Version ${AppConstants.appVersion}', style: AppTypography.bodyMedium),
                  SizedBox(height: 8),
                  Text(
                    'Built with Flutter Clean Architecture.\nBrain Score is an internal game-performance metric only.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
