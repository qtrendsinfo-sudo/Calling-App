enum MessageType {
  text,
  image,
  voice,
  file,
  system,
}

/// Domain representation of a chat message in Telora.
class MessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.messageType = MessageType.text,
    required this.content,
    this.isRead = false,
    required this.createdAt,
    this.editedAt,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? messageType,
    String? content,
    bool? isRead,
    DateTime? createdAt,
    DateTime? editedAt,
    DateTime? deletedAt,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory MessageEntity.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final typeStr = map['message_type'] as String? ?? 'text';
    final MessageType type;
    switch (typeStr) {
      case 'image':
        type = MessageType.image;
        break;
      case 'voice':
        type = MessageType.voice;
        break;
      case 'file':
        type = MessageType.file;
        break;
      case 'system':
        type = MessageType.system;
        break;
      default:
        type = MessageType.text;
    }

    return MessageEntity(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      messageType: type,
      content: map['content'] as String? ?? '',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      editedAt: map['edited_at'] != null ? DateTime.tryParse(map['edited_at'] as String) : null,
      deletedAt: map['deleted_at'] != null ? DateTime.tryParse(map['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType.name,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}
