import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/xp_progress_bar.dart';

/// Player Profile screen with avatar customization, username editing, and gameplay stats.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = 'Player1234';
  int _selectedAvatarIndex = 0;

  static const List<IconData> _availableAvatars = [
    Icons.person_rounded,
    Icons.psychology_rounded,
    Icons.emoji_objects_rounded,
    Icons.rocket_launch_rounded,
    Icons.auto_awesome_rounded,
    Icons.extension_rounded,
  ];

  void _showEditUsernameDialog() {
    final controller = TextEditingController(text: _username);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Username', style: AppTypography.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Enter new username',
            hintStyle: AppTypography.bodyMedium,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() => _username = newName);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Your Avatar', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(_availableAvatars.length, (index) {
                final isSelected = index == _selectedAvatarIndex;
                return InkWell(
                  onTap: () {
                    setState(() => _selectedAvatarIndex = index);
                    Navigator.of(ctx).pop();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _availableAvatars[index],
                      size: 32,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: _showEditUsernameDialog,
            tooltip: 'Edit Username',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Avatar & Level Header
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  InkWell(
                    onTap: _showAvatarPicker,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x3300E5FF),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _availableAvatars[_selectedAvatarIndex],
                        size: 56,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.textInverse),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(_username, style: AppTypography.displayMedium, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('Novice Thinker • Level 1', style: AppTypography.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 18),

            // XP Progress Card
            const AppCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: XpProgressBar(
                  currentXp: 0,
                  nextLevelXp: 150,
                  playerLevel: 1,
                  height: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Performance Statistics Header
            const Text('OVERALL PERFORMANCE', style: AppTypography.labelSmall),
            const SizedBox(height: 10),

            // Row 1: Primary Stats
            const AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(label: 'Total XP', value: '0'),
                  _StatColumn(label: 'Coins', value: '${AppConstants.startingCoins}'),
                  _StatColumn(label: 'Stars', value: '0 / 150'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Row 2: Secondary Stats
            const AppCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatColumn(label: 'Levels Won', value: '0'),
                  _StatColumn(label: 'Streak', value: '0 days'),
                  _StatColumn(label: 'Win Rate', value: '100%'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Quick Badges Link
            AppButton(
              label: 'View Achievements',
              icon: Icons.emoji_events_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () => context.push(RoutePaths.achievements),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.titleLarge),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}
