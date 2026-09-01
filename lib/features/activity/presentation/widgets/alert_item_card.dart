import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/operational_alert.dart';

class AlertItemCard extends StatelessWidget {
  final OperationalAlert alert;

  const AlertItemCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    final timeStr = alert.timestamp != null
        ? dateFormat.format(alert.timestamp!)
        : 'Recent';

    final severityColor = _getSeverityColor(alert.severity);

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
                    alert.title.isNotEmpty
                        ? alert.title
                        : alert.type.displayName,
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
                    alert.severity.displayName.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (alert.message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                alert.message,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (alert.siteId != null && alert.siteId!.isNotEmpty) ...[
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Site: ${alert.siteId}',
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
                  alert.status.displayName,
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

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return Colors.red.shade700;
      case AlertSeverity.warning:
        return Colors.amber.shade900;
      case AlertSeverity.info:
        return Colors.blue.shade700;
    }
  }

  IconData _getAlertIcon(OperationalAlertType type) {
    switch (type) {
      case OperationalAlertType.missedShift:
        return Icons.event_busy;
      case OperationalAlertType.lateCheckIn:
        return Icons.access_alarm;
      case OperationalAlertType.understaffedSite:
        return Icons.group_off;
      case OperationalAlertType.criticalIncident:
        return Icons.warning_amber_rounded;
      case OperationalAlertType.other:
        return Icons.notifications_active;
    }
  }
}
