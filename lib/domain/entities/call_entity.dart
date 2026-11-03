import 'profile_entity.dart';

enum CallType {
  voice,
  video,
}

enum CallStatus {
  initiated,
  ringing,
  accepted,
  connected,
  rejected,
  cancelled,
  missed,
  busy,
  failed,
  ended,
}

/// Domain representation of a voice or video call record.
class CallEntity {
  final String id;
  final String callerId;
  final String receiverId;
  final CallType callType;
  final CallStatus status;
  final DateTime? startedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final DateTime createdAt;
  final ProfileEntity? callerProfile;
  final ProfileEntity? receiverProfile;

  const CallEntity({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.callType,
    required this.status,
    this.startedAt,
    this.connectedAt,
    this.endedAt,
    this.durationSeconds = 0,
    required this.createdAt,
    this.callerProfile,
    this.receiverProfile,
  });

  bool get isConnected => status == CallStatus.connected;
  bool get isTerminated =>
      status == CallStatus.ended ||
      status == CallStatus.rejected ||
      status == CallStatus.cancelled ||
      status == CallStatus.missed ||
      status == CallStatus.failed ||
      status == CallStatus.busy;

  ProfileEntity? getOtherProfile(String currentUserId) {
    if (callerId == currentUserId) return receiverProfile;
    return callerProfile;
  }

  CallEntity copyWith({
    String? id,
    String? callerId,
    String? receiverId,
    CallType? callType,
    CallStatus? status,
    DateTime? startedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    int? durationSeconds,
    DateTime? createdAt,
    ProfileEntity? callerProfile,
    ProfileEntity? receiverProfile,
  }) {
    return CallEntity(
      id: id ?? this.id,
      callerId: callerId ?? this.callerId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt ?? this.createdAt,
      callerProfile: callerProfile ?? this.callerProfile,
      receiverProfile: receiverProfile ?? this.receiverProfile,
    );
  }

  factory CallEntity.fromMap(Map<String, dynamic> map, {
    ProfileEntity? callerProfile,
    ProfileEntity? receiverProfile,
  }) {
    final typeStr = map['call_type'] as String? ?? 'voice';
    final statusStr = map['status'] as String? ?? 'initiated';

    return CallEntity(
      id: map['id'] as String,
      callerId: map['caller_id'] as String,
      receiverId: map['receiver_id'] as String,
      callType: typeStr == 'video' ? CallType.video : CallType.voice,
      status: CallStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => CallStatus.initiated,
      ),
      startedAt: map['started_at'] != null ? DateTime.tryParse(map['started_at'] as String) : null,
      connectedAt: map['connected_at'] != null ? DateTime.tryParse(map['connected_at'] as String) : null,
      endedAt: map['ended_at'] != null ? DateTime.tryParse(map['ended_at'] as String) : null,
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      callerProfile: callerProfile,
      receiverProfile: receiverProfile,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'call_type': callType.name,
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'connected_at': connectedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
