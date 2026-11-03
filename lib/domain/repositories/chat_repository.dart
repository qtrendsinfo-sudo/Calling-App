import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<ConversationEntity>> getConversations();
  Future<ConversationEntity> getOrCreateDirectConversation(String recipientUserId);
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 30,
    DateTime? before,
  });
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  });
  Future<void> markAsRead(String conversationId);
  Stream<MessageEntity> subscribeToMessages(String conversationId);
}
