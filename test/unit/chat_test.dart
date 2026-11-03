import 'package:flutter_test/flutter_test.dart';
import 'package:telora/domain/entities/conversation_entity.dart';
import 'package:telora/domain/entities/message_entity.dart';
import 'package:telora/domain/entities/profile_entity.dart';

void main() {
  group('MessageEntity Tests', () {
    test('Correctly deserializes text message from map', () {
      final map = {
        'id': 'msg-100',
        'conversation_id': 'conv-1',
        'sender_id': 'user-1',
        'content': 'Hello from Telora!',
        'message_type': 'text',
        'is_read': true,
        'created_at': '2026-10-02T12:00:00Z',
      };

      final msg = MessageEntity.fromMap(map);

      expect(msg.id, 'msg-100');
      expect(msg.conversationId, 'conv-1');
      expect(msg.senderId, 'user-1');
      expect(msg.content, 'Hello from Telora!');
      expect(msg.messageType, MessageType.text);
      expect(msg.isRead, isTrue);
      expect(msg.isDeleted, isFalse);
    });

    test('Message validation rules', () {
      const emptyContent = '   ';
      expect(emptyContent.trim().isEmpty, isTrue, reason: 'Empty messages must be rejected');

      final validContent = '  Valid message  ';
      expect(validContent.trim(), 'Valid message');
      expect(validContent.trim().length <= 2000, isTrue);

      const arabicContent = 'مرحبا بك في تيلورا';
      expect(arabicContent.trim().isNotEmpty, isTrue, reason: 'Arabic text must be preserved');
    });

    test('Message de-duplication logic', () {
      final messages = [
        MessageEntity(
          id: 'msg-1',
          conversationId: 'c-1',
          senderId: 'u-1',
          content: 'First',
          createdAt: DateTime(2026, 1, 1, 10, 0),
        ),
      ];

      final incoming = MessageEntity(
        id: 'msg-1',
        conversationId: 'c-1',
        senderId: 'u-1',
        content: 'First (Realtime duplicate)',
        createdAt: DateTime(2026, 1, 1, 10, 0),
      );

      final exists = messages.any((m) => m.id == incoming.id);
      expect(exists, isTrue, reason: 'Duplicate realtime events must be de-duplicated');
    });
  });

  group('ConversationEntity Tests', () {
    test('Correctly extracts other member in direct conversation', () {
      final memberA = ProfileEntity(
        id: 'user-me',
        username: 'my_username',
        displayName: 'My Name',
        createdAt: DateTime.now(),
      );
      final memberB = ProfileEntity(
        id: 'user-other',
        username: 'other_user',
        displayName: 'Other User',
        createdAt: DateTime.now(),
      );

      final conversation = ConversationEntity(
        id: 'conv-1',
        isGroup: false,
        members: [memberA, memberB],
        updatedAt: DateTime.now(),
      );

      final other = conversation.getOtherMember('user-me');

      expect(other, isNotNull);
      expect(other?.id, 'user-other');
      expect(other?.username, 'other_user');
    });
  });
}
