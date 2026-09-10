import 'package:meta/meta.dart';

@immutable
abstract class IncidentFailure implements Exception {
  final String message;
  const IncidentFailure(this.message);

  @override
  String toString() => message;
}

class InvalidIncidentDataFailure extends IncidentFailure {
  const InvalidIncidentDataFailure([
    super.message =
        'Invalid incident details provided. Please check all fields.',
  ]);
}

class IncidentNotFoundFailure extends IncidentFailure {
  const IncidentNotFoundFailure([
    super.message = 'Incident record not found.',
  ]);
}

class UnknownIncidentFailure extends IncidentFailure {
  const UnknownIncidentFailure(super.message);
}
