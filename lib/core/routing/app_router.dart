import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_routes.dart';
import '../../domain/entities/call_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
import '../../features/calls/presentation/screens/active_call_screen.dart';
import '../../features/calls/presentation/screens/incoming_call_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/contacts/presentation/screens/user_search_screen.dart';
import '../../features/home/presentation/screens/main_shell_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/user_profile_screen.dart';
import '../../features/settings/presentation/screens/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../presentation/common_widgets/error_view.dart';

/// Type-safe route generator for Telora.
class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );

      case AppRoutes.onboarding:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const OnboardingScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.signup:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const SignupScreen(),
        );

      case AppRoutes.forgotPassword:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case AppRoutes.updatePassword:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const UpdatePasswordScreen(),
        );

      case AppRoutes.emailVerification:
        final email = settings.arguments as String?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => EmailVerificationScreen(email: email),
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const MainShellScreen(),
        );

      case AppRoutes.settings:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case AppRoutes.blockedUsers:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const BlockedUsersScreen(),
        );

      case AppRoutes.editProfile:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const EditProfileScreen(),
        );

      case AppRoutes.userSearch:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const UserSearchScreen(),
        );

      case AppRoutes.userProfile:
        final profile = settings.arguments as ProfileEntity;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => UserProfileScreen(profile: profile),
        );

      case AppRoutes.chatConversation:
        final args = settings.arguments as Map<String, dynamic>;
        final conversationId = args['conversationId'] as String;
        final otherMember = args['otherMember'] as ProfileEntity?;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherMember: otherMember,
          ),
        );

      case AppRoutes.voiceCall:
      case AppRoutes.videoCall:
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => const ActiveCallScreen(),
        );

      case AppRoutes.incomingCall:
        final call = settings.arguments as CallEntity;
        return CupertinoPageRoute(
          settings: settings,
          builder: (_) => IncomingCallScreen(call: call),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Navigation')),
            body: Center(
              child: CustomErrorWidget(
                title: 'Route Not Found',
                message: 'No route configured for "${settings.name}".',
                buttonText: 'Return to Home',
                onRetry: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
              ),
            ),
          ),
        );
    }
  }
}
