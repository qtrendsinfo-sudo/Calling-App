import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../domain/entities/conversation_entity.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/chat_repository_impl.dart';

class ConversationListState {
  final bool isLoading;
  final List<ConversationEntity> conversations;
  final String? errorMessage;

  const ConversationListState({
    this.isLoading = false,
    this.conversations = const [],
    this.errorMessage,
  });

  ConversationListState copyWith({
    bool? isLoading,
    List<ConversationEntity>? conversations,
    String? errorMessage,
  }) {
    return ConversationListState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      errorMessage: errorMessage,
    );
  }

  int get totalUnreadCount =>
      conversations.fold(0, (sum, item) => sum + item.unreadCount);
}

final conversationListControllerProvider =
    StateNotifierProvider<ConversationListController, ConversationListState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return ConversationListController(repository, userId);
});

class ConversationListController extends StateNotifier<ConversationListState> {
  final ChatRepository _repository;
  final String? _currentUserId;

  ConversationListController(this._repository, this._currentUserId)
      : super(const ConversationListState(isLoading: true)) {
    if (_currentUserId != null) {
      loadConversations();
    }
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getConversations();
      state = state.copyWith(
        isLoading: false,
        conversations: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<ConversationEntity?> openOrCreateDirectChat(String recipientUserId) async {
    try {
      final conversation =
          await _repository.getOrCreateDirectConversation(recipientUserId);
      await loadConversations();
      return conversation;
    } catch (e) {
      state = state.copyWith(errorMessage: ErrorHandler.getUserMessage(e));
      return null;
    }
  }
}
