import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';

void main() {
  group('ShiftTime Value Object Tests', () {
    test('creates valid ShiftTime instance', () {
      const time = ShiftTime(hour: 9, minute: 30);
      expect(time.hour, equals(9));
      expect(time.minute, equals(30));
      expect(time.toFormattedString(), equals('09:30'));
    });

    test('throws AssertionError for invalid hours or minutes', () {
      expect(() => ShiftTime(hour: -1, minute: 0), throwsAssertionError);
      expect(() => ShiftTime(hour: 24, minute: 0), throwsAssertionError);
      expect(() => ShiftTime(hour: 12, minute: -1), throwsAssertionError);
      expect(() => ShiftTime(hour: 12, minute: 60), throwsAssertionError);
    });

    test('parses valid time string correctly', () {
      final parsed = ShiftTime.tryParse('14:45');
      expect(parsed, isNotNull);
      expect(parsed!.hour, equals(14));
      expect(parsed.minute, equals(45));
    });

    test('returns null when parsing invalid time string', () {
      expect(ShiftTime.tryParse('invalid'), isNull);
      expect(ShiftTime.tryParse('25:00'), isNull);
      expect(ShiftTime.tryParse('12:60'), isNull);
      expect(ShiftTime.tryParse('12:-5'), isNull);
      expect(ShiftTime.tryParse(''), isNull);
    });

    test('compares ShiftTime ordering correctly (isBefore, isAfter, compareTo)',
        () {
      const t1 = ShiftTime(hour: 9, minute: 0);
      const t2 = ShiftTime(hour: 9, minute: 30);
      const t3 = ShiftTime(hour: 17, minute: 0);

      expect(t1.isBefore(t2), isTrue);
      expect(t2.isBefore(t3), isTrue);
      expect(t3.isBefore(t1), isFalse);

      expect(t3.isAfter(t2), isTrue);
      expect(t2.isAfter(t1), isTrue);
      expect(t1.isAfter(t3), isFalse);

      expect(t1.compareTo(t2), lessThan(0));
      expect(t2.compareTo(t1), greaterThan(0));
      expect(t1.compareTo(t1), equals(0));
    });

    test('supports value equality', () {
      const t1 = ShiftTime(hour: 10, minute: 15);
      const t2 = ShiftTime(hour: 10, minute: 15);
      const t3 = ShiftTime(hour: 10, minute: 16);

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
      expect(t1 == t3, isFalse);
    });
  });
}
