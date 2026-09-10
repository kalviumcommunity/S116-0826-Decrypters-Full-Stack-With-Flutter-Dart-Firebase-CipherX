import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/repositories/incident_repository.dart';
import '../../domain/validators/incident_validator.dart';
import '../datasources/firebase_incident_data_source.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final FirebaseIncidentDataSource _dataSource;

  IncidentRepositoryImpl({FirebaseIncidentDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseIncidentDataSource();

  @override
  Future<Incident> createIncident(Incident incident) async {
    try {
      final validated = IncidentValidator.validate(incident);
      return await _dataSource.createIncident(validated);
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || incidentId.trim().isEmpty) {
        return null;
      }
      return await _dataSource.getIncident(
        organizationId: organizationId,
        incidentId: incidentId,
      );
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  }) async {
    try {
      if (organizationId.trim().isEmpty) return [];
      return await _dataSource.getIncidentsByOrganization(
        organizationId,
        status: status,
        severity: severity,
        limit: limit,
      );
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) {
    if (organizationId.trim().isEmpty) return Stream.value([]);
    return _dataSource.watchIncidentsByOrganization(
      organizationId,
      status: status,
      severity: severity,
    );
  }

  @override
  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) async {
    try {
      if (organizationId.trim().isEmpty || siteId.trim().isEmpty) return [];
      return await _dataSource.getIncidentsBySite(
        organizationId: organizationId,
        siteId: siteId,
        status: status,
      );
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) {
    if (organizationId.trim().isEmpty || siteId.trim().isEmpty) {
      return Stream.value([]);
    }
    return _dataSource.watchIncidentsBySite(
      organizationId: organizationId,
      siteId: siteId,
      status: status,
    );
  }

  @override
  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) async {
    try {
      if (organizationId.trim().isEmpty || reportedBy.trim().isEmpty) return [];
      return await _dataSource.getIncidentsByReporter(
        organizationId: organizationId,
        reportedBy: reportedBy,
      );
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  Stream<List<Incident>> watchIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) {
    if (organizationId.trim().isEmpty || reportedBy.trim().isEmpty) {
      return Stream.value([]);
    }
    return _dataSource.watchIncidentsByReporter(
      organizationId: organizationId,
      reportedBy: reportedBy,
    );
  }

  @override
  Future<Incident> updateIncident(Incident incident) async {
    try {
      final validated = IncidentValidator.validate(incident);
      return await _dataSource.updateIncident(validated);
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    try {
      if (organizationId.trim().isEmpty) {
        throw const InvalidOrganizationIdFailure(
          'Organization ID cannot be empty.',
        );
      }
      if (incidentId.trim().isEmpty) {
        throw const InvalidIncidentIdFailure(
          'Incident ID cannot be empty.',
        );
      }
      if (status == IncidentStatus.resolved) {
        if (resolvedBy == null || resolvedBy.trim().isEmpty) {
          throw const MissingResolutionMetadataFailure(
            'Resolver ID required.',
          );
        }
      }
      return await _dataSource.updateIncidentStatus(
        organizationId: organizationId,
        incidentId: incidentId,
        status: status,
        resolvedBy: resolvedBy,
        resolvedAt: resolvedAt,
      );
    } on IncidentFailure {
      rethrow;
    } catch (e) {
      throw UnknownIncidentFailure(e.toString());
    }
  }
}
