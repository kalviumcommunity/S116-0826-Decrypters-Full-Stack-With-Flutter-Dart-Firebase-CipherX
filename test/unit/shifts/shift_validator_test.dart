import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:cipher_x/features/shifts/domain/validators/shift_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShiftValidator Unit Tests', () {
    test('validateGuard returns error when guardId is empty or null', () {
      expect(
          ShiftValidator.validateGuard(null), equals('Please select a guard.'));
      expect(
          ShiftValidator.validateGuard(''), equals('Please select a guard.'));
      expect(ShiftValidator.validateGuard('   '),
          equals('Please select a guard.'));
      expect(ShiftValidator.validateGuard('guard-123'), isNull);
    });

    test('validateSite returns error when siteId is empty or null', () {
      expect(
          ShiftValidator.validateSite(null), equals('Please select a site.'));
      expect(ShiftValidator.validateSite(''), equals('Please select a site.'));
      expect(ShiftValidator.validateSite('site-456'), isNull);
    });

    test('validateDate returns error when date is null', () {
      expect(ShiftValidator.validateDate(null),
          equals('Please select a shift date.'));
      expect(ShiftValidator.validateDate(DateTime.now()), isNull);
    });

    test('validateStartTime returns error when startTime is null', () {
      expect(ShiftValidator.validateStartTime(null),
          equals('Please select a start time.'));
      expect(ShiftValidator.validateStartTime(DateTime.now()), isNull);
    });

    test('validateEndTime returns error when endTime is null', () {
      expect(ShiftValidator.validateEndTime(null),
          equals('Please select an end time.'));
      expect(ShiftValidator.validateEndTime(DateTime.now()), isNull);
    });

    test(
        'validateTimeOrdering rejects end time preceding or equal to start time',
        () {
      final start = DateTime(2026, 8, 27, 9, 0);
      final endBefore = DateTime(2026, 8, 27, 8, 0);
      final endEqual = DateTime(2026, 8, 27, 9, 0);
      final endAfter = DateTime(2026, 8, 27, 17, 0);

      expect(
        ShiftValidator.validateTimeOrdering(start, endBefore),
        equals('End time must be after start time.'),
      );
      expect(
        ShiftValidator.validateTimeOrdering(start, endEqual),
        equals('End time must be after start time.'),
      );
      expect(ShiftValidator.validateTimeOrdering(start, endAfter), isNull);
    });

    test(
        'validate throws ShiftValidationFailure on missing fields or invalid range',
        () {
      final start = DateTime(2026, 8, 27, 9, 0);
      final end = DateTime(2026, 8, 27, 17, 0);

      expect(
        () => ShiftValidator.validate(
          guardId: null,
          siteId: 'site-1',
          date: DateTime(2026, 8, 27),
          startTime: start,
          endTime: end,
        ),
        throwsA(isA<ShiftValidationFailure>()),
      );

      expect(
        () => ShiftValidator.validate(
          guardId: 'guard-1',
          siteId: null,
          date: DateTime(2026, 8, 27),
          startTime: start,
          endTime: end,
        ),
        throwsA(isA<ShiftValidationFailure>()),
      );

      expect(
        () => ShiftValidator.validate(
          guardId: 'guard-1',
          siteId: 'site-1',
          date: DateTime(2026, 8, 27),
          startTime: start,
          endTime: start, // Same start and end
        ),
        throwsA(isA<ShiftValidationFailure>()),
      );

      expect(
        () => ShiftValidator.validate(
          guardId: 'guard-1',
          siteId: 'site-1',
          date: DateTime(2026, 8, 27),
          startTime: start,
          endTime: end,
        ),
        returnsNormally,
      );
    });
  });
}
