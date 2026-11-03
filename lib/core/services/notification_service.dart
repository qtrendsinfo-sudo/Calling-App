import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationServiceImpl();
});

abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getDeviceToken();
  Future<void> showCallNotification({
    required String callId,
    required String callerName,
    required bool isVideo,
  });
  Future<void> cancelCallNotification();
}

class NotificationServiceImpl implements NotificationService {
  @override
  Future<void> initialize() async {
    // Phase 15 will wire FCM and flutter_local_notifications background handler
  }

  @override
  Future<String?> getDeviceToken() async {
    return null;
  }

  @override
  Future<void> showCallNotification({
    required String callId,
    required String callerName,
    required bool isVideo,
  }) async {}

  @override
  Future<void> cancelCallNotification() async {}
}
