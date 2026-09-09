import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:cipher_x/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart';
import 'package:cipher_x/features/location/domain/services/location_service.dart';
import 'package:cipher_x/features/location/presentation/providers/location_providers.dart';

class MockAttendanceRepository extends Mock implements AttendanceRepository {}

class MockLocationService extends Mock implements LocationService {}

void main() {
  late MockAttendanceRepository mockAttendanceRepository;
  late MockLocationService mockLocationService;
  late ProviderContainer container;

  const testProfile = UserProfile(
    uid: 'guard_123',
    email: 'guard@example.com',
    displayName: 'John Guard',
    phone: '+1234567890',
    role: UserRole.guard,
    organizationId: 'org_456',
  );

  final testLocation = LocationData(
    latitude: 18.5204,
    longitude: 73.8567,
    accuracy: 12.0,
    timestamp: DateTime.now(),
  );

  setUp(() {
    mockAttendanceRepository = MockAttendanceRepository();
    mockLocationService = MockLocationService();

    registerFallbackValue(testLocation);

    container = ProviderContainer(
      overrides: [
        currentUserProfileProvider.overrideWithValue(
          const AsyncValue.data(testProfile),
        ),
        attendanceRepositoryProvider.overrideWithValue(
          mockAttendanceRepository,
        ),
        locationServiceProvider.overrideWithValue(
          mockLocationService,
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('CheckOutController Unit Tests', () {
    test('initial state has isLoading false and null error', () {
      final state = container.read(checkOutControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.completedRecord, isNull);
    });

    test('aborts check-out and sets error when location retrieval fails',
        () async {
      when(() => mockLocationService.getCurrentLocation()).thenThrow(
        const LocationPermissionDeniedFailure(),
      );

      final controller = container.read(checkOutControllerProvider.notifier);
      final success = await controller.checkOut(attendanceId: 'att_001');

      expect(success, isFalse);
      final state = container.read(checkOutControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Location verification failed'));
      expect(state.completedRecord, isNull);

      // Verify repository was NEVER called with fake coordinates!
      verifyNever(() => mockAttendanceRepository.checkOutGuard(
            organizationId: any(named: 'organizationId'),
            attendanceId: any(named: 'attendanceId'),
            location: any(named: 'location'),
          ));
    });

    test('handles DuplicateCheckOutFailure cleanly', () async {
      when(() => mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => testLocation,
      );

      when(() => mockAttendanceRepository.checkOutGuard(
            organizationId: 'org_456',
            attendanceId: 'att_001',
            location: any(named: 'location'),
          )).thenThrow(const DuplicateCheckOutFailure());

      final controller = container.read(checkOutControllerProvider.notifier);
      final success = await controller.checkOut(attendanceId: 'att_001');

      expect(success, isFalse);
      final state = container.read(checkOutControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('already been recorded'));
      expect(state.completedRecord, isNull);
    });

    test(
        'completes check-out successfully when location and repository succeed',
        () async {
      when(() => mockLocationService.getCurrentLocation()).thenAnswer(
        (_) async => testLocation,
      );

      final completed = AttendanceRecord(
        attendanceId: 'att_001',
        organizationId: 'org_456',
        shiftId: 'shift_789',
        siteId: 'site_101',
        guardId: 'guard_123',
        checkInTime: DateTime.now().subtract(const Duration(hours: 8)),
        checkOutTime: DateTime.now(),
        checkOutLocation: testLocation,
        status: AttendanceStatus.completed,
      );

      when(() => mockAttendanceRepository.checkOutGuard(
            organizationId: 'org_456',
            attendanceId: 'att_001',
            location: any(named: 'location'),
          )).thenAnswer((_) async => completed);

      final controller = container.read(checkOutControllerProvider.notifier);
      final success = await controller.checkOut(attendanceId: 'att_001');

      expect(success, isTrue);
      final state = container.read(checkOutControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.completedRecord, equals(completed));
    });
  });
}
