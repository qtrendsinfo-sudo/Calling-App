import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/supabase_error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/user_connection_entity.dart';
import '../mock/mock_datasources.dart';

final connectionRemoteDataSourceProvider = Provider<ConnectionRemoteDataSource>((ref) {
  if (kIsWeb || !SupabaseService.instance.isInitialized) {
    return MockConnectionDataSourceImpl();
  }
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseConnectionDataSourceImpl(supabase);
});

abstract class ConnectionRemoteDataSource {
  Future<List<UserConnectionEntity>> getConnections();
  Future<List<UserConnectionEntity>> getIncomingRequests();
  Future<List<UserConnectionEntity>> getOutgoingRequests();
  Future<void> sendConnectionRequest(String targetUserId);
  Future<void> acceptConnectionRequest(String connectionId);
  Future<void> rejectConnectionRequest(String connectionId);
  Future<void> cancelConnectionRequest(String connectionId);
  Future<void> removeConnection(String connectionId);
  Future<void> blockUser(String targetUserId);
  Future<void> unblockUser(String targetUserId);
  Future<List<ProfileEntity>> getBlockedUsers();
  Future<RelationshipStatus> getRelationshipStatus(String targetUserId);
}

class SupabaseConnectionDataSourceImpl implements ConnectionRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseConnectionDataSourceImpl(this._supabase);

  String get _currentUserId {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException(message: 'Authentication required');
    }
    return uid;
  }

  @override
  Future<List<UserConnectionEntity>> getConnections() async {
    final uid = _currentUserId;
    try {
      final data = await _supabase
          .from('user_connections')
          .select('''
            id, requester_id, receiver_id, status, created_at, updated_at,
            requester:profiles!user_connections_requester_id_fkey(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at),
            receiver:profiles!user_connections_receiver_id_fkey(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at)
          ''')
          .eq('status', 'accepted')
          .or('requester_id.eq.$uid,receiver_id.eq.$uid')
          .order('updated_at', ascending: false);

      return (data as List).map((row) {
        return UserConnectionEntity.fromMap(row as Map<String, dynamic>, currentUserId: uid);
      }).toList();
    } catch (e) {
      // Fallback in case embedded foreign key syntax varies
      try {
        final fallback = await _supabase
            .from('user_connections')
            .select()
            .eq('status', 'accepted')
            .or('requester_id.eq.$uid,receiver_id.eq.$uid')
            .order('updated_at', ascending: false);

        final items = <UserConnectionEntity>[];
        for (final row in fallback as List) {
          final otherId = row['requester_id'] == uid ? row['receiver_id'] : row['requester_id'];
          final profileData = await _supabase.from('profiles').select().eq('id', otherId).maybeSingle();
          final profile = profileData != null ? ProfileEntity.fromMap(profileData) : null;
          items.add(UserConnectionEntity.fromMap(row, currentUserId: uid).copyWith(profile: profile));
        }
        return items;
      } catch (err) {
        throw SupabaseErrorHandler.handleError(err);
      }
    }
  }

  @override
  Future<List<UserConnectionEntity>> getIncomingRequests() async {
    final uid = _currentUserId;
    try {
      final data = await _supabase
          .from('user_connections')
          .select('''
            id, requester_id, receiver_id, status, created_at, updated_at,
            requester:profiles!user_connections_requester_id_fkey(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at)
          ''')
          .eq('status', 'pending')
          .eq('receiver_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        return UserConnectionEntity.fromMap(row as Map<String, dynamic>, currentUserId: uid);
      }).toList();
    } catch (e) {
      try {
        final fallback = await _supabase
            .from('user_connections')
            .select()
            .eq('status', 'pending')
            .eq('receiver_id', uid)
            .order('created_at', ascending: false);

        final items = <UserConnectionEntity>[];
        for (final row in fallback as List) {
          final requesterId = row['requester_id'] as String;
          final profileData = await _supabase.from('profiles').select().eq('id', requesterId).maybeSingle();
          final profile = profileData != null ? ProfileEntity.fromMap(profileData) : null;
          items.add(UserConnectionEntity.fromMap(row, currentUserId: uid).copyWith(profile: profile));
        }
        return items;
      } catch (err) {
        throw SupabaseErrorHandler.handleError(err);
      }
    }
  }

  @override
  Future<List<UserConnectionEntity>> getOutgoingRequests() async {
    final uid = _currentUserId;
    try {
      final data = await _supabase
          .from('user_connections')
          .select('''
            id, requester_id, receiver_id, status, created_at, updated_at,
            receiver:profiles!user_connections_receiver_id_fkey(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at)
          ''')
          .eq('status', 'pending')
          .eq('requester_id', uid)
          .order('created_at', ascending: false);

      return (data as List).map((row) {
        return UserConnectionEntity.fromMap(row as Map<String, dynamic>, currentUserId: uid);
      }).toList();
    } catch (e) {
      try {
        final fallback = await _supabase
            .from('user_connections')
            .select()
            .eq('status', 'pending')
            .eq('requester_id', uid)
            .order('created_at', ascending: false);

        final items = <UserConnectionEntity>[];
        for (final row in fallback as List) {
          final receiverId = row['receiver_id'] as String;
          final profileData = await _supabase.from('profiles').select().eq('id', receiverId).maybeSingle();
          final profile = profileData != null ? ProfileEntity.fromMap(profileData) : null;
          items.add(UserConnectionEntity.fromMap(row, currentUserId: uid).copyWith(profile: profile));
        }
        return items;
      } catch (err) {
        throw SupabaseErrorHandler.handleError(err);
      }
    }
  }

  @override
  Future<void> sendConnectionRequest(String targetUserId) async {
    final uid = _currentUserId;
    if (uid == targetUserId) {
      throw const AppException(message: 'You cannot send a connection request to yourself.');
    }

    try {
      // Check if blocked in either direction
      final blocked = await _supabase
          .from('blocked_users')
          .select('id')
          .or('and(blocker_id.eq.$uid,blocked_id.eq.$targetUserId),and(blocker_id.eq.$targetUserId,blocked_id.eq.$uid)')
          .maybeSingle();

      if (blocked != null) {
        throw const AppException(message: 'Unable to connect with this user.');
      }

      // Check if an existing connection record exists
      final existing = await _supabase
          .from('user_connections')
          .select('id, status, requester_id')
          .or('and(requester_id.eq.$uid,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$uid)')
          .maybeSingle();

      if (existing != null) {
        final status = existing['status'];
        if (status == 'accepted') {
          throw const AppException(message: 'You are already connected with this user.');
        } else if (status == 'pending') {
          throw const AppException(message: 'A connection request is already pending.');
        } else {
          // Re-send after previous cancellation / rejection by updating to pending
          await _supabase.from('user_connections').update({
            'requester_id': uid,
            'receiver_id': targetUserId,
            'status': 'pending',
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing['id']);
          return;
        }
      }

      await _supabase.from('user_connections').insert({
        'requester_id': uid,
        'receiver_id': targetUserId,
        'status': 'pending',
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw const AppException(message: 'A connection request already exists.');
      }
      throw SupabaseErrorHandler.handleError(e);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> acceptConnectionRequest(String connectionId) async {
    final uid = _currentUserId;
    try {
      await _supabase
          .from('user_connections')
          .update({
            'status': 'accepted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', connectionId)
          .eq('receiver_id', uid);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> rejectConnectionRequest(String connectionId) async {
    final uid = _currentUserId;
    try {
      // Removing rejected request allows clean future re-requests
      await _supabase
          .from('user_connections')
          .delete()
          .eq('id', connectionId)
          .eq('receiver_id', uid);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> cancelConnectionRequest(String connectionId) async {
    final uid = _currentUserId;
    try {
      await _supabase
          .from('user_connections')
          .delete()
          .eq('id', connectionId)
          .eq('requester_id', uid);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> removeConnection(String connectionId) async {
    final uid = _currentUserId;
    try {
      await _supabase
          .from('user_connections')
          .delete()
          .eq('id', connectionId)
          .or('requester_id.eq.$uid,receiver_id.eq.$uid');
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> blockUser(String targetUserId) async {
    final uid = _currentUserId;
    if (uid == targetUserId) {
      throw const AppException(message: 'You cannot block yourself.');
    }

    try {
      // 1. Insert into blocked_users
      await _supabase.from('blocked_users').upsert({
        'blocker_id': uid,
        'blocked_id': targetUserId,
      });

      // 2. Remove any connection or pending request between the two users
      await _supabase
          .from('user_connections')
          .delete()
          .or('and(requester_id.eq.$uid,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$uid)');
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    final uid = _currentUserId;
    try {
      await _supabase
          .from('blocked_users')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', targetUserId);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<List<ProfileEntity>> getBlockedUsers() async {
    final uid = _currentUserId;
    try {
      final data = await _supabase
          .from('blocked_users')
          .select('''
            blocked_id,
            blocked:profiles!blocked_users_blocked_id_fkey(id, username, display_name, avatar_url, bio, is_online, last_seen, created_at)
          ''')
          .eq('blocker_id', uid)
          .order('created_at', ascending: false);

      final profiles = <ProfileEntity>[];
      for (final row in data as List) {
        if (row['blocked'] != null) {
          profiles.add(ProfileEntity.fromMap(row['blocked'] as Map<String, dynamic>));
        }
      }
      return profiles;
    } catch (e) {
      // Fallback
      try {
        final fallback = await _supabase
            .from('blocked_users')
            .select('blocked_id')
            .eq('blocker_id', uid);

        final list = <ProfileEntity>[];
        for (final row in fallback as List) {
          final p = await _supabase.from('profiles').select().eq('id', row['blocked_id']).maybeSingle();
          if (p != null) list.add(ProfileEntity.fromMap(p));
        }
        return list;
      } catch (err) {
        throw SupabaseErrorHandler.handleError(err);
      }
    }
  }

  @override
  Future<RelationshipStatus> getRelationshipStatus(String targetUserId) async {
    final uid = _currentUserId;
    if (uid == targetUserId) return RelationshipStatus.self;

    try {
      // 1. Try helper RPC if deployed
      try {
        final rpcResult = await _supabase.rpc('get_relationship_status', params: {
          'p_target_user_id': targetUserId,
        });
        if (rpcResult != null) {
          switch (rpcResult as String) {
            case 'self':
              return RelationshipStatus.self;
            case 'blocked_by_me':
              return RelationshipStatus.blockedByMe;
            case 'blocked_by_them':
              return RelationshipStatus.blockedByThem;
            case 'connected':
              return RelationshipStatus.connected;
            case 'pending_sent':
              return RelationshipStatus.pendingSent;
            case 'pending_received':
              return RelationshipStatus.pendingReceived;
            default:
              return RelationshipStatus.none;
          }
        }
      } catch (_) {
        // Fallback to direct queries
      }

      // 2. Direct query fallback
      final blockedMe = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', uid)
          .eq('blocked_id', targetUserId)
          .maybeSingle();
      if (blockedMe != null) return RelationshipStatus.blockedByMe;

      final blockedThem = await _supabase
          .from('blocked_users')
          .select('id')
          .eq('blocker_id', targetUserId)
          .eq('blocked_id', uid)
          .maybeSingle();
      if (blockedThem != null) return RelationshipStatus.blockedByThem;

      final conn = await _supabase
          .from('user_connections')
          .select('status, requester_id')
          .or('and(requester_id.eq.$uid,receiver_id.eq.$targetUserId),and(requester_id.eq.$targetUserId,receiver_id.eq.$uid)')
          .maybeSingle();

      if (conn != null) {
        if (conn['status'] == 'accepted') return RelationshipStatus.connected;
        if (conn['status'] == 'pending') {
          return conn['requester_id'] == uid
              ? RelationshipStatus.pendingSent
              : RelationshipStatus.pendingReceived;
        }
      }

      return RelationshipStatus.none;
    } catch (e) {
      return RelationshipStatus.none;
    }
  }
}
