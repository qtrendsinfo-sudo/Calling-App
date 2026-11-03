import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../core/constants/app_shadows.dart';
import 'telora_badge.dart';

/// Premium Bottom Navigation Bar for Telora Main Shell.
class TeloraBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final int unreadChatsCount;
  final int missedCallsCount;

  const TeloraBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.unreadChatsCount = 0,
    this.missedCallsCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: AppShadows.navigation,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: currentIndex == 0 ? AppIcons.home : AppIcons.homeOutlined,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: currentIndex == 1 ? AppIcons.chats : AppIcons.chatsOutlined,
                label: 'Chats',
                badgeCount: unreadChatsCount,
              ),
              _buildNavItem(
                index: 2,
                icon: currentIndex == 2 ? AppIcons.calls : AppIcons.callsOutlined,
                label: 'Calls',
                badgeCount: missedCallsCount,
                badgeColor: AppColors.callMissed,
              ),
              _buildNavItem(
                index: 3,
                icon: currentIndex == 3 ? AppIcons.contacts : AppIcons.contactsOutlined,
                label: 'Contacts',
              ),
              _buildNavItem(
                index: 4,
                icon: currentIndex == 4 ? AppIcons.profile : AppIcons.profileOutlined,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    Color badgeColor = AppColors.primary,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => onIndexChanged(index),
        splashColor: AppColors.primaryContainer.withOpacity(0.4),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -10,
                    child: TeloraBadge(
                      count: badgeCount,
                      backgroundColor: badgeColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
