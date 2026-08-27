import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shift Entity Unit Tests', () {
    final now = DateTime(2026, 8, 27, 9, 0);
    final end = DateTime(2026, 8, 27, 17, 0);

    final testShift = Shift(
      id: 'shf-101',
      organizationId: 'org-decrypters',
      siteId: 'site-alpha',
      siteName: 'Alpha Tech Park',
      guardId: 'guard-77',
      guardName: 'Avadhut Guard',
      supervisorId: 'admin-01',
      shiftDate: '2026-08-27',
      startTime: now,
      endTime: end,
      status: ShiftStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );

    test('toMap converts Shift entity into valid Firestore map', () {
      final map = testShift.toMap();

      expect(map['id'], equals('shf-101'));
      expect(map['organizationId'], equals('org-decrypters'));
      expect(map['siteId'], equals('site-alpha'));
      expect(map['siteName'], equals('Alpha Tech Park'));
      expect(map['guardId'], equals('guard-77'));
      expect(map['guardName'], equals('Avadhut Guard'));
      expect(map['shiftDate'], equals('2026-08-27'));
      expect(map['status'], equals('scheduled'));
      expect(map['startTime'], isA<Timestamp>());
      expect(map['endTime'], isA<Timestamp>());
    });

    test('fromMap restores Shift entity correctly from Firestore map', () {
      final map = testShift.toMap();
      final restored = Shift.fromMap(map);

      expect(restored.id, equals(testShift.id));
      expect(restored.organizationId, equals(testShift.organizationId));
      expect(restored.siteId, equals(testShift.siteId));
      expect(restored.guardId, equals(testShift.guardId));
      expect(restored.status, equals(ShiftStatus.scheduled));
    });

    test('copyWith updates specified fields correctly', () {
      final updated = testShift.copyWith(
        status: ShiftStatus.completed,
        guardName: 'Updated Name',
      );

      expect(updated.status, equals(ShiftStatus.completed));
      expect(updated.guardName, equals('Updated Name'));
      expect(updated.id, equals(testShift.id));
    });
  });
}
