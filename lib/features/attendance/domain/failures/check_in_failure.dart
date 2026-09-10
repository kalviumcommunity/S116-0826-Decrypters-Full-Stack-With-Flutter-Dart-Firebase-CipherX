import 'package:meta/meta.dart';
import 'attendance_failure.dart';

/// Base class for all security-critical check-in failures.
@immutable
abstract class CheckInFailure extends AttendanceFailure {
  const CheckInFailure(super.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInFailure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => Object.hash(runtimeType, message);
}

/// Thrown when no authenticated Firebase session or user profile exists.
class UnauthenticatedFailure extends CheckInFailure {
  const UnauthenticatedFailure([
    super.message = 'Authentication required. Please sign in to check in.',
  ]);
}

/// Thrown when the authenticated user does not have the GUARD role.
class UnauthorizedRoleFailure extends CheckInFailure {
  const UnauthorizedRoleFailure([
    super.message =
        'Access denied. Only active guards can perform shift check-ins.',
  ]);
}

/// Thrown when no guard profile is found for the authenticated user.
class CheckInGuardNotFoundFailure extends CheckInFailure {
  const CheckInGuardNotFoundFailure([
    super.message = 'Guard record not found for the authenticated user.',
  ]);
}

/// Thrown when the guard profile is inactive or suspended.
class InactiveGuardFailure extends CheckInFailure {
  const InactiveGuardFailure([
    super.message =
        'Your guard profile is inactive. Please contact your supervisor.',
  ]);
}

/// Thrown when the guard belongs to a different organization.
class GuardOrgMismatchFailure extends CheckInFailure {
  const GuardOrgMismatchFailure([
    super.message =
        'Tenant isolation violation: Guard does not belong to this organization.',
  ]);
}

/// Thrown when the target shift does not exist.
class CheckInShiftNotFoundFailure extends CheckInFailure {
  const CheckInShiftNotFoundFailure([
    super.message = 'Target shift was not found.',
  ]);
}

/// Thrown when the shift belongs to another organization.
class ShiftOrgMismatchFailure extends CheckInFailure {
  const ShiftOrgMismatchFailure([
    super.message =
        'Tenant isolation violation: Shift belongs to another organization.',
  ]);
}

/// Thrown when the shift is assigned to a different guard.
class ShiftGuardMismatchFailure extends CheckInFailure {
  const ShiftGuardMismatchFailure([
    super.message =
        'Security violation: This shift is assigned to another guard.',
  ]);
}

/// Thrown when the shift has been cancelled.
class ShiftCancelledFailure extends CheckInFailure {
  const ShiftCancelledFailure([
    super.message =
        'This shift has been cancelled and cannot accept attendance.',
  ]);
}

/// Thrown when the shift's associated site cannot be found.
class CheckInSiteNotFoundFailure extends CheckInFailure {
  const CheckInSiteNotFoundFailure([
    super.message = 'Assigned site was not found.',
  ]);
}

/// Thrown when the shift's associated site is inactive.
class InactiveSiteFailure extends CheckInFailure {
  const InactiveSiteFailure([
    super.message =
        'Site is currently inactive. Attendance cannot be recorded.',
  ]);
}

/// Thrown when the site belongs to a different organization.
class SiteOrgMismatchFailure extends CheckInFailure {
  const SiteOrgMismatchFailure([
    super.message =
        'Tenant isolation violation: Site belongs to another organization.',
  ]);
}

/// Thrown when the site coordinates or geofence radius are invalid or corrupt.
class InvalidSiteCoordinatesFailure extends CheckInFailure {
  const InvalidSiteCoordinatesFailure([
    super.message =
        'Site configuration error: invalid geofence coordinates or radius.',
  ]);
}

/// Thrown when the scanned QR code cannot be parsed or validated.
class QrValidationFailedFailure extends CheckInFailure {
  const QrValidationFailedFailure([
    super.message = 'QR verification failed: invalid or unsupported QR code.',
  ]);
}

/// Thrown when the scanned QR belongs to a different site than the shift.
class QrSiteMismatchFailure extends CheckInFailure {
  const QrSiteMismatchFailure([
    super.message =
        'Security violation: Scanned QR code does not match the shift site.',
  ]);
}

/// Thrown when device location services are disabled.
class LocationDisabledFailure extends CheckInFailure {
  const LocationDisabledFailure([
    super.message =
        'Location services are disabled. Please enable GPS to check in.',
  ]);
}

/// Thrown when device location permissions are denied.
class LocationPermissionDeniedFailure extends CheckInFailure {
  const LocationPermissionDeniedFailure([
    super.message =
        'Location permission is required to verify your presence at the site.',
  ]);
}

/// Thrown when the device location cannot be acquired.
class LocationUnavailableFailure extends CheckInFailure {
  const LocationUnavailableFailure([
    super.message =
        'Unable to acquire current device location. Please try again.',
  ]);
}

/// Thrown when the acquired GPS coordinates are out of bounds or corrupt.
class InvalidLocationCoordinatesFailure extends CheckInFailure {
  const InvalidLocationCoordinatesFailure([
    super.message = 'Invalid GPS coordinates acquired from device.',
  ]);
}

/// Thrown when GPS accuracy is too poor to reliably verify geofence presence.
class PoorGpsAccuracyFailure extends CheckInFailure {
  const PoorGpsAccuracyFailure([
    super.message =
        'GPS accuracy is insufficient for geofence verification. Please move to an open area and retry.',
  ]);
}

/// Thrown when the guard is outside the site geofence radius.
class OutsideGeofenceFailure extends CheckInFailure {
  const OutsideGeofenceFailure([
    super.message =
        'You are outside the site geofence perimeter. Check-in must be performed on site.',
  ]);
}

/// Thrown when an attendance record already exists for the relevant shift.
class AlreadyCheckedInFailure extends CheckInFailure {
  const AlreadyCheckedInFailure([
    super.message =
        'Attendance check-in has already been recorded for this shift.',
  ]);
}

/// Thrown when Firestore write fails or network issues prevent persistence.
class AttendancePersistenceFailure extends CheckInFailure {
  const AttendancePersistenceFailure([
    super.message =
        'Failed to record attendance. Please check connection and retry.',
  ]);
}
