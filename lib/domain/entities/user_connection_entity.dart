import 'profile_entity.dart';

enum ConnectionStatus {
  pending,
  accepted,
  rejected,
  cancelled,
}

enum RelationshipStatus {
  none,
  pendingSent,
  pendingReceived,
  connected,
  blockedByMe,
  blockedByThem,
  self,
}

/// Domain representation of a connection relation between users.
class UserConnectionEntity {
  final String id;
  final String requesterId;
  final String receiverId;
  final ConnectionStatus status;
  final ProfileEntity? profile;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserConnectionEntity({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  UserConnectionEntity copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    ConnectionStatus? status,
    ProfileEntity? profile,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserConnectionEntity(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      profile: profile ?? this.profile,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserConnectionEntity.fromMap(Map<String, dynamic> map, {String? currentUserId}) {
    final statusStr = map['status'] as String? ?? 'pending';
    final ConnectionStatus status;
    switch (statusStr) {
      case 'accepted':
        status = ConnectionStatus.accepted;
        break;
      case 'rejected':
        status = ConnectionStatus.rejected;
        break;
      case 'cancelled':
        status = ConnectionStatus.cancelled;
        break;
      default:
        status = ConnectionStatus.pending;
    }

    ProfileEntity? associatedProfile;
    if (map['profile'] != null && map['profile'] is Map<String, dynamic>) {
      associatedProfile = ProfileEntity.fromMap(map['profile'] as Map<String, dynamic>);
    } else if (map['requester'] != null && currentUserId != null && map['requester_id'] != currentUserId) {
      associatedProfile = ProfileEntity.fromMap(map['requester'] as Map<String, dynamic>);
    } else if (map['receiver'] != null && currentUserId != null && map['receiver_id'] != currentUserId) {
      associatedProfile = ProfileEntity.fromMap(map['receiver'] as Map<String, dynamic>);
    }

    return UserConnectionEntity(
      id: map['id'] as String,
      requesterId: map['requester_id'] as String,
      receiverId: map['receiver_id'] as String,
      status: status,
      profile: associatedProfile,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? (DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_id': requesterId,
      'receiver_id': receiverId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
