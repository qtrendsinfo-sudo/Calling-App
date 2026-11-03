import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../calls/presentation/controllers/call_controller.dart';
import '../controllers/message_controller.dart';

/// One-to-one real-time text chat screen with cursor pagination and composer.
class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final ProfileEntity? otherMember;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.otherMember,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(messageControllerProvider(widget.conversationId).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    final success = await ref
        .read(messageControllerProvider(widget.conversationId).notifier)
        .sendMessage(text);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.messageFailed)),
      );
    }
  }

  String _formatMessageTime(DateTime time) {
    return DateFormat.jm().format(time);
  }

  @override
  Widget build(BuildContext context) {
    final messageState = ref.watch(messageControllerProvider(widget.conversationId));
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';
    final other = widget.otherMember;
    final displayName = other?.displayName ?? 'Conversation';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: other != null
              ? () => Navigator.of(context).pushNamed(AppRoutes.userProfile, arguments: other)
              : null,
          child: Row(
            children: [
              UserAvatar(
                avatarUrl: other?.avatarUrl,
                displayName: displayName,
                radius: 18,
                isOnline: other?.isOnline ?? false,
                showOnlineIndicator: true,
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      other?.isOnline == true ? AppStrings.online : AppStrings.offline,
                      style: AppTypography.labelSmall.copyWith(
                        color: other?.isOnline == true ? AppColors.online : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.voiceCall, color: AppColors.onSurfaceVariant),
            tooltip: AppStrings.voiceCall,
            onPressed: () async {
              if (other == null) return;
              final success = await ref
                  .read(callControllerProvider.notifier)
                  .startCall(
                    receiverId: other.id,
                    type: CallType.voice,
                    receiverProfile: other,
                  );
              if (success && context.mounted) {
                Navigator.of(context).pushNamed(AppRoutes.voiceCall);
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages List Area
            Expanded(
              child: _buildMessagesList(messageState, currentUserId),
            ),

            // Message Composer Area
            _buildComposer(messageState),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(MessageState state, String currentUserId) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(AppIcons.chats, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                'No messages yet',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Send a message to start the conversation.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
      itemCount: state.messages.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.messages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.s),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final msg = state.messages[index];
        final isMine = msg.senderId == currentUserId;

        return _buildMessageBubble(msg, isMine);
      },
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: AppTypography.bodyMedium.copyWith(
                color: isMine ? AppColors.onPrimary : AppColors.onBackground,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMessageTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine
                        ? AppColors.onPrimary.withOpacity(0.7)
                        : AppColors.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 14,
                    color: AppColors.onPrimary.withOpacity(0.8),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(MessageState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.input,
              ),
              child: TextField(
                controller: _textController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: AppStrings.typeAMessage,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: state.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20, color: AppColors.onPrimary),
              onPressed: state.isSending ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }
}
