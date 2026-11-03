enum NotificationType {
  message,
  incomingCall,
  missedCall,
  connectionRequest,
  connectionAccepted,
  system,
}

/// Domain representation of an in-app and push notification record.
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });
}
