import '../entities/incident.dart';
import '../entities/incident_status.dart';
import '../failures/incident_failure.dart';

/// Pure domain validator enforcing all invariants for the Incident Domain.
class IncidentValidator {
  /// Validates the incident identifier.
  static String? validateIncidentId(String? incidentId) {
    if (incidentId == null || incidentId.trim().isEmpty) {
      return 'Incident ID cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates the organization (tenant) identifier.
  static String? validateOrganizationId(String? organizationId) {
    if (organizationId == null || organizationId.trim().isEmpty) {
      return 'Organization ID cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates the reporter user identifier.
  static String? validateReporterId(String? reportedBy) {
    if (reportedBy == null || reportedBy.trim().isEmpty) {
      return 'ReportedBy user ID cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates the site identifier.
  static String? validateSiteId(String? siteId) {
    if (siteId == null || siteId.trim().isEmpty) {
      return 'Site ID cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates the incident type string.
  static String? validateType(String? type) {
    if (type == null || type.trim().isEmpty) {
      return 'Incident type cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates the incident description.
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Incident description cannot be empty or whitespace-only.';
    }
    return null;
  }

  /// Validates geographic coordinate consistency and boundaries.
  ///
  /// Enforces that coordinates are either both absent (null) or both present.
  /// When present, coordinates must be finite and within valid geographic bounds:
  /// Latitude: [-90.0, 90.0]
  /// Longitude: [-180.0, 180.0]
  static void validateCoordinates({
    required double? latitude,
    required double? longitude,
  }) {
    if (latitude == null && longitude == null) {
      return;
    }

    if (latitude != null && longitude == null) {
      throw const PartialCoordinatesFailure(
        'Latitude cannot be specified without longitude.',
      );
    }

    if (latitude == null && longitude != null) {
      throw const PartialCoordinatesFailure(
        'Longitude cannot be specified without latitude.',
      );
    }

    // Both are non-null
    if (!latitude!.isFinite) {
      throw const InvalidCoordinatesFailure(
        'Latitude must be a finite number.',
      );
    }

    if (!longitude!.isFinite) {
      throw const InvalidCoordinatesFailure(
        'Longitude must be a finite number.',
      );
    }

    if (latitude < -90.0 || latitude > 90.0) {
      throw InvalidCoordinatesFailure(
        'Latitude must be between -90 and 90 degrees. Received: $latitude',
      );
    }

    if (longitude < -180.0 || longitude > 180.0) {
      throw InvalidCoordinatesFailure(
        'Longitude must be between -180 and 180 degrees. Received: $longitude',
      );
    }
  }

  /// Validates chronological consistency across incident timestamps.
  static void validateTimestamps({
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? resolvedAt,
  }) {
    if (updatedAt.isBefore(createdAt)) {
      throw InvalidIncidentTimestampFailure(
        'updatedAt ($updatedAt) cannot be earlier than createdAt ($createdAt).',
      );
    }

    if (resolvedAt != null && resolvedAt.isBefore(createdAt)) {
      throw InvalidIncidentTimestampFailure(
        'resolvedAt ($resolvedAt) cannot be earlier than createdAt ($createdAt).',
      );
    }
  }

  /// Validates the resolution state invariant:
  /// - If status is RESOLVED: resolvedAt and resolvedBy must both be present and non-empty.
  /// - If status is NOT RESOLVED (OPEN/INVESTIGATING): resolvedAt and resolvedBy must both be null.
  static void validateResolutionState({
    required IncidentStatus status,
    required DateTime? resolvedAt,
    required String? resolvedBy,
    required DateTime createdAt,
  }) {
    if (status == IncidentStatus.resolved) {
      if (resolvedAt == null) {
        throw const MissingResolutionMetadataFailure(
          'Resolved incident must have a resolvedAt timestamp.',
        );
      }

      if (resolvedBy == null || resolvedBy.trim().isEmpty) {
        throw const MissingResolutionMetadataFailure(
          'Resolved incident must have a non-empty resolvedBy identifier.',
        );
      }

      if (resolvedAt.isBefore(createdAt)) {
        throw InvalidIncidentTimestampFailure(
          'resolvedAt ($resolvedAt) cannot be earlier than createdAt ($createdAt).',
        );
      }
    } else {
      if (resolvedAt != null) {
        throw ContradictoryResolutionMetadataFailure(
          'Unresolved incident ($status) cannot have a resolvedAt timestamp.',
        );
      }

      if (resolvedBy != null) {
        throw ContradictoryResolutionMetadataFailure(
          'Unresolved incident ($status) cannot have a resolvedBy identifier.',
        );
      }
    }
  }

  /// Validates whether a status transition from [from] to [to] is permitted.
  static void validateStatusTransition({
    required IncidentStatus from,
    required IncidentStatus to,
  }) {
    if (!from.canTransitionTo(to)) {
      throw InvalidStatusTransitionFailure(
        'Cannot transition incident status from ${from.name.toUpperCase()} to ${to.name.toUpperCase()}.',
      );
    }
  }

  /// Normalizes all user-supplied string fields (trims whitespace).
  static Incident normalize(Incident incident) {
    return incident.copyWith(
      incidentId: incident.incidentId.trim(),
      organizationId: incident.organizationId.trim(),
      reportedBy: incident.reportedBy.trim(),
      siteId: incident.siteId.trim(),
      type: incident.type.trim(),
      description: incident.description.trim(),
      resolvedBy: incident.resolvedBy?.trim(),
    );
  }

  /// Validates all domain invariants of [incident].
  ///
  /// Throws a concrete subclass of [IncidentFailure] upon the first encountered violation.
  /// Returns a normalized, validated [Incident] on success.
  static Incident validate(Incident incident) {
    final idErr = validateIncidentId(incident.incidentId);
    if (idErr != null) throw InvalidIncidentIdFailure(idErr);

    final orgErr = validateOrganizationId(incident.organizationId);
    if (orgErr != null) throw InvalidOrganizationIdFailure(orgErr);

    final reporterErr = validateReporterId(incident.reportedBy);
    if (reporterErr != null) throw InvalidReporterIdFailure(reporterErr);

    final siteErr = validateSiteId(incident.siteId);
    if (siteErr != null) throw InvalidSiteIdFailure(siteErr);

    final typeErr = validateType(incident.type);
    if (typeErr != null) throw InvalidIncidentTypeFailure(typeErr);

    final descErr = validateDescription(incident.description);
    if (descErr != null) throw InvalidIncidentDescriptionFailure(descErr);

    validateCoordinates(
      latitude: incident.latitude,
      longitude: incident.longitude,
    );

    validateTimestamps(
      createdAt: incident.createdAt,
      updatedAt: incident.updatedAt,
      resolvedAt: incident.resolvedAt,
    );

    validateResolutionState(
      status: incident.status,
      resolvedAt: incident.resolvedAt,
      resolvedBy: incident.resolvedBy,
      createdAt: incident.createdAt,
    );

    return normalize(incident);
  }
}
