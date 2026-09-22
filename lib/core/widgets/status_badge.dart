import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

enum StatusBadgeVariant {
  success,
  warning,
  error,
  info,
  wine,
  neutral,
}

/// Reusable pill status badge from the reference design.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeVariant variant;
  final IconData? icon;
  final Color? customColor;
  final Color? customBgColor;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.neutral,
    this.icon,
    this.customColor,
    this.customBgColor,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    if (customColor != null && customBgColor != null) {
      textColor = customColor!;
      bgColor = customBgColor!;
    } else {
      switch (variant) {
        case StatusBadgeVariant.success:
          textColor = AppColors.success;
          bgColor = AppColors.successBadgeBg;
          break;
        case StatusBadgeVariant.warning:
          textColor = AppColors.warning;
          bgColor = AppColors.warningBadgeBg;
          break;
        case StatusBadgeVariant.error:
          textColor = AppColors.error;
          bgColor = AppColors.errorBadgeBg;
          break;
        case StatusBadgeVariant.info:
          textColor = AppColors.info;
          bgColor = AppColors.infoBadgeBg;
          break;
        case StatusBadgeVariant.wine:
          textColor = AppColors.primaryLight;
          bgColor = AppColors.accentRose;
          break;
        case StatusBadgeVariant.neutral:
          textColor = AppColors.textSecondaryLight;
          bgColor = AppColors.surfaceMuted;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.caption(color: textColor).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
