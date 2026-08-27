import '../entities/shift.dart';

/// Repository abstraction for managing operational shifts within an organization context.
///
/// Pure domain contract — contains zero framework or database dependencies.
abstract class ShiftRepository {
  /// Validates and persists a new [shift].
  Future<Shift> createShift(Shift shift);

  /// Retrieves a shift by [organizationId] and [shiftId].
  /// Returns `null` if not found.
  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  });

  /// Retrieves shifts for an organization, optionally filtered by [date] or [status].
  Future<List<Shift>> getShiftsByOrganization(
    String organizationId, {
    DateTime? date,
    ShiftStatus? status,
  });

  /// Retrieves shifts assigned to a specific guard within an organization.
  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId, {
    DateTime? date,
  });

  /// Retrieves shifts assigned to a specific site within an organization.
  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId, {
    DateTime? date,
  });

  /// Validates and updates mutable fields of an existing [shift].
  Future<Shift> updateShift(Shift shift);

  /// Updates the status of a shift enforcing transition invariants.
  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  });

  /// Cancels a shift by setting its status to [ShiftStatus.cancelled].
  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  });
}
