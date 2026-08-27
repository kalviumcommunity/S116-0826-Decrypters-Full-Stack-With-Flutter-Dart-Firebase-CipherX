import 'package:flutter/foundation.dart';

enum ShiftStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String toMapString() => name;

  static ShiftStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return ShiftStatus.scheduled;
      case 'in_progress':
      case 'inprogress':
        return ShiftStatus.inProgress;
      case 'completed':
        return ShiftStatus.completed;
      case 'cancelled':
        return ShiftStatus.cancelled;
      default:
        return ShiftStatus.scheduled;
    }
  }
}

@immutable
class Shift {
  final String shiftId;
  final String organizationId;
  final String guardId;
  final String siteId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final ShiftStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shift({
    required this.shiftId,
    required this.organizationId,
    required this.guardId,
    required this.siteId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  Shift copyWith({
    String? shiftId,
    String? organizationId,
    String? guardId,
    String? siteId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shift(
      shiftId: shiftId ?? this.shiftId,
      organizationId: organizationId ?? this.organizationId,
      guardId: guardId ?? this.guardId,
      siteId: siteId ?? this.siteId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'organizationId': organizationId,
      'guardId': guardId,
      'siteId': siteId,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return null;
      }
    }

    return Shift(
      shiftId: map['shiftId'] as String? ?? id,
      organizationId: map['organizationId'] as String? ?? '',
      guardId: map['guardId'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      date: parseDate(map['date']) ?? DateTime.now(),
      startTime: parseDate(map['startTime']) ?? DateTime.now(),
      endTime: parseDate(map['endTime']) ?? DateTime.now(),
      status: ShiftStatus.fromMapString(map['status'] as String? ?? 'scheduled'),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shift &&
        other.shiftId == shiftId &&
        other.organizationId == organizationId &&
        other.guardId == guardId &&
        other.siteId == siteId &&
        other.date == date &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      shiftId,
      organizationId,
      guardId,
      siteId,
      date,
      startTime,
      endTime,
      status,
      createdAt,
      updatedAt,
    );
  }
}
