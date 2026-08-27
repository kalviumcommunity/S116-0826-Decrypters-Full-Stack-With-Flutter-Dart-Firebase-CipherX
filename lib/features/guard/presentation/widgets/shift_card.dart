import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Card(
      elevation: isToday ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      style: TextStyle(
                        fontSize: isToday ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => Container(
                      height: 20,
                      width: 120,
                      color: Colors.grey.shade300,
                    ),
                    error: (_, __) => Text(
                      'Site: ${shift.siteId}',
                      style: TextStyle(
                        fontSize: isToday ? 18 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                ShiftStatusBadge(status: shift.status),
              ],
            ),
            const SizedBox(height: 8),
            siteAsync.when(
              data: (site) => site?.address != null && site!.address.isNotEmpty
                  ? Text(
                      site.address,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  '${shift.startTime.toFormattedString()} - ${shift.endTime.toFormattedString()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${shift.date.day}/${shift.date.month}/${shift.date.year}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
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
