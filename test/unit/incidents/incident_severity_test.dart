import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/failures/incident_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncidentSeverity Enum Tests', () {
    test('contains all 4 required product severity values', () {
      expect(IncidentSeverity.values, hasLength(4));
      expect(IncidentSeverity.values, contains(IncidentSeverity.low));
      expect(IncidentSeverity.values, contains(IncidentSeverity.medium));
      expect(IncidentSeverity.values, contains(IncidentSeverity.high));
      expect(IncidentSeverity.values, contains(IncidentSeverity.critical));
    });

    test('toMapString returns exact uppercase string representations', () {
      expect(IncidentSeverity.low.toMapString(), equals('LOW'));
      expect(IncidentSeverity.medium.toMapString(), equals('MEDIUM'));
      expect(IncidentSeverity.high.toMapString(), equals('HIGH'));
      expect(IncidentSeverity.critical.toMapString(), equals('CRITICAL'));
    });

    test(
        'fromMapString parses valid strings case-insensitively and with whitespace',
        () {
      expect(
          IncidentSeverity.fromMapString('LOW'), equals(IncidentSeverity.low));
      expect(
          IncidentSeverity.fromMapString('low'), equals(IncidentSeverity.low));
      expect(IncidentSeverity.fromMapString('  Low  '),
          equals(IncidentSeverity.low));

      expect(IncidentSeverity.fromMapString('MEDIUM'),
          equals(IncidentSeverity.medium));
      expect(IncidentSeverity.fromMapString('medium'),
          equals(IncidentSeverity.medium));

      expect(IncidentSeverity.fromMapString('HIGH'),
          equals(IncidentSeverity.high));
      expect(IncidentSeverity.fromMapString('high'),
          equals(IncidentSeverity.high));

      expect(IncidentSeverity.fromMapString('CRITICAL'),
          equals(IncidentSeverity.critical));
      expect(IncidentSeverity.fromMapString('critical'),
          equals(IncidentSeverity.critical));
    });

    test(
        'fromMapString rejects unknown or invalid severity values with typed failure',
        () {
      expect(
        () => IncidentSeverity.fromMapString('URGENT'),
        throwsA(isA<InvalidIncidentSeverityFailure>().having(
          (f) => f.message,
          'message',
          contains('Invalid incident severity: "URGENT"'),
        )),
      );

      expect(
        () => IncidentSeverity.fromMapString(''),
        throwsA(isA<InvalidIncidentSeverityFailure>()),
      );

      expect(
        () => IncidentSeverity.fromMapString('   '),
        throwsA(isA<InvalidIncidentSeverityFailure>()),
      );
    });

    test(
        'tryFromMapString returns null for invalid or empty inputs without throwing',
        () {
      expect(IncidentSeverity.tryFromMapString(null), isNull);
      expect(IncidentSeverity.tryFromMapString(''), isNull);
      expect(IncidentSeverity.tryFromMapString('   '), isNull);
      expect(IncidentSeverity.tryFromMapString('INVALID'), isNull);
      expect(IncidentSeverity.tryFromMapString('CRITICAL'),
          equals(IncidentSeverity.critical));
    });

    test('priority predicates evaluate accurately', () {
      expect(IncidentSeverity.low.isHighPriority, isFalse);
      expect(IncidentSeverity.medium.isHighPriority, isFalse);
      expect(IncidentSeverity.high.isHighPriority, isTrue);
      expect(IncidentSeverity.critical.isHighPriority, isTrue);

      expect(IncidentSeverity.critical.isCritical, isTrue);
      expect(IncidentSeverity.high.isCritical, isFalse);
    });
  });
}
