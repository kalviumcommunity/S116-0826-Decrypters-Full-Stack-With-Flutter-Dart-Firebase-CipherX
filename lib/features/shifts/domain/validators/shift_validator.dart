import '../entities/shift.dart';
import '../failures/shift_failure.dart';

class ShiftValidator {
  static String? validateShiftId(String shiftId) {
    if (shiftId.trim().isEmpty) {
      return 'Shift ID cannot be empty.';
    }
    return null;
  }

  static String? validateOrganizationId(String organizationId) {
    if (organizationId.trim().isEmpty) {
      return 'Organization ID cannot be empty.';
    }
    return null;
  }

  static String? validateGuardId(String guardId) {
    if (guardId.trim().isEmpty) {
      return 'Guard ID cannot be empty.';
    }
    return null;
  }

  static String? validateSiteId(String siteId) {
    if (siteId.trim().isEmpty) {
      return 'Site ID cannot be empty.';
    }
    return null;
  }

  static String? validateTimeRange(Shift shift) {
    if (!shift.startTime.isBefore(shift.endTime)) {
      return 'Start time must be strictly before end time for same-day shifts.';
    }
    return null;
  }

  static String? validateStatusTransition({
    required ShiftStatus from,
    required ShiftStatus to,
  }) {
    if (from == to) return null;

    switch (from) {
      case ShiftStatus.scheduled:
        if (to == ShiftStatus.active || to == ShiftStatus.cancelled) {
          return null;
        }
        return 'Cannot transition shift from SCHEDULED to ${to.name.toUpperCase()}.';

      case ShiftStatus.active:
        if (to == ShiftStatus.completed || to == ShiftStatus.cancelled) {
          return null;
        }
        return 'Cannot transition shift from ACTIVE to ${to.name.toUpperCase()}.';

      case ShiftStatus.completed:
        return 'Cannot transition shift from COMPLETED to any other status.';

      case ShiftStatus.cancelled:
        return 'Cannot transition shift from CANCELLED to any other status.';
    }
  }

  /// Normalizes shift IDs and calendar date representation.
  static Shift normalize(Shift shift) {
    final d = shift.date;
    final normalizedDate = DateTime.utc(d.year, d.month, d.day);

    return shift.copyWith(
      shiftId: shift.shiftId.trim(),
      organizationId: shift.organizationId.trim(),
      guardId: shift.guardId.trim(),
      siteId: shift.siteId.trim(),
      date: normalizedDate,
    );
  }

  /// Validates all domain invariants of [shift].
  /// Throws a concrete [ShiftFailure] if invalid.
  /// Returns normalized [Shift] if valid.
  static Shift validate(Shift shift) {
    final shiftIdErr = validateShiftId(shift.shiftId);
    if (shiftIdErr != null) throw InvalidShiftIdFailure(shiftIdErr);

    final orgErr = validateOrganizationId(shift.organizationId);
    if (orgErr != null) throw InvalidOrganizationIdFailure(orgErr);

    final guardErr = validateGuardId(shift.guardId);
    if (guardErr != null) throw InvalidGuardIdFailure(guardErr);

    final siteErr = validateSiteId(shift.siteId);
    if (siteErr != null) throw InvalidSiteIdFailure(siteErr);

    final timeRangeErr = validateTimeRange(shift);
    if (timeRangeErr != null) throw InvalidTimeRangeFailure(timeRangeErr);

    return normalize(shift);
  }
}
