import 'package:meta/meta.dart';

@immutable
abstract class ShiftFailure implements Exception {
  final String message;
  const ShiftFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShiftFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

class ShiftValidationFailure extends ShiftFailure {
  const ShiftValidationFailure(super.message);
}

class InvalidShiftIdFailure extends ShiftFailure {
  const InvalidShiftIdFailure([super.message = 'Shift ID cannot be empty.']);
}

class InvalidOrganizationIdFailure extends ShiftFailure {
  const InvalidOrganizationIdFailure(
      [super.message = 'Organization ID cannot be empty.']);
}

class InvalidGuardIdFailure extends ShiftFailure {
  const InvalidGuardIdFailure([super.message = 'Guard ID cannot be empty.']);
}

class InvalidSiteIdFailure extends ShiftFailure {
  const InvalidSiteIdFailure([super.message = 'Site ID cannot be empty.']);
}

class InvalidShiftDateFailure extends ShiftFailure {
  const InvalidShiftDateFailure([super.message = 'Invalid shift date.']);
}

class InvalidTimeRangeFailure extends ShiftFailure {
  const InvalidTimeRangeFailure([
    super.message =
        'Start time must be strictly before end time for same-day shifts.',
  ]);
}

class InvalidShiftStatusFailure extends ShiftFailure {
  const InvalidShiftStatusFailure([super.message = 'Invalid shift status.']);
}

class InvalidStatusTransitionFailure extends ShiftFailure {
  const InvalidStatusTransitionFailure(super.message);
}

class ShiftNotFoundFailure extends ShiftFailure {
  const ShiftNotFoundFailure([super.message = 'Shift was not found.']);
}

class UnknownShiftFailure extends ShiftFailure {
  const UnknownShiftFailure(
      [super.message = 'An unexpected shift domain error occurred.']);
}
