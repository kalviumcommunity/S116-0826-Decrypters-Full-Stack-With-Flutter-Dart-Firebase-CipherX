import 'package:flutter/material.dart';

import '../../../../core/utils/time_utils.dart';
import '../../domain/entities/audit_log.dart';

/// Professional audit log and activity item card.
/// Displays clear natural language action statements:
/// e.g. "Hardik created Site A • Today, 10:42 AM"
class ActivityItemCard extends StatelessWidget {
  final AuditLog auditLog;

  const ActivityItemCard({
    super.key,
    required this.auditLog,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final relativeTime = TimeUtils.formatHumanFriendly(auditLog.timestamp);
    final exactTime = TimeUtils.formatExact(auditLog.timestamp);

    final roleColor = _getRoleColor(auditLog.actorRole);
    final naturalAction = _formatSentence(auditLog);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Icon(
                _getActionIcon(auditLog.action),
                size: 18,
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
                      Expanded(
                        child: Text(
                          auditLog.actorName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(height: 2),
                  Text(
                    auditLog.action.replaceAll('_', ' '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    naturalAction,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade700,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        size: 13,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${auditLog.entityType.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: exactTime,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              relativeTime,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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

  String _formatSentence(AuditLog log) {
    final actor = log.actorName.isNotEmpty ? log.actorName : 'User';
    final actionLower = log.action.toLowerCase();

    if (actionLower.contains('check_in') || actionLower.contains('checkin')) {
      return '$actor checked in at ${log.entityType}';
    }
    if (actionLower.contains('check_out') || actionLower.contains('checkout')) {
      return '$actor checked out from ${log.entityType}';
    }
    if (actionLower.contains('incident') || actionLower.contains('report')) {
      return '$actor reported an incident';
    }
    if (actionLower.contains('shift')) {
      return '$actor scheduled a shift';
    }
    if (actionLower.contains('site')) {
      return '$actor updated ${log.entityType}';
    }
    if (actionLower.contains('guard') || actionLower.contains('user')) {
      return '$actor created guard profile';
    }

    final verb = log.action.replaceAll('_', ' ').toLowerCase();
    return '$actor $verb';
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
        return Icons.login_rounded;
      case 'CHECK_OUT_SUCCESS':
      case 'CHECK_OUT_OK':
        return Icons.logout_rounded;
      case 'INCIDENT_CREATED':
      case 'INCIDENT_SUBMITTED':
        return Icons.warning_amber_rounded;
      case 'SHIFT_CREATED':
        return Icons.event_available_rounded;
      case 'USER_CREATED':
        return Icons.person_add_rounded;
      default:
        return Icons.history_rounded;
    }
  }
}
