import 'package:cipher_x/features/incidents/data/repositories/incident_repository_impl.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/incidents/data/datasources/firebase_incident_data_source.dart';

void main() {
  group('Admin Incident Repository & Concurrency Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirebaseIncidentDataSource dataSource;
    late IncidentRepositoryImpl repository;

    const orgId = 'org_test_cipherx';
    final now = DateTime.utc(2026, 9, 16, 10, 0);

    Incident makeSampleIncident({
      String id = 'inc_concurrency_01',
      IncidentStatus status = IncidentStatus.open,
      String? resolvedBy,
      DateTime? resolvedAt,
      String? resolution,
    }) {
      return Incident(
        incidentId: id,
        organizationId: orgId,
        reportedBy: 'guard_alpha',
        siteId: 'site_north',
        type: 'Fire Hazard',
        severity: IncidentSeverity.high,
        description: 'Exposed electrical wiring sparking.',
        status: status,
        createdAt: now,
        updatedAt: now,
        resolvedAt: resolvedAt,
        resolvedBy: resolvedBy,
        resolution: resolution,
      );
    }

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      dataSource = FirebaseIncidentDataSource(firestore: fakeFirestore);
      repository = IncidentRepositoryImpl(dataSource: dataSource);
    });

    test('updateIncidentStatus advances status from OPEN to INVESTIGATING',
        () async {
      await repository.createIncident(makeSampleIncident());

      final updated = await repository.updateIncidentStatus(
        organizationId: orgId,
        incidentId: 'inc_concurrency_01',
        status: IncidentStatus.investigating,
      );

      expect(updated.status, equals(IncidentStatus.investigating));
      expect(updated.resolvedBy, isNull);
      expect(updated.resolution, isNull);
    });

    test(
        'updateIncidentStatus resolves incident with resolution notes and resolver audit',
        () async {
      await repository.createIncident(makeSampleIncident());

      final resTime = DateTime.now().add(const Duration(hours: 1));
      final resolved = await repository.updateIncidentStatus(
        organizationId: orgId,
        incidentId: 'inc_concurrency_01',
        status: IncidentStatus.resolved,
        resolvedBy: 'admin_super',
        resolvedAt: resTime,
        resolution: 'Electrician called and wires isolated.',
      );

      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolvedBy, equals('admin_super'));
      expect(resolved.resolution,
          equals('Electrician called and wires isolated.'));
      expect(resolved.resolvedAt, equals(resTime));
    });

    test('updateIncidentStatus rejects resolution when resolver ID is missing',
        () async {
      await repository.createIncident(makeSampleIncident());

      expect(
        () => repository.updateIncidentStatus(
          organizationId: orgId,
          incidentId: 'inc_concurrency_01',
          status: IncidentStatus.resolved,
          resolvedBy: null,
          resolution: 'Some notes',
        ),
        throwsA(isA<MissingResolutionMetadataFailure>()),
      );
    });

    test(
        'updateIncidentStatus rejects resolution when resolution text is whitespace only',
        () async {
      await repository.createIncident(makeSampleIncident());

      expect(
        () => repository.updateIncidentStatus(
          organizationId: orgId,
          incidentId: 'inc_concurrency_01',
          status: IncidentStatus.resolved,
          resolvedBy: 'admin_1',
          resolution: '   \t\n  ',
        ),
        throwsA(isA<InvalidResolutionTextFailure>()),
      );
    });

    test(
        'updateIncidentStatus prevents concurrent overwrite on already resolved incident',
        () async {
      await repository.createIncident(makeSampleIncident());

      // Admin A resolves incident
      await repository.updateIncidentStatus(
        organizationId: orgId,
        incidentId: 'inc_concurrency_01',
        status: IncidentStatus.resolved,
        resolvedBy: 'admin_A',
        resolution: 'Issue resolved by Admin A',
      );

      // Admin B attempts to set status back to INVESTIGATING
      expect(
        () => repository.updateIncidentStatus(
          organizationId: orgId,
          incidentId: 'inc_concurrency_01',
          status: IncidentStatus.investigating,
        ),
        throwsA(isA<IncidentAlreadyResolvedFailure>()),
      );
    });

    test(
        'updateIncidentStatus throws IncidentNotFoundFailure if document does not exist',
        () async {
      expect(
        () => repository.updateIncidentStatus(
          organizationId: orgId,
          incidentId: 'non_existent_inc',
          status: IncidentStatus.investigating,
        ),
        throwsA(isA<IncidentNotFoundFailure>()),
      );
    });

    test(
        'updateIncidentStatus throws InvalidOrganizationIdFailure if org ID is empty',
        () async {
      expect(
        () => repository.updateIncidentStatus(
          organizationId: '',
          incidentId: 'inc_1',
          status: IncidentStatus.investigating,
        ),
        throwsA(isA<InvalidOrganizationIdFailure>()),
      );
    });

    test(
        'updateIncidentStatus throws InvalidIncidentIdFailure if incident ID is empty',
        () async {
      expect(
        () => repository.updateIncidentStatus(
          organizationId: orgId,
          incidentId: '   ',
          status: IncidentStatus.investigating,
        ),
        throwsA(isA<InvalidIncidentIdFailure>()),
      );
    });
  });
}
