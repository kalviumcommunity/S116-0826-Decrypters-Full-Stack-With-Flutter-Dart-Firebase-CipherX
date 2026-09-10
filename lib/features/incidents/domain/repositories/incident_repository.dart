import '../entities/incident.dart';
import '../entities/incident_severity.dart';
import '../entities/incident_status.dart';

/// Pure domain repository contract defining operations for incident management.
///
/// All operations enforce tenant isolation through the mandatory [organizationId] parameter.
/// Implementation details (Firestore, caching, offline support) are delegated to the infrastructure layer.
abstract class IncidentRepository {
  /// Persists a new [incident] report.
  ///
  /// Throws a concrete [IncidentFailure] if validation or persistence fails.
  Future<Incident> createIncident(Incident incident);

  /// Retrieves an incident by its unique [incidentId] within the specified [organizationId].
  ///
  /// Returns `null` if no matching incident exists.
  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  });

  /// Retrieves a list of incidents for [organizationId], optionally filtered by [status] or [severity].
  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  });

  /// Real-time stream of incidents for [organizationId], optionally filtered by [status] or [severity].
  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  });

  /// Retrieves incidents associated with a specific [siteId] within [organizationId].
  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  });

  /// Real-time stream of incidents for a specific [siteId] within [organizationId].
  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  });

  /// Retrieves incidents reported by a specific user ([reportedBy]) within [organizationId].
  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  });

  /// Updates mutable fields of an existing [incident].
  ///
  /// Preserves immutable tenant and reporter identity fields.
  Future<Incident> updateIncident(Incident incident);

  /// Updates the lifecycle [status] of an incident.
  ///
  /// If transitioning to [IncidentStatus.resolved], [resolvedBy] is required.
  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
  });
}
