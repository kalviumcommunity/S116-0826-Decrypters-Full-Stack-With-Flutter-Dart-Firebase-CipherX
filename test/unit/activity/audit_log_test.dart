import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/activity/domain/entities/audit_log.dart';

void main() {
  group('AuditLog Domain Entity Tests', () {
    final now = DateTime.utc(2026, 9, 17, 10, 30);

    test('toMap and fromMap serialize and deserialize correctly with Timestamp',
        () {
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
        metadata: const {'accuracy': 10.5},
      );

      final map = auditLog.toMap();
      expect(map['id'], equals('aud_001'));
      expect(map['organizationId'], equals('org_001'));
      expect(map['actorName'], equals('Gauri Guard'));
      expect(map['action'], equals('CHECK_IN_SUCCESS'));
      expect(map['timestamp'], isA<Timestamp>());

      final restored = AuditLog.fromMap(map, 'fallback_id');
      expect(restored.id, equals('aud_001'));
      expect(restored.organizationId, equals('org_001'));
      expect(restored.actorName, equals('Gauri Guard'));
      expect(restored.actorRole, equals('guard'));
      expect(restored.action, equals('CHECK_IN_SUCCESS'));
      expect(restored.entityType, equals('attendance'));
      expect(restored.entityId, equals('att_500'));
      expect(restored.timestamp?.toUtc(), equals(now.toUtc()));
      expect(restored.metadata['accuracy'], equals(10.5));
    });

    test('fromMap parses ISO8601 string timestamps correctly', () {
      final map = {
        'id': 'aud_002',
        'organizationId': 'org_001',
        'actorId': 'usr_102',
        'actorName': 'Admin User',
        'actorRole': 'admin',
        'action': 'USER_CREATED',
        'entityType': 'user',
        'entityId': 'usr_999',
        'timestamp': now.toIso8601String(),
      };

      final restored = AuditLog.fromMap(map);
      expect(restored.timestamp?.toUtc(), equals(now.toUtc()));
    });

    test('fromMap uses fallback values when optional fields are missing', () {
      final map = <String, dynamic>{};
      final restored = AuditLog.fromMap(map, 'fallback_aud_99');

      expect(restored.id, equals('fallback_aud_99'));
      expect(restored.organizationId, isEmpty);
      expect(restored.actorName, equals('System User'));
      expect(restored.actorRole, equals('guard'));
      expect(restored.action, equals('UNKNOWN_ACTION'));
      expect(restored.entityType, equals('system'));
      expect(restored.timestamp, isNull);
      expect(restored.metadata, isEmpty);
    });

    test('copyWith properly overrides specified attributes', () {
      final original = AuditLog(
        id: 'aud_001',
        organizationId: 'org_001',
        actorId: 'usr_101',
        actorName: 'User One',
        actorRole: 'guard',
        action: 'LOGIN',
        entityType: 'session',
        entityId: 'sess_1',
        timestamp: now,
      );

      final modified = original.copyWith(
        actorName: 'User Two',
        action: 'LOGOUT',
      );

      expect(modified.id, equals(original.id));
      expect(modified.actorName, equals('User Two'));
      expect(modified.action, equals('LOGOUT'));
      expect(modified.organizationId, equals(original.organizationId));
    });

    test('equality and hashCode verify value identity', () {
      const log1 = AuditLog(
        id: 'aud_001',
        organizationId: 'org_001',
        actorId: 'usr_101',
        actorName: 'User',
        actorRole: 'guard',
        action: 'ACTION',
        entityType: 'type',
        entityId: 'id_1',
      );

      const log2 = AuditLog(
        id: 'aud_001',
        organizationId: 'org_001',
        actorId: 'usr_101',
        actorName: 'User',
        actorRole: 'guard',
        action: 'ACTION',
        entityType: 'type',
        entityId: 'id_1',
      );

      final log3 = log1.copyWith(id: 'aud_002');

      expect(log1, equals(log2));
      expect(log1.hashCode, equals(log2.hashCode));
      expect(log1, isNot(equals(log3)));
    });
  });
}
