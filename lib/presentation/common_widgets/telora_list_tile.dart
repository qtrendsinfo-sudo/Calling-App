import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';

/// Section Header for Settings and Categorized Lists.
class TeloraSectionHeader extends StatelessWidget {
  final String title;

  const TeloraSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.m,
        right: AppSpacing.m,
        top: AppSpacing.l,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Styled List Tile for Settings, Profiles, and Navigation Actions.
class TeloraListTile extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final bool showDivider;

  const TeloraListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 2),
          leading: leading,
          title: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: titleColor ?? AppColors.onBackground,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.onSurfaceVariant),
                )
              : null,
          trailing: trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onSurfaceVariant,
                size: 20,
              ),
          onTap: onTap,
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: AppSpacing.m,
            endIndent: AppSpacing.m,
            color: AppColors.divider,
          ),
      ],
    );
  }
}
