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
      case 'in_progress':
      case 'inprogress':
        return ShiftStatus.active;
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

  Shift activate() {
    return copyWith(
      status: ShiftStatus.active,
      updatedAt: DateTime.now(),
    );
  }

  Shift complete() {
    return copyWith(
      status: ShiftStatus.completed,
      updatedAt: DateTime.now(),
    );
  }

  Shift cancel() {
    return copyWith(
      status: ShiftStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

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

  Map<String, dynamic> toMap() {
    return {
      'shiftId': shiftId,
      'organizationId': organizationId,
      'guardId': guardId,
      'siteId': siteId,
      'date': DateTime.utc(date.year, date.month, date.day).toIso8601String(),
      'startTime': startTime.toMapString(),
      'endTime': endTime.toMapString(),
      'status': status.toMapString(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory Shift.fromMap(Map<String, dynamic> map, [String? fallbackId]) {
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

    final rawDate = parseDate(map['date']);
    final normDate = DateTime.utc(rawDate.year, rawDate.month, rawDate.day);

    final rawStart = map['startTime'];
    final startShiftTime = rawStart is String
        ? ShiftTime.fromMapString(rawStart)
        : const ShiftTime(hour: 9, minute: 0);

    final rawEnd = map['endTime'];
    final endShiftTime = rawEnd is String
        ? ShiftTime.fromMapString(rawEnd)
        : const ShiftTime(hour: 17, minute: 0);

    return Shift(
      shiftId: (map['shiftId'] as String?) ?? fallbackId ?? '',
      organizationId: (map['organizationId'] as String?) ?? '',
      guardId: (map['guardId'] as String?) ?? '',
      siteId: (map['siteId'] as String?) ?? '',
      date: normDate,
      startTime: startShiftTime,
      endTime: endShiftTime,
      status:
          ShiftStatus.fromMapString((map['status'] as String?) ?? 'scheduled'),
      createdAt: map['createdAt'] != null ? parseDate(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
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
        other.status == status;
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
    );
  }
}
