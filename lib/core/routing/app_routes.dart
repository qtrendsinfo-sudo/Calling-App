/// Centralized Route Name Definitions for Telora.
class AppRoutes {
  AppRoutes._();

  // Onboarding & Authentication
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String updatePassword = '/update-password';
  static const String emailVerification = '/email-verification';

  // Main Experience
  static const String home = '/home';

  // Chat
  static const String conversationList = '/conversations';
  static const String chat = '/chat';

  // Calling
  static const String voiceCall = '/call/voice';
  static const String videoCall = '/call/video';
  static const String incomingCall = '/call/incoming';
  static const String callHistory = '/calls/history';

  // Contacts & Discovery
  static const String contacts = '/contacts';
  static const String userSearch = '/users/search';
  static const String userProfile = '/users/profile';
  static const String connectionRequests = '/contacts/requests';

  // Notifications
  static const String notifications = '/notifications';

  // Profile & Settings
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/settings';
  static const String privacySettings = '/settings/privacy';
  static const String notificationSettings = '/settings/notifications';
  static const String blockedUsers = '/settings/blocked';
  static const String report = '/report';
  static const String legal = '/legal';
}
