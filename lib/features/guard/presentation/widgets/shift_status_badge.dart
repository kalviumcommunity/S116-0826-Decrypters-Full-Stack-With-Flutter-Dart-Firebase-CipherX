import 'package:flutter/material.dart';

import '../../../shifts/domain/entities/shift.dart';

class ShiftStatusBadge extends StatelessWidget {
  final ShiftStatus status;

  const ShiftStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = _getBadgeStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color, Color) _getBadgeStyle(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.scheduled:
        return ('SCHEDULED', Colors.blue.shade50, Colors.blue.shade700);
      case ShiftStatus.active:
        return ('ACTIVE', Colors.green.shade50, Colors.green.shade700);
      case ShiftStatus.completed:
        return ('COMPLETED', Colors.purple.shade50, Colors.purple.shade700);
      case ShiftStatus.cancelled:
        return ('CANCELLED', Colors.red.shade50, Colors.red.shade700);
    }
  }
}
