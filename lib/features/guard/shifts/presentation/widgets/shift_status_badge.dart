import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../shifts/domain/entities/shift.dart';

class ShiftStatusBadge extends StatelessWidget {
  final ShiftStatus status;

  const ShiftStatusBadge({super.key, required this.status});

  Color _getBackgroundColor(BuildContext context) {
    switch (status) {
      case ShiftStatus.scheduled:
        return AppColors.info.withOpacity(0.1);
      case ShiftStatus.inProgress:
        return AppColors.accentGold.withOpacity(0.1);
      case ShiftStatus.completed:
        return AppColors.success.withOpacity(0.1);
      case ShiftStatus.cancelled:
        return AppColors.error.withOpacity(0.1);
    }
    return AppColors.info.withOpacity(0.1);
  }

  Color _getTextColor(BuildContext context) {
    switch (status) {
      case ShiftStatus.scheduled:
        return AppColors.info;
      case ShiftStatus.inProgress:
        return AppColors.accentGold;
      case ShiftStatus.completed:
        return AppColors.success;
      case ShiftStatus.cancelled:
        return AppColors.error;
    }
    return AppColors.info;
  }

  String _getLabel() {
    switch (status) {
      case ShiftStatus.scheduled:
        return 'Scheduled';
      case ShiftStatus.inProgress:
        return 'In Progress';
      case ShiftStatus.completed:
        return 'Completed';
      case ShiftStatus.cancelled:
        return 'Cancelled';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getTextColor(context).withOpacity(0.5)),
      ),
      child: Text(
        _getLabel(),
        style: TextStyle(
          color: _getTextColor(context),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
