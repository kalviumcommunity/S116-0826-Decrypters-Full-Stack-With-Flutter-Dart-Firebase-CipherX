import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/entities/check_in_entities.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/attendance/domain/services/secure_check_in_use_case.dart';
import 'package:cipher_x/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSecureCheckInUseCase implements SecureCheckInUseCase {
  CheckInResult? stubbedResult;
  Exception? exceptionToThrow;
  int callCount = 0;

  @override
  Future<CheckInResult> execute(CheckInRequest request) async {
    callCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (stubbedResult != null) return stubbedResult!;

    final now = DateTime.utc(2026, 9, 10, 9, 0);
    return CheckInResult(
      record: AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_001',
        shiftId: request.shiftId,
        siteId: 'site_001',
        guardId: 'guard_001',
        checkInTime: now,
        checkInLocation: LocationData(
          latitude: 18.5204,
          longitude: 73.8567,
          accuracy: 5.0,
          timestamp: now,
        ),
      ),
      shift: Shift(
        shiftId: request.shiftId,
        organizationId: 'org_001',
        guardId: 'guard_001',
        siteId: 'site_001',
        date: DateTime.utc(2026, 9, 10),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
        status: ShiftStatus.active,
      ),
      site: const Site(
        siteId: 'site_001',
        organizationId: 'org_001',
        name: 'Alpha Site',
        address: '100 Main St',
        latitude: 18.5204,
        longitude: 73.8567,
        geofenceRadius: 100.0,
      ),
      distanceMeters: 10.0,
      accuracyMeters: 5.0,
      verifiedAt: now,
    );
  }
}

void main() {
  group('CheckInController Unit Tests', () {
    late ProviderContainer container;
    late FakeSecureCheckInUseCase fakeUseCase;

    setUp(() {
      fakeUseCase = FakeSecureCheckInUseCase();
      container = ProviderContainer(
        overrides: [
          secureCheckInUseCaseProvider.overrideWithValue(fakeUseCase),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle with no errors or results', () {
      final state = container.read(checkInControllerProvider);

      expect(state.phase, equals(CheckInVerificationPhase.idle));
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.result, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.isFailure, isFalse);
    });

    test('successful check-in updates phase to success and populates result',
        () async {
      final controller = container.read(checkInControllerProvider.notifier);

      final success = await controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      expect(success, isTrue);

      final state = container.read(checkInControllerProvider);
      expect(state.phase, equals(CheckInVerificationPhase.success));
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.result, isNotNull);
      expect(state.result!.shift.shiftId, equals('shift_100'));
      expect(fakeUseCase.callCount, equals(1));
    });

    test('failed check-in updates phase to failure and populates errorMessage',
        () async {
      fakeUseCase.exceptionToThrow = const OutsideGeofenceFailure(
        'Guard is outside the site geofence perimeter.',
      );
      final controller = container.read(checkInControllerProvider.notifier);

      final success = await controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      expect(success, isFalse);

      final state = container.read(checkInControllerProvider);
      expect(state.phase, equals(CheckInVerificationPhase.failure));
      expect(state.isFailure, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.result, isNull);
      expect(
        state.errorMessage,
        equals('Guard is outside the site geofence perimeter.'),
      );
      expect(fakeUseCase.callCount, equals(1));
    });

    test('unexpected exception sets safe failure message', () async {
      fakeUseCase.exceptionToThrow = Exception('Network connection reset');
      final controller = container.read(checkInControllerProvider.notifier);

      final success = await controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      expect(success, isFalse);

      final state = container.read(checkInControllerProvider);
      expect(state.isFailure, isTrue);
      expect(state.errorMessage, contains('Network connection reset'));
    });

    test('double-tap guard prevents repeated concurrent execution', () async {
      final controller = container.read(checkInControllerProvider.notifier);

      // Start first execution
      final future1 = controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      // Immediate second call while first is in progress
      final future2 = controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      final results = await Future.wait([future1, future2]);

      expect(results[0], isTrue);
      expect(results[1], isFalse); // Blocked by isLoading check!
      expect(fakeUseCase.callCount, equals(1));
    });

    test('reset clears state back to initial idle', () async {
      final controller = container.read(checkInControllerProvider.notifier);

      await controller.checkIn(
        shiftId: 'shift_100',
        rawQrData: '{"siteId":"site_001"}',
      );

      expect(container.read(checkInControllerProvider).isSuccess, isTrue);

      controller.reset();

      final state = container.read(checkInControllerProvider);
      expect(state.phase, equals(CheckInVerificationPhase.idle));
      expect(state.isSuccess, isFalse);
      expect(state.result, isNull);
    });
  });
}
