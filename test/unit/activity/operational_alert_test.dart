import 'package:cipher_x/features/activity/domain/entities/operational_alert.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OperationalAlert Domain Entity Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime.utc(2026, 9, 1, 11, 30);
      final alert = OperationalAlert(
        alertId: 'alt_001',
        organizationId: 'org_001',
        siteId: 'site_001',
        type: OperationalAlertType.missedShift,
        severity: AlertSeverity.critical,
        title: 'Missed Shift Alert',
        message: 'Guard EMP-101 missed shift check-in by >30 mins.',
        status: AlertStatus.active,
        timestamp: now,
      );

      final map = alert.toMap();
      expect(map['alertId'], equals('alt_001'));
      expect(map['type'], equals('missedShift'));
      expect(map['severity'], equals('critical'));
      expect(map['status'], equals('active'));

      final restored = OperationalAlert.fromMap(map, 'alt_001');
      expect(restored.alertId, equals('alt_001'));
      expect(restored.type, equals(OperationalAlertType.missedShift));
      expect(restored.severity, equals(AlertSeverity.critical));
      expect(restored.title, equals('Missed Shift Alert'));
    });

    test('OperationalAlertType enum string conversion', () {
      expect(
          OperationalAlertType.missedShift.displayName, equals('Missed Shift'));
      expect(OperationalAlertType.fromMapString('late_checkin'),
          equals(OperationalAlertType.lateCheckIn));
      expect(OperationalAlertType.fromMapString('understaffed_site'),
          equals(OperationalAlertType.understaffedSite));
      expect(OperationalAlertType.fromMapString('unknown'),
          equals(OperationalAlertType.other));
    });

    test('AlertSeverity enum string conversion', () {
      expect(AlertSeverity.critical.displayName, equals('Critical'));
      expect(AlertSeverity.fromMapString('warning'),
          equals(AlertSeverity.warning));
      expect(
          AlertSeverity.fromMapString('invalid'), equals(AlertSeverity.info));
    });

    test('AlertStatus enum string conversion', () {
      expect(AlertStatus.active.displayName, equals('Active'));
      expect(AlertStatus.fromMapString('acknowledged'),
          equals(AlertStatus.acknowledged));
      expect(
          AlertStatus.fromMapString('resolved'), equals(AlertStatus.resolved));
    });
  });
}
