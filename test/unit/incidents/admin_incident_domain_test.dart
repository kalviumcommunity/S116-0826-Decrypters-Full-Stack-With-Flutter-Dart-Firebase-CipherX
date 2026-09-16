import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:cipher_x/features/incidents/domain/validators/incident_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Admin Incident Domain & Lifecycle Tests', () {
    final now = DateTime.now().subtract(const Duration(hours: 2));

    Incident makeIncident({
      String incidentId = 'inc_001',
      String organizationId = 'org_001',
      String reportedBy = 'guard_001',
      String siteId = 'site_001',
      String type = 'Trespassing',
      IncidentSeverity severity = IncidentSeverity.medium,
      String description = 'Unauthorized person at perimeter.',
      IncidentStatus status = IncidentStatus.open,
      DateTime? createdAt,
      DateTime? updatedAt,
      DateTime? resolvedAt,
      String? resolvedBy,
      String? resolution,
    }) {
      return Incident(
        incidentId: incidentId,
        organizationId: organizationId,
        reportedBy: reportedBy,
        siteId: siteId,
        type: type,
        severity: severity,
        description: description,
        status: status,
        createdAt: createdAt ?? now,
        updatedAt: updatedAt ?? now,
        resolvedAt: resolvedAt,
        resolvedBy: resolvedBy,
        resolution: resolution,
      );
    }

    group('Resolution Validation', () {
      test('accepts valid resolution text', () {
        expect(
            IncidentValidator.validateResolution(
                'Perimeter secured and fence repaired.'),
            isNull);
      });

      test('rejects null resolution text', () {
        expect(IncidentValidator.validateResolution(null),
            equals('Resolution text cannot be empty or whitespace-only.'));
      });

      test('rejects empty resolution text', () {
        expect(IncidentValidator.validateResolution(''),
            equals('Resolution text cannot be empty or whitespace-only.'));
      });

      test('rejects whitespace-only resolution text', () {
        expect(IncidentValidator.validateResolution('   \n\t  '),
            equals('Resolution text cannot be empty or whitespace-only.'));
      });
    });

    group('Status Transitions & Invariants', () {
      test('OPEN can transition to INVESTIGATING', () {
        final open = makeIncident(status: IncidentStatus.open);
        final investigating = open.investigate();
        expect(investigating.status, equals(IncidentStatus.investigating));
      });

      test('OPEN can transition to RESOLVED with valid resolution', () {
        final open = makeIncident(status: IncidentStatus.open);
        final resolvedTime = DateTime.utc(2026, 9, 16, 11, 0);
        final resolved = open.resolve(
          resolvedBy: 'admin_1',
          resolution: 'Investigated and false alarm verified.',
          resolvedAt: resolvedTime,
        );
        expect(resolved.status, equals(IncidentStatus.resolved));
        expect(resolved.resolvedBy, equals('admin_1'));
        expect(resolved.resolution,
            equals('Investigated and false alarm verified.'));
        expect(resolved.resolvedAt, equals(resolvedTime));
      });

      test('INVESTIGATING can transition to RESOLVED with valid resolution',
          () {
        final investigating =
            makeIncident(status: IncidentStatus.investigating);
        final resolvedTime = DateTime.utc(2026, 9, 16, 11, 30);
        final resolved = investigating.resolve(
          resolvedBy: 'supervisor_2',
          resolution: 'Intruder escorted off premises.',
          resolvedAt: resolvedTime,
        );
        expect(resolved.status, equals(IncidentStatus.resolved));
        expect(resolved.resolvedBy, equals('supervisor_2'));
        expect(resolved.resolution, equals('Intruder escorted off premises.'));
      });

      test('RESOLVED cannot transition backwards to OPEN', () {
        final resolved = makeIncident(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: 'admin_1',
          resolution: 'Fixed',
        );
        expect(
          () => IncidentValidator.validateStatusTransition(
            from: resolved.status,
            to: IncidentStatus.open,
          ),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
      });

      test('RESOLVED cannot transition backwards to INVESTIGATING', () {
        final resolved = makeIncident(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: 'admin_1',
          resolution: 'Fixed',
        );
        expect(
          () => resolved.investigate(),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
      });

      test('INVESTIGATING cannot transition backwards to OPEN', () {
        final investigating =
            makeIncident(status: IncidentStatus.investigating);
        expect(
          () => IncidentValidator.validateStatusTransition(
            from: investigating.status,
            to: IncidentStatus.open,
          ),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
      });

      test('Cannot resolve an already RESOLVED incident', () {
        final resolved = makeIncident(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: 'admin_1',
          resolution: 'Fixed',
        );
        expect(
          () => resolved.resolve(
            resolvedBy: 'admin_2',
            resolution: 'Second fix',
          ),
          throwsA(isA<IncidentAlreadyResolvedFailure>()),
        );
      });

      test('Unresolved incident cannot have resolution text', () {
        expect(
          () => IncidentValidator.validate(makeIncident(
            status: IncidentStatus.open,
            resolution: 'premature resolution',
          )),
          throwsA(isA<ContradictoryResolutionMetadataFailure>()),
        );
      });

      test(
          'Resolved incident rejects whitespace-only resolution in domain validation',
          () {
        expect(
          () => IncidentValidator.validate(makeIncident(
            status: IncidentStatus.resolved,
            resolvedAt: now,
            resolvedBy: 'admin_1',
            resolution: '    ',
          )),
          throwsA(isA<InvalidResolutionTextFailure>()),
        );
      });
    });

    group('Serialization Round-Trip with Resolution', () {
      test('serializes and deserializes resolution field correctly', () {
        final resolved = makeIncident(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: 'admin_master',
          resolution: 'Gate lock replaced with biometric latch.',
        );

        final map = resolved.toMap();
        expect(map['resolution'],
            equals('Gate lock replaced with biometric latch.'));

        final restored = Incident.fromMap(map);
        expect(restored.resolution,
            equals('Gate lock replaced with biometric latch.'));
        expect(restored, equals(resolved));
      });
    });
  });
}
