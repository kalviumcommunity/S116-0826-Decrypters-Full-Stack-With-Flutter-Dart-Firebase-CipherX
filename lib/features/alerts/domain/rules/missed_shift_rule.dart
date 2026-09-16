import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../entities/alert.dart';
import '../entities/alert_type.dart';
import '../policies/missed_shift_policy.dart';
import '../services/alert_id_generator.dart';
import 'alert_rule.dart';

class MissedShiftInput {
  final Shift shift;
  final List<AttendanceRecord> attendanceRecords;
  final String targetOrganizationId;

  const MissedShiftInput({
    required this.shift,
    required this.attendanceRecords,
    required this.targetOrganizationId,
  });
}

class MissedShiftRule implements AlertRule<MissedShiftInput> {
  final MissedShiftPolicy policy;

  const MissedShiftRule({
    this.policy = const DefaultMissedShiftPolicy(),
  });

  @override
  String get ruleName => 'MISSED_SHIFT';

  @override
  Future<Alert?> evaluate(
    MissedShiftInput input, {
    required DateTime evaluationTime,
  }) async {
    final shift = input.shift;

    // Tenant boundary check
    if (shift.organizationId != input.targetOrganizationId) {
      return null;
    }

    // Do not alert on cancelled shifts
    if (shift.status == ShiftStatus.cancelled) {
      return null;
    }

    // Check if guard has a valid check-in for this shift
    final hasValidCheckIn = input.attendanceRecords.any(
      (record) =>
          record.organizationId == input.targetOrganizationId &&
          record.shiftId == shift.shiftId &&
          record.guardId == shift.guardId,
    );

    if (hasValidCheckIn) {
      return null;
    }

    final isMissed = policy.isMissed(
      shift: shift,
      evaluationTime: evaluationTime,
      hasValidCheckIn: hasValidCheckIn,
    );

    if (!isMissed) {
      return null;
    }

    final alertId = AlertIdGenerator.missedShift(
      shift.organizationId,
      shift.shiftId,
    );

    return Alert(
      alertId: alertId,
      organizationId: shift.organizationId,
      type: AlertType.missedShift,
      sourceEntityId: shift.shiftId,
      sourceEntityType: 'shift',
      createdAt: evaluationTime,
      metadata: {
        'guardId': shift.guardId,
        'siteId': shift.siteId,
        'shiftDate': shift.date.toIso8601String(),
        'startTime': shift.startTime.toFormattedString(),
        'endTime': shift.endTime.toFormattedString(),
      },
    );
  }
}
