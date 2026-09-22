import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../providers/guard_shifts_provider.dart';
import 'shift_status_badge.dart';

class ShiftCard extends ConsumerWidget {
  final Shift shift;
  final bool isToday;

  const ShiftCard({
    super.key,
    required this.shift,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteProvider(shift.siteId));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isToday
              ? AppColors.primaryLight.withValues(alpha: 0.5)
              : AppColors.borderLight,
          width: isToday ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.shadowColor,
            blurRadius: isToday ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: siteAsync.when(
                    data: (site) => Text(
                      site?.name ?? 'Site: ${shift.siteId}',
                      style: AppTextStyles.titleMedium(
                        color: AppColors.textPrimaryLight,
                      ).copyWith(
                        fontSize: isToday ? 17 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Container(
                      height: 20,
                      width: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    error: (_, __) => Text(
                      'Site: ${shift.siteId}',
                      style: AppTextStyles.titleMedium(
                        color: AppColors.textPrimaryLight,
                      ).copyWith(
                        fontSize: isToday ? 17 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                ShiftStatusBadge(status: shift.status),
              ],
            ),
            const SizedBox(height: 6),
            siteAsync.when(
              data: (site) => site?.address != null && site!.address.isNotEmpty
                  ? Text(
                      site.address,
                      style: AppTextStyles.bodyMedium(
                        color: AppColors.textSecondaryLight,
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${shift.startTime.toFormattedString()} - ${shift.endTime.toFormattedString()}',
                  style: AppTextStyles.bodyMedium(
                    color: AppColors.textPrimaryLight,
                  ).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${shift.date.day}/${shift.date.month}/${shift.date.year}',
                  style: AppTextStyles.caption(
                    color: AppColors.textSecondaryLight,
                  ).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
