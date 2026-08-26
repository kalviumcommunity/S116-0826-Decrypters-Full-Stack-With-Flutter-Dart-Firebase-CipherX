import '../entities/guard.dart';

/// Repository abstraction for managing security guards within an organization context.
///
/// All operations are organization-scoped to enforce multi-tenant security boundaries.
abstract class GuardRepository {
  /// Validates and persists a new [guard] document in Firestore.
  ///
  /// Throws [GuardValidationFailure] if guard fields fail domain validation rules.
  Future<Guard> createGuard(Guard guard);

  /// Retrieves a specific guard by [organizationId] and [guardId].
  ///
  /// Returns `null` if the guard document does not exist.
  Future<Guard?> getGuard({
    required String organizationId,
    required String guardId,
  });

  /// Retrieves guards belonging to the specified [organizationId].
  /// By default, soft-deleted (`inactive`) records are excluded unless [includeInactive] is true.
  Future<List<Guard>> getGuards(
    String organizationId, {
    bool includeInactive = false,
  });

  /// Watches guards belonging to the specified [organizationId] in real-time.
  /// By default, soft-deleted (`inactive`) records are excluded unless [includeInactive] is true.
  Stream<List<Guard>> watchGuards(
    String organizationId, {
    bool includeInactive = false,
  });

  /// Validates and updates mutable fields of an existing [guard].
  ///
  /// Immutable fields (`guardId`, `organizationId`, `createdAt`) are preserved.
  Future<Guard> updateGuard(Guard guard);

  /// Updates the status of a guard.
  Future<Guard> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  });

  /// Deactivates a guard by setting their status to [GuardStatus.inactive].
  ///
  /// Operational history (shifts, attendance, incidents) is preserved.
  Future<void> deleteGuard({
    required String organizationId,
    required String guardId,
  });
}
