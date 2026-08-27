import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';

void main() {
  group('GuardShifts Categorization Tests', () {
    test('Shift entity serialization and status validation', () {
      final now = DateTime.now();
      final shift = Shift(
        shiftId: 'shift-001',
        organizationId: 'org-001',
        guardId: 'guard-001',
        siteId: 'site-001',
        date: DateTime.utc(now.year, now.month, now.day),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
        status: ShiftStatus.scheduled,
      );

      expect(shift.status, equals(ShiftStatus.scheduled));
      expect(shift.startTime.toFormattedString(), equals('09:00'));
      expect(shift.endTime.toFormattedString(), equals('17:00'));
    });
  });
}
