import 'message_entity.dart';
import 'profile_entity.dart';

/// Domain representation of a conversation thread.
class ConversationEntity {
  final String id;
  final bool isGroup;
  final String? title;
  final List<ProfileEntity> members;
  final MessageEntity? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    this.isGroup = false,
    this.title,
    required this.members,
    this.lastMessage,
    this.unreadCount = 0,
    required this.updatedAt,
  });

  /// Returns the other member's profile for direct one-to-one conversations.
  ProfileEntity? getOtherMember(String currentUserId) {
    if (members.isEmpty) return null;
    final other = members.where((m) => m.id != currentUserId).toList();
    return other.isNotEmpty ? other.first : members.first;
  }

  ConversationEntity copyWith({
    String? id,
    bool? isGroup,
    String? title,
    List<ProfileEntity>? members,
    MessageEntity? lastMessage,
    int? unreadCount,
    DateTime? updatedAt,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      members: members ?? this.members,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationEntity.fromMap(
    Map<String, dynamic> map, {
    String? currentUserId,
    List<ProfileEntity> members = const [],
    MessageEntity? lastMessage,
    int unreadCount = 0,
  }) {
    final type = map['type'] as String? ?? 'direct';
    return ConversationEntity(
      id: map['id'] as String,
      isGroup: type == 'group',
      title: map['title'] as String?,
      members: members,
      lastMessage: lastMessage,
      unreadCount: unreadCount,
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': isGroup ? 'group' : 'direct',
      'title': title,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
