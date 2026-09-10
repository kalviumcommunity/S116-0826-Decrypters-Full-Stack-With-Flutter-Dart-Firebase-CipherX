import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/attendance/domain/entities/check_in_entities.dart';
import 'package:cipher_x/features/attendance/domain/failures/attendance_failure.dart';
import 'package:cipher_x/features/attendance/domain/failures/check_in_failure.dart';
import 'package:cipher_x/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:cipher_x/features/attendance/domain/services/secure_check_in_use_case.dart';
import 'package:cipher_x/features/geofence/domain/services/geofence_engine.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/repositories/guard_repository.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/location/domain/entities/location_data.dart';
import 'package:cipher_x/features/location/domain/entities/location_permission_state.dart';
import 'package:cipher_x/features/location/domain/failures/location_failure.dart'
    as loc_fail;
import 'package:cipher_x/features/location/domain/services/location_service.dart';
import 'package:cipher_x/features/qr/domain/entities/site_qr_payload.dart';
import 'package:cipher_x/features/qr/domain/services/qr_validator.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/shifts/domain/repositories/shift_repository.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/sites/domain/repositories/site_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

class FakeGuardRepository implements GuardRepository {
  final Map<String, Guard> guards = {};

  @override
  Future<Guard> createGuard(Guard guard) async => guard;

  @override
  Future<void> deleteGuard({
    required String organizationId,
    required String guardId,
  }) async {}

  @override
  Future<Guard?> getGuard({
    required String organizationId,
    required String guardId,
  }) async {
    return guards['${organizationId}_$guardId'];
  }

  @override
  Future<List<Guard>> getGuards(String organizationId,
          {bool includeInactive = false}) async =>
      [];

  @override
  Future<Guard> updateGuard(Guard guard) async => guard;

  @override
  Future<Guard> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  }) async =>
      guards['${organizationId}_$guardId']!.copyWith(status: status);

  @override
  Stream<List<Guard>> watchGuards(String organizationId,
          {bool includeInactive = false}) =>
      Stream.value([]);
}

class FakeShiftRepository implements ShiftRepository {
  final Map<String, Shift> shifts = {};

  @override
  Future<Shift> createShift(Shift shift) async => shift;

  @override
  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  }) async {}

  @override
  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  }) async {
    return shifts['${organizationId}_$shiftId'];
  }

  @override
  Future<List<Shift>> getShiftsByGuard(
          String organizationId, String guardId) async =>
      [];

  @override
  Future<List<Shift>> getShiftsByOrganization(String organizationId) async =>
      [];

  @override
  Future<List<Shift>> getShiftsBySite(
          String organizationId, String siteId) async =>
      [];

  @override
  Future<Shift> updateShift(Shift shift) async => shift;

  @override
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async =>
      shifts['${organizationId}_$shiftId']!.copyWith(status: status);

  @override
  Stream<List<Shift>> watchShiftsByGuard(
          String organizationId, String guardId) =>
      Stream.value([]);
}

class FakeSiteRepository implements SiteRepository {
  final Map<String, Site> sites = {};

  @override
  Future<Site> createSite(Site site) async => site;

  @override
  Future<void> deleteSite({
    required String organizationId,
    required String siteId,
  }) async {}

  @override
  Future<Site?> getSite({
    required String organizationId,
    required String siteId,
  }) async {
    return sites['${organizationId}_$siteId'];
  }

  @override
  Future<List<Site>> getSites(String organizationId,
          {bool includeInactive = false}) async =>
      [];

  @override
  Future<Site> updateSite(Site site) async => site;

  @override
  Future<Site> updateSiteStatus({
    required String organizationId,
    required String siteId,
    required SiteStatus status,
  }) async =>
      sites['${organizationId}_$siteId']!.copyWith(status: status);

  @override
  Stream<List<Site>> watchSites(String organizationId,
          {bool includeInactive = false}) =>
      Stream.value([]);
}

class FakeLocationService implements LocationService {
  LocationData? stubbedLocation;
  Exception? exceptionToThrow;

  @override
  Future<LocationData> getCurrentLocation({Duration? timeout}) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (stubbedLocation != null) return stubbedLocation!;
    return LocationData(
      latitude: 18.5204,
      longitude: 73.8567,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermissionState> checkPermission() async =>
      LocationPermissionState.granted;

  @override
  Future<LocationPermissionState> requestPermission() async =>
      LocationPermissionState.granted;
}

class FakeAttendanceRepository implements AttendanceRepository {
  final Map<String, AttendanceRecord> records = {};
  AttendanceRecord? activeAttendance;
  Exception? exceptionToThrow;

  @override
  Future<AttendanceRecord> checkInGuard({
    required AttendanceRecord record,
  }) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    if (records.containsKey(record.attendanceId)) {
      throw const AlreadyCheckedInFailure();
    }
    records[record.attendanceId] = record;
    activeAttendance = record;
    return record;
  }

  @override
  Future<AttendanceRecord> createAttendanceRecord(
      AttendanceRecord record) async {
    return checkInGuard(record: record);
  }

  @override
  Future<AttendanceRecord> checkOutGuard({
    required String organizationId,
    required String attendanceId,
    required LocationData location,
  }) async {
    final existing = records[attendanceId];
    if (existing == null) throw const AttendanceNotFoundFailure();
    final updated = existing.checkOut(location: location);
    records[attendanceId] = updated;
    activeAttendance = null;
    return updated;
  }

  @override
  Future<AttendanceRecord?> getActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) async {
    return activeAttendance;
  }

  @override
  Future<AttendanceRecord?> getAttendanceById({
    required String organizationId,
    required String attendanceId,
  }) async =>
      records[attendanceId];

  @override
  Future<List<AttendanceRecord>> getAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) async =>
      records.values.toList();

  @override
  Stream<AttendanceRecord?> watchActiveAttendanceForGuard({
    required String organizationId,
    required String guardId,
  }) =>
      Stream.value(activeAttendance);

  @override
  Stream<List<AttendanceRecord>> watchAttendanceHistoryForGuard({
    required String organizationId,
    required String guardId,
  }) =>
      Stream.value(records.values.toList());
}

// =============================================================================
// MAIN TEST SUITE
// =============================================================================

void main() {
  late FakeGuardRepository fakeGuardRepo;
  late FakeShiftRepository fakeShiftRepo;
  late FakeSiteRepository fakeSiteRepo;
  late FakeLocationService fakeLocationService;
  late FakeAttendanceRepository fakeAttendanceRepo;

  UserProfile? mockProfile;

  SecureCheckInUseCase buildUseCase() {
    return SecureCheckInUseCase(
      getCurrentUserProfile: () => mockProfile,
      guardRepository: fakeGuardRepo,
      shiftRepository: fakeShiftRepo,
      siteRepository: fakeSiteRepo,
      locationService: fakeLocationService,
      qrValidator: const QrValidator(),
      geofenceEngine: const GeofenceEngine(),
      attendanceRepository: fakeAttendanceRepo,
    );
  }

  setUp(() {
    fakeGuardRepo = FakeGuardRepository();
    fakeShiftRepo = FakeShiftRepository();
    fakeSiteRepo = FakeSiteRepository();
    fakeLocationService = FakeLocationService();
    fakeAttendanceRepo = FakeAttendanceRepository();

    mockProfile = const UserProfile(
      uid: 'guard_123',
      email: 'guard@example.com',
      displayName: 'Guard John',
      phone: '+1234567890',
      organizationId: 'org_test',
      role: UserRole.guard,
      status: UserStatus.active,
    );

    // Setup valid guard
    fakeGuardRepo.guards['org_test_guard_123'] = const Guard(
      guardId: 'guard_123',
      organizationId: 'org_test',
      name: 'Guard John',
      employeeId: 'EMP001',
      phone: '+1234567890',
      status: GuardStatus.active,
    );

    // Setup valid shift
    fakeShiftRepo.shifts['org_test_shift_001'] = Shift(
      shiftId: 'shift_001',
      organizationId: 'org_test',
      guardId: 'guard_123',
      siteId: 'site_001',
      date: DateTime.now(),
      startTime: const ShiftTime(hour: 9, minute: 0),
      endTime: const ShiftTime(hour: 17, minute: 0),
      status: ShiftStatus.active,
    );

    // Setup valid site
    fakeSiteRepo.sites['org_test_site_001'] = const Site(
      siteId: 'site_001',
      organizationId: 'org_test',
      name: 'Alpha Facility',
      address: '100 Cyber Way',
      latitude: 18.5204,
      longitude: 73.8567,
      geofenceRadius: 100.0,
      status: SiteStatus.active,
    );

    // Setup valid location exactly at site
    fakeLocationService.stubbedLocation = LocationData(
      latitude: 18.5204,
      longitude: 73.8567,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  });

  group('SecureCheckInUseCase - Verification Pipeline Gates', () {
    test('Gate 1: unauthenticated user throws UnauthenticatedFailure',
        () async {
      mockProfile = null;
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<UnauthenticatedFailure>()));
    });

    test('Gate 2: user without guard role throws UnauthorizedRoleFailure',
        () async {
      mockProfile = mockProfile?.copyWith(role: UserRole.admin);
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<UnauthorizedRoleFailure>()));
    });

    test('Gate 3: guard profile not found throws CheckInGuardNotFoundFailure',
        () async {
      fakeGuardRepo.guards.clear();
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<CheckInGuardNotFoundFailure>()));
    });

    test('Gate 3b: inactive guard throws InactiveGuardFailure', () async {
      fakeGuardRepo.guards['org_test_guard_123'] = fakeGuardRepo
          .guards['org_test_guard_123']!
          .copyWith(status: GuardStatus.inactive);
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(
          () => useCase.execute(request), throwsA(isA<InactiveGuardFailure>()));
    });

    test('Gate 4: shift not found throws CheckInShiftNotFoundFailure',
        () async {
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_999_non_existent',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<CheckInShiftNotFoundFailure>()));
    });

    test('Gate 4b: cross-org shift throws ShiftOrgMismatchFailure', () async {
      fakeShiftRepo.shifts['org_test_shift_001'] = fakeShiftRepo
          .shifts['org_test_shift_001']!
          .copyWith(organizationId: 'another_org');
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<ShiftOrgMismatchFailure>()));
    });

    test(
        'Gate 4c: shift assigned to another guard throws ShiftGuardMismatchFailure',
        () async {
      fakeShiftRepo.shifts['org_test_shift_001'] = fakeShiftRepo
          .shifts['org_test_shift_001']!
          .copyWith(guardId: 'different_guard_999');
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<ShiftGuardMismatchFailure>()));
    });

    test('Gate 4d: cancelled shift throws ShiftCancelledFailure', () async {
      fakeShiftRepo.shifts['org_test_shift_001'] = fakeShiftRepo
          .shifts['org_test_shift_001']!
          .copyWith(status: ShiftStatus.cancelled);
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<ShiftCancelledFailure>()));
    });

    test('Gate 5: site not found throws CheckInSiteNotFoundFailure', () async {
      fakeSiteRepo.sites.clear();
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<CheckInSiteNotFoundFailure>()));
    });

    test('Gate 5b: inactive site throws InactiveSiteFailure', () async {
      fakeSiteRepo.sites['org_test_site_001'] = fakeSiteRepo
          .sites['org_test_site_001']!
          .copyWith(status: SiteStatus.inactive);
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(
          () => useCase.execute(request), throwsA(isA<InactiveSiteFailure>()));
    });

    test('Gate 5c: cross-org site throws SiteOrgMismatchFailure', () async {
      fakeSiteRepo.sites['org_test_site_001'] = fakeSiteRepo
          .sites['org_test_site_001']!
          .copyWith(organizationId: 'another_org');
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<SiteOrgMismatchFailure>()));
    });

    test(
        'Gate 5d: invalid site coordinates throws InvalidSiteCoordinatesFailure',
        () async {
      fakeSiteRepo.sites['org_test_site_001'] =
          fakeSiteRepo.sites['org_test_site_001']!.copyWith(latitude: 999.0);
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<InvalidSiteCoordinatesFailure>()));
    });

    test('Gate 6: location disabled throws LocationDisabledFailure', () async {
      fakeLocationService.exceptionToThrow =
          const loc_fail.LocationServiceDisabledFailure();
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<LocationDisabledFailure>()));
    });

    test(
        'Gate 6b: location permission denied throws LocationPermissionDeniedFailure',
        () async {
      fakeLocationService.exceptionToThrow =
          const loc_fail.LocationPermissionDeniedFailure();
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<LocationPermissionDeniedFailure>()));
    });

    test(
        'Gate 6c: invalid device coordinates throws InvalidLocationCoordinatesFailure',
        () async {
      fakeLocationService.exceptionToThrow =
          const loc_fail.InvalidLocationCoordinatesFailure(
              'Invalid coordinates');
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<InvalidLocationCoordinatesFailure>()));
    });

    test('Gate 7: invalid QR payload format throws QrValidationFailedFailure',
        () async {
      final useCase = buildUseCase();

      const request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: 'INVALID_NOT_JSON',
      );

      expect(() => useCase.execute(request),
          throwsA(isA<QrValidationFailedFailure>()));
    });

    test(
        'Gate 7b: QR site mismatch (Site B QR for Site A shift) throws QrSiteMismatchFailure',
        () async {
      // Setup Site B in repository
      fakeSiteRepo.sites['org_test_site_002'] = const Site(
        siteId: 'site_002',
        organizationId: 'org_test',
        name: 'Beta Facility',
        address: '200 Secure Ave',
        latitude: 18.5204,
        longitude: 73.8567,
        geofenceRadius: 100.0,
        status: SiteStatus.active,
      );

      final useCase = buildUseCase();

      // Request for shift_001 (which is at site_001), but scanned QR is for site_002!
      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_002').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<QrSiteMismatchFailure>()));
    });

    test('Gate 8: poor GPS accuracy (> 50m) throws PoorGpsAccuracyFailure',
        () async {
      fakeLocationService.stubbedLocation = LocationData(
        latitude: 18.5204,
        longitude: 73.8567,
        accuracy: 75.0, // Exceeds 50m threshold
        timestamp: DateTime.now(),
      );
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<PoorGpsAccuracyFailure>()));
    });

    test('Gate 8b: outside geofence throws OutsideGeofenceFailure', () async {
      // Move guard 500m away (site radius is 100m)
      fakeLocationService.stubbedLocation = LocationData(
        latitude: 18.5250,
        longitude: 73.8567,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<OutsideGeofenceFailure>()));
    });

    test('Gate 9: already checked in throws AlreadyCheckedInFailure', () async {
      fakeAttendanceRepo.activeAttendance = AttendanceRecord(
        attendanceId: 'att_shift_001',
        organizationId: 'org_test',
        shiftId: 'shift_001',
        siteId: 'site_001',
        guardId: 'guard_123',
        checkInTime: DateTime.now(),
        status: AttendanceStatus.active,
      );

      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<AlreadyCheckedInFailure>()));
    });

    test('Gate 10: persistence failure throws AttendancePersistenceFailure',
        () async {
      fakeAttendanceRepo.exceptionToThrow = Exception('Firestore timeout');
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(() => useCase.execute(request),
          throwsA(isA<AttendancePersistenceFailure>()));
    });

    test(
        'Complete Success: all gates pass -> creates attendance and returns typed CheckInResult',
        () async {
      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      final result = await useCase.execute(request);

      expect(result.record, isNotNull);
      expect(result.record.attendanceId, equals('att_shift_001'));
      expect(result.record.organizationId, equals('org_test'));
      expect(result.record.guardId, equals('guard_123'));
      expect(result.record.shiftId, equals('shift_001'));
      expect(result.record.siteId, equals('site_001'));
      expect(result.record.status, equals(AttendanceStatus.active));
      expect(result.record.checkInLatitude, equals(18.5204));
      expect(result.record.checkInLongitude, equals(73.8567));
      expect(result.record.checkInAccuracy, equals(5.0));
      expect(result.record.verificationMethod, equals('qr_gps_geofence'));
      expect(result.distanceMeters, lessThanOrEqualTo(100.0));
      expect(result.site.name, equals('Alpha Facility'));
      expect(result.shift.shiftId, equals('shift_001'));
    });
    test(
        'Gate 21 rejects check-in when guard has active attendance on another shift',
        () async {
      fakeAttendanceRepo.activeAttendance = AttendanceRecord(
        attendanceId: 'att_other_shift',
        organizationId: 'org_test',
        shiftId: 'shift_other',
        siteId: 'site_001',
        guardId: 'guard_123',
        checkInTime: DateTime.now().subtract(const Duration(hours: 1)),
        status: AttendanceStatus.active,
      );

      final useCase = buildUseCase();

      final request = CheckInRequest(
        shiftId: 'shift_001',
        rawQrData: SiteQrPayload.createForSite('site_001').toJson(),
      );

      expect(
        () => useCase.execute(request),
        throwsA(isA<AlreadyCheckedInFailure>().having(
          (f) => f.message,
          'message',
          contains(
              'Guard already has an active check-in session for shift shift_other'),
        )),
      );
    });
  });
}
