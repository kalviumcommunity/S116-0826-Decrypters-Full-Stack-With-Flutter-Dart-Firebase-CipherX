import 'package:meta/meta.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../sites/domain/entities/site.dart';
import 'attendance_record.dart';

/// Supported check-in verification methods.
enum CheckInVerificationMethod {
  qrGpsGeofence;

  String toMapString() {
    switch (this) {
      case CheckInVerificationMethod.qrGpsGeofence:
        return 'qr_gps_geofence';
    }
  }

  static CheckInVerificationMethod fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'qr_gps_geofence':
      case 'qr_gps':
        return CheckInVerificationMethod.qrGpsGeofence;
      default:
        return CheckInVerificationMethod.qrGpsGeofence;
    }
  }
}

/// Typed request for initiating a secure check-in operation.
@immutable
class CheckInRequest {
  final String shiftId;
  final String rawQrData;

  const CheckInRequest({
    required this.shiftId,
    required this.rawQrData,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInRequest &&
          runtimeType == other.runtimeType &&
          shiftId == other.shiftId &&
          rawQrData == other.rawQrData;

  @override
  int get hashCode => Object.hash(shiftId, rawQrData);

  @override
  String toString() =>
      'CheckInRequest(shiftId: $shiftId, rawQrData: [PROTECTED])';
}

/// Typed, authoritative result returned upon a successful secure check-in pipeline completion.
@immutable
class CheckInResult {
  final AttendanceRecord record;
  final Shift shift;
  final Site site;
  final double distanceMeters;
  final double accuracyMeters;
  final DateTime verifiedAt;
  final String verificationMethod;

  const CheckInResult({
    required this.record,
    required this.shift,
    required this.site,
    required this.distanceMeters,
    required this.accuracyMeters,
    required this.verifiedAt,
    this.verificationMethod = 'qr_gps_geofence',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckInResult &&
          runtimeType == other.runtimeType &&
          record == other.record &&
          shift == other.shift &&
          site == other.site &&
          distanceMeters == other.distanceMeters &&
          accuracyMeters == other.accuracyMeters &&
          verifiedAt == other.verifiedAt &&
          verificationMethod == other.verificationMethod;

  @override
  int get hashCode => Object.hash(
        record,
        shift,
        site,
        distanceMeters,
        accuracyMeters,
        verifiedAt,
        verificationMethod,
      );

  @override
  String toString() =>
      'CheckInResult(recordId: ${record.attendanceId}, shiftId: ${shift.shiftId}, siteId: ${site.siteId}, distance: ${distanceMeters.toStringAsFixed(1)}m, accuracy: ${accuracyMeters.toStringAsFixed(1)}m)';
}
