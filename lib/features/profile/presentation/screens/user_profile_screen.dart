import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../../../../domain/entities/user_connection_entity.dart';
import '../../../../presentation/common_widgets/telora_button.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../calls/presentation/controllers/call_controller.dart';
import '../../../contacts/presentation/controllers/connection_controller.dart';
import '../../../chat/presentation/controllers/conversation_list_controller.dart';
import '../controllers/relationship_controller.dart';

/// Screen displaying another user's public profile and live relationship actions.
class UserProfileScreen extends ConsumerWidget {
  final ProfileEntity profile;

  const UserProfileScreen({
    super.key,
    required this.profile,
  });

  void _showBlockConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.blockUser),
        content: Text(
          'Are you sure you want to block ${profile.displayName}? They will no longer be able to message you, call you, or see your online status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(connectionControllerProvider.notifier).blockUser(profile.id);
              ref.invalidate(relationshipStatusProvider(profile.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${profile.displayName} has been blocked.')),
                );
              }
            },
            child: Text(
              AppStrings.blockUser,
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnblockConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.unblockUser),
        content: Text('Unblock ${profile.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(connectionControllerProvider.notifier).unblockUser(profile.id);
              ref.invalidate(relationshipStatusProvider(profile.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${profile.displayName} has been unblocked.')),
                );
              }
            },
            child: const Text(AppStrings.unblockUser),
          ),
        ],
      ),
    );
  }

  void _showRemoveConnectionDialog(BuildContext context, WidgetRef ref, String connectionId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(AppStrings.removeConnection),
        content: Text('Remove ${profile.displayName} from your connections?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(connectionControllerProvider.notifier).removeConnection(connectionId);
              ref.invalidate(relationshipStatusProvider(profile.id));
            },
            child: Text(
              AppStrings.removeConnection,
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relationAsync = ref.watch(relationshipStatusProvider(profile.id));
    final connectionState = ref.watch(connectionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(profile.displayName),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant),
            onSelected: (action) {
              if (action == 'block') {
                _showBlockConfirmation(context, ref);
              } else if (action == 'unblock') {
                _showUnblockConfirmation(context, ref);
              } else if (action == 'report') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted for review.')),
                );
              }
            },
            itemBuilder: (ctx) {
              final isBlocked = relationAsync.value == RelationshipStatus.blockedByMe;
              return [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report User'),
                ),
                PopupMenuItem(
                  value: isBlocked ? 'unblock' : 'block',
                  child: Text(
                    isBlocked ? AppStrings.unblockUser : AppStrings.blockUser,
                    style: TextStyle(color: isBlocked ? AppColors.primary : AppColors.error),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              TeloraCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    UserAvatar(
                      avatarUrl: profile.avatarUrl,
                      displayName: profile.displayName,
                      radius: 48,
                      isOnline: profile.isOnline,
                      showOnlineIndicator: true,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      profile.displayName,
                      style: AppTypography.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${profile.username}',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        profile.bio!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: profile.isOnline ? AppColors.online : AppColors.offline,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.isOnline ? AppStrings.online : AppStrings.offline,
                          style: AppTypography.labelSmall.copyWith(
                            color: profile.isOnline ? AppColors.online : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Relationship Action Widget
              relationAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (status) => _buildRelationshipActions(context, ref, status, connectionState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipActions(
    BuildContext context,
    WidgetRef ref,
    RelationshipStatus status,
    ConnectionState connectionState,
  ) {
    switch (status) {
      case RelationshipStatus.self:
        return TeloraOutlinedButton(
          text: 'Edit Your Profile',
          icon: Icons.edit_rounded,
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.editProfile),
        );

      case RelationshipStatus.blockedByMe:
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'You have blocked this user.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            TeloraButton(
              text: AppStrings.unblockUser,
              onPressed: () => _showUnblockConfirmation(context, ref),
            ),
          ],
        );

      case RelationshipStatus.blockedByThem:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'User profile is not accessible.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
          ),
        );

      case RelationshipStatus.connected:
        // Find connection ID
        final matching = connectionState.connections.where((c) =>
            c.requesterId == profile.id || c.receiverId == profile.id).toList();
        final connId = matching.isNotEmpty ? matching.first.id : '';

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TeloraButton(
                    text: AppStrings.message,
                    icon: AppIcons.chats,
                    onPressed: () async {
                      final conv = await ref
                          .read(conversationListControllerProvider.notifier)
                          .openOrCreateDirectChat(profile.id);
                      if (conv != null && context.mounted) {
                        Navigator.of(context).pushNamed(
                          AppRoutes.chatConversation,
                          arguments: {
                            'conversationId': conv.id,
                            'otherMember': profile,
                          },
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: TeloraOutlinedButton(
                    text: AppStrings.voiceCall,
                    icon: AppIcons.voiceCall,
                    onPressed: () async {
                      final success = await ref
                          .read(callControllerProvider.notifier)
                          .startCall(
                            receiverId: profile.id,
                            type: CallType.voice,
                            receiverProfile: profile,
                          );
                      if (success && context.mounted) {
                        Navigator.of(context).pushNamed(AppRoutes.voiceCall);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            TeloraOutlinedButton(
              text: AppStrings.videoCall,
              icon: AppIcons.videoCall,
              onPressed: () async {
                final success = await ref
                    .read(callControllerProvider.notifier)
                    .startCall(
                      receiverId: profile.id,
                      type: CallType.video,
                      receiverProfile: profile,
                    );
                if (success && context.mounted) {
                  Navigator.of(context).pushNamed(AppRoutes.videoCall);
                }
              },
            ),
            const SizedBox(height: AppSpacing.m),
            if (connId.isNotEmpty)
              TextButton(
                onPressed: () => _showRemoveConnectionDialog(context, ref, connId),
                child: Text(
                  AppStrings.removeConnection,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                ),
              ),
          ],
        );

      case RelationshipStatus.pendingSent:
        final matching = connectionState.outgoingRequests.where((c) => c.receiverId == profile.id).toList();
        final reqId = matching.isNotEmpty ? matching.first.id : '';

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    AppStrings.requestSent,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (reqId.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () async {
                  await ref.read(connectionControllerProvider.notifier).cancelRequest(reqId);
                  ref.invalidate(relationshipStatusProvider(profile.id));
                },
                child: Text(
                  AppStrings.cancelRequest,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        );

      case RelationshipStatus.pendingReceived:
        final matching = connectionState.incomingRequests.where((c) => c.requesterId == profile.id).toList();
        final reqId = matching.isNotEmpty ? matching.first.id : '';

        return Row(
          children: [
            Expanded(
              child: TeloraButton(
                text: AppStrings.accept,
                onPressed: reqId.isNotEmpty
                    ? () async {
                        await ref.read(connectionControllerProvider.notifier).acceptRequest(reqId);
                        ref.invalidate(relationshipStatusProvider(profile.id));
                      }
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: TeloraOutlinedButton(
                text: AppStrings.reject,
                onPressed: reqId.isNotEmpty
                    ? () async {
                        await ref.read(connectionControllerProvider.notifier).rejectRequest(reqId);
                        ref.invalidate(relationshipStatusProvider(profile.id));
                      }
                    : null,
              ),
            ),
          ],
        );

      case RelationshipStatus.none:
      default:
        return TeloraButton(
          text: AppStrings.addConnection,
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () async {
            final sent = await ref
                .read(connectionControllerProvider.notifier)
                .sendRequest(profile.id);
            if (sent) {
              ref.invalidate(relationshipStatusProvider(profile.id));
            }
          },
        );
    }
  }
}
