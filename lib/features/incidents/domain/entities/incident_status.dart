import '../failures/incident_failure.dart';

/// Strongly-typed incident lifecycle states as defined by the Cipher-X product contract.
enum IncidentStatus {
  open,
  investigating,
  resolved;

  /// Returns the canonical uppercase persistence representation.
  String toMapString() => name.toUpperCase();

  /// Parses a string into an [IncidentStatus].
  ///
  /// Throws [InvalidIncidentStatusFailure] if [value] is null, empty, or not one of
  /// OPEN, INVESTIGATING, or RESOLVED.
  static IncidentStatus fromMapString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'OPEN':
        return IncidentStatus.open;
      case 'INVESTIGATING':
        return IncidentStatus.investigating;
      case 'RESOLVED':
        return IncidentStatus.resolved;
      default:
        throw InvalidIncidentStatusFailure(
          'Invalid incident status: "$value". Must be OPEN, INVESTIGATING, or RESOLVED.',
        );
    }
  }

  /// Attempts to parse a string into an [IncidentStatus], returning `null` if invalid.
  static IncidentStatus? tryFromMapString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return fromMapString(value);
    } catch (_) {
      return null;
    }
  }

  /// Verifies whether a lifecycle transition from this status to [target] is permissible.
  ///
  /// Lifecycle rules:
  /// - OPEN -> INVESTIGATING: Allowed
  /// - OPEN -> RESOLVED: Allowed
  /// - INVESTIGATING -> RESOLVED: Allowed
  /// - Same status transitions: Allowed (no-op)
  /// - Backwards transitions (RESOLVED -> OPEN, RESOLVED -> INVESTIGATING, INVESTIGATING -> OPEN): Rejected
  bool canTransitionTo(IncidentStatus target) {
    if (this == target) return true;

    switch (this) {
      case IncidentStatus.open:
        return target == IncidentStatus.investigating ||
            target == IncidentStatus.resolved;

      case IncidentStatus.investigating:
        return target == IncidentStatus.resolved;

      case IncidentStatus.resolved:
        // Terminal state in current product specification (no reopening workflow)
        return false;
    }
  }

  bool get isOpen => this == IncidentStatus.open;
  bool get isInvestigating => this == IncidentStatus.investigating;
  bool get isResolved => this == IncidentStatus.resolved;
}
