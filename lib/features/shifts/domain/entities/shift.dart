import 'package:meta/meta.dart';
import 'shift_time.dart';

enum ShiftStatus {
  scheduled,
  active,
  completed,
  cancelled;

  String toMapString() => name;

  static ShiftStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'scheduled':
        return ShiftStatus.scheduled;
      case 'active':
        return ShiftStatus.active;
      case 'completed':
        return ShiftStatus.completed;
      case 'cancelled':
        return ShiftStatus.cancelled;
      default:
        throw FormatException('Invalid ShiftStatus value: $value');
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
  final ShiftTime startTime;
  final ShiftTime endTime;
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
    this.status = ShiftStatus.scheduled,
    this.createdAt,
    this.updatedAt,
  });

  Shift copyWith({
    String? shiftId,
    String? organizationId,
    String? guardId,
    String? siteId,
    DateTime? date,
    ShiftTime? startTime,
    ShiftTime? endTime,
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

  Shift activate({DateTime? updatedAt}) {
    return copyWith(
      status: ShiftStatus.active,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Shift complete({DateTime? updatedAt}) {
    return copyWith(
      status: ShiftStatus.completed,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Shift cancel({DateTime? updatedAt}) {
    return copyWith(
      status: ShiftStatus.cancelled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'organizationId': organizationId,
      'guardId': guardId,
      'siteId': siteId,
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime.toMapString(),
      'endTime': endTime.toMapString(),
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      try {
        return (val as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      if (val is String) return DateTime.tryParse(val);
      try {
        return (val as dynamic).toDate();
      } catch (_) {
        return null;
      }
    }

    final rawDate = parseDate(map['date']);
    final dateOnly = DateTime.utc(rawDate.year, rawDate.month, rawDate.day);

    final startTimeStr = map['startTime'] as String? ?? '00:00';
    final endTimeStr = map['endTime'] as String? ?? '00:00';

    return Shift(
      shiftId: map['shiftId'] as String? ?? map['id'] as String? ?? '',
      organizationId: map['organizationId'] as String? ?? '',
      guardId: map['guardId'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      date: dateOnly,
      startTime: ShiftTime.fromMapString(startTimeStr),
      endTime: ShiftTime.fromMapString(endTimeStr),
      status:
          ShiftStatus.fromMapString(map['status'] as String? ?? 'scheduled'),
      createdAt: parseNullableDate(map['createdAt']),
      updatedAt: parseNullableDate(map['updatedAt']),
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
        other.date.year == date.year &&
        other.date.month == date.month &&
        other.date.day == date.day &&
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
      date.year,
      date.month,
      date.day,
      startTime,
      endTime,
      status,
      createdAt,
      updatedAt,
    );
  }
}
