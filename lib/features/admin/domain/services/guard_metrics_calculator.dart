import '../../../alerts/domain/policies/late_check_in_policy.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../guards/domain/entities/guard.dart';
import '../../../shifts/domain/entities/shift.dart';

/// Calculation service for guard-specific operational metrics.
///
/// Fully testable with injected evaluation times and late policies.
class GuardMetricsCalculator {
  final LateCheckInPolicy lateCheckInPolicy;

  const GuardMetricsCalculator({
    this.lateCheckInPolicy = const DefaultLateCheckInPolicy(),
  });

  /// Computes total guards in the organization.
  int calculateTotalGuards(List<Guard> guards) {
    return guards.length;
  }

  /// Computes count of distinct guards currently active on duty.
  int calculateOnDutyGuards(List<AttendanceRecord> activeAttendances) {
    return activeAttendances
        .where((a) => a.status == AttendanceStatus.active && !a.isCheckedOut)
        .map((a) => a.guardId)
        .toSet()
        .length;
  }

  /// Computes count of guards absent from scheduled shifts today.
  int calculateAbsentGuards({
    required List<Shift> shifts,
    required List<AttendanceRecord> allAttendancesToday,
    required DateTime evaluationTime,
  }) {
    final absentGuardIds = <String>{};

    for (final shift in shifts) {
      if (shift.status == ShiftStatus.cancelled) continue;

      final isToday = shift.date.year == evaluationTime.year &&
          shift.date.month == evaluationTime.month &&
          shift.date.day == evaluationTime.day;
      if (!isToday) continue;

      final shiftEnd = DateTime(
        shift.date.year,
        shift.date.month,
        shift.date.day,
        shift.endTime.hour,
        shift.endTime.minute,
      );

      // Shift has concluded
      if (evaluationTime.isAfter(shiftEnd)) {
        final hasCheckIn = allAttendancesToday.any(
          (a) => a.shiftId == shift.shiftId && a.guardId == shift.guardId,
        );
        if (!hasCheckIn) {
          absentGuardIds.add(shift.guardId);
        }
      }
    }

    return absentGuardIds.length;
  }

  /// Computes count of guards currently late for scheduled shifts today.
  int calculateLateGuards({
    required List<Shift> shifts,
    required List<AttendanceRecord> allAttendancesToday,
    required DateTime evaluationTime,
  }) {
    final lateGuardIds = <String>{};

    for (final shift in shifts) {
      if (shift.status == ShiftStatus.cancelled) continue;

      final isToday = shift.date.year == evaluationTime.year &&
          shift.date.month == evaluationTime.month &&
          shift.date.day == evaluationTime.day;
      if (!isToday) continue;

      final scheduledStart = DateTime(
        shift.date.year,
        shift.date.month,
        shift.date.day,
        shift.startTime.hour,
        shift.startTime.minute,
      );

      final matchingRecords = allAttendancesToday.where(
        (a) => a.shiftId == shift.shiftId && a.guardId == shift.guardId,
      );

      final actualCheckIn =
          matchingRecords.isNotEmpty ? matchingRecords.first.checkInTime : null;

      final isLate = lateCheckInPolicy.isLate(
        scheduledStartTime: scheduledStart,
        evaluationTime: evaluationTime,
        actualCheckInTime: actualCheckIn,
      );

      if (isLate) {
        lateGuardIds.add(shift.guardId);
      }
    }

    return lateGuardIds.length;
  }
}
