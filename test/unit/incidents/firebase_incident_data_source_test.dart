import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/incidents/data/datasources/firebase_incident_data_source.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseIncidentDataSource dataSource;

  const orgId = 'org_test_1';
  const reporterId = 'guard_test_1';
  const siteId = 'site_test_1';
  final now = DateTime.utc(2026, 9, 10, 10, 0);

  Incident createSampleIncident({
    String id = 'inc_1',
    String organizationId = orgId,
    String reporter = reporterId,
    String site = siteId,
    IncidentSeverity severity = IncidentSeverity.medium,
    IncidentStatus status = IncidentStatus.open,
    String type = 'Theft',
    String desc = 'Broken padlock on warehouse door.',
    double? lat = 18.5204,
    double? lng = 73.8567,
    DateTime? resolvedAt,
    String? resolvedBy,
  }) {
    return Incident(
      incidentId: id,
      organizationId: organizationId,
      reportedBy: reporter,
      siteId: site,
      type: type,
      severity: severity,
      description: desc,
      latitude: lat,
      longitude: lng,
      status: status,
      createdAt: now,
      updatedAt: now,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
    );
  }

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirebaseIncidentDataSource(firestore: fakeFirestore);
  });

  group('FirebaseIncidentDataSource — Persistence & Retrieval', () {
    test('createIncident persists record and returns created incident',
        () async {
      final sample = createSampleIncident(id: '');
      final created = await dataSource.createIncident(sample);

      expect(created.incidentId, isNotEmpty);
      expect(created.organizationId, equals(orgId));
      expect(created.reportedBy, equals(reporterId));
      expect(created.siteId, equals(siteId));
      expect(created.status, equals(IncidentStatus.open));

      final doc = await fakeFirestore
          .collection('organizations')
          .doc(orgId)
          .collection('incidents')
          .doc(created.incidentId)
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['type'], equals('Theft'));
      expect(doc.data()?['severity'], equals('MEDIUM'));
      expect(doc.data()?['status'], equals('OPEN'));
    });

    test('getIncident retrieves existing incident by ID', () async {
      final sample = createSampleIncident(id: 'inc_101');
      await dataSource.createIncident(sample);

      final fetched = await dataSource.getIncident(
        organizationId: orgId,
        incidentId: 'inc_101',
      );

      expect(fetched, isNotNull);
      expect(fetched!.incidentId, equals('inc_101'));
      expect(fetched.description, equals('Broken padlock on warehouse door.'));
    });

    test('getIncident returns null when document does not exist', () async {
      final fetched = await dataSource.getIncident(
        organizationId: orgId,
        incidentId: 'non_existent',
      );

      expect(fetched, isNull);
    });

    test('getIncidentsByOrganization returns filtered records', () async {
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_1',
        severity: IncidentSeverity.low,
      ));
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_2',
        severity: IncidentSeverity.critical,
      ));

      final all = await dataSource.getIncidentsByOrganization(orgId);
      expect(all.length, equals(2));

      final criticalOnly = await dataSource.getIncidentsByOrganization(
        orgId,
        severity: IncidentSeverity.critical,
      );
      expect(criticalOnly.length, equals(1));
      expect(criticalOnly.first.incidentId, equals('inc_2'));
    });

    test('getIncidentsBySite filters by siteId', () async {
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_site1',
        site: 'site_1',
      ));
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_site2',
        site: 'site_2',
      ));

      final site1List = await dataSource.getIncidentsBySite(
        organizationId: orgId,
        siteId: 'site_1',
      );

      expect(site1List.length, equals(1));
      expect(site1List.first.incidentId, equals('inc_site1'));
    });

    test(
        'getIncidentsByReporter and watchIncidentsByReporter filter by reportedBy',
        () async {
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_g1',
        reporter: 'guard_1',
      ));
      await dataSource.createIncident(createSampleIncident(
        id: 'inc_g2',
        reporter: 'guard_2',
      ));

      final list = await dataSource.getIncidentsByReporter(
        organizationId: orgId,
        reportedBy: 'guard_1',
      );
      expect(list.length, equals(1));
      expect(list.first.incidentId, equals('inc_g1'));

      final streamList = await dataSource
          .watchIncidentsByReporter(
            organizationId: orgId,
            reportedBy: 'guard_1',
          )
          .first;
      expect(streamList.length, equals(1));
    });

    test('updateIncident modifies mutable fields in Firestore', () async {
      await dataSource.createIncident(createSampleIncident(id: 'inc_mod'));

      final updated = createSampleIncident(
        id: 'inc_mod',
        desc: 'Updated description by guard.',
        severity: IncidentSeverity.high,
      );

      final result = await dataSource.updateIncident(updated);
      expect(result.description, equals('Updated description by guard.'));
      expect(result.severity, equals(IncidentSeverity.high));
    });

    test('updateIncidentStatus modifies status and resolution metadata',
        () async {
      await dataSource.createIncident(createSampleIncident(id: 'inc_res'));

      final resTime = DateTime.now().add(const Duration(hours: 1));
      final resolved = await dataSource.updateIncidentStatus(
        organizationId: orgId,
        incidentId: 'inc_res',
        status: IncidentStatus.resolved,
        resolvedBy: 'supervisor_1',
        resolvedAt: resTime,
      );

      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolvedBy, equals('supervisor_1'));
    });
  });
}
