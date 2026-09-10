import 'package:meta/meta.dart';

/// Base class for all domain-level exceptions and failures in the Incident Domain.
///
/// Follows pure Dart conventions and does not depend on Flutter or Firebase.
@immutable
abstract class IncidentFailure implements Exception {
  final String message;

  const IncidentFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Generic validation failure for incidents.
class IncidentValidationFailure extends IncidentFailure {
  const IncidentValidationFailure(super.message);
}

/// Thrown when an incident ID is empty, whitespace-only, or invalid.
class InvalidIncidentIdFailure extends IncidentValidationFailure {
  const InvalidIncidentIdFailure(
      [super.message = 'Incident ID cannot be empty or whitespace-only.']);
}

/// Thrown when an organization ID is empty, whitespace-only, or missing.
class InvalidOrganizationIdFailure extends IncidentValidationFailure {
  const InvalidOrganizationIdFailure([
    super.message = 'Organization ID cannot be empty or whitespace-only.',
  ]);
}

/// Thrown when the reporter user ID is empty, whitespace-only, or missing.
class InvalidReporterIdFailure extends IncidentValidationFailure {
  const InvalidReporterIdFailure(
      [super.message =
          'ReportedBy user ID cannot be empty or whitespace-only.']);
}

/// Thrown when the site ID is empty, whitespace-only, or missing.
class InvalidSiteIdFailure extends IncidentValidationFailure {
  const InvalidSiteIdFailure(
      [super.message = 'Site ID cannot be empty or whitespace-only.']);
}

/// Thrown when the incident type is empty, whitespace-only, or missing.
class InvalidIncidentTypeFailure extends IncidentValidationFailure {
  const InvalidIncidentTypeFailure(
      [super.message = 'Incident type cannot be empty or whitespace-only.']);
}

/// Thrown when the incident description is empty, whitespace-only, or missing.
class InvalidIncidentDescriptionFailure extends IncidentValidationFailure {
  const InvalidIncidentDescriptionFailure([
    super.message = 'Incident description cannot be empty or whitespace-only.',
  ]);
}

/// Thrown when an invalid severity string or representation is encountered.
class InvalidIncidentSeverityFailure extends IncidentValidationFailure {
  const InvalidIncidentSeverityFailure(super.message);
}

/// Thrown when an invalid status string or representation is encountered.
class InvalidIncidentStatusFailure extends IncidentValidationFailure {
  const InvalidIncidentStatusFailure(super.message);
}

/// Thrown when geographic coordinates are non-finite or outside valid boundaries.
class InvalidCoordinatesFailure extends IncidentValidationFailure {
  const InvalidCoordinatesFailure(super.message);
}

/// Thrown when only one coordinate of a coordinate pair (latitude/longitude) is provided.
class PartialCoordinatesFailure extends IncidentValidationFailure {
  const PartialCoordinatesFailure([
    super.message =
        'Latitude and longitude must both be present or both absent.',
  ]);
}

/// Thrown when timestamps are logically contradictory (e.g., updatedAt before createdAt).
class InvalidIncidentTimestampFailure extends IncidentValidationFailure {
  const InvalidIncidentTimestampFailure(super.message);
}

/// Thrown when a resolved incident lacks resolution metadata (resolvedAt or resolvedBy).
class MissingResolutionMetadataFailure extends IncidentValidationFailure {
  const MissingResolutionMetadataFailure(super.message);
}

/// Thrown when an unresolved incident (OPEN/INVESTIGATING) contains resolution metadata.
class ContradictoryResolutionMetadataFailure extends IncidentValidationFailure {
  const ContradictoryResolutionMetadataFailure(super.message);
}

/// Thrown when an illegal lifecycle transition is attempted (e.g., RESOLVED -> OPEN).
class InvalidStatusTransitionFailure extends IncidentFailure {
  const InvalidStatusTransitionFailure(super.message);
}

/// Thrown when attempting to resolve an already resolved incident.
class IncidentAlreadyResolvedFailure extends InvalidStatusTransitionFailure {
  const IncidentAlreadyResolvedFailure([
    super.message =
        'Incident is already resolved and cannot be resolved again.',
  ]);
}

/// Thrown when an incident is not found in the repository.
class IncidentNotFoundFailure extends IncidentFailure {
  const IncidentNotFoundFailure([super.message = 'Incident was not found.']);
}

/// Thrown when a repository/database layer error occurs while managing incidents.
class IncidentDatabaseFailure extends IncidentFailure {
  const IncidentDatabaseFailure(super.message);
}

/// Thrown when an unexpected incident domain error occurs.
class UnknownIncidentFailure extends IncidentFailure {
  const UnknownIncidentFailure([
    super.message = 'An unexpected incident domain error occurred.',
  ]);
}
