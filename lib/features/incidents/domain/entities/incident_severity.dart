import '../failures/incident_failure.dart';

/// Strongly-typed severity levels for incidents as defined by the Cipher-X product contract.
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  /// Returns the canonical uppercase persistence representation.
  String toMapString() => name.toUpperCase();

  /// Parses a string into an [IncidentSeverity].
  ///
  /// Throws [InvalidIncidentSeverityFailure] if [value] is null, empty, or not one of
  /// LOW, MEDIUM, HIGH, or CRITICAL.
  static IncidentSeverity fromMapString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'LOW':
        return IncidentSeverity.low;
      case 'MEDIUM':
        return IncidentSeverity.medium;
      case 'HIGH':
        return IncidentSeverity.high;
      case 'CRITICAL':
        return IncidentSeverity.critical;
      default:
        throw InvalidIncidentSeverityFailure(
          'Invalid incident severity: "$value". Must be LOW, MEDIUM, HIGH, or CRITICAL.',
        );
    }
  }

  /// Attempts to parse a string into an [IncidentSeverity], returning `null` if invalid.
  static IncidentSeverity? tryFromMapString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return fromMapString(value);
    } catch (_) {
      return null;
    }
  }

  /// Returns true if this severity is considered high priority ([high] or [critical]).
  bool get isHighPriority =>
      this == IncidentSeverity.high || this == IncidentSeverity.critical;

  /// Returns true if this severity is [critical].
  bool get isCritical => this == IncidentSeverity.critical;
}
