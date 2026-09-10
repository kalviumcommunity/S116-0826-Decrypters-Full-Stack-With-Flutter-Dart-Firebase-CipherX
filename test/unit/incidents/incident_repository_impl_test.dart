import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/incidents/data/datasources/firebase_incident_data_source.dart';
import 'package:cipher_x/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseIncidentDataSource dataSource;
  late IncidentRepositoryImpl repository;

  final now = DateTime.utc(2026, 9, 10, 10, 0);

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseIncidentDataSource(firestore: fakeFirestore);
    repository = IncidentRepositoryImpl(dataSource: dataSource);
  });

  group('IncidentRepositoryImpl Tests', () {
    test('createIncident validates incident before persisting', () async {
      final invalid = Incident(
        incidentId: 'inc_1',
        organizationId: '', // Invalid
        reportedBy: 'guard_1',
        siteId: 'site_1',
        type: 'Theft',
        severity: IncidentSeverity.low,
        description: 'Test',
        status: IncidentStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () => repository.createIncident(invalid),
        throwsA(isA<InvalidOrganizationIdFailure>()),
      );
    });

    test('createIncident succeeds with valid incident', () async {
      final valid = Incident(
        incidentId: 'inc_100',
        organizationId: 'org_1',
        reportedBy: 'guard_1',
        siteId: 'site_1',
        type: 'Medical',
        severity: IncidentSeverity.high,
        description: 'Guard reported injury on site.',
        status: IncidentStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      final created = await repository.createIncident(valid);
      expect(created.incidentId, equals('inc_100'));
      expect(created.status, equals(IncidentStatus.open));
    });

    test('getIncident returns null on empty parameters', () async {
      expect(await repository.getIncident(organizationId: '', incidentId: '1'),
          isNull);
      expect(await repository.getIncident(organizationId: '1', incidentId: ''),
          isNull);
    });

    test('getIncidentsByOrganization returns empty list on empty orgId',
        () async {
      final list = await repository.getIncidentsByOrganization('');
      expect(list, isEmpty);
    });

    test('getIncidentsBySite returns empty list on empty parameters', () async {
      expect(
          await repository.getIncidentsBySite(organizationId: '', siteId: 's1'),
          isEmpty);
      expect(
          await repository.getIncidentsBySite(organizationId: 'o1', siteId: ''),
          isEmpty);
    });

    test('getIncidentsByReporter returns empty list on empty parameters',
        () async {
      expect(
          await repository.getIncidentsByReporter(
              organizationId: '', reportedBy: 'g1'),
          isEmpty);
      expect(
          await repository.getIncidentsByReporter(
              organizationId: 'o1', reportedBy: ''),
          isEmpty);
    });

    test(
        'updateIncidentStatus throws when missing required resolver on resolution',
        () async {
      expect(
        () => repository.updateIncidentStatus(
          organizationId: 'o1',
          incidentId: 'i1',
          status: IncidentStatus.resolved,
          resolvedBy: null,
        ),
        throwsA(isA<MissingResolutionMetadataFailure>()),
      );
    });
  });
}
