import 'package:flutter/material.dart';

import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;

  const IncidentCard({super.key, required this.incident});

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return Colors.red.shade700;
      case IncidentSeverity.high:
        return Colors.orange.shade800;
      case IncidentSeverity.medium:
        return Colors.amber.shade800;
      case IncidentSeverity.low:
        return Colors.blue.shade700;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Colors.orange;
      case IncidentStatus.investigating:
        return Colors.blue;
      case IncidentStatus.resolved:
        return Colors.green;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(incident.severity);
    final statusColor = _getStatusColor(incident.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withAlpha(80), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: severityColor),
                  ),
                  child: Text(
                    incident.severity.name.toUpperCase(),
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    incident.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(incident.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              incident.type,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              incident.description,
              style: theme.textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Site: ${incident.siteId}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                ),
                if (incident.latitude != null &&
                    incident.longitude != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.my_location,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${incident.latitude!.toStringAsFixed(4)}, ${incident.longitude!.toStringAsFixed(4)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
