import '../../../shifts/domain/entities/shift.dart';

/// Configurable policy determining when an entire shift is classified as missed.
abstract interface class MissedShiftPolicy {
  Duration get gracePeriodAfterEnd;

  bool isMissed({
    required Shift shift,
    required DateTime evaluationTime,
    required bool hasValidCheckIn,
  });
}

class DefaultMissedShiftPolicy implements MissedShiftPolicy {
  @override
  final Duration gracePeriodAfterEnd;

  const DefaultMissedShiftPolicy({
    this.gracePeriodAfterEnd = Duration.zero,
  });

  @override
  bool isMissed({
    required Shift shift,
    required DateTime evaluationTime,
    required bool hasValidCheckIn,
  }) {
    if (shift.status == ShiftStatus.cancelled) return false;
    if (hasValidCheckIn) return false;

    final shiftEnd = DateTime(
      shift.date.year,
      shift.date.month,
      shift.date.day,
      shift.endTime.hour,
      shift.endTime.minute,
    );

    final evaluationBoundary = shiftEnd.add(gracePeriodAfterEnd);
    return evaluationTime.isAfter(evaluationBoundary);
  }
}
