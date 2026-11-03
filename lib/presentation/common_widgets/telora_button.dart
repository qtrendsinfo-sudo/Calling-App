import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import 'loading_indicator.dart';

/// Primary Brand Action Button for Telora.
class TeloraButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final Color backgroundColor;
  final Color foregroundColor;

  const TeloraButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 50.0,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        ),
        child: isLoading
            ? CustomLoadingIndicator(color: foregroundColor, size: 20)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: foregroundColor),
                    const SizedBox(width: AppSpacing.s),
                  ],
                  Text(
                    text,
                    style: AppTypography.labelLarge.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Outlined Secondary Action Button for Telora.
class TeloraOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double height;
  final Color borderColor;
  final Color textColor;

  const TeloraOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height = 50.0,
    this.borderColor = AppColors.border,
    this.textColor = AppColors.onBackground,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadius.button,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: AppSpacing.s),
            ],
            Text(
              text,
              style: AppTypography.labelLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
