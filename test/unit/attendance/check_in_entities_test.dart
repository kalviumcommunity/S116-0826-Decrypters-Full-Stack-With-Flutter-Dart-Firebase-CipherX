import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/entities/check_in_entities.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckInFailure Hierarchy Tests', () {
    test('all failures instantiate with default and custom messages', () {
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

      for (final f in failures) {
        expect(f.message, isNotEmpty);
        expect(f.toString(), equals(f.message));
        expect(f, equals(f));
        expect(f.hashCode, equals(f.hashCode));
      }

      const custom = UnauthenticatedFailure('Custom auth error');
      expect(custom.message, equals('Custom auth error'));
      expect(custom, isNot(equals(const UnauthenticatedFailure())));
    });
  });

  group('CheckInEntities Domain Value Object Tests', () {
    test('CheckInVerificationMethod enum toMapString and fromMapString', () {
      expect(
        CheckInVerificationMethod.qrGpsGeofence.toMapString(),
        equals('qr_gps_geofence'),
      );
      expect(
        CheckInVerificationMethod.fromMapString('qr_gps_geofence'),
        equals(CheckInVerificationMethod.qrGpsGeofence),
      );
      expect(
        CheckInVerificationMethod.fromMapString('qr_gps'),
        equals(CheckInVerificationMethod.qrGpsGeofence),
      );
      expect(
        CheckInVerificationMethod.fromMapString('unknown'),
        equals(CheckInVerificationMethod.qrGpsGeofence),
      );
    });

    test('CheckInRequest value object equality, hashCode, and toString', () {
      const req1 = CheckInRequest(
        shiftId: 'shift_123',
        rawQrData: '{"siteId":"site_abc"}',
      );
      const req2 = CheckInRequest(
        shiftId: 'shift_123',
        rawQrData: '{"siteId":"site_abc"}',
      );
      const req3 = CheckInRequest(
        shiftId: 'shift_999',
        rawQrData: '{"siteId":"site_abc"}',
      );

      expect(req1, equals(req2));
      expect(req1.hashCode, equals(req2.hashCode));
      expect(req1, isNot(equals(req3)));
      expect(req1.toString(), contains('PROTECTED'));
    });

    test('CheckInResult value object equality, hashCode, and toString', () {
      final now = DateTime.utc(2026, 9, 10, 9, 0);
      final record = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: now,
        checkInLocation: LocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          accuracy: 5.0,
          timestamp: now,
        ),
      );

      final shift = Shift(
        shiftId: 'shift_001',
        organizationId: 'org_001',
        guardId: 'guard_001',
        siteId: 'site_001',
        date: DateTime.utc(2026, 9, 10),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
        status: ShiftStatus.active,
      );

      const site = Site(
        siteId: 'site_001',
        organizationId: 'org_001',
        name: 'Headquarters',
        address: '123 Main St',
        latitude: 18.5204,
        longitude: 73.8567,
        geofenceRadius: 100.0,
      );

      final res1 = CheckInResult(
        record: record,
        shift: shift,
        site: site,
        distanceMeters: 12.5,
        accuracyMeters: 5.0,
        verifiedAt: now,
      );

      final res2 = CheckInResult(
        record: record,
        shift: shift,
        site: site,
        distanceMeters: 12.5,
        accuracyMeters: 5.0,
        verifiedAt: now,
      );

      expect(res1, equals(res2));
      expect(res1.hashCode, equals(res2.hashCode));
      expect(res1.toString(), contains('12.5m'));
      expect(res1.toString(), contains('5.0m'));
    });
    test(
        'AttendanceRecord.fromMap treats unparsable coordinates as null instead of (0,0)',
        () {
      final mapWithUnparsable = {
        'attendanceId': 'att_123',
        'organizationId': 'org_1',
        'shiftId': 'shift_1',
        'siteId': 'site_1',
        'guardId': 'guard_1',
        'checkInTime': DateTime.now().toIso8601String(),
        'checkInLatitude': 'not_a_valid_lat',
        'checkInLongitude': 'not_a_valid_lng',
        'checkInAccuracy': 'invalid_acc',
        'status': 'active',
      };

      final record = AttendanceRecord.fromMap(mapWithUnparsable);
      expect(record.checkInLocation, isNull);
      expect(record.checkInLatitude, isNull);
      expect(record.checkInLongitude, isNull);
      expect(record.checkInAccuracy, isNull);
    });
  });
}
