import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:cipher_x/features/incidents/domain/validators/incident_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentValidator Tests', () {
    final now = DateTime.utc(2026, 9, 10, 10, 0);

    Incident createSample({
      String incidentId = 'inc_001',
      String organizationId = 'org_001',
      String reportedBy = 'user_guard_1',
      String siteId = 'site_001',
      String type = 'Security Breach',
      IncidentSeverity severity = IncidentSeverity.high,
      String description = 'Unauthorized access detected at perimeter gate 3.',
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

    test('valid incident passes validation cleanly and trims string fields',
        () {
      final sample = createSample(
        incidentId: '  inc_001  ',
        organizationId: '  org_001  ',
        reportedBy: '  user_001  ',
        siteId: '  site_001  ',
        type: '  Intrusion  ',
        description: '  Suspect spotted  ',
      );

      final validated = IncidentValidator.validate(sample);

      expect(validated.incidentId, equals('inc_001'));
      expect(validated.organizationId, equals('org_001'));
      expect(validated.reportedBy, equals('user_001'));
      expect(validated.siteId, equals('site_001'));
      expect(validated.type, equals('Intrusion'));
      expect(validated.description, equals('Suspect spotted'));
    });

    group('Identity & Field String Validations', () {
      test('rejects empty incidentId', () {
        final inc = createSample(incidentId: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentIdFailure>()));
      });

      test('rejects whitespace incidentId', () {
        final inc = createSample(incidentId: '   \t\n  ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentIdFailure>()));
      });

      test('rejects empty organizationId', () {
        final inc = createSample(organizationId: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidOrganizationIdFailure>()));
      });

      test('rejects whitespace organizationId', () {
        final inc = createSample(organizationId: '   ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidOrganizationIdFailure>()));
      });

      test('rejects empty reportedBy', () {
        final inc = createSample(reportedBy: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidReporterIdFailure>()));
      });

      test('rejects whitespace reportedBy', () {
        final inc = createSample(reportedBy: '   ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidReporterIdFailure>()));
      });

      test('rejects empty siteId', () {
        final inc = createSample(siteId: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidSiteIdFailure>()));
      });

      test('rejects whitespace siteId', () {
        final inc = createSample(siteId: '   ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidSiteIdFailure>()));
      });

      test('rejects empty type', () {
        final inc = createSample(type: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentTypeFailure>()));
      });

      test('rejects whitespace type', () {
        final inc = createSample(type: '   ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentTypeFailure>()));
      });

      test('rejects empty description', () {
        final inc = createSample(description: '');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentDescriptionFailure>()));
      });

      test('rejects whitespace description', () {
        final inc = createSample(description: '   \n  ');
        expect(() => IncidentValidator.validate(inc),
            throwsA(isA<InvalidIncidentDescriptionFailure>()));
      });

      test('accepts multiline, unicode, and large valid descriptions', () {
        const multiline = 'First line\nSecond line\nThird line';
        expect(
            IncidentValidator.validate(sampleWithDesc(multiline)).description,
            equals(multiline));

        const unicode = '🚨 Warning: Security alert at ゲート 3! Café area clean.';
        expect(IncidentValidator.validate(sampleWithDesc(unicode)).description,
            equals(unicode));

        final large = 'A' * 4000;
        expect(IncidentValidator.validate(sampleWithDesc(large)).description,
            equals(large));
      });
    });

    group('Coordinate Boundaries & Consistency Validations', () {
      test('accepts null coordinates (both absent)', () {
        final inc = createSample(latitude: null, longitude: null);
        final validated = IncidentValidator.validate(inc);
        expect(validated.latitude, isNull);
        expect(validated.longitude, isNull);
        expect(validated.hasLocation, isFalse);
      });

      test('rejects partial coordinates (latitude present, longitude null)',
          () {
        final inc = createSample(latitude: 18.5204, longitude: null);
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<PartialCoordinatesFailure>()),
        );
      });

      test('rejects partial coordinates (latitude null, longitude present)',
          () {
        final inc = createSample(latitude: null, longitude: 73.8567);
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<PartialCoordinatesFailure>()),
        );
      });

      test('accepts exact boundary latitude: -90.0 and 90.0', () {
        expect(
            () => IncidentValidator.validate(
                createSample(latitude: -90.0, longitude: 0.0)),
            returnsNormally);
        expect(
            () => IncidentValidator.validate(
                createSample(latitude: 90.0, longitude: 0.0)),
            returnsNormally);
      });

      test('rejects latitude beyond boundary: -90.000001 and 90.000001', () {
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: -90.000001, longitude: 0.0)),
          throwsA(isA<InvalidCoordinatesFailure>().having(
              (f) => f.message, 'message', contains('between -90 and 90'))),
        );
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: 90.000001, longitude: 0.0)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
      });

      test('accepts exact boundary longitude: -180.0 and 180.0', () {
        expect(
            () => IncidentValidator.validate(
                createSample(latitude: 0.0, longitude: -180.0)),
            returnsNormally);
        expect(
            () => IncidentValidator.validate(
                createSample(latitude: 0.0, longitude: 180.0)),
            returnsNormally);
      });

      test('rejects longitude beyond boundary: -180.000001 and 180.000001', () {
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: 0.0, longitude: -180.000001)),
          throwsA(isA<InvalidCoordinatesFailure>().having(
              (f) => f.message, 'message', contains('between -180 and 180'))),
        );
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: 0.0, longitude: 180.000001)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
      });

      test('rejects NaN and infinite coordinates', () {
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: double.nan, longitude: 0.0)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: 0.0, longitude: double.nan)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: double.infinity, longitude: 0.0)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
        expect(
          () => IncidentValidator.validate(
              createSample(latitude: 0.0, longitude: double.negativeInfinity)),
          throwsA(isA<InvalidCoordinatesFailure>()),
        );
      });
    });

    group('Timestamp Consistency Validations', () {
      test('rejects updatedAt earlier than createdAt', () {
        final created = DateTime.utc(2026, 9, 10, 10, 0);
        final earlierUpdated = DateTime.utc(2026, 9, 10, 9, 59);

        final inc = createSample(createdAt: created, updatedAt: earlierUpdated);
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<InvalidIncidentTimestampFailure>().having(
            (f) => f.message,
            'message',
            contains('cannot be earlier than createdAt'),
          )),
        );
      });

      test('rejects resolvedAt earlier than createdAt', () {
        final created = DateTime.utc(2026, 9, 10, 10, 0);
        final earlierResolved = DateTime.utc(2026, 9, 10, 9, 30);

        final inc = createSample(
          status: IncidentStatus.resolved,
          createdAt: created,
          updatedAt: created,
          resolvedAt: earlierResolved,
          resolvedBy: 'supervisor_1',
        );

        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<InvalidIncidentTimestampFailure>()),
        );
      });
    });

    group('Resolution Invariants Validations', () {
      test('rejects unresolved incident with resolvedAt', () {
        final inc = createSample(
          status: IncidentStatus.open,
          resolvedAt: now,
        );
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<ContradictoryResolutionMetadataFailure>()),
        );
      });

      test('rejects unresolved incident with resolvedBy', () {
        final inc = createSample(
          status: IncidentStatus.investigating,
          resolvedBy: 'user_sup_1',
        );
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<ContradictoryResolutionMetadataFailure>()),
        );
      });

      test('rejects resolved incident without resolvedAt', () {
        final inc = createSample(
          status: IncidentStatus.resolved,
          resolvedAt: null,
          resolvedBy: 'user_sup_1',
        );
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<MissingResolutionMetadataFailure>().having(
            (f) => f.message,
            'message',
            contains('resolvedAt timestamp'),
          )),
        );
      });

      test('rejects resolved incident without resolvedBy', () {
        final inc = createSample(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: null,
        );
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<MissingResolutionMetadataFailure>().having(
            (f) => f.message,
            'message',
            contains('resolvedBy'),
          )),
        );
      });

      test('rejects resolved incident with whitespace resolvedBy', () {
        final inc = createSample(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: '   ',
        );
        expect(
          () => IncidentValidator.validate(inc),
          throwsA(isA<MissingResolutionMetadataFailure>()),
        );
      });

      test('accepts valid resolved incident with resolvedAt and resolvedBy',
          () {
        final inc = createSample(
          status: IncidentStatus.resolved,
          resolvedAt: now,
          resolvedBy: 'supervisor_007',
        );
        final validated = IncidentValidator.validate(inc);
        expect(validated.status, equals(IncidentStatus.resolved));
        expect(validated.resolvedBy, equals('supervisor_007'));
        expect(validated.resolvedAt, equals(now));
      });
    });

    group('Status Transition Validations', () {
      test('allows valid lifecycle transitions', () {
        expect(
            () => IncidentValidator.validateStatusTransition(
                from: IncidentStatus.open, to: IncidentStatus.investigating),
            returnsNormally);
        expect(
            () => IncidentValidator.validateStatusTransition(
                from: IncidentStatus.open, to: IncidentStatus.resolved),
            returnsNormally);
        expect(
            () => IncidentValidator.validateStatusTransition(
                from: IncidentStatus.investigating,
                to: IncidentStatus.resolved),
            returnsNormally);
        expect(
            () => IncidentValidator.validateStatusTransition(
                from: IncidentStatus.open, to: IncidentStatus.open),
            returnsNormally);
      });

      test('rejects invalid transitions with typed failure', () {
        expect(
          () => IncidentValidator.validateStatusTransition(
              from: IncidentStatus.investigating, to: IncidentStatus.open),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
        expect(
          () => IncidentValidator.validateStatusTransition(
              from: IncidentStatus.resolved, to: IncidentStatus.open),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
        expect(
          () => IncidentValidator.validateStatusTransition(
              from: IncidentStatus.resolved, to: IncidentStatus.investigating),
          throwsA(isA<InvalidStatusTransitionFailure>()),
        );
      });
    });
  });
}

Incident sampleWithDesc(String desc) {
  final now = DateTime.utc(2026, 9, 10, 10, 0);
  return Incident(
    incidentId: 'inc_test',
    organizationId: 'org_test',
    reportedBy: 'user_test',
    siteId: 'site_test',
    type: 'Theft',
    severity: IncidentSeverity.medium,
    description: desc,
    status: IncidentStatus.open,
    createdAt: now,
    updatedAt: now,
  );
}
