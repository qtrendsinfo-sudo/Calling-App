import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/entities/signaling_message.dart';
import '../../domain/repositories/call_repository.dart';
import '../datasources/remote/supabase_call_datasource.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final dataSource = ref.watch(callRemoteDataSourceProvider);
  return CallRepositoryImpl(dataSource);
});

class CallRepositoryImpl implements CallRepository {
  final CallRemoteDataSource _dataSource;

  CallRepositoryImpl(this._dataSource);

  @override
  Future<CallEntity> initiateCall({
    required String receiverId,
    required CallType type,
  }) {
    return _dataSource.initiateCall(
      receiverId: receiverId,
      type: type,
    );
  }

  @override
  Future<void> updateCallStatus({
    required String callId,
    required CallStatus status,
  }) {
    return _dataSource.updateCallStatus(
      callId: callId,
      status: status,
    );
  }

  @override
  Future<List<CallEntity>> getCallHistory() {
    return _dataSource.getCallHistory();
  }

  @override
  Stream<CallEntity> listenIncomingCalls() {
    return _dataSource.listenIncomingCalls();
  }

  @override
  Stream<CallStatus> listenCallStatus(String callId) {
    return _dataSource.listenCallStatus(callId);
  }

  @override
  Future<void> sendSignaling(SignalingMessage message) {
    return _dataSource.sendSignaling(message);
  }

  @override
  Stream<SignalingMessage> listenSignaling(String callId) {
    return _dataSource.listenSignaling(callId);
  }
}
