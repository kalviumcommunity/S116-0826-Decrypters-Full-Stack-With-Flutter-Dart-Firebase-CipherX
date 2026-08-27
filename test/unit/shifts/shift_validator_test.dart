import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:cipher_x/features/shifts/domain/validators/shift_validator.dart';

void main() {
  final tDate = DateTime.utc(2026, 8, 27);

  final validShift = Shift(
    shiftId: 'shift-100',
    organizationId: 'org-100',
    guardId: 'guard-200',
    siteId: 'site-300',
    date: tDate,
    startTime: const ShiftTime(hour: 9, minute: 0),
    endTime: const ShiftTime(hour: 17, minute: 0),
    status: ShiftStatus.scheduled,
  );

  group('ShiftValidator Tests', () {
    test('passes validation for valid shift and normalizes fields', () {
      final paddedShift = validShift.copyWith(
        shiftId: '  shift-100  ',
        organizationId: ' org-100 ',
      );

      final normalized = ShiftValidator.validate(paddedShift);
      expect(normalized.shiftId, equals('shift-100'));
      expect(normalized.organizationId, equals('org-100'));
    });

    test('throws InvalidShiftIdFailure when shiftId is empty', () {
      final invalid = validShift.copyWith(shiftId: '   ');
      expect(
        () => ShiftValidator.validate(invalid),
        throwsA(isA<InvalidShiftIdFailure>()),
      );
    });

    test('throws InvalidOrganizationIdFailure when organizationId is empty',
        () {
      final invalid = validShift.copyWith(organizationId: '   ');
      expect(
        () => ShiftValidator.validate(invalid),
        throwsA(isA<InvalidOrganizationIdFailure>()),
      );
    });

    test('throws InvalidGuardIdFailure when guardId is empty', () {
      final invalid = validShift.copyWith(guardId: '   ');
      expect(
        () => ShiftValidator.validate(invalid),
        throwsA(isA<InvalidGuardIdFailure>()),
      );
    });

    test('throws InvalidSiteIdFailure when siteId is empty', () {
      final invalid = validShift.copyWith(siteId: '   ');
      expect(
        () => ShiftValidator.validate(invalid),
        throwsA(isA<InvalidSiteIdFailure>()),
      );
    });

    group('Time Invariants (startTime < endTime)', () {
      test('accepts valid normal shift (09:00 -> 17:00)', () {
        final shift = validShift.copyWith(
          startTime: const ShiftTime(hour: 9, minute: 0),
          endTime: const ShiftTime(hour: 17, minute: 0),
        );
        expect(() => ShiftValidator.validate(shift), returnsNormally);
      });

      test('rejects equal start and end time (09:00 -> 09:00)', () {
        final shift = validShift.copyWith(
          startTime: const ShiftTime(hour: 9, minute: 0),
          endTime: const ShiftTime(hour: 9, minute: 0),
        );
        expect(
          () => ShiftValidator.validate(shift),
          throwsA(isA<InvalidTimeRangeFailure>()),
        );
      });

      test(
          'rejects inverted overnight time range (17:00 -> 09:00) per same-day shift decision',
          () {
        final shift = validShift.copyWith(
          startTime: const ShiftTime(hour: 17, minute: 0),
          endTime: const ShiftTime(hour: 9, minute: 0),
        );
        expect(
          () => ShiftValidator.validate(shift),
          throwsA(isA<InvalidTimeRangeFailure>()),
        );
      });
    });

    group('Status Transition Lifecycle Rules', () {
      test('allows valid status transitions', () {
        expect(
          ShiftValidator.validateStatusTransition(
            from: ShiftStatus.scheduled,
            to: ShiftStatus.active,
          ),
          isNull,
        );

        expect(
          ShiftValidator.validateStatusTransition(
            from: ShiftStatus.scheduled,
            to: ShiftStatus.cancelled,
          ),
          isNull,
        );

        expect(
          ShiftValidator.validateStatusTransition(
            from: ShiftStatus.active,
            to: ShiftStatus.completed,
          ),
          isNull,
        );
      });

      test('rejects invalid status transitions', () {
        expect(
          ShiftValidator.validateStatusTransition(
            from: ShiftStatus.completed,
            to: ShiftStatus.active,
          ),
          isNotNull,
        );

        expect(
          ShiftValidator.validateStatusTransition(
            from: ShiftStatus.cancelled,
            to: ShiftStatus.active,
          ),
          isNotNull,
        );
      });
    });
  });
}
