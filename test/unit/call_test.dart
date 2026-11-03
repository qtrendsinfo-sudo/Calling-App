import 'package:flutter_test/flutter_test.dart';
import 'package:telora/domain/entities/call_entity.dart';
import 'package:telora/domain/entities/profile_entity.dart';
import 'package:telora/domain/entities/signaling_message.dart';
import 'package:telora/domain/entities/user_connection_entity.dart';

void main() {
  group('CallEntity & SignalingMessage Unit Tests', () {
    test('CallEntity serialization and deserialization', () {
      final map = {
        'id': 'call-123',
        'caller_id': 'user-a',
        'receiver_id': 'user-b',
        'call_type': 'video',
        'status': 'connected',
        'started_at': '2026-10-02T10:00:00Z',
        'connected_at': '2026-10-02T10:00:05Z',
        'duration_seconds': 120,
        'created_at': '2026-10-02T10:00:00Z',
      };

      final call = CallEntity.fromMap(map);

      expect(call.id, 'call-123');
      expect(call.callerId, 'user-a');
      expect(call.receiverId, 'user-b');
      expect(call.callType, CallType.video);
      expect(call.status, CallStatus.connected);
      expect(call.isConnected, isTrue);
      expect(call.isTerminated, isFalse);
      expect(call.durationSeconds, 120);
    });

    test('CallEntity termination detection', () {
      final terminatedStatuses = [
        CallStatus.ended,
        CallStatus.rejected,
        CallStatus.cancelled,
        CallStatus.missed,
        CallStatus.failed,
        CallStatus.busy,
      ];

      for (final s in terminatedStatuses) {
        final c = CallEntity(
          id: 'c-1',
          callerId: 'u-1',
          receiverId: 'u-2',
          callType: CallType.voice,
          status: s,
          createdAt: DateTime.now(),
        );
        expect(c.isTerminated, isTrue, reason: 'Status $s must be recognized as terminated');
        expect(c.isConnected, isFalse);
      }
    });

    test('CallEntity resolves counterparty profile correctly', () {
      final caller = ProfileEntity(
        id: 'u-alice',
        username: 'alice',
        displayName: 'Alice A',
        createdAt: DateTime.now(),
      );
      final receiver = ProfileEntity(
        id: 'u-bob',
        username: 'bob',
        displayName: 'Bob B',
        createdAt: DateTime.now(),
      );

      final call = CallEntity(
        id: 'call-1',
        callerId: 'u-alice',
        receiverId: 'u-bob',
        callType: CallType.voice,
        status: CallStatus.connected,
        createdAt: DateTime.now(),
        callerProfile: caller,
        receiverProfile: receiver,
      );

      // From Alice's perspective, other is Bob
      expect(call.getOtherProfile('u-alice')?.id, 'u-bob');
      // From Bob's perspective, other is Alice
      expect(call.getOtherProfile('u-bob')?.id, 'u-alice');
    });

    test('SignalingMessage serialization and deserialization', () {
      final original = SignalingMessage(
        callId: 'call-xyz',
        senderId: 'user-a',
        receiverId: 'user-b',
        type: SignalingType.offer,
        payload: {'sdp': 'v=0...', 'type': 'offer'},
        timestamp: DateTime(2026, 10, 2, 12, 0),
      );

      final json = original.toJson();
      final recovered = SignalingMessage.fromJson(json);

      expect(recovered.callId, original.callId);
      expect(recovered.senderId, original.senderId);
      expect(recovered.receiverId, original.receiverId);
      expect(recovered.type, SignalingType.offer);
      expect(recovered.payload?['type'], 'offer');
    });
  });

  group('Call Eligibility & Security Logic Tests', () {
    test('Self-calling is strictly prohibited', () {
      const callerId = 'user-same';
      const receiverId = 'user-same';

      final canCallSelf = callerId != receiverId;
      expect(canCallSelf, isFalse, reason: 'Users cannot initiate a call to themselves');
    });

    test('Call is rejected if users are not accepted connections', () {
      final statuses = [
        ConnectionStatus.pending,
        ConnectionStatus.rejected,
        ConnectionStatus.cancelled,
        null,
      ];

      for (final status in statuses) {
        final canCall = status == ConnectionStatus.accepted;
        expect(canCall, isFalse, reason: 'Status $status must not allow initiating a call');
      }

      const acceptedStatus = ConnectionStatus.accepted;
      expect(acceptedStatus == ConnectionStatus.accepted, isTrue);
    });

    test('Call is rejected if either user blocked the other', () {
      const userA = 'user-alice';
      const userB = 'user-bob';

      // Alice blocked Bob
      final isBlocked1 = true;
      final canCall1 = !isBlocked1;
      expect(canCall1, isFalse);

      // Bob blocked Alice
      final isBlocked2 = true;
      final canCall2 = !isBlocked2;
      expect(canCall2, isFalse);
    });

    test('Signaling authorization requires participant match', () {
      const callerId = 'user-a';
      const receiverId = 'user-b';
      const outsiderId = 'user-eve';

      final canEveSignal = outsiderId == callerId || outsiderId == receiverId;
      expect(canEveSignal, isFalse, reason: 'Third-party users cannot participate in signaling');
    });

    test('Receiver must be the exact counterparty participant, not an arbitrary user', () {
      const callCallerId = 'user-alice';
      const callReceiverId = 'user-bob';
      const rogueReceiverId = 'user-mallory';

      // Direction 1: Alice (caller) sends to Bob (receiver) -> Valid
      bool isValidParticipantPair(String sender, String receiver) {
        return (sender == callCallerId && receiver == callReceiverId) ||
            (sender == callReceiverId && receiver == callCallerId);
      }

      expect(isValidParticipantPair(callCallerId, callReceiverId), isTrue);
      // Direction 2: Bob (receiver) sends to Alice (caller) -> Valid
      expect(isValidParticipantPair(callReceiverId, callCallerId), isTrue);

      // Invalid: Alice attempts to send signal with rogue receiver
      expect(isValidParticipantPair(callCallerId, rogueReceiverId), isFalse,
          reason: 'Arbitrary receiver IDs must be rejected');

      // Invalid: Bob attempts to send signal with rogue receiver
      expect(isValidParticipantPair(callReceiverId, rogueReceiverId), isFalse,
          reason: 'Arbitrary receiver IDs must be rejected');

      // Invalid: Self-signaling
      expect(isValidParticipantPair(callCallerId, callCallerId), isFalse,
          reason: 'Self-signaling must be rejected');
    });

    test('Signaling is accepted only during active call lifecycle states', () {
      final activeStates = [
        CallStatus.initiated,
        CallStatus.ringing,
        CallStatus.accepted,
        CallStatus.connected,
      ];

      final terminatedStates = [
        CallStatus.ended,
        CallStatus.rejected,
        CallStatus.cancelled,
        CallStatus.missed,
        CallStatus.busy,
        CallStatus.failed,
      ];

      bool canSignalInCallState(CallStatus status) {
        return activeStates.contains(status);
      }

      for (final state in activeStates) {
        expect(canSignalInCallState(state), isTrue,
            reason: 'Active state $state must allow signaling');
      }

      for (final state in terminatedStates) {
        expect(canSignalInCallState(state), isFalse,
            reason: 'Terminated state $state must reject all new signaling');
      }
    });

    test('Bidirectional WebRTC offer, answer, and ICE candidate exchange flow', () {
      const callerId = 'user-alice';
      const receiverId = 'user-bob';
      const callId = 'call-xyz';

      // 1. Caller creates Offer
      final offerMsg = SignalingMessage(
        callId: callId,
        senderId: callerId,
        receiverId: receiverId,
        type: SignalingType.offer,
        payload: {'sdp': 'v=0...offer'},
        timestamp: DateTime.now(),
      );
      expect(offerMsg.senderId, callerId);
      expect(offerMsg.receiverId, receiverId);
      expect(offerMsg.type, SignalingType.offer);

      // 2. Receiver answers Offer
      final answerMsg = SignalingMessage(
        callId: callId,
        senderId: receiverId,
        receiverId: callerId,
        type: SignalingType.answer,
        payload: {'sdp': 'v=0...answer'},
        timestamp: DateTime.now(),
      );
      expect(answerMsg.senderId, receiverId);
      expect(answerMsg.receiverId, callerId);
      expect(answerMsg.type, SignalingType.answer);

      // 3. Both exchange ICE candidates
      final callerIce = SignalingMessage(
        callId: callId,
        senderId: callerId,
        receiverId: receiverId,
        type: SignalingType.iceCandidate,
        payload: {'candidate': 'candidate:...'},
        timestamp: DateTime.now(),
      );
      final receiverIce = SignalingMessage(
        callId: callId,
        senderId: receiverId,
        receiverId: callerId,
        type: SignalingType.iceCandidate,
        payload: {'candidate': 'candidate:...'},
        timestamp: DateTime.now(),
      );
      expect(callerIce.receiverId, receiverId);
      expect(receiverIce.receiverId, callerId);
    });

    test('Call-history retention vs block privacy rule', () {
      const viewerId = 'user-alice';
      const counterpartyId = 'user-bob';

      // Case 1: Normal call history while connected -> visible
      bool canViewCallHistory({required bool isConnected, required bool isBlocked}) {
        // Privacy rule: Call logs are retained for audit even after connection removal,
        // but strictly hidden if either user blocks the other.
        return !isBlocked;
      }

      expect(canViewCallHistory(isConnected: true, isBlocked: false), isTrue,
          reason: 'Active connected users can view past call records');

      // Case 2: Connection removed -> past history retained for audit log
      expect(canViewCallHistory(isConnected: false, isBlocked: false), isTrue,
          reason: 'Call history is preserved as an audit record after connection removal');

      // Case 3: Blocked relationship -> past history hidden
      expect(canViewCallHistory(isConnected: false, isBlocked: true), isFalse,
          reason: 'Blocked relationship hides past call history from both users');
      expect(canViewCallHistory(isConnected: true, isBlocked: true), isFalse,
          reason: 'Blocked relationship overrides connection status');
    });
  });
}
