import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../contacts/presentation/controllers/connection_controller.dart';

/// Screen displaying all users blocked by the authenticated user with unblock actions.
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  void _showUnblockDialog(BuildContext context, WidgetRef ref, String userId, String displayName) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Are you sure you want to unblock $displayName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(connectionControllerProvider.notifier).unblockUser(userId);
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionControllerProvider);
    final blockedList = connectionState.blockedUsers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.blockedUsers),
      ),
      body: SafeArea(
        child: connectionState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : blockedList.isEmpty
                ? const Padding(
                    padding: AppSpacing.screenPadding,
                    child: TeloraEmptyState(
                      icon: AppIcons.privacy,
                      title: 'No Blocked Users',
                      description: 'Users you have blocked will be listed here. You have not blocked anyone.',
                    ),
                  )
                : ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: blockedList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final user = blockedList[index];
                      return TeloraCard(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
                        child: Row(
                          children: [
                            UserAvatar(
                              avatarUrl: user.avatarUrl,
                              displayName: user.displayName,
                              radius: 22,
                            ),
                            const SizedBox(width: AppSpacing.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName,
                                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '@${user.username}',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _showUnblockDialog(context, ref, user.id, user.displayName),
                              child: const Text(AppStrings.unblockUser),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
