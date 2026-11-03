import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/conversation_entity.dart';
import '../../../../presentation/common_widgets/telora_badge.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/conversation_list_controller.dart';

/// Screen displaying the active conversations list with real-time updates and unread badges.
class ChatListTabScreen extends ConsumerWidget {
  const ChatListTabScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time);
    } else {
      return DateFormat.MMMd().format(time);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(conversationListControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navChats),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.search, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
            tooltip: AppStrings.search,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(conversationListControllerProvider.notifier).loadConversations(),
          child: _buildBody(context, ref, listState, currentUserId),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 2,
        tooltip: 'New Chat',
        child: const Icon(Icons.edit_note_rounded, size: 26),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ConversationListState state,
    String currentUserId,
  ) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.conversations.isEmpty) {
      return Padding(
        padding: AppSpacing.screenPadding,
        child: TeloraEmptyState(
          icon: AppIcons.chatsOutlined,
          title: AppStrings.emptyChatsTitle,
          description: AppStrings.emptyChatsDesc,
          actionText: 'Find People',
          onAction: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
        ),
      );
    }

    return ListView.separated(
      padding: AppSpacing.screenPadding,
      itemCount: state.conversations.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        final otherMember = conversation.getOtherMember(currentUserId);
        final displayName = otherMember?.displayName ?? conversation.title ?? 'Chat';
        final lastMsg = conversation.lastMessage;
        final preview = lastMsg != null
            ? (lastMsg.senderId == currentUserId ? 'You: ' : '') + lastMsg.content
            : 'No messages yet';

        return TeloraCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRoutes.chatConversation,
              arguments: {
                'conversationId': conversation.id,
                'otherMember': otherMember,
              },
            );
          },
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: otherMember?.avatarUrl,
                displayName: displayName,
                radius: 26,
                isOnline: otherMember?.isOnline ?? false,
                showOnlineIndicator: true,
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: AppColors.onBackground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMsg != null)
                          Text(
                            _formatTime(lastMsg.createdAt),
                            style: AppTypography.labelSmall.copyWith(
                              color: conversation.unreadCount > 0
                                  ? AppColors.primary
                                  : AppColors.onSurfaceVariant,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            style: AppTypography.bodySmall.copyWith(
                              color: conversation.unreadCount > 0
                                  ? AppColors.onBackground
                                  : AppColors.onSurfaceVariant,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: AppSpacing.s),
                          TeloraBadge(count: conversation.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
