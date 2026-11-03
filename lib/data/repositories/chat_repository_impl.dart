import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/remote/supabase_chat_datasource.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final dataSource = ref.watch(chatRemoteDataSourceProvider);
  return ChatRepositoryImpl(dataSource);
});

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _dataSource;

  ChatRepositoryImpl(this._dataSource);

  @override
  Future<List<ConversationEntity>> getConversations() {
    return _dataSource.getConversations();
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation(String recipientUserId) {
    return _dataSource.getOrCreateDirectConversation(recipientUserId);
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 30,
    DateTime? before,
  }) {
    return _dataSource.getMessages(
      conversationId: conversationId,
      limit: limit,
      before: before,
    );
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) {
    return _dataSource.sendMessage(
      conversationId: conversationId,
      content: content,
      type: type,
    );
  }

  @override
  Future<void> markAsRead(String conversationId) {
    return _dataSource.markAsRead(conversationId);
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    return _dataSource.subscribeToMessages(conversationId);
  }
}
