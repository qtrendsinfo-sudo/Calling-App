enum SignalingType {
  offer,
  answer,
  iceCandidate,
  hangup,
  busy,
  reject,
}

/// Ephemeral WebRTC signaling message exchanged over Supabase Realtime Broadcast.
class SignalingMessage {
  final String callId;
  final String senderId;
  final String receiverId;
  final SignalingType type;
  final Map<String, dynamic>? payload;
  final DateTime timestamp;

  const SignalingMessage({
    required this.callId,
    required this.senderId,
    required this.receiverId,
    required this.type,
    this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type.name,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      callId: json['call_id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      type: SignalingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SignalingType.hangup,
      ),
      payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload'] as Map) : null,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
