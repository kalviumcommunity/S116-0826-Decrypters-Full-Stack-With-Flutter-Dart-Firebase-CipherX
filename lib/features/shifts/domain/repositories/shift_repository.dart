import '../entities/shift.dart';

abstract class ShiftRepository {
  Future<Shift> createShift(Shift shift);

  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  });

  Future<List<Shift>> getShiftsByOrganization(String organizationId);

  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId,
  );

  Stream<List<Shift>> watchShiftsByGuard(
    String organizationId,
    String guardId,
  );

  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId,
  );

  Future<Shift> updateShift(Shift shift);

  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  });

  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  });
}
