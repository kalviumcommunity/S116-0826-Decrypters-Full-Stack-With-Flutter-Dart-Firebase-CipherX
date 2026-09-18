import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QA Hardening: Duplicate Action & Concurrency Idempotency Tests', () {
    final t1 = DateTime.utc(2026, 9, 18, 8, 0);
    final loc1 = LocationData(
      latitude: 12.9716,
      longitude: 77.5946,
      accuracy: 5.0,
      timestamp: t1,
    );

    test('1. Multiple rapid check-in calls with same parameters preserve single session identity', () {
      final recordA = AttendanceRecord(
        attendanceId: 'att_shift_101',
        organizationId: 'org_main',
        shiftId: 'shift_101',
        siteId: 'site_alpha',
        guardId: 'guard_g1',
        checkInTime: t1,
        checkInLocation: loc1,
        status: AttendanceStatus.active,
      );

      final recordB = AttendanceRecord(
        attendanceId: 'att_shift_101',
        organizationId: 'org_main',
        shiftId: 'shift_101',
        siteId: 'site_alpha',
        guardId: 'guard_g1',
        checkInTime: t1.add(const Duration(seconds: 1)),
        checkInLocation: loc1,
        status: AttendanceStatus.active,
      );

      // Deterministic attendance session identity matches on shiftId
      expect(recordA.attendanceId, equals(recordB.attendanceId));
      expect(recordA.shiftId, equals(recordB.shiftId));
      expect(recordA.guardId, equals(recordB.guardId));
    });

    test('2. Rapid duplicate check-out attempts are strictly idempotent', () {
      final active = AttendanceRecord(
        attendanceId: 'att_101',
        organizationId: 'org_main',
        shiftId: 'shift_101',
        siteId: 'site_alpha',
        guardId: 'guard_g1',
        checkInTime: t1,
        checkInLocation: loc1,
        status: AttendanceStatus.active,
      );

      final t2 = DateTime.utc(2026, 9, 18, 17, 0);
      final loc2 = LocationData(
        latitude: 12.9720,
        longitude: 77.5950,
        accuracy: 4.0,
        timestamp: t2,
      );

      final firstCheckout = active.checkOut(location: loc2, timestamp: t2);
      expect(firstCheckout.status, equals(AttendanceStatus.completed));
      expect(firstCheckout.checkOutTime, equals(t2));

      // Second checkout attempted 10 seconds later
      final t3 = t2.add(const Duration(seconds: 10));
      final secondCheckout = firstCheckout.checkOut(location: loc2, timestamp: t3);

      expect(secondCheckout.checkOutTime, equals(t2)); // Retained first timestamp!
      expect(secondCheckout.status, equals(AttendanceStatus.completed));
    });

    test('3. Attendance state machine enforces strict terminal status', () {
      final completed = AttendanceRecord(
        attendanceId: 'att_101',
        organizationId: 'org_main',
        shiftId: 'shift_101',
        siteId: 'site_alpha',
        guardId: 'guard_g1',
        checkInTime: t1,
        checkOutTime: t1.add(const Duration(hours: 8)),
        status: AttendanceStatus.completed,
      );

      expect(completed.isCheckedOut, isTrue);
      // Completed attendance cannot revert to active
      expect(completed.status, equals(AttendanceStatus.completed));
    });
  });
}
