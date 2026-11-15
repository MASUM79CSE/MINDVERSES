import 'package:flutter/material.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';

/// Settings screen for sound, music, haptic, and privacy toggles.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SETTINGS'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('AUDIO & HAPTICS', style: AppTypography.labelSmall),
            const SizedBox(height: 10),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Sound Effects', style: AppTypography.titleMedium),
                    subtitle: const Text('Puzzle movement and connection sounds', style: AppTypography.bodyMedium),
                    value: _soundEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Music Ambiance', style: AppTypography.titleMedium),
                    subtitle: const Text('Soothing background focus audio', style: AppTypography.bodyMedium),
                    value: _musicEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _musicEnabled = val),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Tactile Haptic Feedback', style: AppTypography.titleMedium),
                    subtitle: const Text('Vibrations on clicks, rotations, and wins', style: AppTypography.bodyMedium),
                    value: _hapticEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (val) => setState(() => _hapticEnabled = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('ABOUT', style: AppTypography.labelSmall),
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
                    'Built with Flutter & Clean Architecture.\nBrain Score is an internal game-performance metric only.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
