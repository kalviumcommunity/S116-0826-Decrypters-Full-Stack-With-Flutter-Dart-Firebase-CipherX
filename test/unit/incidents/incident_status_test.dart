import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentStatus Enum & Lifecycle Tests', () {
    test('contains all 3 required product lifecycle status values', () {
      expect(IncidentStatus.values, hasLength(3));
      expect(IncidentStatus.values, contains(IncidentStatus.open));
      expect(IncidentStatus.values, contains(IncidentStatus.investigating));
      expect(IncidentStatus.values, contains(IncidentStatus.resolved));
    });

    test('toMapString returns exact uppercase string representations', () {
      expect(IncidentStatus.open.toMapString(), equals('OPEN'));
      expect(
          IncidentStatus.investigating.toMapString(), equals('INVESTIGATING'));
      expect(IncidentStatus.resolved.toMapString(), equals('RESOLVED'));
    });

    test(
        'fromMapString parses valid strings case-insensitively and with whitespace',
        () {
      expect(IncidentStatus.fromMapString('OPEN'), equals(IncidentStatus.open));
      expect(IncidentStatus.fromMapString('open'), equals(IncidentStatus.open));
      expect(IncidentStatus.fromMapString('  Open  '),
          equals(IncidentStatus.open));

      expect(IncidentStatus.fromMapString('INVESTIGATING'),
          equals(IncidentStatus.investigating));
      expect(IncidentStatus.fromMapString('investigating'),
          equals(IncidentStatus.investigating));

      expect(IncidentStatus.fromMapString('RESOLVED'),
          equals(IncidentStatus.resolved));
      expect(IncidentStatus.fromMapString('resolved'),
          equals(IncidentStatus.resolved));
    });

    test(
        'fromMapString rejects unknown or invalid status values with typed failure',
        () {
      expect(
        () => IncidentStatus.fromMapString('CLOSED'),
        throwsA(isA<InvalidIncidentStatusFailure>().having(
          (f) => f.message,
          'message',
          contains('Invalid incident status: "CLOSED"'),
        )),
      );

      expect(
        () => IncidentStatus.fromMapString('PENDING'),
        throwsA(isA<InvalidIncidentStatusFailure>()),
      );

      expect(
        () => IncidentStatus.fromMapString(''),
        throwsA(isA<InvalidIncidentStatusFailure>()),
      );
    });

    test('tryFromMapString handles null and invalid values safely', () {
      expect(IncidentStatus.tryFromMapString(null), isNull);
      expect(IncidentStatus.tryFromMapString(''), isNull);
      expect(IncidentStatus.tryFromMapString('UNKNOWN'), isNull);
      expect(
          IncidentStatus.tryFromMapString('OPEN'), equals(IncidentStatus.open));
    });

    group('Status Lifecycle Transition Matrix', () {
      test('OPEN allows transitions to OPEN, INVESTIGATING, and RESOLVED', () {
        expect(
            IncidentStatus.open.canTransitionTo(IncidentStatus.open), isTrue);
        expect(
            IncidentStatus.open.canTransitionTo(IncidentStatus.investigating),
            isTrue);
        expect(IncidentStatus.open.canTransitionTo(IncidentStatus.resolved),
            isTrue);
      });

      test('INVESTIGATING allows transitions to INVESTIGATING and RESOLVED',
          () {
        expect(
            IncidentStatus.investigating
                .canTransitionTo(IncidentStatus.investigating),
            isTrue);
        expect(
            IncidentStatus.investigating
                .canTransitionTo(IncidentStatus.resolved),
            isTrue);
      });

      test('INVESTIGATING rejects backwards transition to OPEN', () {
        expect(
            IncidentStatus.investigating.canTransitionTo(IncidentStatus.open),
            isFalse);
      });

      test(
          'RESOLVED is terminal: rejects backwards transitions to OPEN and INVESTIGATING',
          () {
        expect(IncidentStatus.resolved.canTransitionTo(IncidentStatus.resolved),
            isTrue);
        expect(IncidentStatus.resolved.canTransitionTo(IncidentStatus.open),
            isFalse);
        expect(
            IncidentStatus.resolved
                .canTransitionTo(IncidentStatus.investigating),
            isFalse);
      });
    });

    test('boolean queries evaluate correctly', () {
      expect(IncidentStatus.open.isOpen, isTrue);
      expect(IncidentStatus.open.isInvestigating, isFalse);
      expect(IncidentStatus.open.isResolved, isFalse);

      expect(IncidentStatus.investigating.isInvestigating, isTrue);
      expect(IncidentStatus.resolved.isResolved, isTrue);
    });
  });
}
