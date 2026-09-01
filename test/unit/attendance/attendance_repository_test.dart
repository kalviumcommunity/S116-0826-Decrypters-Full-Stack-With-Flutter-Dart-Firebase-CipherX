import 'package:cipher_x/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRepositoryImpl Unit Tests', () {
    test(
        'createAttendanceRecord throws UnknownAttendanceFailure when organizationId is empty',
        () async {
      final repository = AttendanceRepositoryImpl();
      final record = AttendanceRecord(
        attendanceId: 'att_1',
        organizationId: '',
        shiftId: 'shift_1',
        siteId: 'site_1',
        guardId: 'guard_1',
        checkInTime: DateTime.now(),
      );

      expect(
        () => repository.createAttendanceRecord(record),
        throwsA(isA<UnknownAttendanceFailure>()),
      );
    });

    test(
        'checkOutGuard throws UnknownAttendanceFailure when parameters are empty',
        () async {
      final repository = AttendanceRepositoryImpl();
      final location = LocationData(
        latitude: 18.5,
        longitude: 73.8,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );

      expect(
        () => repository.checkOutGuard(
          organizationId: '',
          attendanceId: 'att_1',
          location: location,
        ),
        throwsA(isA<UnknownAttendanceFailure>()),
      );
    });

    test('getAttendanceHistoryForGuard returns empty list for empty parameters',
        () async {
      final repository = AttendanceRepositoryImpl();
      final result = await repository.getAttendanceHistoryForGuard(
        organizationId: '',
        guardId: 'guard_1',
      );

      expect(result, isEmpty);
    });

    test(
        'watchActiveAttendanceForGuard returns null stream for empty parameters',
        () async {
      final repository = AttendanceRepositoryImpl();
      final stream = repository.watchActiveAttendanceForGuard(
        organizationId: '',
        guardId: '',
      );

      expect(await stream.first, isNull);
    });
  });
}
