import '../entities/call_entity.dart';
import '../entities/signaling_message.dart';

abstract class CallRepository {
  Future<List<CallEntity>> getCallHistory();
  Stream<CallEntity> listenIncomingCalls();
  Stream<CallStatus> listenCallStatus(String callId);
  Future<CallEntity> initiateCall({
    required String receiverId,
    required CallType type,
  });
  Future<void> updateCallStatus({
    required String callId,
    required CallStatus status,
  });
  Future<void> sendSignaling(SignalingMessage message);
  Stream<SignalingMessage> listenSignaling(String callId);
}
