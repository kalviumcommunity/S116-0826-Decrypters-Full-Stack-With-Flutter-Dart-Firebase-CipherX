import 'package:meta/meta.dart';

@immutable
abstract class AttendanceFailure implements Exception {
  final String message;
  const AttendanceFailure(this.message);

  @override
  String toString() => message;
}

class DuplicateCheckOutFailure extends AttendanceFailure {
  const DuplicateCheckOutFailure([
    super.message =
        'Check-out has already been recorded for this attendance session.',
  ]);
}

class NoActiveAttendanceFailure extends AttendanceFailure {
  const NoActiveAttendanceFailure([
    super.message = 'No active attendance record found to check out.',
  ]);
}

class AttendanceNotFoundFailure extends AttendanceFailure {
  const AttendanceNotFoundFailure([
    super.message = 'Requested attendance record was not found.',
  ]);
}

class UnknownAttendanceFailure extends AttendanceFailure {
  const UnknownAttendanceFailure(super.message);
}
