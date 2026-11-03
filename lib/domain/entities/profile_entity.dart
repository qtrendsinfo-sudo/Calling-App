/// Domain representation of a user profile in Telora.
class ProfileEntity {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;

  const ProfileEntity({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.lastSeen,
    required this.createdAt,
  });

  ProfileEntity copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ProfileEntity.fromMap(Map<String, dynamic> map) {
    return ProfileEntity(
      id: map['id'] as String,
      username: map['username'] as String? ?? 'user',
      displayName: map['display_name'] as String? ?? 'User',
      avatarUrl: map['avatar_url'] as String?,
      bio: map['bio'] as String?,
      isOnline: map['is_online'] as bool? ?? false,
      lastSeen: map['last_seen'] != null
          ? DateTime.tryParse(map['last_seen'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? (DateTime.tryParse(map['created_at'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
