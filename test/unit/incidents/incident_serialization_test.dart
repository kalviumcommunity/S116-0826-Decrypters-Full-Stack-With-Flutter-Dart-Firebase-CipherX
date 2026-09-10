import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident Serialization Tests', () {
    final now = DateTime.utc(2026, 9, 10, 10, 0);

    test(
        'valid incident with location round-trips cleanly through toMap and fromMap',
        () {
      final incident = Incident(
        incidentId: 'inc_101',
        organizationId: 'org_acme',
        reportedBy: 'user_bob',
        siteId: 'site_warehouse',
        type: 'Equipment Damage',
        severity: IncidentSeverity.critical,
        description: 'Forklift collided with emergency exit door.',
        latitude: 18.5204,
        longitude: 73.8567,
        status: IncidentStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      final map = incident.toMap();
      final restored = Incident.fromMap(map);

      expect(restored, equals(incident));
      expect(restored.incidentId, equals('inc_101'));
      expect(restored.organizationId, equals('org_acme'));
      expect(restored.reportedBy, equals('user_bob'));
      expect(restored.siteId, equals('site_warehouse'));
      expect(restored.type, equals('Equipment Damage'));
      expect(restored.severity, equals(IncidentSeverity.critical));
      expect(restored.description,
          equals('Forklift collided with emergency exit door.'));
      expect(restored.latitude, equals(18.5204));
      expect(restored.longitude, equals(73.8567));
      expect(restored.status, equals(IncidentStatus.open));
      expect(restored.createdAt, equals(now));
      expect(restored.updatedAt, equals(now));
      expect(restored.resolvedAt, isNull);
      expect(restored.resolvedBy, isNull);
    });

    test('valid incident without location round-trips cleanly', () {
      final incident = Incident(
        incidentId: 'inc_102',
        organizationId: 'org_acme',
        reportedBy: 'user_alice',
        siteId: 'site_hq',
        type: 'Suspicious Behavior',
        severity: IncidentSeverity.low,
        description: 'Unidentified vehicle parked in visitor slot after hours.',
        latitude: null,
        longitude: null,
        status: IncidentStatus.open,
        createdAt: now,
        updatedAt: now,
      );

      final map = incident.toMap();
      final restored = Incident.fromMap(map);

      expect(restored, equals(incident));
      expect(restored.latitude, isNull);
      expect(restored.longitude, isNull);
      expect(restored.hasLocation, isFalse);
    });

    test('resolved incident with full resolution metadata round-trips cleanly',
        () {
      final resolvedAt = DateTime.utc(2026, 9, 10, 11, 30);
      final incident = Incident(
        incidentId: 'inc_103',
        organizationId: 'org_acme',
        reportedBy: 'user_alice',
        siteId: 'site_hq',
        type: 'Power Outage',
        severity: IncidentSeverity.high,
        description: 'Generator failure in sector B.',
        latitude: 18.5204,
        longitude: 73.8567,
        status: IncidentStatus.resolved,
        createdAt: now,
        updatedAt: resolvedAt,
        resolvedAt: resolvedAt,
        resolvedBy: 'lead_technician',
      );

      final map = incident.toMap();
      final restored = Incident.fromMap(map);

      expect(restored, equals(incident));
      expect(restored.status, equals(IncidentStatus.resolved));
      expect(restored.resolvedBy, equals('lead_technician'));
      expect(restored.resolvedAt, equals(resolvedAt));
    });

    test('fromMap uses fallbackId if incidentId is missing from map', () {
      final map = {
        'organizationId': 'org_1',
        'reportedBy': 'guard_1',
        'siteId': 'site_1',
        'type': 'Theft',
        'severity': 'MEDIUM',
        'description': 'Stolen keys',
        'status': 'OPEN',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final restored = Incident.fromMap(map, 'fallback_id_42');
      expect(restored.incidentId, equals('fallback_id_42'));
    });

    group('Defensive Parsing & Malformed Data Rejection', () {
      Map<String, dynamic> validMap() {
        return {
          'incidentId': 'inc_001',
          'organizationId': 'org_001',
          'reportedBy': 'guard_001',
          'siteId': 'site_001',
          'type': 'Intrusion',
          'severity': 'HIGH',
          'description': 'Fence breached',
          'latitude': 18.5204,
          'longitude': 73.8567,
          'status': 'OPEN',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        };
      }

      test('rejects missing incidentId when no fallbackId provided', () {
        final map = validMap()..remove('incidentId');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentIdFailure>()));
      });

      test('rejects missing organizationId', () {
        final map = validMap()..remove('organizationId');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidOrganizationIdFailure>()));
      });

      test('rejects missing reportedBy', () {
        final map = validMap()..remove('reportedBy');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidReporterIdFailure>()));
      });

      test('rejects missing siteId', () {
        final map = validMap()..remove('siteId');
        expect(
            () => Incident.fromMap(map), throwsA(isA<InvalidSiteIdFailure>()));
      });

      test('rejects missing type', () {
        final map = validMap()..remove('type');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentTypeFailure>()));
      });

      test('rejects missing description', () {
        final map = validMap()..remove('description');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentDescriptionFailure>()));
      });

      test('rejects missing severity', () {
        final map = validMap()..remove('severity');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentSeverityFailure>()));
      });

      test('rejects malformed severity value', () {
        final map = validMap()..['severity'] = 'SUPER_CRITICAL';
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentSeverityFailure>()));
      });

      test('rejects missing status', () {
        final map = validMap()..remove('status');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentStatusFailure>()));
      });

      test('rejects malformed status value', () {
        final map = validMap()..['status'] = 'CLOSED';
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentStatusFailure>()));
      });

      test('rejects partial coordinates (latitude without longitude)', () {
        final map = validMap()..remove('longitude');
        expect(() => Incident.fromMap(map),
            throwsA(isA<PartialCoordinatesFailure>()));
      });

      test('rejects non-numeric coordinate string', () {
        final map = validMap()..['latitude'] = 'not_a_number';
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidCoordinatesFailure>()));
      });

      test('rejects out of bounds coordinates', () {
        final map = validMap()..['latitude'] = 99.9;
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidCoordinatesFailure>()));
      });

      test('rejects missing createdAt timestamp', () {
        final map = validMap()..remove('createdAt');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentTimestampFailure>()));
      });

      test('rejects missing updatedAt timestamp', () {
        final map = validMap()..remove('updatedAt');
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentTimestampFailure>()));
      });

      test('rejects unparseable timestamp string', () {
        final map = validMap()..['createdAt'] = 'not-a-timestamp';
        expect(() => Incident.fromMap(map),
            throwsA(isA<InvalidIncidentTimestampFailure>()));
      });

      test('rejects resolved status when resolution metadata is missing in map',
          () {
        final map = validMap()
          ..['status'] = 'RESOLVED'
          ..remove('resolvedAt')
          ..remove('resolvedBy');

        expect(() => Incident.fromMap(map),
            throwsA(isA<MissingResolutionMetadataFailure>()));
      });

      test('rejects open status when resolution metadata is present in map',
          () {
        final map = validMap()
          ..['status'] = 'OPEN'
          ..['resolvedAt'] = now.toIso8601String()
          ..['resolvedBy'] = 'someone';

        expect(() => Incident.fromMap(map),
            throwsA(isA<ContradictoryResolutionMetadataFailure>()));
      });
    });
  });
}
