import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
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
    final dateFormat = DateFormat('MMM d, yyyy - hh:mm a');
    final timeStr = dateFormat.format(alert.createdAt);
    final severityColor = _getSeverityColor(alert.type);

    final siteId = alert.metadata['siteId'] as String?;
    final message = (alert.metadata['message'] as String?) ??
        (alert.metadata['details'] as String?) ??
        'Triggered by ${alert.sourceEntityType} (${alert.sourceEntityId})';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getAlertIcon(alert.type),
                    color: severityColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getAlertTypeName(alert.type),
                    style: AppTextStyles.titleMedium(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _getSeverityLabel(alert.type),
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: AppTextStyles.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (siteId != null && siteId.isNotEmpty) ...[
                  const Icon(Icons.business_rounded,
                      size: 14, color: AppColors.textSecondaryLight),
                  const SizedBox(width: 4),
                  Text(
                    'Site: $siteId',
                    style: AppTextStyles.caption(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textSecondaryLight),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: AppTextStyles.caption(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                Text(
                  _getStatusDisplayName(alert.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: alert.status == AlertStatus.active
                        ? AppColors.error
                        : AppColors.success,
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
