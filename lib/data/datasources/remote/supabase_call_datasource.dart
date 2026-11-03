import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/supabase_error_handler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../domain/entities/call_entity.dart';
import '../../../domain/entities/profile_entity.dart';
import '../../../domain/entities/signaling_message.dart';
import '../mock/mock_datasources.dart';

final callRemoteDataSourceProvider = Provider<CallRemoteDataSource>((ref) {
  if (kIsWeb || !SupabaseService.instance.isInitialized) {
    return MockCallDataSourceImpl();
  }
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseCallDataSourceImpl(supabase);
});

abstract class CallRemoteDataSource {
  Future<CallEntity> initiateCall({required String receiverId, required CallType type});
  Future<void> updateCallStatus({required String callId, required CallStatus status});
  Future<List<CallEntity>> getCallHistory();
  Stream<CallEntity> listenIncomingCalls();
  Stream<CallStatus> listenCallStatus(String callId);
  Future<void> sendSignaling(SignalingMessage message);
  Stream<SignalingMessage> listenSignaling(String callId);
}

class SupabaseCallDataSourceImpl implements CallRemoteDataSource {
  final SupabaseClient _supabase;

  SupabaseCallDataSourceImpl(this._supabase);

  String get _currentUserId {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AuthException(message: 'Authentication required');
    }
    return uid;
  }

  @override
  Future<CallEntity> initiateCall({required String receiverId, required CallType type}) async {
    final uid = _currentUserId;
    if (uid == receiverId) {
      throw const AppException(message: 'Cannot call yourself.');
    }

    try {
      String? callId;

      // 1. Try secure RPC
      try {
        final res = await _supabase.rpc('initiate_call', params: {
          'p_receiver_id': receiverId,
          'p_call_type': type.name,
        });
        if (res != null) {
          callId = res as String;
        }
      } catch (_) {
        // Fallback to direct insertion
      }

      // 2. Direct fallback
      if (callId == null) {
        final inserted = await _supabase.from('calls').insert({
          'caller_id': uid,
          'receiver_id': receiverId,
          'call_type': type.name,
          'status': 'initiated',
        }).select().single();
        callId = inserted['id'] as String;
      }

      // Fetch caller and receiver profiles
      final receiverData = await _supabase.from('profiles').select().eq('id', receiverId).maybeSingle();
      final receiverProfile = receiverData != null ? ProfileEntity.fromMap(receiverData) : null;

      final callerData = await _supabase.from('profiles').select().eq('id', uid).maybeSingle();
      final callerProfile = callerData != null ? ProfileEntity.fromMap(callerData) : null;

      return CallEntity(
        id: callId,
        callerId: uid,
        receiverId: receiverId,
        callType: type,
        status: CallStatus.initiated,
        createdAt: DateTime.now(),
        callerProfile: callerProfile,
        receiverProfile: receiverProfile,
      );
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<void> updateCallStatus({required String callId, required CallStatus status}) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
      };
      if (status == CallStatus.connected) {
        updates['connected_at'] = DateTime.now().toIso8601String();
      } else if (status == CallStatus.ended ||
          status == CallStatus.rejected ||
          status == CallStatus.cancelled ||
          status == CallStatus.missed ||
          status == CallStatus.busy ||
          status == CallStatus.failed) {
        updates['ended_at'] = DateTime.now().toIso8601String();
      }

      await _supabase.from('calls').update(updates).eq('id', callId);
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Future<List<CallEntity>> getCallHistory() async {
    final uid = _currentUserId;
    try {
      final data = await _supabase
          .from('calls')
          .select('*, caller:caller_id(id, username, display_name, avatar_url), receiver:receiver_id(id, username, display_name, avatar_url)')
          .or('caller_id.eq.$uid,receiver_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(50);

      final list = <CallEntity>[];
      for (final row in data as List) {
        final callerProfile =
            row['caller'] != null ? ProfileEntity.fromMap(row['caller'] as Map<String, dynamic>) : null;
        final receiverProfile =
            row['receiver'] != null ? ProfileEntity.fromMap(row['receiver'] as Map<String, dynamic>) : null;

        list.add(CallEntity.fromMap(
          row,
          callerProfile: callerProfile,
          receiverProfile: receiverProfile,
        ));
      }

      return list;
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Stream<CallEntity> listenIncomingCalls() {
    final uid = _currentUserId;
    late StreamController<CallEntity> controller;
    RealtimeChannel? channel;

    controller = StreamController<CallEntity>.broadcast(
      onListen: () {
        channel = _supabase.channel('public:calls:incoming:$uid').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: uid,
          ),
          callback: (payload) async {
            try {
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty && newRecord['status'] == 'initiated') {
                final callerId = newRecord['caller_id'] as String;
                final callerData =
                    await _supabase.from('profiles').select().eq('id', callerId).maybeSingle();
                final callerProfile =
                    callerData != null ? ProfileEntity.fromMap(callerData) : null;

                if (!controller.isClosed) {
                  controller.add(CallEntity.fromMap(newRecord, callerProfile: callerProfile));
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

  @override
  Stream<CallStatus> listenCallStatus(String callId) {
    late StreamController<CallStatus> controller;
    RealtimeChannel? channel;

    controller = StreamController<CallStatus>.broadcast(
      onListen: () {
        channel = _supabase.channel('public:calls:$callId').onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: callId,
          ),
          callback: (payload) {
            try {
              final statusStr = payload.newRecord['status'] as String?;
              if (statusStr != null && !controller.isClosed) {
                final status = CallStatus.values.firstWhere(
                  (s) => s.name == statusStr,
                  orElse: () => CallStatus.ended,
                );
                controller.add(status);
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

  @override
  Future<void> sendSignaling(SignalingMessage message) async {
    try {
      await _supabase.from('call_signals').insert({
        'call_id': message.callId,
        'sender_id': message.senderId,
        'receiver_id': message.receiverId,
        'type': message.type.name,
        'payload': message.payload ?? {},
      });
    } catch (e) {
      throw SupabaseErrorHandler.handleError(e);
    }
  }

  @override
  Stream<SignalingMessage> listenSignaling(String callId) {
    final uid = _currentUserId;
    late StreamController<SignalingMessage> controller;
    RealtimeChannel? channel;

    controller = StreamController<SignalingMessage>.broadcast(
      onListen: () {
        channel = _supabase.channel('public:call_signals:$callId').onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'call_signals',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'call_id',
            value: callId,
          ),
          callback: (payload) {
            try {
              final record = payload.newRecord;
              if (record.isNotEmpty && record['sender_id'] != uid) {
                final message = SignalingMessage.fromJson(record);
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
