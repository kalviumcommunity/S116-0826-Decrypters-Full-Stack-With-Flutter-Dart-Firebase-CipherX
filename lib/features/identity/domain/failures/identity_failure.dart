import 'package:flutter/foundation.dart';

@immutable
abstract class IdentityFailure implements Exception {
  final String message;
  const IdentityFailure(this.message);

  @override
  String toString() => 'IdentityFailure: $message';
}

class ProfileNotFoundFailure extends IdentityFailure {
  const ProfileNotFoundFailure([super.message = 'User profile was not found.']);
}

class OrganizationNotFoundFailure extends IdentityFailure {
  const OrganizationNotFoundFailure([
    super.message = 'Organization was not found.',
  ]);
}

class ProfileValidationFailure extends IdentityFailure {
  const ProfileValidationFailure(super.message);
}

class OrganizationValidationFailure extends IdentityFailure {
  const OrganizationValidationFailure(super.message);
}

class PermissionDeniedFailure extends IdentityFailure {
  const PermissionDeniedFailure([
    super.message = 'You do not have permission to access this resource.',
  ]);
}

class FirestoreFailure extends IdentityFailure {
  const FirestoreFailure([
    super.message = 'Database operation failed. Please try again.',
  ]);
}

class UnknownIdentityFailure extends IdentityFailure {
  const UnknownIdentityFailure([
    super.message = 'An unexpected identity error occurred.',
  ]);
}
