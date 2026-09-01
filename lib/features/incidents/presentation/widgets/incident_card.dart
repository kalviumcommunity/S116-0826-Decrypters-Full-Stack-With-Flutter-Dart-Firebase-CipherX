import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/incident.dart';

class IncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    final dateStr = incident.createdAt != null
        ? dateFormat.format(incident.createdAt!)
        : 'Just now';

    final severityColor = _getSeverityColor(incident.severity);
    final statusColor = _getStatusColor(incident.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
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
                      incident.type.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildBadge(
                    text: incident.severity.displayName.toUpperCase(),
                    color: severityColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                incident.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildBadge(
                    text: incident.status.displayName,
                    color: statusColor,
                    isOutlined: true,
                  ),
                  const Spacer(),
                  if (incident.evidenceUrls.isNotEmpty) ...[
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${incident.evidenceUrls.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (incident.latitude != null &&
                      incident.longitude != null) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${incident.latitude!.toStringAsFixed(4)}, ${incident.longitude!.toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String text,
    required Color color,
    bool isOutlined = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: isOutlined ? color.withValues(alpha: 0.1) : color,
        borderRadius: BorderRadius.circular(12.0),
        border:
            isOutlined ? Border.all(color: color.withValues(alpha: 0.5)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isOutlined ? color : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return Colors.red.shade700;
      case IncidentSeverity.high:
        return Colors.orange.shade800;
      case IncidentSeverity.medium:
        return Colors.amber.shade900;
      case IncidentSeverity.low:
        return Colors.blue.shade700;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.underReview:
        return Colors.amber.shade800;
      case IncidentStatus.open:
        return Colors.blue;
    }
  }
}
