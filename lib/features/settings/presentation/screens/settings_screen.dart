import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_list_tile.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Comprehensive Settings Interface for Telora.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _showOnlineStatus = true;
  bool _showLastSeen = true;
  bool _allowCallsFromAll = true;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          children: [
            // Account Section
            const TeloraSectionHeader(title: 'Account'),
            TeloraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  TeloraListTile(
                    leading: const Icon(Icons.password_rounded, color: AppColors.primary),
                    title: 'Update Password',
                    subtitle: 'Change your login credentials',
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.updatePassword),
                  ),
                  TeloraListTile(
                    leading: const Icon(Icons.phonelink_setup_rounded, color: AppColors.primary),
                    title: 'Active Devices',
                    subtitle: 'Manage registered devices',
                    showDivider: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // Privacy Section
            const TeloraSectionHeader(title: 'Privacy'),
            TeloraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _showOnlineStatus,
                    activeColor: AppColors.primary,
                    title: const Text('Show Online Status'),
                    subtitle: const Text('Allow contacts to see when you are active'),
                    onChanged: (val) => setState(() => _showOnlineStatus = val),
                  ),
                  const Divider(height: 1, indent: AppSpacing.m, endIndent: AppSpacing.m),
                  SwitchListTile.adaptive(
                    value: _showLastSeen,
                    activeColor: AppColors.primary,
                    title: const Text('Show Last Seen'),
                    subtitle: const Text('Display your last connection timestamp'),
                    onChanged: (val) => setState(() => _showLastSeen = val),
                  ),
                  const Divider(height: 1, indent: AppSpacing.m, endIndent: AppSpacing.m),
                  SwitchListTile.adaptive(
                    value: _allowCallsFromAll,
                    activeColor: AppColors.primary,
                    title: const Text('Allow Incoming Calls'),
                    subtitle: const Text('Permit connections to place voice/video calls'),
                    onChanged: (val) => setState(() => _allowCallsFromAll = val),
                  ),
                  const Divider(height: 1, indent: AppSpacing.m, endIndent: AppSpacing.m),
                  TeloraListTile(
                    leading: const Icon(Icons.block_rounded, color: AppColors.error),
                    title: 'Blocked Users',
                    subtitle: 'Manage blocked profiles',
                    showDivider: false,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.blockedUsers),
                  ),
                ],
              ),
            ),

            // Notifications Section
            const TeloraSectionHeader(title: 'Notifications'),
            TeloraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _notificationsEnabled,
                    activeColor: AppColors.primary,
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive alerts for calls and messages'),
                    onChanged: (val) => setState(() => _notificationsEnabled = val),
                  ),
                ],
              ),
            ),

            // About & Version Section
            const TeloraSectionHeader(title: 'About'),
            TeloraCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  TeloraListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.onSurfaceVariant),
                    title: 'Application Version',
                    subtitle: '${AppConstants.appName} v1.0.0 (Production Architecture)',
                    showDivider: true,
                    trailing: const SizedBox.shrink(),
                  ),
                  TeloraListTile(
                    leading: const Icon(Icons.shield_outlined, color: AppColors.onSurfaceVariant),
                    title: 'Terms of Service & Privacy Policy',
                    showDivider: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
