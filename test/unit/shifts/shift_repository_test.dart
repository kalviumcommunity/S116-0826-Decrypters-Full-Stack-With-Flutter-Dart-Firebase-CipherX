import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:cipher_x/features/shifts/domain/repositories/shift_repository.dart';
import 'package:cipher_x/features/shifts/domain/validators/shift_validator.dart';

class InMemoryShiftRepository implements ShiftRepository {
  final List<Shift> _shifts = [];

  @override
  Future<Shift> createShift(Shift shift) async {
    final validated = ShiftValidator.validate(shift);
    _shifts.add(validated);
    return validated;
  }

  @override
  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  }) async {
    try {
      return _shifts.firstWhere(
        (s) => s.organizationId == organizationId && s.shiftId == shiftId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Shift>> getShiftsByOrganization(
    String organizationId, {
    DateTime? date,
    ShiftStatus? status,
  }) async {
    return _shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (date != null &&
          (s.date.year != date.year ||
              s.date.month != date.month ||
              s.date.day != date.day)) {
        return false;
      }
      if (status != null && s.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId, {
    DateTime? date,
  }) async {
    return _shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (s.guardId != guardId) return false;
      if (date != null &&
          (s.date.year != date.year ||
              s.date.month != date.month ||
              s.date.day != date.day)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId, {
    DateTime? date,
  }) async {
    return _shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (s.siteId != siteId) return false;
      if (date != null &&
          (s.date.year != date.year ||
              s.date.month != date.month ||
              s.date.day != date.day)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    final validated = ShiftValidator.validate(shift);
    final index = _shifts.indexWhere((s) => s.shiftId == validated.shiftId);
    if (index == -1) {
      throw const ShiftNotFoundFailure();
    }
    _shifts[index] = validated;
    return validated;
  }

  @override
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async {
    final shift =
        await getShift(organizationId: organizationId, shiftId: shiftId);
    if (shift == null) {
      throw const ShiftNotFoundFailure();
    }

    final transitionErr = ShiftValidator.validateStatusTransition(
      from: shift.status,
      to: status,
    );
    if (transitionErr != null) {
      throw InvalidStatusTransitionFailure(transitionErr);
    }

    final updated = shift.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    return updateShift(updated);
  }

  @override
  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  }) async {
    await updateShiftStatus(
      organizationId: organizationId,
      shiftId: shiftId,
      status: ShiftStatus.cancelled,
    );
  }
}

void main() {
  final tDate = DateTime.utc(2026, 8, 27);
  final tShift = Shift(
    shiftId: 'shift-001',
    organizationId: 'org-100',
    guardId: 'guard-200',
    siteId: 'site-300',
    date: tDate,
    startTime: const ShiftTime(hour: 8, minute: 0),
    endTime: const ShiftTime(hour: 16, minute: 0),
    status: ShiftStatus.scheduled,
  );

  group('ShiftRepository Abstraction Unit Tests', () {
    late InMemoryShiftRepository repository;

    setUp(() {
      repository = InMemoryShiftRepository();
    });

    test('createShift validates and persists shift', () async {
      final created = await repository.createShift(tShift);
      expect(created.shiftId, equals('shift-001'));

      final retrieved = await repository.getShift(
        organizationId: 'org-100',
        shiftId: 'shift-001',
      );
      expect(retrieved, equals(created));
    });

    test('getShiftsByOrganization filters by organization and date', () async {
      await repository.createShift(tShift);
      await repository.createShift(
        tShift.copyWith(
          shiftId: 'shift-002',
          date: DateTime.utc(2026, 8, 28),
        ),
      );

      final orgShifts = await repository.getShiftsByOrganization('org-100');
      expect(orgShifts.length, equals(2));

      final dateFiltered = await repository.getShiftsByOrganization(
        'org-100',
        date: tDate,
      );
      expect(dateFiltered.length, equals(1));
      expect(dateFiltered.first.shiftId, equals('shift-001'));
    });

    test('getShiftsByGuard and getShiftsBySite filter correctly', () async {
      await repository.createShift(tShift);

      final guardShifts =
          await repository.getShiftsByGuard('org-100', 'guard-200');
      expect(guardShifts.length, equals(1));

      final siteShifts =
          await repository.getShiftsBySite('org-100', 'site-300');
      expect(siteShifts.length, equals(1));
    });

    test('updateShiftStatus enforces lifecycle transition rules', () async {
      await repository.createShift(tShift);

      final active = await repository.updateShiftStatus(
        organizationId: 'org-100',
        shiftId: 'shift-001',
        status: ShiftStatus.active,
      );
      expect(active.status, equals(ShiftStatus.active));

      expect(
        () => repository.updateShiftStatus(
          organizationId: 'org-100',
          shiftId: 'shift-001',
          status: ShiftStatus.scheduled,
        ),
        throwsA(isA<InvalidStatusTransitionFailure>()),
      );
    });

    test('cancelShift sets status to CANCELLED', () async {
      await repository.createShift(tShift);

      await repository.cancelShift(
        organizationId: 'org-100',
        shiftId: 'shift-001',
      );

      final cancelled = await repository.getShift(
        organizationId: 'org-100',
        shiftId: 'shift-001',
      );
      expect(cancelled!.status, equals(ShiftStatus.cancelled));
    });
  });
}
