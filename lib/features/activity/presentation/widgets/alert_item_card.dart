import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/domain/entities/alert_status.dart';
import '../../../alerts/domain/entities/alert_type.dart';

class AlertItemCard extends StatelessWidget {
  final Alert alert;

  const AlertItemCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    final timeStr = dateFormat.format(alert.createdAt);
    final severityColor = _getSeverityColor(alert.type);

    final siteId = alert.metadata['siteId'] as String?;
    final message = (alert.metadata['message'] as String?) ??
        (alert.metadata['details'] as String?) ??
        'Triggered by ${alert.sourceEntityType} (${alert.sourceEntityId})';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: BorderSide(
          color: severityColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAlertIcon(alert.type),
                  color: severityColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getAlertTypeName(alert.type),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _getSeverityLabel(alert.type),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (siteId != null && siteId.isNotEmpty) ...[
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Site: $siteId',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  _getStatusDisplayName(alert.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: alert.status == AlertStatus.active
                        ? Colors.red.shade700
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getAlertTypeName(AlertType type) {
    switch (type) {
      case AlertType.missedShift:
        return 'Missed Shift';
      case AlertType.lateCheckIn:
        return 'Late Check-In';
      case AlertType.understaffedSite:
        return 'Understaffed Site';
      case AlertType.criticalIncident:
        return 'Critical Incident';
    }
  }

  String _getStatusDisplayName(AlertStatus status) {
    switch (status) {
      case AlertStatus.active:
        return 'Active';
      case AlertStatus.acknowledged:
        return 'Acknowledged';
      case AlertStatus.resolved:
        return 'Resolved';
    }
  }

  Color _getSeverityColor(AlertType type) {
    switch (type) {
      case AlertType.criticalIncident:
        return Colors.red.shade700;
      case AlertType.understaffedSite:
        return Colors.orange.shade800;
      case AlertType.missedShift:
        return Colors.amber.shade900;
      case AlertType.lateCheckIn:
        return Colors.blue.shade700;
    }
  }

  String _getSeverityLabel(AlertType type) {
    switch (type) {
      case AlertType.criticalIncident:
        return 'CRITICAL';
      case AlertType.understaffedSite:
        return 'HIGH';
      case AlertType.missedShift:
        return 'WARNING';
      case AlertType.lateCheckIn:
        return 'NOTICE';
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.missedShift:
        return Icons.event_busy;
      case AlertType.lateCheckIn:
        return Icons.access_alarm;
      case AlertType.understaffedSite:
        return Icons.group_off;
      case AlertType.criticalIncident:
        return Icons.warning_amber_rounded;
    }
  }
}
