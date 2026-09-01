import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRecord Domain Entity Tests', () {
    final checkInTime = DateTime.utc(2026, 9, 1, 9, 0);
    final checkOutTime = DateTime.utc(2026, 9, 1, 17, 0);
    final initialLocation = LocationData(
      latitude: 18.5204,
      longitude: 73.8567,
      accuracy: 10.0,
      timestamp: checkInTime,
    );
    final checkoutLocation = LocationData(
      latitude: 18.5210,
      longitude: 73.8570,
      accuracy: 8.0,
      timestamp: checkOutTime,
    );

    test('isCheckedOut returns false for active record without checkOutTime',
        () {
      final record = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: checkInTime,
        checkInLocation: initialLocation,
        status: AttendanceStatus.active,
      );

      expect(record.isCheckedOut, isFalse);
    });

    test(
        'isCheckedOut returns true when checkOutTime is set or status is completed',
        () {
      final record = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        checkInLocation: initialLocation,
        checkOutLocation: checkoutLocation,
        status: AttendanceStatus.completed,
      );

      expect(record.isCheckedOut, isTrue);
    });

    test(
        'checkOut updates status, checkOutTime, and checkOutLocation for active record',
        () {
      final record = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: checkInTime,
        checkInLocation: initialLocation,
        status: AttendanceStatus.active,
      );

      final updated = record.checkOut(
        location: checkoutLocation,
        timestamp: checkOutTime,
      );

      expect(updated.status, equals(AttendanceStatus.completed));
      expect(updated.checkOutTime, equals(checkOutTime));
      expect(updated.checkOutLocation, equals(checkoutLocation));
      expect(updated.isCheckedOut, isTrue);
    });

    test(
        'checkOut duplicate prevention returns unchanged record if already checked out',
        () {
      final original = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        checkInLocation: initialLocation,
        checkOutLocation: checkoutLocation,
        status: AttendanceStatus.completed,
      );

      final secondLocation = LocationData(
        latitude: 20.0,
        longitude: 70.0,
        accuracy: 50.0,
        timestamp: DateTime.utc(2026, 9, 2, 12, 0),
      );

      final secondResult = original.checkOut(
        location: secondLocation,
        timestamp: DateTime.utc(2026, 9, 2, 12, 0),
      );

      // Should retain original check-out timestamp and location!
      expect(secondResult.checkOutTime, equals(checkOutTime));
      expect(secondResult.checkOutLocation, equals(checkoutLocation));
    });

    test('toMap and fromMap serialize and deserialize correctly', () {
      final record = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
        checkInLocation: initialLocation,
        checkOutLocation: checkoutLocation,
        status: AttendanceStatus.completed,
        verificationMethod: 'qr_gps',
      );

      final map = record.toMap();
      final restored = AttendanceRecord.fromMap(map, 'att_001');

      expect(restored.attendanceId, equals('att_001'));
      expect(restored.organizationId, equals('org_001'));
      expect(restored.guardId, equals('guard_001'));
      expect(restored.status, equals(AttendanceStatus.completed));
      expect(restored.checkInLocation?.latitude, equals(18.5204));
      expect(restored.checkOutLocation?.latitude, equals(18.5210));
    });
  });
}
