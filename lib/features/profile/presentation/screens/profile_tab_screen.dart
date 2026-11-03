import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_list_tile.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';

/// Premium Profile Screen for Telora with live Supabase Auth actions and reactive profile state.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of Telora?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            child: Text(
              'Sign Out',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. All your messages, call history, and profile records will be permanently removed. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authControllerProvider.notifier).deleteAccount();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            child: Text(
              'Permanently Delete',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final authState = ref.watch(authControllerProvider);

    final profile = profileState.profile;
    final displayName = profile?.displayName ?? authState.email?.split('@').first ?? 'User';
    final username = profile?.username ?? displayName.toLowerCase();
    final bio = profile?.bio ?? 'Available for calls and messages on Telora.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.settingsOutlined, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.m),
          child: Column(
            children: [
              // Profile Header Card
              TeloraCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        UserAvatar(
                          avatarUrl: profile?.avatarUrl,
                          displayName: displayName,
                          radius: 44,
                          isOnline: true,
                          showOnlineIndicator: true,
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 14, color: AppColors.onPrimary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      displayName,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$username',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Text(
                      bio,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Settings & Management Options
              TeloraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    TeloraListTile(
                      leading: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      title: AppStrings.editProfile,
                      subtitle: 'Name, bio, and avatar',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
                    ),
                    TeloraListTile(
                      leading: const Icon(AppIcons.privacy, color: AppColors.secondary),
                      title: 'Privacy & Security',
                      subtitle: 'Last seen, online status, blocked users',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                    ),
                    TeloraListTile(
                      leading: const Icon(Icons.notifications_outlined, color: AppColors.tertiary),
                      title: 'Notifications',
                      subtitle: 'Ringtone, call alerts, preview',
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
                    ),
                    TeloraListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: AppColors.onSurfaceVariant),
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    TeloraListTile(
                      leading: const Icon(Icons.policy_outlined, color: AppColors.onSurfaceVariant),
                      title: 'Legal & Privacy Policy',
                      showDivider: false,
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Account Actions Card (Sign out & Delete Account)
              TeloraCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    TeloraListTile(
                      leading: const Icon(AppIcons.logout, color: AppColors.error),
                      title: AppStrings.signOut,
                      titleColor: AppColors.error,
                      showDivider: true,
                      onTap: () => _showLogoutDialog(context, ref),
                    ),
                    TeloraListTile(
                      leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                      title: AppStrings.deleteAccount,
                      titleColor: AppColors.error,
                      showDivider: false,
                      onTap: () => _showDeleteAccountDialog(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
