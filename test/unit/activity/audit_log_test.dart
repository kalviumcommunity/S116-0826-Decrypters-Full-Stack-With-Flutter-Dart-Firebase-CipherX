import 'package:cipher_x/features/activity/domain/entities/audit_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuditLog Domain Entity Tests', () {
    test('toMap and fromMap serialize and deserialize correctly', () {
      final now = DateTime.utc(2026, 9, 1, 11, 30);
      final auditLog = AuditLog(
        id: 'aud_001',
        organizationId: 'org_001',
        actorId: 'usr_101',
        actorName: 'Gauri Guard',
        actorRole: 'guard',
        action: 'CHECK_IN_SUCCESS',
        entityType: 'attendance',
        entityId: 'att_500',
        timestamp: now,
        metadata: const {'gpsAccuracy': 12.4},
      );

      final map = auditLog.toMap();
      expect(map['id'], equals('aud_001'));
      expect(map['action'], equals('CHECK_IN_SUCCESS'));
      expect(map['actorRole'], equals('guard'));

      final restored = AuditLog.fromMap(map, 'aud_001');
      expect(restored.id, equals('aud_001'));
      expect(restored.actorName, equals('Gauri Guard'));
      expect(restored.action, equals('CHECK_IN_SUCCESS'));
      expect(restored.entityType, equals('attendance'));
      expect(restored.metadata['gpsAccuracy'], equals(12.4));
    });
  });
}
