import 'package:meta/meta.dart';

@immutable
class ShiftTime implements Comparable<ShiftTime> {
  final int hour;
  final int minute;

  const ShiftTime({
    required this.hour,
    required this.minute,
  })  : assert(hour >= 0 && hour <= 23, 'Hour must be between 0 and 23'),
        assert(minute >= 0 && minute <= 59, 'Minute must be between 0 and 59');

  static ShiftTime? tryParse(String formatted) {
    try {
      final parts = formatted.trim().split(':');
      if (parts.length != 2) return null;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return null;
      if (h < 0 || h > 23 || m < 0 || m > 59) return null;
      return ShiftTime(hour: h, minute: m);
    } catch (_) {
      return null;
    }
  }

  bool isBefore(ShiftTime other) {
    if (hour < other.hour) return true;
    if (hour == other.hour && minute < other.minute) return true;
    return false;
  }

  bool isAfter(ShiftTime other) {
    if (hour > other.hour) return true;
    if (hour == other.hour && minute > other.minute) return true;
    return false;
  }

  @override
  int compareTo(ShiftTime other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    return minute.compareTo(other.minute);
  }

  String toFormattedString() {
    final hStr = hour.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr';
  }

  String toMapString() => toFormattedString();

  static ShiftTime fromMapString(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid ShiftTime format: $value');
    }
    return parsed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShiftTime && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toFormattedString();
}
