import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../presentation/common_widgets/telora_bottom_navigation.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../../calls/presentation/screens/call_history_tab_screen.dart';
import '../../../chat/presentation/screens/chat_list_tab_screen.dart';
import '../../../contacts/presentation/screens/contacts_tab_screen.dart';
import '../../../profile/presentation/screens/profile_tab_screen.dart';
import 'home_tab_screen.dart';

/// Main Shell holding the 5 primary tabs with bottom navigation.
class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Auth Guard: If user logs out or session is invalidated, safely route to Login
    if (authState.status != AuthStatus.initial && !authState.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      });
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomeTabScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const ChatListTabScreen(),
      const CallHistoryTabScreen(),
      const ContactsTabScreen(),
      const ProfileTabScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: TeloraBottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
