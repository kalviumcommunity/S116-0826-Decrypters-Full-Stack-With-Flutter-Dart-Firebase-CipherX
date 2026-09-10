import '../../../geofence/domain/services/geofence_engine.dart';
import '../../../guards/domain/entities/guard.dart';
import '../../../guards/domain/repositories/guard_repository.dart';
import '../../../identity/domain/entities/user_profile.dart';
import '../../../location/domain/entities/location_data.dart';
import '../../../location/domain/failures/location_failure.dart' as loc_fail;
import '../../../location/domain/services/location_service.dart';
import '../../../qr/domain/services/qr_validator.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../shifts/domain/repositories/shift_repository.dart';
import '../../../sites/domain/entities/site.dart';
import '../../../sites/domain/repositories/site_repository.dart';
import '../entities/attendance_record.dart';
import '../entities/check_in_entities.dart';
import '../failures/check_in_failure.dart';
import '../repositories/attendance_repository.dart';

/// Secure Check-In Use Case executing the exhaustive 21-gate verification pipeline.
///
/// Ensures zero client-trusted identity or site data. Attendance is created
/// only after all 21 verification gates pass:
///
/// 1.  Authenticated User Gate
/// 2.  Guard Organization Tenant Gate
/// 3.  Guard Role Authorization Gate (UserRole.guard)
/// 4.  Guard Profile Existence Gate
/// 5.  Guard Organization Match Gate
/// 6.  Guard Active Status Gate
/// 7.  Shift Identifier Gate
/// 8.  Shift Existence Gate
/// 9.  Shift Organization Match Gate
/// 10. Shift Guard Assignment Gate
/// 11. Shift Not Cancelled Gate
/// 12. Site Existence Gate (resolved from shift)
/// 13. Site Organization Match Gate
/// 14. Site Active Status Gate
/// 15. Site Coordinates and Radius Gate
/// 16. Device GPS Location Acquisition Gate
/// 17. Device Coordinates Bounds and Accuracy Gate
/// 18. QR Code Decryption and Validation Gate
/// 19. QR Site Match Gate (qrSite == shiftSite)
/// 20. Geofence Distance & Accuracy Gate (accuracy <= 50m, inside radius)
/// 21. Existing Active Attendance & Atomic Persistence Gate (deterministic ID `att_${shiftId}`)
class SecureCheckInUseCase {
  final UserProfile? Function() _getCurrentUserProfile;
  final GuardRepository _guardRepository;
  final ShiftRepository _shiftRepository;
  final SiteRepository _siteRepository;
  final LocationService _locationService;
  final QrValidator _qrValidator;
  final GeofenceEngine _geofenceEngine;
  final AttendanceRepository _attendanceRepository;

  const SecureCheckInUseCase({
    required UserProfile? Function() getCurrentUserProfile,
    required GuardRepository guardRepository,
    required ShiftRepository shiftRepository,
    required SiteRepository siteRepository,
    required LocationService locationService,
    required QrValidator qrValidator,
    required GeofenceEngine geofenceEngine,
    required AttendanceRepository attendanceRepository,
  })  : _getCurrentUserProfile = getCurrentUserProfile,
        _guardRepository = guardRepository,
        _shiftRepository = shiftRepository,
        _siteRepository = siteRepository,
        _locationService = locationService,
        _qrValidator = qrValidator,
        _geofenceEngine = geofenceEngine,
        _attendanceRepository = attendanceRepository;

  /// Executes the 21-gate secure check-in pipeline against [request].
  ///
  /// Throws a typed subclass of [CheckInFailure] immediately upon any verification gate failure.
  Future<CheckInResult> execute(CheckInRequest request) async {
    // -------------------------------------------------------------------------
    // Gate 1: Authenticated User Gate
    // -------------------------------------------------------------------------
    final profile = _getCurrentUserProfile();
    if (profile == null || profile.uid.trim().isEmpty) {
      throw const UnauthenticatedFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 2: Guard Organization Tenant Gate
    // -------------------------------------------------------------------------
    if (profile.organizationId.trim().isEmpty) {
      throw const UnauthenticatedFailure(
        'User profile lacks valid organization identifier.',
      );
    }

    // -------------------------------------------------------------------------
    // Gate 3: Guard Role Authorization Gate (GUARD role required)
    // -------------------------------------------------------------------------
    if (profile.role != UserRole.guard) {
      throw const UnauthorizedRoleFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 4: Guard Profile Existence Gate
    // -------------------------------------------------------------------------
    final guard = await _guardRepository.getGuard(
      organizationId: profile.organizationId,
      guardId: profile.uid,
    );
    if (guard == null) {
      throw const CheckInGuardNotFoundFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 5: Guard Organization Match Gate
    // -------------------------------------------------------------------------
    if (guard.organizationId != profile.organizationId) {
      throw const GuardOrgMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 6: Guard Active Status Gate
    // -------------------------------------------------------------------------
    if (guard.status != GuardStatus.active) {
      throw const InactiveGuardFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 7: Shift Identifier Gate
    // -------------------------------------------------------------------------
    if (request.shiftId.trim().isEmpty) {
      throw const CheckInShiftNotFoundFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 8: Shift Existence Gate
    // -------------------------------------------------------------------------
    final shift = await _shiftRepository.getShift(
      organizationId: profile.organizationId,
      shiftId: request.shiftId.trim(),
    );
    if (shift == null) {
      throw const CheckInShiftNotFoundFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 9: Shift Organization Match Gate
    // -------------------------------------------------------------------------
    if (shift.organizationId != profile.organizationId) {
      throw const ShiftOrgMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 10: Shift Guard Assignment Gate
    // -------------------------------------------------------------------------
    if (shift.guardId != guard.guardId) {
      throw const ShiftGuardMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 11: Shift Not Cancelled Gate
    // -------------------------------------------------------------------------
    if (shift.status == ShiftStatus.cancelled) {
      throw const ShiftCancelledFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 12: Site Existence Gate (resolved strictly from shift, never from client)
    // -------------------------------------------------------------------------
    final site = await _siteRepository.getSite(
      organizationId: profile.organizationId,
      siteId: shift.siteId,
    );
    if (site == null) {
      throw const CheckInSiteNotFoundFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 13: Site Organization Match Gate
    // -------------------------------------------------------------------------
    if (site.organizationId != profile.organizationId) {
      throw const SiteOrgMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 14: Site Active Status Gate
    // -------------------------------------------------------------------------
    if (site.status != SiteStatus.active) {
      throw const InactiveSiteFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 15: Site Coordinates and Geofence Radius Gate
    // -------------------------------------------------------------------------
    if (!site.latitude.isFinite ||
        site.latitude < -90.0 ||
        site.latitude > 90.0 ||
        !site.longitude.isFinite ||
        site.longitude < -180.0 ||
        site.longitude > 180.0 ||
        !site.geofenceRadius.isFinite ||
        site.geofenceRadius <= 0.0) {
      throw const InvalidSiteCoordinatesFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 16: Device GPS Location Acquisition Gate
    // -------------------------------------------------------------------------
    final LocationData location;
    try {
      location = await _locationService.getCurrentLocation();
    } on loc_fail.LocationServiceDisabledFailure {
      throw const LocationDisabledFailure();
    } on loc_fail.LocationPermissionDeniedFailure {
      throw const LocationPermissionDeniedFailure();
    } on loc_fail.LocationPermissionPermanentlyDeniedFailure {
      throw const LocationPermissionDeniedFailure(
        'Location permission permanently denied. Please enable in device settings.',
      );
    } on loc_fail.LocationTimeoutFailure {
      throw const LocationUnavailableFailure('Location acquisition timed out.');
    } on loc_fail.InvalidLocationCoordinatesFailure {
      throw const InvalidLocationCoordinatesFailure();
    } catch (e) {
      throw LocationUnavailableFailure(e.toString());
    }

    // -------------------------------------------------------------------------
    // Gate 17: Device Coordinates Bounds and Accuracy Gate
    // -------------------------------------------------------------------------
    if (!location.latitude.isFinite ||
        location.latitude < -90.0 ||
        location.latitude > 90.0 ||
        !location.longitude.isFinite ||
        location.longitude < -180.0 ||
        location.longitude > 180.0 ||
        !location.accuracy.isFinite ||
        location.accuracy < 0.0) {
      throw const InvalidLocationCoordinatesFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 18: QR Code Decryption and Validation Gate
    // -------------------------------------------------------------------------
    final qrResult = await _qrValidator.validateRawQr(
      rawQrData: request.rawQrData,
      organizationId: profile.organizationId,
      siteRepository: _siteRepository,
    );

    if (!qrResult.isValid) {
      throw QrValidationFailedFailure(qrResult.message);
    }

    // -------------------------------------------------------------------------
    // Gate 19: QR Site Match Gate (Reject valid QR from another site)
    // -------------------------------------------------------------------------
    if (qrResult.siteId != shift.siteId) {
      throw const QrSiteMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 20: Geofence Distance & Accuracy Gate
    // -------------------------------------------------------------------------
    final geofenceResult = _geofenceEngine.evaluateWithLocationAndSite(
      location: location,
      site: site,
    );

    if (geofenceResult.isPoorAccuracy) {
      throw PoorGpsAccuracyFailure(
        geofenceResult.message ??
            'GPS accuracy (${location.accuracy.toStringAsFixed(1)}m) is too poor for geofence verification.',
      );
    }

    if (geofenceResult.isInvalidInput) {
      throw const InvalidLocationCoordinatesFailure();
    }

    if (geofenceResult.isOutside) {
      throw OutsideGeofenceFailure(
        geofenceResult.message ??
            'Guard is outside site geofence perimeter (${geofenceResult.distanceMeters.toStringAsFixed(1)}m > ${site.geofenceRadius.toStringAsFixed(1)}m).',
      );
    }

    // -------------------------------------------------------------------------
    // Gate 21: Existing Active Attendance & Atomic Persistence Gate
    // -------------------------------------------------------------------------
    final activeAttendance =
        await _attendanceRepository.getActiveAttendanceForGuard(
      organizationId: profile.organizationId,
      guardId: guard.guardId,
    );
    if (activeAttendance != null) {
      if (activeAttendance.shiftId == shift.shiftId) {
        throw const AlreadyCheckedInFailure();
      } else {
        throw AlreadyCheckedInFailure(
          'Guard already has an active check-in session for shift ${activeAttendance.shiftId}. Must check out first.',
        );
      }
    }

    final now = DateTime.now();
    final deterministicAttendanceId = 'att_${shift.shiftId}';

    final attendanceToCreate = AttendanceRecord(
      attendanceId: deterministicAttendanceId,
      organizationId: profile.organizationId,
      shiftId: shift.shiftId,
      siteId: site.siteId,
      guardId: guard.guardId,
      checkInTime: now,
      checkInLocation: location,
      status: AttendanceStatus.active,
      verificationMethod: CheckInVerificationMethod.qrGpsGeofence.toMapString(),
      createdAt: now,
      updatedAt: now,
    );

    final AttendanceRecord persistedRecord;
    try {
      persistedRecord = await _attendanceRepository.checkInGuard(
        record: attendanceToCreate,
      );
    } on AlreadyCheckedInFailure {
      rethrow;
    } catch (e) {
      if (e is CheckInFailure) rethrow;
      throw AttendancePersistenceFailure(e.toString());
    }

    return CheckInResult(
      record: persistedRecord,
      shift: shift,
      site: site,
      distanceMeters: geofenceResult.distanceMeters,
      accuracyMeters: location.accuracy,
      verifiedAt: now,
      verificationMethod: CheckInVerificationMethod.qrGpsGeofence.toMapString(),
    );
  }
}
