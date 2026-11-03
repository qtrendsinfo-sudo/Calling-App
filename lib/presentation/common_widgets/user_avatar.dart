import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';

/// Reusable User Avatar with cached remote loading and presence indicator.
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;
  final bool? isOnline;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 24.0,
    this.isOnline,
    this.onTap,
  });

  String _getInitials(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return '?';
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return cleanName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    Widget avatarWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surfaceVariant,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildInitialsFallback(size),
        ),
      );
    } else {
      avatarWidget = _buildInitialsFallback(size);
    }

    final content = Stack(
      children: [
        avatarWidget,
        if (isOnline != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: isOnline! ? AppColors.online : AppColors.offline,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.surface,
                  width: 2.0,
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildInitialsFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Center(
        child: Text(
          _getInitials(displayName),
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.onPrimaryContainer,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
