import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../sites/presentation/providers/site_providers.dart';
import '../../../../shifts/domain/entities/shift.dart';
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Date/Indicator and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isToday
                      ? "Today"
                      : DateFormat('MMM d, yyyy').format(shift.date),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isToday ? AppColors.primary : null,
                      ),
                ),
                ShiftStatusBadge(status: shift.status),
              ],
            ),
            const SizedBox(height: 16),
            // Site Information
            Row(
              children: [
                const Icon(Icons.business,
                    color: AppColors.textSecondaryLight, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: siteAsync.when(
                    data: (site) => Text(
                      site?.name ?? 'Unknown Site',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    loading: () => const Text('Loading site...'),
                    error: (_, __) => const Text('Error loading site'),
                  ),
                ),
              ],
            ),
            if (siteAsync.asData?.value?.address != null) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 28), // Align with text above
                  Expanded(
                    child: Text(
                      siteAsync.asData!.value!.address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Time Information
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppColors.textSecondaryLight, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('hh:mm a').format(shift.startTime)} — ${DateFormat('hh:mm a').format(shift.endTime)}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
