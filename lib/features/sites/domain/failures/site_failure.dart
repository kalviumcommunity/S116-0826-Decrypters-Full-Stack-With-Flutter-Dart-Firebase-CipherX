import 'package:flutter/foundation.dart';

@immutable
abstract class SiteFailure implements Exception {
  final String message;
  const SiteFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

class SiteNotFoundFailure extends SiteFailure {
  const SiteNotFoundFailure([
    super.message = 'Site was not found.',
  ]);
}

class SiteValidationFailure extends SiteFailure {
  const SiteValidationFailure(super.message);
}

class PermissionDeniedFailure extends SiteFailure {
  const PermissionDeniedFailure([
    super.message = 'You do not have permission to access this resource.',
  ]);
}

class FirestoreFailure extends SiteFailure {
  const FirestoreFailure([
    super.message = 'Database operation failed. Please try again.',
  ]);
}

class UnknownSiteFailure extends SiteFailure {
  const UnknownSiteFailure([
    super.message = 'An unexpected site domain error occurred.',
  ]);
}
