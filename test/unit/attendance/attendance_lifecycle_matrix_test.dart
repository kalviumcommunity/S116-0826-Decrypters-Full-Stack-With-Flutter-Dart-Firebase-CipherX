import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Attendance Lifecycle & Idempotency Matrix Tests', () {
    final t1 = DateTime.utc(2026, 9, 1, 8, 0);
    final t2 = DateTime.utc(2026, 9, 1, 16, 0);

    final siteLocation = LocationData(
      latitude: 17.44,
      longitude: 78.38,
      accuracy: 5.0,
      timestamp: t1,
    );

    final checkoutLocation = LocationData(
      latitude: 17.4401,
      longitude: 78.3802,
      accuracy: 4.5,
      timestamp: t2,
    );

    test('1. Valid Initial Check-In initializes Active status with immutable audit coordinates', () {
      final record = AttendanceRecord(
        attendanceId: 'att-100',
        organizationId: 'org-cipher',
        shiftId: 'shift-100',
        siteId: 'site-alpha',
        guardId: 'guard-42',
        checkInTime: t1,
        checkInLocation: siteLocation,
        status: AttendanceStatus.active,
        verificationMethod: 'qr_gps',
      );

      expect(record.status, equals(AttendanceStatus.active));
      expect(record.isCheckedOut, isFalse);
      expect(record.checkOutTime, isNull);
      expect(record.checkOutLocation, isNull);
      expect(record.checkInLocation?.latitude, equals(17.44));
    });

    test('2. Duplicate check-out retains original timestamp and preserves idempotency', () {
      final active = AttendanceRecord(
        attendanceId: 'att-100',
        organizationId: 'org-cipher',
        shiftId: 'shift-100',
        siteId: 'site-alpha',
        guardId: 'guard-42',
        checkInTime: t1,
        checkInLocation: siteLocation,
        status: AttendanceStatus.active,
      );

      final completed = active.checkOut(
        location: checkoutLocation,
        timestamp: t2,
      );

      expect(completed.status, equals(AttendanceStatus.completed));
      expect(completed.isCheckedOut, isTrue);
      expect(completed.checkOutTime, equals(t2));

      // Attempt second checkout with later time and location
      final t3 = DateTime.utc(2026, 9, 1, 18, 30);
      final bogusLocation = LocationData(
        latitude: 0.0,
        longitude: 0.0,
        accuracy: 100.0,
        timestamp: t3,
      );

      final secondCheckout = completed.checkOut(
        location: bogusLocation,
        timestamp: t3,
      );

      // Must remain identical to the first checkout
      expect(secondCheckout.checkOutTime, equals(t2));
      expect(secondCheckout.checkOutLocation, equals(checkoutLocation));
      expect(secondCheckout.status, equals(AttendanceStatus.completed));
    });

    test('3. Security Failures Type Matrix guarantees non-null actionable error messages', () {
      const failures = <CheckInFailure>[
        UnauthenticatedFailure(),
        UnauthorizedRoleFailure(),
        CheckInGuardNotFoundFailure(),
        InactiveGuardFailure(),
        GuardOrgMismatchFailure(),
        CheckInShiftNotFoundFailure(),
        ShiftOrgMismatchFailure(),
        ShiftGuardMismatchFailure(),
        ShiftCancelledFailure(),
        CheckInSiteNotFoundFailure(),
        InactiveSiteFailure(),
        SiteOrgMismatchFailure(),
        InvalidSiteCoordinatesFailure(),
        QrValidationFailedFailure(),
        QrSiteMismatchFailure(),
        LocationDisabledFailure(),
        LocationPermissionDeniedFailure(),
        LocationUnavailableFailure(),
        InvalidLocationCoordinatesFailure(),
        PoorGpsAccuracyFailure(),
        OutsideGeofenceFailure(),
        AlreadyCheckedInFailure(),
        AttendancePersistenceFailure(),
      ];

      for (final failure in failures) {
        expect(failure.message, isNotEmpty);
        expect(failure.message, isNot(contains('Exception')));
        expect(failure.toString(), equals(failure.message));
      }
    });

    test('4. AttendanceFailure base domain hierarchy handles checkout failures appropriately', () {
      const dupFailure = DuplicateCheckOutFailure();
      const noActiveFailure = NoActiveAttendanceFailure();
      const notFoundFailure = AttendanceNotFoundFailure();

      expect(dupFailure, isA<AttendanceFailure>());
      expect(noActiveFailure, isA<AttendanceFailure>());
      expect(notFoundFailure, isA<AttendanceFailure>());
      expect(dupFailure.message, contains('already been recorded'));
      expect(noActiveFailure.message, contains('No active attendance'));
    });

    test('5. Serialization roundtrip maintains exact millisecond precision for auditing', () {
      final original = AttendanceRecord(
        attendanceId: 'att-roundtrip',
        organizationId: 'org-audit',
        shiftId: 'shift-audit',
        siteId: 'site-audit',
        guardId: 'guard-audit',
        checkInTime: DateTime.utc(2026, 9, 18, 10, 30, 45, 123),
        checkOutTime: DateTime.utc(2026, 9, 18, 18, 45, 30, 987),
        checkInLocation: siteLocation,
        checkOutLocation: checkoutLocation,
        status: AttendanceStatus.completed,
        verificationMethod: 'qr_gps_biometric',
      );

      final map = original.toMap();
      final reconstructed = AttendanceRecord.fromMap(map, 'att-roundtrip');

      expect(reconstructed.attendanceId, equals(original.attendanceId));
      expect(reconstructed.organizationId, equals(original.organizationId));
      expect(reconstructed.checkInTime.millisecondsSinceEpoch, equals(original.checkInTime.millisecondsSinceEpoch));
      expect(reconstructed.checkOutTime?.millisecondsSinceEpoch, equals(original.checkOutTime?.millisecondsSinceEpoch));
      expect(reconstructed.verificationMethod, equals('qr_gps_biometric'));
    });
  });
}
