import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/app_constants.dart';
import '../../../app/router/route_paths.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/xp_progress_bar.dart';
import '../../../shared/providers/shared_providers.dart';
import '../../../shared/services/xp_service.dart';

/// Player Profile screen with avatar customization, username editing, and gameplay stats.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const List<IconData> _availableAvatars = [
    Icons.person_rounded,
    Icons.psychology_rounded,
    Icons.emoji_objects_rounded,
    Icons.rocket_launch_rounded,
    Icons.auto_awesome_rounded,
    Icons.extension_rounded,
  ];

  int _resolveAvatarIndex(String avatarId) {
    final digits = avatarId.replaceAll(RegExp(r'[^0-9]'), '');
    final index = digits.isEmpty ? 0 : (int.tryParse(digits) ?? 0);
    return index % _availableAvatars.length;
  }

  void _showEditUsernameDialog(String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Username', style: AppTypography.titleLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter new username',
            hintStyle: AppTypography.bodyMedium,
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                ref.read(playerProfileNotifierProvider.notifier).updateUsername(newName);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showAvatarPicker(int selectedIndex) {
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
            Text('Choose Your Avatar', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: List.generate(_availableAvatars.length, (index) {
                final isSelected = index == selectedIndex;
                return InkWell(
                  onTap: () {
                    ref.read(playerProfileNotifierProvider.notifier).updateAvatar('avatar_$index');
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
    final profileAsync = ref.watch(playerProfileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PLAYER PROFILE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              final username = profileAsync.asData?.value.username ?? 'Player1234';
              _showEditUsernameDialog(username);
            },
            tooltip: 'Edit Username',
          ),
        ],
      ),
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            final avatarIdx = _resolveAvatarIndex(profile.avatarId);
            final title = XpService.getLevelTitle(profile.playerLevel);
            final xpMetrics = XpService.getLevelProgress(profile.totalXp);

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar & Level Header
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      InkWell(
                        key: const ValueKey('profile_avatar_tap'),
                        onTap: () => _showAvatarPicker(avatarIdx),
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
                            _availableAvatars[avatarIdx],
                            size: 56,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showAvatarPicker(avatarIdx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.textInverse),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(profile.username, style: AppTypography.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('$title • Level ${profile.playerLevel}', style: AppTypography.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 18),

                // XP Progress Card
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: XpProgressBar(
                      currentXp: xpMetrics.currentXpInLevel,
                      nextLevelXp: xpMetrics.xpForNextLevel,
                      playerLevel: profile.playerLevel,
                      height: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Performance Statistics Header
                Text('OVERALL PERFORMANCE', style: AppTypography.labelSmall),
                const SizedBox(height: 10),

                // Row 1: Primary Stats
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Total XP', value: '${profile.totalXp}'),
                      _StatColumn(label: 'Coins', value: '${profile.coinBalance}'),
                      _StatColumn(label: 'Stars', value: '${profile.totalStars} / ${AppConstants.totalCampaignStars}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Row 2: Secondary Stats
                AppCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(label: 'Levels Won', value: '${profile.levelsCompletedCount}'),
                      _StatColumn(label: 'Streak', value: '${profile.currentStreak} days'),
                      _StatColumn(label: 'Best Streak', value: '${profile.bestStreak} days'),
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
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading profile: $err', style: AppTypography.bodyMedium),
          ),
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
