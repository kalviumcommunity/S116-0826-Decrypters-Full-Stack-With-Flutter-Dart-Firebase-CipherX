import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/audit_log.dart';

class ActivityItemCard extends StatelessWidget {
  final AuditLog auditLog;

  const ActivityItemCard({
    super.key,
    required this.auditLog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    final timeStr = auditLog.timestamp != null
        ? dateFormat.format(auditLog.timestamp!)
        : 'Recent';

    final roleColor = _getRoleColor(auditLog.actorRole);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Icon(
                _getActionIcon(auditLog.action),
                size: 16,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        auditLog.actorName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          auditLog.actorRole.toUpperCase(),
                          style: TextStyle(
                            color: roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatActionTitle(auditLog.action),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Target: ${auditLog.entityType.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'supervisor':
        return Colors.indigo;
      case 'guard':
      default:
        return Colors.teal;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'CHECK_IN_SUCCESS':
      case 'CHECK_IN_OK':
        return Icons.login;
      case 'CHECK_OUT_SUCCESS':
      case 'CHECK_OUT_OK':
        return Icons.logout;
      case 'INCIDENT_CREATED':
      case 'INCIDENT_SUBMITTED':
        return Icons.report_problem;
      case 'SHIFT_CREATED':
        return Icons.event_available;
      case 'USER_CREATED':
        return Icons.person_add;
      default:
        return Icons.history;
    }
  }

  String _formatActionTitle(String action) {
    return action.replaceAll('_', ' ');
  }
}
