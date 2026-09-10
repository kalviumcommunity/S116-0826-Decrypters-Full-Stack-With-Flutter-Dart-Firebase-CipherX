import '../../domain/entities/incident.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/repositories/incident_repository.dart';
import '../datasources/firebase_incident_data_source.dart';

class IncidentRepositoryImpl implements IncidentRepository {
  final FirebaseIncidentDataSource? _dataSource;

  IncidentRepositoryImpl({
    FirebaseIncidentDataSource? dataSource,
  }) : _dataSource = dataSource;

  FirebaseIncidentDataSource get dataSource =>
      _dataSource ?? FirebaseIncidentDataSource();

  @override
  Future<Incident> createIncident(Incident incident) async {
    try {
      if (incident.organizationId.trim().isEmpty) {
        throw const InvalidIncidentDataFailure(
            'Organization ID cannot be empty.');
      }
      if (incident.description.trim().isEmpty) {
        throw const InvalidIncidentDataFailure(
          'Please provide a description of the incident.',
        );
      }
      return await dataSource.createIncident(incident);
    } catch (e) {
      if (e is IncidentFailure) rethrow;
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Future<List<Incident>> getIncidentsByGuard({
    required String organizationId,
    required String guardId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
        return [];
      }
      return await dataSource.getIncidentsByGuard(
        organizationId: organizationId,
        guardId: guardId,
      );
    } catch (e) {
      if (e is IncidentFailure) rethrow;
      throw UnknownIncidentFailure(e.toString());
    }
  }

  @override
  Stream<List<Incident>> watchIncidentsByGuard({
    required String organizationId,
    required String guardId,
  }) {
    if (organizationId.trim().isEmpty || guardId.trim().isEmpty) {
      return Stream.value([]);
    }
    return dataSource.watchIncidentsByGuard(
      organizationId: organizationId,
      guardId: guardId,
    );
  }

  @override
  Future<Incident?> getIncidentById({
    required String organizationId,
    required String incidentId,
  }) async {
    try {
      if (organizationId.trim().isEmpty || incidentId.trim().isEmpty) {
        return null;
      }
      return await dataSource.getIncidentById(
        organizationId: organizationId,
        incidentId: incidentId,
      );
    } catch (e) {
      if (e is IncidentFailure) rethrow;
      throw UnknownIncidentFailure(e.toString());
    }
  }
}
