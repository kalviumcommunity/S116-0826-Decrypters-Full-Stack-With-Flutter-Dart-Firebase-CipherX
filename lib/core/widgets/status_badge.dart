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
/// Always combines icon + text + curated color palette (never color alone).
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

  // Standardized factory constructors for domain entities:

  factory StatusBadge.active({Key? key, String label = 'ACTIVE'}) => StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.success,
        icon: Icons.check_circle_outline_rounded,
      );

  factory StatusBadge.inactive({Key? key, String label = 'INACTIVE'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.neutral,
        icon: Icons.pause_circle_outline_rounded,
      );

  factory StatusBadge.onDuty({Key? key, String label = 'ON DUTY'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.success,
        icon: Icons.shield_outlined,
      );

  factory StatusBadge.absent({Key? key, String label = 'ABSENT'}) => StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.error,
        icon: Icons.cancel_outlined,
      );

  factory StatusBadge.lateStatus({Key? key, String label = 'LATE'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.warning,
        icon: Icons.access_time_rounded,
      );

  factory StatusBadge.open({Key? key, String label = 'OPEN'}) => StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.error,
        icon: Icons.error_outline_rounded,
      );

  factory StatusBadge.investigating(
          {Key? key, String label = 'INVESTIGATING'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.warning,
        icon: Icons.search_rounded,
      );

  factory StatusBadge.resolved({Key? key, String label = 'RESOLVED'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.success,
        icon: Icons.verified_outlined,
      );

  factory StatusBadge.fullyStaffed(
          {Key? key, String label = 'FULLY STAFFED'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.success,
        icon: Icons.people_alt_outlined,
      );

  factory StatusBadge.understaffed(
          {Key? key, String label = 'UNDERSTAFFED'}) =>
      StatusBadge(
        key: key,
        label: label,
        variant: StatusBadgeVariant.error,
        icon: Icons.person_off_outlined,
      );

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
