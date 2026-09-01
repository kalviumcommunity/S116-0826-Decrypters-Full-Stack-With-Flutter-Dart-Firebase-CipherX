import 'package:meta/meta.dart';
import '../../../location/domain/entities/location_data.dart';

enum AttendanceStatus {
  active,
  completed,
  flagged;

  String toMapString() => name;

  static AttendanceStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
      case 'in_progress':
      case 'inprogress':
        return AttendanceStatus.active;
      case 'completed':
      case 'checked_out':
      case 'checkedout':
        return AttendanceStatus.completed;
      case 'flagged':
        return AttendanceStatus.flagged;
      default:
        return AttendanceStatus.active;
    }
  }
}

@immutable
class AttendanceRecord {
  final String attendanceId;
  final String organizationId;
  final String shiftId;
  final String siteId;
  final String guardId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final LocationData? checkInLocation;
  final LocationData? checkOutLocation;
  final AttendanceStatus status;
  final String verificationMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AttendanceRecord({
    required this.attendanceId,
    required this.organizationId,
    required this.shiftId,
    required this.siteId,
    required this.guardId,
    required this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.status = AttendanceStatus.active,
    this.verificationMethod = 'qr_gps',
    this.createdAt,
    this.updatedAt,
  });

  bool get isCheckedOut =>
      checkOutTime != null || status == AttendanceStatus.completed;

  AttendanceRecord checkOut({
    required LocationData location,
    DateTime? timestamp,
  }) {
    if (isCheckedOut) {
      // Duplicate check-out prevention: do not overwrite existing check-out data
      return this;
    }
    final now = timestamp ?? DateTime.now();
    return copyWith(
      checkOutTime: checkOutTime ?? now,
      checkOutLocation: checkOutLocation ?? location,
      status: AttendanceStatus.completed,
      updatedAt: now,
    );
  }

  AttendanceRecord copyWith({
    String? attendanceId,
    String? organizationId,
    String? shiftId,
    String? siteId,
    String? guardId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    LocationData? checkInLocation,
    LocationData? checkOutLocation,
    AttendanceStatus? status,
    String? verificationMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      attendanceId: attendanceId ?? this.attendanceId,
      organizationId: organizationId ?? this.organizationId,
      shiftId: shiftId ?? this.shiftId,
      siteId: siteId ?? this.siteId,
      guardId: guardId ?? this.guardId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      status: status ?? this.status,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'attendanceId': attendanceId,
      'organizationId': organizationId,
      'shiftId': shiftId,
      'siteId': siteId,
      'guardId': guardId,
      'checkInTime': checkInTime.toIso8601String(),
      if (checkOutTime != null) 'checkOutTime': checkOutTime!.toIso8601String(),
      if (checkInLocation != null) 'checkInLocation': checkInLocation!.toMap(),
      if (checkOutLocation != null)
        'checkOutLocation': checkOutLocation!.toMap(),
      'status': status.toMapString(),
      'verificationMethod': verificationMethod,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory AttendanceRecord.fromMap(
    Map<String, dynamic> map, [
    String? fallbackId,
  ]) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return DateTime.now();
      }
    }

    final rawCheckIn = parseDate(map['checkInTime']);
    final rawCheckOut =
        map['checkOutTime'] != null ? parseDate(map['checkOutTime']) : null;

    LocationData? parseLocation(dynamic locMap) {
      if (locMap is Map<String, dynamic>) {
        try {
          return LocationData.fromMap(locMap);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return AttendanceRecord(
      attendanceId: (map['attendanceId'] as String?) ?? fallbackId ?? '',
      organizationId: (map['organizationId'] as String?) ?? '',
      shiftId: (map['shiftId'] as String?) ?? '',
      siteId: (map['siteId'] as String?) ?? '',
      guardId: (map['guardId'] as String?) ?? '',
      checkInTime: rawCheckIn,
      checkOutTime: rawCheckOut,
      checkInLocation: parseLocation(map['checkInLocation']),
      checkOutLocation: parseLocation(map['checkOutLocation']),
      status: AttendanceStatus.fromMapString(
          (map['status'] as String?) ?? 'active'),
      verificationMethod: (map['verificationMethod'] as String?) ?? 'qr_gps',
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord &&
        other.attendanceId == attendanceId &&
        other.organizationId == organizationId &&
        other.shiftId == shiftId &&
        other.siteId == siteId &&
        other.guardId == guardId &&
        other.checkInTime == checkInTime &&
        other.checkOutTime == checkOutTime &&
        other.status == status &&
        other.verificationMethod == verificationMethod;
  }

  @override
  int get hashCode {
    return Object.hash(
      attendanceId,
      organizationId,
      shiftId,
      siteId,
      guardId,
      checkInTime,
      checkOutTime,
      status,
      verificationMethod,
    );
  }
}
