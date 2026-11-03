/// General Application Constants for Telora.
class AppConstants {
  AppConstants._();

  static const String appName = 'Telora';
  static const String appTagline = 'Worldwide Voice, Video & Messaging';
  static const String packageName = 'com.rlstudio.telora';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // Pagination defaults
  static const int defaultPageSize = 25;
  static const int messagesPageSize = 40;

  // Network & Timeout limits
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration callSignalingTimeout = Duration(seconds: 35);
  static const Duration debounceDuration = Duration(milliseconds: 300);

  // Storage Bucket Names
  static const String avatarsBucket = 'avatars';
  static const String chatMediaBucket = 'chat-media';

  // Validation Limits
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int minPasswordLength = 8;
  static const int maxBioLength = 160;

  // Legal & Support Links
  static const String privacyPolicyUrl = 'https://telora.rlstudio.com/privacy';
  static const String termsOfServiceUrl = 'https://telora.rlstudio.com/terms';
  static const String communityGuidelinesUrl = 'https://telora.rlstudio.com/guidelines';
  static const String supportEmail = 'support@telora.rlstudio.com';
}
