import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Primary Home Dashboard for Telora.
class HomeTabScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;

  const HomeTabScreen({
    super.key,
    this.onNavigateTab,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userEmail = authState.email ?? 'Friend';
    final displayName = userEmail.split('@').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.m,
        title: Row(
          children: [
            UserAvatar(
              displayName: displayName,
              radius: 18,
              isOnline: true,
              showOnlineIndicator: true,
            ),
            const SizedBox(width: AppSpacing.s),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
                ),
                Text(
                  displayName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ],
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Entry
              InkWell(
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
                borderRadius: AppRadius.input,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: AppRadius.input,
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(AppIcons.search, size: 20, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.s),
                      Text(
                        'Search chats, calls, or people...',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.l),

              // Quick Communication Actions
              Row(
                children: [
                  _QuickActionButton(
                    icon: AppIcons.chats,
                    label: 'New Chat',
                    color: AppColors.primary,
                    onTap: () => onNavigateTab?.call(1),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  _QuickActionButton(
                    icon: AppIcons.voiceCall,
                    label: 'Start Call',
                    color: AppColors.secondary,
                    onTap: () => onNavigateTab?.call(2),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  _QuickActionButton(
                    icon: AppIcons.contacts,
                    label: 'Find People',
                    color: AppColors.tertiary,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Recent Conversations Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Chats',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab?.call(1),
                    child: const Text('View All'),
                  ),
                ],
              ),

              TeloraCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: TeloraEmptyState(
                  icon: AppIcons.chatsOutlined,
                  title: 'No recent messages',
                  description: 'Stay in touch with your friends and family worldwide.',
                  actionText: 'Start a Chat',
                  onAction: () => onNavigateTab?.call(1),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Recent Calls Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Calls',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab?.call(2),
                    child: const Text('Call History'),
                  ),
                ],
              ),

              TeloraCard(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: TeloraEmptyState(
                  icon: AppIcons.callsOutlined,
                  title: 'No recent calls',
                  description: 'Crystal-clear audio and video call records will show up here.',
                  actionText: 'Make Call',
                  onAction: () => onNavigateTab?.call(2),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Clean Ad Placeholder Container (AdService architecture compliant)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                  borderRadius: AppRadius.card,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withOpacity(0.2),
                        borderRadius: AppRadius.tag,
                      ),
                      child: Text(
                        'Ad',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Text(
                        'AdMob test placeholder - Hidden during active voice/video calls.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TeloraCard(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.m, horizontal: AppSpacing.s),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
