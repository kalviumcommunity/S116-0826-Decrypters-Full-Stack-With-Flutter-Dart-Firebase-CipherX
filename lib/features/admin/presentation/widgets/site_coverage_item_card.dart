import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/coverage_status.dart';
import '../../domain/entities/site_coverage_item.dart';

/// Card displaying real-time staffing status and progress for a single site.
class SiteCoverageItemCard extends StatelessWidget {
  final SiteCoverageItem item;
  final VoidCallback? onTap;

  const SiteCoverageItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFullyStaffed = item.status == CoverageStatus.fullyStaffed;
    final statusColor = isFullyStaffed ? AppColors.success : AppColors.error;
    final badgeBgColor =
        isFullyStaffed ? AppColors.successBadgeBg : AppColors.errorBadgeBg;

    final progressRatio = item.requiredStaff == 0
        ? (item.actualStaff > 0 ? 1.0 : 0.0)
        : (item.actualStaff / item.requiredStaff).clamp(0.0, 1.0);

    return Semantics(
      label:
          '${item.siteName}, status: ${item.status.displayName}, actual guards: ${item.actualStaff}, required guards: ${item.requiredStaff}',
      button: onTap != null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.siteName,
                                style: AppTextStyles.titleMedium(
                                  color: AppColors.textPrimaryLight,
                                ).copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(
                          isFullyStaffed, statusColor, badgeBgColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Staffing: ${item.actualStaff} / ${item.requiredStaff} Guards',
                        style: AppTextStyles.bodyMedium(
                          color: AppColors.textSecondaryLight,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${(progressRatio * 100).toInt()}%',
                        style:
                            AppTextStyles.caption(color: statusColor).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progressRatio,
                      backgroundColor: badgeBgColor,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isFullyStaffed,
    Color statusColor,
    Color badgeBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFullyStaffed ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 13,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            isFullyStaffed ? 'FULLY STAFFED' : 'UNDERSTAFFED',
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
