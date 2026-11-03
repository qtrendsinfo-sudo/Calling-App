import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/supabase_error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/conversation_entity.dart';
import '../../../domain/entities/message_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../mock/mock_datasources.dart';

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  if (kIsWeb || !SupabaseService.instance.isInitialized) {
    return MockChatDataSourceImpl();
  }
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseChatDataSourceImpl(supabase);
});

abstract class ChatRemoteDataSource {
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

class SupabaseChatDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseChatDataSourceImpl(this._supabase);

  String get _currentUserId {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException(message: 'Authentication required');
    }
    return uid;
  }

  @override
  Future<List<ConversationEntity>> getConversations() async {
    final uid = _currentUserId;
    try {
      // 1. Fetch conversations where current user is a member
      final memberRows = await _supabase
          .from('conversation_members')
          .select('conversation_id, last_read_at')
          .eq('user_id', uid);

      if ((memberRows as List).isEmpty) return [];

      final conversationIds = memberRows.map((r) => r['conversation_id'] as String).toList();
      final lastReadMap = <String, DateTime?>{};
      for (final r in memberRows) {
        final cid = r['conversation_id'] as String;
        final lread = r['last_read_at'] as String?;
        lastReadMap[cid] = lread != null ? DateTime.tryParse(lread) : null;
      }

      final conversationsData = await _supabase
          .from('conversations')
          .select('id, type, title, user_a, user_b, updated_at')
          .filter('id', 'in', conversationIds)
          .order('updated_at', ascending: false);

      final conversations = <ConversationEntity>[];

      for (final row in conversationsData as List) {
        final convId = row['id'] as String;
        final type = row['type'] as String? ?? 'direct';

        // Fetch members of this conversation
        final membersData = await _supabase
            .from('conversation_members')
            .select('user_id, profiles(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at)')
            .eq('conversation_id', convId);

        final members = <ProfileEntity>[];
        for (final m in membersData as List) {
          if (m['profiles'] != null) {
            members.add(ProfileEntity.fromMap(m['profiles'] as Map<String, dynamic>));
          }
        }

        // Fetch latest message
        final latestMsgData = await _supabase
            .from('messages')
            .select()
            .eq('conversation_id', convId)
            .filter('deleted_at', 'is', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final latestMessage =
            latestMsgData != null ? MessageEntity.fromMap(latestMsgData) : null;

        // Count unread messages
        final lastRead = lastReadMap[convId];
        int unreadCount = 0;
        if (lastRead != null) {
          final countRes = await _supabase
              .from('messages')
              .select('id')
              .eq('conversation_id', convId)
              .neq('sender_id', uid)
              .gt('created_at', lastRead.toIso8601String())
              .filter('deleted_at', 'is', null);
          unreadCount = (countRes as List).length;
        } else if (latestMessage != null && latestMessage.senderId != uid) {
          unreadCount = 1;
        }

        conversations.add(
          ConversationEntity(
            id: convId,
            isGroup: type == 'group',
            title: row['title'] as String?,
            members: members,
            lastMessage: latestMessage,
            unreadCount: unreadCount,
            updatedAt: row['updated_at'] != null
                ? (DateTime.tryParse(row['updated_at'] as String) ?? DateTime.now())
                : DateTime.now(),
          ),
        );
      }

      return conversations;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<ConversationEntity> getOrCreateDirectConversation(String recipientUserId) async {
    final uid = _currentUserId;
    if (uid == recipientUserId) {
      throw const AppException(message: 'Cannot create a conversation with yourself.');
    }

    try {
      String? convId;

      // 1. Try helper RPC if deployed
      try {
        final rpcResult = await _supabase.rpc('get_or_create_direct_conversation', params: {
          'p_recipient_user_id': recipientUserId,
        });
        if (rpcResult != null) {
          convId = rpcResult as String;
        }
      } catch (_) {
        // Fallback to direct queries
      }

      // 2. Direct fallback (strictly validating connection and block state)
      if (convId == null) {
        // Enforce block verification
        final blocked = await _supabase
            .from('blocked_users')
            .select('id')
            .or('and(blocker_id.eq.$uid,blocked_id.eq.$recipientUserId),and(blocker_id.eq.$recipientUserId,blocked_id.eq.$uid)')
            .maybeSingle();

        if (blocked != null) {
          throw const AppException(message: 'Unable to communicate with this user.');
        }

        // Enforce active connection verification
        final connection = await _supabase
            .from('user_connections')
            .select('id')
            .eq('status', 'accepted')
            .or('and(requester_id.eq.$uid,receiver_id.eq.$recipientUserId),and(requester_id.eq.$recipientUserId,receiver_id.eq.$uid)')
            .maybeSingle();

        if (connection == null) {
          throw const AppException(message: 'You must be connected to start a conversation.');
        }

        final userA = uid.compareTo(recipientUserId) < 0 ? uid : recipientUserId;
        final userB = uid.compareTo(recipientUserId) < 0 ? recipientUserId : uid;

        final existing = await _supabase
            .from('conversations')
            .select('id')
            .eq('user_a', userA)
            .eq('user_b', userB)
            .maybeSingle();

        if (existing != null) {
          convId = existing['id'] as String;
        } else {
          final inserted = await _supabase
              .from('conversations')
              .insert({
                'type': 'direct',
                'user_a': userA,
                'user_b': userB,
              })
              .select('id')
              .single();

          convId = inserted['id'] as String;

          await _supabase.from('conversation_members').upsert([
            {'conversation_id': convId, 'user_id': userA},
            {'conversation_id': convId, 'user_id': userB},
          ]);
        }
      }

      // Fetch recipient profile
      final otherProfileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', recipientUserId)
          .maybeSingle();
      final otherProfile = otherProfileData != null ? ProfileEntity.fromMap(otherProfileData) : null;

      return ConversationEntity(
        id: convId,
        isGroup: false,
        members: otherProfile != null ? [otherProfile] : [],
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<List<MessageEntity>> getMessages({
    required String conversationId,
    int limit = 30,
    DateTime? before,
  }) async {
    try {
      var query = _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .filter('deleted_at', 'is', null);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false).limit(limit);

      return (data as List).map((row) => MessageEntity.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    final uid = _currentUserId;
    final trimmed = content.trim();

    if (trimmed.isEmpty) {
      throw const AppException(message: 'Message cannot be empty.');
    }

    if (trimmed.length > 2000) {
      throw const AppException(message: 'Message exceeds maximum length (2000 characters).');
    }

    try {
      final inserted = await _supabase
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': uid,
            'content': trimmed,
            'message_type': type.name,
          })
          .select()
          .single();

      // Trigger automatic updated_at timestamp on conversations
      await _supabase
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', conversationId);

      return MessageEntity.fromMap(inserted);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    final uid = _currentUserId;
    try {
      await _supabase
          .from('conversation_members')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', uid);
    } catch (_) {
      // Non-blocking read receipt update
    }
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    late StreamController<MessageEntity> controller;
    RealtimeChannel? channel;

    controller = StreamController<MessageEntity>.broadcast(
      onListen: () {
        channel = _supabase.channel('public:messages:$conversationId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            try {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                final message = MessageEntity.fromMap(newRecord);
                if (!controller.isClosed) {
                  controller.add(message);
                }
              }
            } catch (_) {}
          },
        );

        channel?.subscribe();
      },
      onCancel: () {
        channel?.unsubscribe();
        controller.close();
      },
    );

    return controller.stream;
  }
}
