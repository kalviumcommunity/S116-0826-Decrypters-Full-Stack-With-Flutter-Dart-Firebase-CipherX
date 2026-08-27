import '../../../guards/domain/entities/guard.dart';
import '../../../sites/domain/entities/site.dart';
import '../entities/shift.dart';
import '../failures/shift_failure.dart';
import 'shift_overlap_validator.dart';

/// Domain service responsible for validating shift assignments before creation or modification.
class ShiftAssignmentValidator {
  const ShiftAssignmentValidator._();

  /// Validates all business rules for assigning [shift] to [guard] at [site] given [existingShifts].
  ///
  /// Throws domain exceptions extending [ShiftFailure] when validation rules are violated.
  static void validateAssignment({
    required Shift shift,
    required Guard? guard,
    required Site? site,
    required List<Shift> existingShifts,
  }) {
    // 1. Time range validation
    if (!shift.startTime.isBefore(shift.endTime)) {
      throw const ShiftValidationFailure('Start time must be before end time.');
    }

    // 2. Guard existence and status validation
    if (guard == null) {
      throw const GuardNotFoundFailure();
    }
    if (guard.organizationId != shift.organizationId) {
      throw const CrossOrganizationAssignmentFailure();
    }
    if (guard.status != GuardStatus.active) {
      throw const GuardInactiveFailure();
    }

    // 3. Site existence and status validation
    if (site == null) {
      throw const SiteNotFoundFailure();
    }
    if (site.organizationId != shift.organizationId) {
      throw const CrossOrganizationAssignmentFailure();
    }
    if (site.status != SiteStatus.active) {
      throw const SiteInactiveFailure();
    }

    // 4. Duplicate assignment check
    final isDuplicate = existingShifts.any((existing) {
      if (existing.shiftId == shift.shiftId && shift.shiftId.isNotEmpty) {
        return false;
      }
      return existing.organizationId == shift.organizationId &&
          existing.guardId == shift.guardId &&
          existing.siteId == shift.siteId &&
          existing.date.year == shift.date.year &&
          existing.date.month == shift.date.month &&
          existing.date.day == shift.date.day &&
          existing.startTime == shift.startTime &&
          existing.endTime == shift.endTime &&
          existing.status != ShiftStatus.cancelled;
    });

    if (isDuplicate) {
      throw const DuplicateShiftFailure();
    }

    // 5. Overlapping shift detection for the guard
    final activeGuardShifts = existingShifts.where((existing) {
      if (existing.shiftId == shift.shiftId && shift.shiftId.isNotEmpty) {
        return false;
      }
      if (existing.guardId != shift.guardId) {
        return false;
      }
      if (existing.date.year != shift.date.year ||
          existing.date.month != shift.date.month ||
          existing.date.day != shift.date.day) {
        return false;
      }
      // Only active assignments conflict (scheduled or active)
      return existing.status == ShiftStatus.scheduled ||
          existing.status == ShiftStatus.active;
    });

    for (final existing in activeGuardShifts) {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: shift.startTime,
        endA: shift.endTime,
        startB: existing.startTime,
        endB: existing.endTime,
      );

      if (overlaps) {
        throw const ShiftConflictFailure(
          'This guard already has another shift during the selected time.',
        );
      }
    }
  }
}
