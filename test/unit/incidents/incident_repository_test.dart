import 'package:cipher_x/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentRepositoryImpl Unit Tests', () {
    test(
        'createIncident throws InvalidIncidentDataFailure when organizationId is empty',
        () async {
      final repository = IncidentRepositoryImpl();
      const incident = Incident(
        incidentId: 'inc_1',
        organizationId: '',
        siteId: 'site_1',
        guardId: 'guard_1',
        type: IncidentType.theft,
        severity: IncidentSeverity.medium,
        description: 'Test description',
      );

      expect(
        () => repository.createIncident(incident),
        throwsA(isA<InvalidIncidentDataFailure>()),
      );
    });

    test(
        'createIncident throws InvalidIncidentDataFailure when description is empty',
        () async {
      final repository = IncidentRepositoryImpl();
      const incident = Incident(
        incidentId: 'inc_1',
        organizationId: 'org_1',
        siteId: 'site_1',
        guardId: 'guard_1',
        type: IncidentType.theft,
        severity: IncidentSeverity.medium,
        description: '   ',
      );

      expect(
        () => repository.createIncident(incident),
        throwsA(isA<InvalidIncidentDataFailure>()),
      );
    });

    test('getIncidentsByGuard returns empty list when parameters are empty',
        () async {
      final repository = IncidentRepositoryImpl();
      final result = await repository.getIncidentsByGuard(
        organizationId: '',
        guardId: 'guard_1',
      );

      expect(result, isEmpty);
    });

    test(
        'watchIncidentsByGuard returns empty list stream when parameters are empty',
        () async {
      final repository = IncidentRepositoryImpl();
      final stream = repository.watchIncidentsByGuard(
        organizationId: '',
        guardId: '',
      );

      expect(await stream.first, isEmpty);
    });
  });
}
