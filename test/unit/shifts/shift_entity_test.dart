import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shift Entity Unit Tests', () {
    final now = DateTime.utc(2026, 8, 27);

    final testShift = Shift(
      shiftId: 'shf-101',
      organizationId: 'org-decrypters',
      siteId: 'site-alpha',
      guardId: 'guard-77',
      date: now,
      startTime: const ShiftTime(hour: 9, minute: 0),
      endTime: const ShiftTime(hour: 17, minute: 0),
      status: ShiftStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );

    test('toMap converts Shift entity into valid map', () {
      final map = testShift.toMap();

      expect(map['shiftId'], equals('shf-101'));
      expect(map['organizationId'], equals('org-decrypters'));
      expect(map['siteId'], equals('site-alpha'));
      expect(map['guardId'], equals('guard-77'));
      expect(map['date'], equals(now.toIso8601String()));
      expect(map['startTime'], equals('09:00'));
      expect(map['endTime'], equals('17:00'));
      expect(map['status'], equals('scheduled'));
    });

    test('fromMap restores Shift entity correctly from map', () {
      final map = testShift.toMap();
      final restored = Shift.fromMap(map);

      expect(restored.shiftId, equals(testShift.shiftId));
      expect(restored.organizationId, equals(testShift.organizationId));
      expect(restored.siteId, equals(testShift.siteId));
      expect(restored.guardId, equals(testShift.guardId));
      expect(restored.status, equals(ShiftStatus.scheduled));
    });

    test('copyWith updates specified fields correctly', () {
      final updated = testShift.copyWith(
        status: ShiftStatus.completed,
      );

      expect(updated.status, equals(ShiftStatus.completed));
      expect(updated.shiftId, equals(testShift.shiftId));
    });
  });
}
