import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/alerts/domain/failures/alert_failure.dart';
import 'package:cipher_x/features/alerts/domain/services/alert_id_generator.dart';

void main() {
  group('AlertType enum', () {
    test('serializes to canonical uppercase strings', () {
      expect(AlertType.missedShift.toMapString(), 'MISSED_SHIFT');
      expect(AlertType.lateCheckIn.toMapString(), 'LATE_CHECK_IN');
      expect(AlertType.understaffedSite.toMapString(), 'UNDERSTAFFED_SITE');
      expect(AlertType.criticalIncident.toMapString(), 'CRITICAL_INCIDENT');
    });

    test('deserializes from valid uppercase and lowercase strings', () {
      expect(AlertType.fromMapString('MISSED_SHIFT'), AlertType.missedShift);
      expect(AlertType.fromMapString('late_check_in'), AlertType.lateCheckIn);
      expect(AlertType.fromMapString('UNDERSTAFFED_SITE'),
          AlertType.understaffedSite);
      expect(AlertType.fromMapString('CRITICAL_INCIDENT'),
          AlertType.criticalIncident);
    });

    test('throws ArgumentError on invalid string', () {
      expect(() => AlertType.fromMapString('INVALID'), throwsArgumentError);
    });
  });

  group('AlertStatus enum', () {
    test('serializes and deserializes correctly', () {
      expect(AlertStatus.active.toMapString(), 'active');
      expect(AlertStatus.acknowledged.toMapString(), 'acknowledged');
      expect(AlertStatus.resolved.toMapString(), 'resolved');

      expect(AlertStatus.fromMapString('active'), AlertStatus.active);
      expect(
          AlertStatus.fromMapString('acknowledged'), AlertStatus.acknowledged);
      expect(AlertStatus.fromMapString('resolved'), AlertStatus.resolved);
      expect(AlertStatus.fromMapString('unknown'), AlertStatus.active);
    });
  });

  group('Alert entity', () {
    final now = DateTime.utc(2026, 9, 16, 12, 0);

    test('supports value equality and copyWith', () {
      final a1 = Alert(
        alertId: 'alert_1',
        organizationId: 'org_1',
        type: AlertType.missedShift,
        sourceEntityId: 'shift_1',
        sourceEntityType: 'shift',
        createdAt: now,
      );

      final a2 = a1.copyWith();
      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));

      final a3 = a1.copyWith(status: AlertStatus.resolved);
      expect(a3.status, AlertStatus.resolved);
      expect(a1 == a3, isFalse);
    });

    test('serializes to and deserializes from map', () {
      final alert = Alert(
        alertId: 'alert_test_1',
        organizationId: 'org_test',
        type: AlertType.criticalIncident,
        sourceEntityId: 'inc_123',
        sourceEntityType: 'incident',
        createdAt: now,
        status: AlertStatus.active,
        metadata: const {'severity': 'CRITICAL'},
      );

      final map = alert.toMap();
      expect(map['alertId'], 'alert_test_1');
      expect(map['organizationId'], 'org_test');
      expect(map['type'], 'CRITICAL_INCIDENT');
      expect(map['sourceEntityId'], 'inc_123');
      expect(map['sourceEntityType'], 'incident');
      expect(map['status'], 'active');
      expect(map['metadata'], const {'severity': 'CRITICAL'});

      final fromMap = Alert.fromMap(map);
      expect(fromMap.alertId, alert.alertId);
      expect(fromMap.organizationId, alert.organizationId);
      expect(fromMap.type, alert.type);
      expect(fromMap.sourceEntityId, alert.sourceEntityId);
      expect(fromMap.sourceEntityType, alert.sourceEntityType);
    });

    test('throws InvalidAlertDataFailure on empty fields', () {
      expect(
        () => Alert.fromMap(const {
          'alertId': '',
          'organizationId': 'org_1',
          'type': 'MISSED_SHIFT',
          'sourceEntityId': 's1',
        }),
        throwsA(isA<InvalidAlertDataFailure>()),
      );

      expect(
        () => Alert.fromMap(const {
          'alertId': 'a1',
          'organizationId': '',
          'type': 'MISSED_SHIFT',
          'sourceEntityId': 's1',
        }),
        throwsA(isA<InvalidAlertDataFailure>()),
      );
    });
  });

  group('AlertIdGenerator', () {
    test('generates deterministic collision-resistant IDs', () {
      expect(
        AlertIdGenerator.missedShift('org_1', 'shift_99'),
        'alert_org_1_shift_99_missed_shift',
      );
      expect(
        AlertIdGenerator.lateCheckIn('org_1', 'shift_99'),
        'alert_org_1_shift_99_late_check_in',
      );
      expect(
        AlertIdGenerator.understaffedSite('org_1', 'site_44', '2026-09-16_10'),
        'alert_org_1_site_44_understaffed_2026-09-16_10',
      );
      expect(
        AlertIdGenerator.criticalIncident('org_1', 'inc_77'),
        'alert_org_1_inc_77_critical_incident',
      );
    });
  });
}
