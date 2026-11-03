import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_shadows.dart';

/// Reusable Elevated Surface Card for Telora.
class TeloraCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Border? border;
  final List<BoxShadow>? shadows;

  const TeloraCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.border,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.card,
        border: border ?? Border.all(color: AppColors.border.withOpacity(0.8), width: 1),
        boxShadow: shadows ?? AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.card,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
