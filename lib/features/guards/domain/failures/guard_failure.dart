import 'package:flutter/foundation.dart';

@immutable
abstract class GuardFailure implements Exception {
  final String message;
  const GuardFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GuardFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

class GuardNotFoundFailure extends GuardFailure {
  const GuardNotFoundFailure([
    super.message = 'Guard was not found.',
  ]);
}

class GuardValidationFailure extends GuardFailure {
  const GuardValidationFailure(super.message);
}

class PermissionDeniedFailure extends GuardFailure {
  const PermissionDeniedFailure([
    super.message = 'You do not have permission to access this resource.',
  ]);
}

class FirestoreFailure extends GuardFailure {
  const FirestoreFailure([
    super.message = 'Database operation failed. Please try again.',
  ]);
}

class UnknownGuardFailure extends GuardFailure {
  const UnknownGuardFailure([
    super.message = 'An unexpected guard domain error occurred.',
  ]);
}
