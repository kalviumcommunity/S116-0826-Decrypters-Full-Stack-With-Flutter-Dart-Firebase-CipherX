import '../failures/shift_failure.dart';

class ShiftValidator {
  static String? validateGuard(String? guardId) {
    if (guardId == null || guardId.trim().isEmpty) {
      return 'Please select a guard.';
    }
    return null;
  }

  static String? validateSite(String? siteId) {
    if (siteId == null || siteId.trim().isEmpty) {
      return 'Please select a site.';
    }
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Please select a shift date.';
    }
    return null;
  }

  static String? validateStartTime(DateTime? startTime) {
    if (startTime == null) {
      return 'Please select a start time.';
    }
    return null;
  }

  static String? validateEndTime(DateTime? endTime) {
    if (endTime == null) {
      return 'Please select an end time.';
    }
    return null;
  }

  static String? validateTimeOrdering(DateTime? startTime, DateTime? endTime) {
    if (startTime == null || endTime == null) {
      return null; // Checked by presence validators
    }
    if (!endTime.isAfter(startTime)) {
      return 'End time must be after start time.';
    }
    return null;
  }

  static void validate({
    required String? guardId,
    required String? siteId,
    required DateTime? date,
    required DateTime? startTime,
    required DateTime? endTime,
  }) {
    final guardErr = validateGuard(guardId);
    if (guardErr != null) throw ShiftValidationFailure(guardErr);

    final siteErr = validateSite(siteId);
    if (siteErr != null) throw ShiftValidationFailure(siteErr);

    final dateErr = validateDate(date);
    if (dateErr != null) throw ShiftValidationFailure(dateErr);

    final startErr = validateStartTime(startTime);
    if (startErr != null) throw ShiftValidationFailure(startErr);

    final endErr = validateEndTime(endTime);
    if (endErr != null) throw ShiftValidationFailure(endErr);

    final orderErr = validateTimeOrdering(startTime, endTime);
    if (orderErr != null) throw ShiftValidationFailure(orderErr);
  }
}
