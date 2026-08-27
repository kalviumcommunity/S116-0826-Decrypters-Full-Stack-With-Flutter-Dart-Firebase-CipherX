import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum ShiftStatus {
  scheduled,
  inProgress,
  completed,
  missed,
  cancelled;

  String toMapString() {
    switch (this) {
      case ShiftStatus.scheduled:
        return 'scheduled';
      case ShiftStatus.inProgress:
        return 'in_progress';
      case ShiftStatus.completed:
        return 'completed';
      case ShiftStatus.missed:
        return 'missed';
      case ShiftStatus.cancelled:
        return 'cancelled';
    }
  }

  static ShiftStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return ShiftStatus.scheduled;
      case 'in_progress':
      case 'inprogress':
        return ShiftStatus.inProgress;
      case 'completed':
        return ShiftStatus.completed;
      case 'missed':
        return ShiftStatus.missed;
      case 'cancelled':
      case 'canceled':
        return ShiftStatus.cancelled;
      default:
        return ShiftStatus.scheduled;
    }
  }
}

@immutable
class Shift {
  final String id;
  final String organizationId;
  final String siteId;
  final String siteName;
  final String guardId;
  final String guardName;
  final String supervisorId;
  final String shiftDate; // YYYY-MM-DD
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shift({
    required this.id,
    required this.organizationId,
    required this.siteId,
    required this.siteName,
    required this.guardId,
    required this.guardName,
    this.supervisorId = '',
    required this.shiftDate,
    required this.startTime,
    required this.endTime,
    this.status = ShiftStatus.scheduled,
    this.createdAt,
    this.updatedAt,
  });

  Shift copyWith({
    String? id,
    String? organizationId,
    String? siteId,
    String? siteName,
    String? guardId,
    String? guardName,
    String? supervisorId,
    String? shiftDate,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      guardId: guardId ?? this.guardId,
      guardName: guardName ?? this.guardName,
      supervisorId: supervisorId ?? this.supervisorId,
      shiftDate: shiftDate ?? this.shiftDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shiftId': id,
      'organizationId': organizationId,
      'siteId': siteId,
      'siteName': siteName,
      'guardId': guardId,
      'guardName': guardName,
      'supervisorId': supervisorId,
      'shiftDate': shiftDate,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val, DateTime fallback) {
      if (val == null) return fallback;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final now = DateTime.now();
    final statusStr = map['status'] as String? ?? 'scheduled';

    return Shift(
      id: map['id'] as String? ?? map['shiftId'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      siteName: map['siteName'] as String? ?? '',
      guardId: map['guardId'] as String? ?? '',
      guardName: map['guardName'] as String? ?? '',
      supervisorId: map['supervisorId'] as String? ?? '',
      shiftDate: map['shiftDate'] as String? ?? '',
      startTime: parseDate(map['startTime'], now),
      endTime: parseDate(map['endTime'], now.add(const Duration(hours: 8))),
      status: ShiftStatus.fromMapString(statusStr),
      createdAt: parseNullableDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shift &&
        other.id == id &&
        other.organizationId == organizationId &&
        other.siteId == siteId &&
        other.siteName == siteName &&
        other.guardId == guardId &&
        other.guardName == guardName &&
        other.supervisorId == supervisorId &&
        other.shiftDate == shiftDate &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      organizationId,
      siteId,
      siteName,
      guardId,
      guardName,
      supervisorId,
      shiftDate,
      startTime,
      endTime,
      status,
      createdAt,
      updatedAt,
    );
  }
}
