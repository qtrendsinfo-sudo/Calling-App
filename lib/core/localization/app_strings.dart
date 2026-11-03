import 'package:flutter/material.dart';

/// Centralized UI String Catalog with English and Arabic localizations for Telora.
class AppStrings {
  AppStrings._();

  static bool isRtl(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  // App Identity
  static const String appName = 'Telora';
  static const String appTagline = 'Connect Worldwide Without Limits';

  // Navigation
  static const String navHome = 'Home';
  static const String navChats = 'Chats';
  static const String navCalls = 'Calls';
  static const String navContacts = 'Contacts';
  static const String navProfile = 'Profile';

  // Onboarding
  static const String onboarding1Title = 'Connect Without Limits';
  static const String onboarding1Body =
      'Stay connected with people around the world through high-speed internet messaging and calls.';

  static const String onboarding2Title = 'Talk Your Way';
  static const String onboarding2Body =
      'Enjoy crystal-clear voice and video conversations wherever you have an internet connection.';

  static const String onboarding3Title = 'Your Conversations, Your Control';
  static const String onboarding3Body =
      'Manage your privacy, personal connections, and communication rules from one unified, secure place.';

  static const String getStarted = 'Get Started';
  static const String createAccount = 'Create Account';
  static const String signIn = 'Sign In';
  static const String continueText = 'Continue';
  static const String skip = 'Skip';

  // Common UI
  static const String search = 'Search';
  static const String cancel = 'Cancel';
  static const String retry = 'Retry';
  static const String save = 'Save Changes';
  static const String signOut = 'Sign Out';
  static const String deleteAccount = 'Delete Account';
  static const String settings = 'Settings';
  static const String online = 'Online';
  static const String offline = 'Offline';

  // Profile & Editing
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String displayName = 'Display Name';
  static const String username = 'Username';
  static const String bio = 'Bio';
  static const String changePhoto = 'Change Photo';
  static const String removePhoto = 'Remove Photo';
  static const String profileUpdated = 'Profile updated successfully.';
  static const String usernameTaken = 'That username is already taken.';
  static const String usernameAvailable = 'Username is available.';
  static const String uploadFailed = 'Failed to upload avatar. Please try again.';
  static const String bioHint = 'Tell people a little bit about yourself...';

  // User Discovery & Search
  static const String searchUsers = 'Search Users';
  static const String searchHint = 'Search by name or @username...';
  static const String noUsersFound = 'No users found';
  static const String noUsersFoundDesc = 'Try searching with a different name or username.';
  static const String message = 'Message';
  static const String voiceCall = 'Voice Call';
  static const String videoCall = 'Video Call';

  // Chat & Messaging (Phase 10)
  static const String chats = 'Chats';
  static const String messages = 'Messages';
  static const String typeAMessage = 'Type a message...';
  static const String send = 'Send';
  static const String messageFailed = 'Message failed to send. Please retry.';
  static const String loadingMessages = 'Loading messages...';
  static const String connectionRequired = 'You must be connected to send messages.';
  static const String userUnavailable = 'This user is currently unavailable.';

  // Calling & WebRTC (Phase 11)
  static const String connecting = 'Connecting...';
  static const String ringing = 'Ringing...';
  static const String callConnected = 'Connected';
  static const String callDeclined = 'Call Declined';
  static const String userBusy = 'User Busy';
  static const String callFailed = 'Call Failed';
  static const String callEnded = 'Call Ended';
  static const String incomingVoiceCall = 'Incoming Voice Call...';
  static const String incomingVideoCall = 'Incoming Video Call...';
  static const String startCall = 'Start a Call';
  static const String callPermissionsDenied = 'Microphone and/or camera permission denied.';

  // Connections & Requests (Phase 9)
  static const String connections = 'Connections';
  static const String connectionRequests = 'Requests';
  static const String incomingRequests = 'Incoming Requests';
  static const String sentRequests = 'Sent Requests';
  static const String accept = 'Accept';
  static const String reject = 'Decline';
  static const String cancelRequest = 'Cancel Request';
  static const String removeConnection = 'Remove Connection';
  static const String connected = 'Connected';
  static const String requestSent = 'Request Sent';
  static const String addConnection = 'Add Connection';
  static const String blockUser = 'Block User';
  static const String unblockUser = 'Unblock User';
  static const String blockedUsers = 'Blocked Users';
  static const String blockedUser = 'Blocked User';
  static const String noRequests = 'No Requests';
  static const String noConnections = 'No Connections';
  static const String requestUpdated = 'Request updated.';
  static const String userBlocked = 'User has been blocked.';
  static const String userUnblocked = 'User has been unblocked.';
  static const String somethingWentWrong = 'Something went wrong. Please try again.';

  // Empty States
  static const String emptyChatsTitle = 'No conversations yet';
  static const String emptyChatsDesc = 'Start a conversation with your connections or search for someone new.';
  static const String emptyCallsTitle = 'No recent calls';
  static const String emptyCallsDesc = 'Your voice and video call history will appear here once you make or receive calls.';
  static const String emptyContactsTitle = 'No connections yet';
  static const String emptyContactsDesc = 'Search and send connection requests to start chatting and calling.';
  static const String emptyNotificationsTitle = 'All caught up';
  static const String emptyNotificationsDesc = 'You have no new notifications at the moment.';

  // Offline & Errors
  static const String offlineTitle = 'No Internet Connection';
  static const String offlineDesc = 'Connect to the internet to chat, call, and sync with Telora.';
  static const String networkError = 'Network error. Please check your connection and try again.';
  static const String profileNotFound = 'Profile not found.';
}
