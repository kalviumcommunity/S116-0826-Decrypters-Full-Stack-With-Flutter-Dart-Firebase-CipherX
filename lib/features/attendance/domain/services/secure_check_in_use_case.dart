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

/// Secure Check-In Use Case executing the 21-gate verification pipeline.
///
/// Ensures zero client-trusted identity or site data. Attendance is created
/// only after all authentication, role, guard, shift, site, location, QR,
/// geofence, and duplicate-prevention gates pass.
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

  /// Executes the secure check-in pipeline against [request].
  ///
  /// Throws a typed subclass of [CheckInFailure] immediately upon any verification gate failure.
  Future<CheckInResult> execute(CheckInRequest request) async {
    // -------------------------------------------------------------------------
    // Gate 1: Authenticated User & Profile Check
    // -------------------------------------------------------------------------
    final profile = _getCurrentUserProfile();
    if (profile == null ||
        profile.uid.trim().isEmpty ||
        profile.organizationId.trim().isEmpty) {
      throw const UnauthenticatedFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 2: Role Authorization Gate (GUARD role required)
    // -------------------------------------------------------------------------
    if (profile.role != UserRole.guard) {
      throw const UnauthorizedRoleFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 3: Guard Verification Gate
    // -------------------------------------------------------------------------
    final guard = await _guardRepository.getGuard(
      organizationId: profile.organizationId,
      guardId: profile.uid,
    );
    if (guard == null) {
      throw const CheckInGuardNotFoundFailure();
    }
    if (guard.organizationId != profile.organizationId) {
      throw const GuardOrgMismatchFailure();
    }
    if (guard.status != GuardStatus.active) {
      throw const InactiveGuardFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 4: Shift Verification Gate
    // -------------------------------------------------------------------------
    if (request.shiftId.trim().isEmpty) {
      throw const CheckInShiftNotFoundFailure();
    }

    final shift = await _shiftRepository.getShift(
      organizationId: profile.organizationId,
      shiftId: request.shiftId.trim(),
    );
    if (shift == null) {
      throw const CheckInShiftNotFoundFailure();
    }
    if (shift.organizationId != profile.organizationId) {
      throw const ShiftOrgMismatchFailure();
    }
    if (shift.guardId != guard.guardId) {
      throw const ShiftGuardMismatchFailure();
    }
    if (shift.status == ShiftStatus.cancelled) {
      throw const ShiftCancelledFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 5: Site Resolution Gate (strictly resolved from shift, never from client)
    // -------------------------------------------------------------------------
    final site = await _siteRepository.getSite(
      organizationId: profile.organizationId,
      siteId: shift.siteId,
    );
    if (site == null) {
      throw const CheckInSiteNotFoundFailure();
    }
    if (site.organizationId != profile.organizationId) {
      throw const SiteOrgMismatchFailure();
    }
    if (site.status != SiteStatus.active) {
      throw const InactiveSiteFailure();
    }

    // Validate site coordinates and geofence radius
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
    // Gate 6: Device GPS Location Acquisition Gate
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

    // Validate location coordinates
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
    // Gate 7: QR Validation & Site Matching Gate
    // -------------------------------------------------------------------------
    final qrResult = await _qrValidator.validateRawQr(
      rawQrData: request.rawQrData,
      organizationId: profile.organizationId,
      siteRepository: _siteRepository,
    );

    if (!qrResult.isValid) {
      throw QrValidationFailedFailure(qrResult.message);
    }

    // Ensure QR site matches shift site (Reject Site B QR for Site A shift)
    if (qrResult.siteId != shift.siteId) {
      throw const QrSiteMismatchFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 8: Geofence Verification Gate
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
    // Gate 9: Duplicate Attendance Check Gate
    // -------------------------------------------------------------------------
    final activeAttendance =
        await _attendanceRepository.getActiveAttendanceForGuard(
      organizationId: profile.organizationId,
      guardId: guard.guardId,
    );
    if (activeAttendance != null && activeAttendance.shiftId == shift.shiftId) {
      throw const AlreadyCheckedInFailure();
    }

    // -------------------------------------------------------------------------
    // Gate 10: Atomic Attendance Creation Gate
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // Gate 11: Typed Success Result
    // -------------------------------------------------------------------------
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
