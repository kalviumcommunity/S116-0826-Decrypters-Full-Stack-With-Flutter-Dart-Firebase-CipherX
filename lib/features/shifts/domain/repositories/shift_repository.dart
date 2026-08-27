import '../entities/shift.dart';

abstract class ShiftRepository {
  /// Fetches shifts for a specific guard in a given organization.
  Future<List<Shift>> getShiftsByGuard(String organizationId, String guardId);

  /// Fetches a shift by its ID.
  Future<Shift?> getShiftById(String organizationId, String shiftId);
}
