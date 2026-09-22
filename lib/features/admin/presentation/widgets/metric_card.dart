import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

/// Reusable metric KPI card displaying operational counts, status icons,
/// and contextual labels with accessible semantics.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: $value',
      button: onTap != null,
      child: Container(
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
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      if (onTap != null)
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: AppColors.textSecondaryLight,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: AppTextStyles.metricValue(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTextStyles.caption(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption(
                        color: AppColors.textSecondaryLight,
                      ).copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
