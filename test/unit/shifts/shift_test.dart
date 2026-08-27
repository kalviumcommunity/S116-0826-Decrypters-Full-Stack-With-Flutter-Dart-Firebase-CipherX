import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';

void main() {
  final tDate = DateTime.utc(2026, 8, 27);
  final tCreatedAt = DateTime.utc(2026, 8, 27, 8, 0);

  final tShift = Shift(
    shiftId: 'shift-001',
    organizationId: 'org-100',
    guardId: 'guard-200',
    siteId: 'site-300',
    date: tDate,
    startTime: const ShiftTime(hour: 9, minute: 0),
    endTime: const ShiftTime(hour: 17, minute: 0),
    status: ShiftStatus.scheduled,
    createdAt: tCreatedAt,
    updatedAt: tCreatedAt,
  );

  group('Shift Model Unit Tests', () {
    test('supports value equality', () {
      final duplicate = Shift(
        shiftId: 'shift-001',
        organizationId: 'org-100',
        guardId: 'guard-200',
        siteId: 'site-300',
        date: tDate,
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
        status: ShiftStatus.scheduled,
        createdAt: tCreatedAt,
        updatedAt: tCreatedAt,
      );

      expect(tShift, equals(duplicate));
      expect(tShift.hashCode, equals(duplicate.hashCode));
    });

    test('serializes to Map correctly', () {
      final map = tShift.toMap();
      expect(map['shiftId'], equals('shift-001'));
      expect(map['organizationId'], equals('org-100'));
      expect(map['guardId'], equals('guard-200'));
      expect(map['siteId'], equals('site-300'));
      expect(map['date'], equals('2026-08-27'));
      expect(map['startTime'], equals('09:00'));
      expect(map['endTime'], equals('17:00'));
      expect(map['status'], equals('scheduled'));
    });

    test('deserializes from Map correctly', () {
      final map = {
        'shiftId': 'shift-001',
        'organizationId': 'org-100',
        'guardId': 'guard-200',
        'siteId': 'site-300',
        'date': '2026-08-27',
        'startTime': '09:00',
        'endTime': '17:00',
        'status': 'scheduled',
        'createdAt': tCreatedAt.toIso8601String(),
        'updatedAt': tCreatedAt.toIso8601String(),
      };

      final deserialized = Shift.fromMap(map);
      expect(deserialized.shiftId, equals('shift-001'));
      expect(deserialized.organizationId, equals('org-100'));
      expect(deserialized.guardId, equals('guard-200'));
      expect(deserialized.siteId, equals('site-300'));
      expect(
          deserialized.startTime, equals(const ShiftTime(hour: 9, minute: 0)));
      expect(
          deserialized.endTime, equals(const ShiftTime(hour: 17, minute: 0)));
      expect(deserialized.status, equals(ShiftStatus.scheduled));
    });

    test('copyWith creates modified copy', () {
      final updated = tShift.copyWith(status: ShiftStatus.active);
      expect(updated.status, equals(ShiftStatus.active));
      expect(updated.shiftId, equals(tShift.shiftId));
      expect(updated.guardId, equals(tShift.guardId));
    });

    test('domain methods activate, complete, and cancel update status', () {
      final activeShift = tShift.activate();
      expect(activeShift.status, equals(ShiftStatus.active));

      final completedShift = activeShift.complete();
      expect(completedShift.status, equals(ShiftStatus.completed));

      final cancelledShift = tShift.cancel();
      expect(cancelledShift.status, equals(ShiftStatus.cancelled));
    });

    test(
        'ShiftStatus fromMapString converts valid values and throws on invalid',
        () {
      expect(ShiftStatus.fromMapString('scheduled'),
          equals(ShiftStatus.scheduled));
      expect(ShiftStatus.fromMapString('active'), equals(ShiftStatus.active));
      expect(ShiftStatus.fromMapString('completed'),
          equals(ShiftStatus.completed));
      expect(ShiftStatus.fromMapString('cancelled'),
          equals(ShiftStatus.cancelled));
      expect(
        () => ShiftStatus.fromMapString('invalid_status'),
        throwsFormatException,
      );
    });
  });
}
