import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../entities/alert.dart';
import '../entities/alert_type.dart';
import '../policies/late_check_in_policy.dart';
import '../services/alert_id_generator.dart';
import 'alert_rule.dart';

class LateCheckInInput {
  final Shift shift;
  final List<AttendanceRecord> attendanceRecords;
  final String targetOrganizationId;

  const LateCheckInInput({
    required this.shift,
    required this.attendanceRecords,
    required this.targetOrganizationId,
  });
}

class LateCheckInRule implements AlertRule<LateCheckInInput> {
  final LateCheckInPolicy policy;

  const LateCheckInRule({
    this.policy = const DefaultLateCheckInPolicy(),
  });

  @override
  String get ruleName => 'LATE_CHECK_IN';

  @override
  Future<Alert?> evaluate(
    LateCheckInInput input, {
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

    final scheduledStartTime = DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      shift.startTime.hour,
      shift.startTime.minute,
    );

    // Look for existing attendance records for this shift & guard
    final matchingRecords = input.attendanceRecords.where(
      (r) =>
          r.organizationId == input.targetOrganizationId &&
          r.shiftId == shift.shiftId &&
          r.guardId == shift.guardId,
    );

    final actualCheckInTime = matchingRecords.isNotEmpty
        ? matchingRecords.first.checkInTime
        : null;

    final isLate = policy.isLate(
      scheduledStartTime: scheduledStartTime,
      evaluationTime: evaluationTime,
      actualCheckInTime: actualCheckInTime,
    );

    if (!isLate) {
      return null;
    }

    final alertId = AlertIdGenerator.lateCheckIn(
      shift.organizationId,
      shift.shiftId,
    );

    return Alert(
      alertId: alertId,
      organizationId: shift.organizationId,
      type: AlertType.lateCheckIn,
      sourceEntityId: shift.shiftId,
      sourceEntityType: 'shift',
      createdAt: evaluationTime,
      metadata: {
        'guardId': shift.guardId,
        'siteId': shift.siteId,
        'scheduledStartTime': scheduledStartTime.toIso8601String(),
        'actualCheckInTime': actualCheckInTime?.toIso8601String(),
        'lateThresholdMinutes': policy.lateThreshold.inMinutes,
      },
    );
  }
}
