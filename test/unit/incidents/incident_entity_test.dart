import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Incident Domain Entity Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime.utc(2026, 9, 1, 11, 0);
      final incident = Incident(
        incidentId: 'inc_101',
        organizationId: 'org_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        type: IncidentType.vandalism,
        severity: IncidentSeverity.high,
        description: 'Perimeter fence damaged by vehicle.',
        status: IncidentStatus.open,
        latitude: 18.5204,
        longitude: 73.8567,
        evidenceUrls: const ['http://example.com/photo1.jpg'],
        createdAt: now,
        updatedAt: now,
      );

      final map = incident.toMap();
      expect(map['incidentId'], equals('inc_101'));
      expect(map['type'], equals('vandalism'));
      expect(map['severity'], equals('high'));
      expect(map['status'], equals('open'));

      final restored = Incident.fromMap(map, 'inc_101');
      expect(restored.incidentId, equals('inc_101'));
      expect(restored.type, equals(IncidentType.vandalism));
      expect(restored.severity, equals(IncidentSeverity.high));
      expect(
          restored.description, equals('Perimeter fence damaged by vehicle.'));
      expect(restored.latitude, equals(18.5204));
      expect(restored.longitude, equals(73.8567));
      expect(restored.evidenceUrls, contains('http://example.com/photo1.jpg'));
    });

    test('IncidentType enum converts display names and strings correctly', () {
      expect(IncidentType.theft.displayName, contains('Theft'));
      expect(IncidentType.fromMapString('vandalism'),
          equals(IncidentType.vandalism));
      expect(
          IncidentType.fromMapString('medical'), equals(IncidentType.medical));
      expect(IncidentType.fromMapString('unknown'), equals(IncidentType.other));
    });

    test('IncidentSeverity enum converts strings correctly', () {
      expect(IncidentSeverity.low.displayName, equals('Low'));
      expect(IncidentSeverity.critical.displayName, equals('Critical'));
      expect(IncidentSeverity.fromMapString('high'),
          equals(IncidentSeverity.high));
      expect(IncidentSeverity.fromMapString('invalid'),
          equals(IncidentSeverity.low));
    });

    test('IncidentStatus enum converts strings correctly', () {
      expect(IncidentStatus.open.displayName, equals('Open'));
      expect(IncidentStatus.fromMapString('open'), equals(IncidentStatus.open));
      expect(IncidentStatus.fromMapString('under_review'),
          equals(IncidentStatus.underReview));
      expect(IncidentStatus.fromMapString('resolved'),
          equals(IncidentStatus.resolved));
    });
  });
}
