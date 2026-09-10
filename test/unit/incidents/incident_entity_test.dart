import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident Entity Tests', () {
    final now = DateTime.utc(2026, 9, 10, 10, 0);

    Incident makeIncident({
      String incidentId = 'inc_001',
      String organizationId = 'org_001',
      String reportedBy = 'guard_001',
      String siteId = 'site_001',
      String type = 'Trespassing',
      IncidentSeverity severity = IncidentSeverity.medium,
      String description = 'Person found climbing fence.',
      double? latitude = 18.5204,
      double? longitude = 73.8567,
      IncidentStatus status = IncidentStatus.open,
      DateTime? createdAt,
      DateTime? updatedAt,
      DateTime? resolvedAt,
      String? resolvedBy,
    }) {
      return Incident(
        incidentId: incidentId,
        organizationId: organizationId,
        reportedBy: reportedBy,
        siteId: siteId,
        type: type,
        severity: severity,
        description: description,
        latitude: latitude,
        longitude: longitude,
        status: status,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
        resolvedAt: resolvedAt,
        resolvedBy: resolvedBy,
      );
    }

    test(
        'Incident.create factory initializes valid open incident with validation',
        () {
      final incident = Incident.create(
        incidentId: '  inc_999  ',
        organizationId: '  org_001  ',
        reportedBy: '  guard_42  ',
        siteId: '  site_east  ',
        type: '  Vandalism  ',
        severity: IncidentSeverity.low,
        description: '  Graffiti on west gate  ',
        latitude: 18.5204,
        longitude: 73.8567,
        createdAt: now,
      );

      expect(incident.incidentId, equals('inc_999'));
      expect(incident.organizationId, equals('org_001'));
      expect(incident.reportedBy, equals('guard_42'));
      expect(incident.siteId, equals('site_east'));
      expect(incident.type, equals('Vandalism'));
      expect(incident.severity, equals(IncidentSeverity.low));
      expect(incident.description, equals('Graffiti on west gate'));
      expect(incident.status, equals(IncidentStatus.open));
      expect(incident.hasLocation, isTrue);
      expect(incident.resolvedAt, isNull);
      expect(incident.resolvedBy, isNull);
    });

    test('investigate transitions open incident to investigating', () {
      final incident = makeIncident();
      final updatedTime = DateTime.utc(2026, 9, 10, 10, 15);

      final investigating = incident.investigate(updatedAt: updatedTime);

      expect(investigating.status, equals(IncidentStatus.investigating));
      expect(investigating.updatedAt, equals(updatedTime));
      expect(investigating.incidentId, equals(incident.incidentId));
      expect(investigating.organizationId, equals(incident.organizationId));
    });

    test('resolve transitions open incident to resolved with metadata', () {
      final incident = makeIncident();
      final resolvedTime = DateTime.utc(2026, 9, 10, 11, 0);

      final resolved = incident.resolve(
        resolvedBy: 'supervisor_bob',
        resolvedAt: resolvedTime,
      );

      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolvedBy, equals('supervisor_bob'));
      expect(resolved.resolvedAt, equals(resolvedTime));
      expect(resolved.updatedAt, equals(resolvedTime));
    });

    test('resolve transitions investigating incident to resolved', () {
      final investigating = makeIncident(status: IncidentStatus.investigating);
      final resolvedTime = DateTime.utc(2026, 9, 10, 11, 30);

      final resolved = investigating.resolve(
        resolvedBy: 'lead_investigator',
        resolvedAt: resolvedTime,
      );

      expect(resolved.status, equals(IncidentStatus.resolved));
      expect(resolved.resolvedBy, equals('lead_investigator'));
      expect(resolved.resolvedAt, equals(resolvedTime));
    });

    test('resolve rejects repeated resolution on already resolved incident',
        () {
      final resolved = makeIncident(
        status: IncidentStatus.resolved,
        resolvedAt: now,
        resolvedBy: 'sup_1',
      );

      expect(
        () => resolved.resolve(resolvedBy: 'sup_2'),
        throwsA(isA<IncidentAlreadyResolvedFailure>()),
      );
    });

    test('investigate rejects transition on resolved incident', () {
      final resolved = makeIncident(
        status: IncidentStatus.resolved,
        resolvedAt: now,
        resolvedBy: 'sup_1',
      );

      expect(
        () => resolved.investigate(),
        throwsA(isA<InvalidStatusTransitionFailure>()),
      );
    });

    test(
        'updateDetails safely modifies mutable fields while preserving identity',
        () {
      final incident = makeIncident();
      final updatedTime = DateTime.utc(2026, 9, 10, 10, 45);

      final updated = incident.updateDetails(
        description: 'New detailed description',
        severity: IncidentSeverity.critical,
        latitude: 18.5209,
        longitude: 73.8572,
        updatedAt: updatedTime,
      );

      expect(updated.description, equals('New detailed description'));
      expect(updated.severity, equals(IncidentSeverity.critical));
      expect(updated.latitude, equals(18.5209));
      expect(updated.longitude, equals(73.8572));
      expect(updated.updatedAt, equals(updatedTime));
      // Identity unchanged
      expect(updated.incidentId, equals(incident.incidentId));
      expect(updated.organizationId, equals(incident.organizationId));
      expect(updated.reportedBy, equals(incident.reportedBy));
      expect(updated.createdAt, equals(incident.createdAt));
    });

    group('Value Equality and HashCode', () {
      test('identical fields produce equal incidents with same hashCode', () {
        final a = makeIncident();
        final b = makeIncident();

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('differences in any field produce inequality', () {
        final base = makeIncident();

        expect(base, isNot(equals(makeIncident(incidentId: 'diff_id'))));
        expect(base, isNot(equals(makeIncident(organizationId: 'diff_org'))));
        expect(base, isNot(equals(makeIncident(reportedBy: 'diff_guard'))));
        expect(base, isNot(equals(makeIncident(siteId: 'diff_site'))));
        expect(base, isNot(equals(makeIncident(type: 'Fire Hazard'))));
        expect(base,
            isNot(equals(makeIncident(severity: IncidentSeverity.critical))));
        expect(base,
            isNot(equals(makeIncident(description: 'Different details'))));
        expect(base, isNot(equals(makeIncident(latitude: 19.0000))));
        expect(base, isNot(equals(makeIncident(longitude: 74.0000))));
        expect(base,
            isNot(equals(makeIncident(status: IncidentStatus.investigating))));
        expect(base,
            isNot(equals(makeIncident(createdAt: DateTime.utc(2025, 1, 1)))));
        expect(base,
            isNot(equals(makeIncident(updatedAt: DateTime.utc(2027, 1, 1)))));
      });
    });

    test('toString includes critical domain information', () {
      final inc = makeIncident();
      final str = inc.toString();
      expect(str, contains('inc_001'));
      expect(str, contains('org_001'));
      expect(str, contains('MEDIUM'));
      expect(str, contains('OPEN'));
    });
  });
}
