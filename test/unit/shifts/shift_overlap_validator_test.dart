import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/shifts/domain/validators/shift_overlap_validator.dart';

void main() {
  group('ShiftOverlapValidator Unit Tests — Interval Matrix', () {
    ShiftTime makeTime(int hour, [int minute = 0]) {
      return ShiftTime(hour: hour, minute: minute);
    }

    test('08:00–10:00 overlaps 09:00–17:00 (Partial start overlap) -> CONFLICT',
        () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(8),
        endA: makeTime(10),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isTrue);
    });

    test('10:00–12:00 overlaps 09:00–17:00 (Enclosed shift) -> CONFLICT', () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(10),
        endA: makeTime(12),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isTrue);
    });

    test('16:00–18:00 overlaps 09:00–17:00 (Partial end overlap) -> CONFLICT',
        () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(16),
        endA: makeTime(18),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isTrue);
    });

    test('09:00–17:00 overlaps 09:00–17:00 (Identical interval) -> CONFLICT',
        () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(9),
        endA: makeTime(17),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isTrue);
    });

    test('08:00–18:00 overlaps 09:00–17:00 (Full enclosure) -> CONFLICT', () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(8),
        endA: makeTime(18),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isTrue);
    });

    test('17:00–19:00 after 09:00–17:00 (Exact boundary adjacency) -> ALLOWED',
        () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(17),
        endA: makeTime(19),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isFalse);
    });

    test('07:00–09:00 before 09:00–17:00 (Exact boundary adjacency) -> ALLOWED',
        () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(7),
        endA: makeTime(9),
        startB: makeTime(9),
        endB: makeTime(17),
      );
      expect(overlaps, isFalse);
    });

    test('09:00–12:00 and 12:00–17:00 -> ALLOWED', () {
      final overlaps = ShiftOverlapValidator.hasShiftOverlap(
        startA: makeTime(9),
        endA: makeTime(12),
        startB: makeTime(12),
        endB: makeTime(17),
      );
      expect(overlaps, isFalse);
    });
  });
}
