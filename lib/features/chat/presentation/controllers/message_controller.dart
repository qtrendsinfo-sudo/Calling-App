import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../domain/entities/message_entity.dart';
import '../../../../domain/repositories/chat_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/chat_repository_impl.dart';

class MessageState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSending;
  final List<MessageEntity> messages;
  final bool hasReachedEnd;
  final String? errorMessage;

  const MessageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSending = false,
    this.messages = const [],
    this.hasReachedEnd = false,
    this.errorMessage,
  });

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSending,
    List<MessageEntity>? messages,
    bool? hasReachedEnd,
    String? errorMessage,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: errorMessage,
    );
  }
}

final messageControllerProvider = StateNotifierProvider.autoDispose
    .family<MessageController, MessageState, String>((ref, conversationId) {
  final repository = ref.watch(chatRepositoryProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return MessageController(repository, conversationId, currentUserId);
});

class MessageController extends StateNotifier<MessageState> {
  final ChatRepository _repository;
  final String _conversationId;
  final String? _currentUserId;
  StreamSubscription<MessageEntity>? _realtimeSubscription;
  static const int _pageSize = 30;

  MessageController(this._repository, this._conversationId, this._currentUserId)
      : super(const MessageState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await loadInitialMessages();
    _subscribeToRealtime();
    _markRead();
  }

  Future<void> loadInitialMessages() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final history = await _repository.getMessages(
        conversationId: _conversationId,
        limit: _pageSize,
      );

      state = state.copyWith(
        isLoading: false,
        messages: history,
        hasReachedEnd: history.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || state.hasReachedEnd || state.messages.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final oldestMessage = state.messages.last;
      final older = await _repository.getMessages(
        conversationId: _conversationId,
        limit: _pageSize,
        before: oldestMessage.createdAt,
      );

      state = state.copyWith(
        isLoadingMore: false,
        messages: [...state.messages, ...older],
        hasReachedEnd: older.length < _pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
    }
  }

  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _currentUserId == null) return false;

    state = state.copyWith(isSending: true, errorMessage: null);
    try {
      final sent = await _repository.sendMessage(
        conversationId: _conversationId,
        content: trimmed,
      );

      // De-duplicate if realtime event already added it
      final exists = state.messages.any((m) => m.id == sent.id);
      if (!exists) {
        state = state.copyWith(
          isSending: false,
          messages: [sent, ...state.messages],
        );
      } else {
        state = state.copyWith(isSending: false);
      }

      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      return false;
    }
  }

  void _subscribeToRealtime() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = _repository.subscribeToMessages(_conversationId).listen((newMsg) {
      // Check de-duplication
      final exists = state.messages.any((m) => m.id == newMsg.id);
      if (!exists) {
        state = state.copyWith(messages: [newMsg, ...state.messages]);
        _markRead();
      }
    });
  }

  void _markRead() {
    _repository.markAsRead(_conversationId);
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
