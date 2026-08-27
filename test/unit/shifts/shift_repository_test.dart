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
    String organizationId,
  ) async {
    return _shifts.where((s) => s.organizationId == organizationId).toList();
  }

  @override
  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId,
  ) async {
    return _shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (s.guardId != guardId) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<Shift>> watchShiftsByGuard(
    String organizationId,
    String guardId,
  ) async* {
    yield await getShiftsByGuard(organizationId, guardId);
  }

  @override
  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId,
  ) async {
    return _shifts.where((s) {
      if (s.organizationId != organizationId) return false;
      if (s.siteId != siteId) return false;
      return true;
    }).toList();
  }

  @override
  Future<Shift> updateShift(Shift shift) async {
    final index = _shifts.indexWhere((s) => s.shiftId == shift.shiftId);
    if (index != -1) {
      final validated = ShiftValidator.validate(shift);
      _shifts[index] = validated;
      return validated;
    }
    throw const ShiftNotFoundFailure();
  }

  @override
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async {
    final index = _shifts.indexWhere(
      (s) => s.organizationId == organizationId && s.shiftId == shiftId,
    );
    if (index != -1) {
      final updated = _shifts[index].copyWith(status: status);
      _shifts[index] = updated;
      return updated;
    }
    throw const ShiftNotFoundFailure();
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
  final tShift = Shift(
    shiftId: 'shift-001',
    organizationId: 'org-001',
    guardId: 'guard-001',
    siteId: 'site-001',
    date: DateTime.utc(2026, 8, 27),
    startTime: const ShiftTime(hour: 9, minute: 0),
    endTime: const ShiftTime(hour: 17, minute: 0),
    status: ShiftStatus.scheduled,
  );

  group('ShiftRepository Domain Contract Tests', () {
    late InMemoryShiftRepository repository;

    setUp(() {
      repository = InMemoryShiftRepository();
    });

    test('createShift persists valid shift in repository', () async {
      final result = await repository.createShift(tShift);

      expect(result.shiftId, equals('shift-001'));
      expect(result.status, equals(ShiftStatus.scheduled));

      final fetched = await repository.getShift(
        organizationId: 'org-001',
        shiftId: 'shift-001',
      );
      expect(fetched, equals(tShift));
    });

    test('getShiftsByOrganization filters by organizationId', () async {
      await repository.createShift(tShift);
      await repository.createShift(tShift.copyWith(
        shiftId: 'shift-002',
        organizationId: 'org-999',
      ));

      final results = await repository.getShiftsByOrganization('org-001');
      expect(results.length, equals(1));
      expect(results.first.shiftId, equals('shift-001'));
    });

    test('updateShiftStatus transitions shift status', () async {
      await repository.createShift(tShift);

      final updated = await repository.updateShiftStatus(
        organizationId: 'org-001',
        shiftId: 'shift-001',
        status: ShiftStatus.active,
      );

      expect(updated.status, equals(ShiftStatus.active));
    });

    test('cancelShift sets status to cancelled', () async {
      await repository.createShift(tShift);

      await repository.cancelShift(
        organizationId: 'org-001',
        shiftId: 'shift-001',
      );

      final fetched = await repository.getShift(
        organizationId: 'org-001',
        shiftId: 'shift-001',
      );
      expect(fetched?.status, equals(ShiftStatus.cancelled));
    });
  });
}
