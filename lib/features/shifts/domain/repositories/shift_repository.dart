import '../entities/shift.dart';

abstract class ShiftRepository {
  Future<Shift> createShift(Shift shift);

  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  });

  Future<List<Shift>> getShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  });

  Stream<List<Shift>> watchShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  });
}
