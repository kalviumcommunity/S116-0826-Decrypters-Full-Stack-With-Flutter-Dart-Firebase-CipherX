import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../guard/presentation/providers/guard_shifts_provider.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../domain/entities/attendance_record.dart';
import '../providers/attendance_providers.dart';

class AttendanceDetailsScreen extends ConsumerWidget {
  final AttendanceRecord record;

  const AttendanceDetailsScreen({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final checkOutState = ref.watch(checkOutControllerProvider);

    // Watch live detail updates if available
    final liveRecordAsync = ref.watch(
      attendanceDetailsProvider(record.attendanceId),
    );

    final currentRecord = liveRecordAsync.asData?.value ?? record;

    final siteAsync = ref.watch(siteProvider(currentRecord.siteId));
    final siteName =
        siteAsync.asData?.value?.name ?? 'Site #${currentRecord.siteId}';

    final fullDateFormat = DateFormat('MMMM d, yyyy - hh:mm:ss a');
    final checkInFormatted = fullDateFormat.format(currentRecord.checkInTime);
    final checkOutFormatted = currentRecord.checkOutTime != null
        ? fullDateFormat.format(currentRecord.checkOutTime!)
        : 'Not Checked Out';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
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
                          child: Text(
                            siteName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(currentRecord.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attendance ID: ${currentRecord.attendanceId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shift ID: ${currentRecord.shiftId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Check-In Section
            _buildSectionHeader(theme, 'Check-In Details', Icons.login),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Timestamp',
                      value: checkInFormatted,
                      icon: Icons.access_time,
                    ),
                    if (currentRecord.checkInLocation != null) ...[
                      const Divider(height: 24),
                      _buildLocationInfo(
                        context,
                        location: currentRecord.checkInLocation!,
                        title: 'Check-In GPS Location',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Check-Out Section
            _buildSectionHeader(theme, 'Check-Out Details', Icons.logout),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Timestamp',
                      value: checkOutFormatted,
                      icon: Icons.access_time,
                    ),
                    if (currentRecord.checkOutLocation != null) ...[
                      const Divider(height: 24),
                      _buildLocationInfo(
                        context,
                        location: currentRecord.checkOutLocation!,
                        title: 'Check-Out GPS Location',
                      ),
                    ],
                    if (!currentRecord.isCheckedOut) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: checkOutState.isLoading
                              ? null
                              : () async {
                                  final success = await ref
                                      .read(checkOutControllerProvider.notifier)
                                      .checkOut(
                                        attendanceId:
                                            currentRecord.attendanceId,
                                      );

                                  if (context.mounted) {
                                    if (success) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Check-out successful!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      final err = ref
                                              .read(checkOutControllerProvider)
                                              .errorMessage ??
                                          'Check-out failed.';
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(err),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: checkOutState.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.logout),
                          label: Text(
                            checkOutState.isLoading
                                ? 'Checking Out...'
                                : 'Complete Check-Out',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Metadata / Verification Info
            _buildSectionHeader(
                theme, 'Verification & System Info', Icons.verified_user),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context,
                      label: 'Verification Method',
                      value: currentRecord.verificationMethod.toUpperCase(),
                      icon: Icons.security,
                    ),
                    if (currentRecord.createdAt != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        label: 'Record Created At',
                        value: fullDateFormat.format(currentRecord.createdAt!),
                        icon: Icons.create,
                      ),
                    ],
                    if (currentRecord.updatedAt != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        context,
                        label: 'Last Updated At',
                        value: fullDateFormat.format(currentRecord.updatedAt!),
                        icon: Icons.update,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfo(
    BuildContext context, {
    required LocationData location,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latitude: ${location.latitude.toStringAsFixed(6)}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Longitude: ${location.longitude.toStringAsFixed(6)}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'GPS Accuracy: ±${location.accuracy.toStringAsFixed(1)} m',
          style: theme.textTheme.bodySmall?.copyWith(
            color: location.accuracy <= 35.0
                ? Colors.green
                : Colors.amber.shade800,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(AttendanceStatus status) {
    Color statusColor;
    String statusText;

    switch (status) {
      case AttendanceStatus.completed:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case AttendanceStatus.flagged:
        statusColor = Colors.amber.shade800;
        statusText = 'Flagged';
        break;
      case AttendanceStatus.active:
        statusColor = Colors.blue;
        statusText = 'Active';
        break;
    }

    return Chip(
      label: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      backgroundColor: statusColor.withValues(alpha: 0.1),
      side: BorderSide(color: statusColor.withValues(alpha: 0.5)),
    );
  }
}
