import '../entities/incident.dart';

abstract class IncidentRepository {
  Future<Incident> createIncident(Incident incident);

  Future<List<Incident>> getIncidentsByGuard({
    required String organizationId,
    required String guardId,
  });

  Stream<List<Incident>> watchIncidentsByGuard({
    required String organizationId,
    required String guardId,
  });

  Future<Incident?> getIncidentById({
    required String organizationId,
    required String incidentId,
  });
}
