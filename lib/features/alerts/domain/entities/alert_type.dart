/// Strongly typed alert conditions supported by the Cipher-X Alert Engine.
enum AlertType {
  missedShift,
  lateCheckIn,
  understaffedSite,
  criticalIncident;

  /// Returns canonical uppercase persistence string.
  String toMapString() {
    switch (this) {
      case AlertType.missedShift:
        return 'MISSED_SHIFT';
      case AlertType.lateCheckIn:
        return 'LATE_CHECK_IN';
      case AlertType.understaffedSite:
        return 'UNDERSTAFFED_SITE';
      case AlertType.criticalIncident:
        return 'CRITICAL_INCIDENT';
    }
  }

  /// Parses string into [AlertType].
  static AlertType fromMapString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'MISSED_SHIFT':
        return AlertType.missedShift;
      case 'LATE_CHECK_IN':
        return AlertType.lateCheckIn;
      case 'UNDERSTAFFED_SITE':
        return AlertType.understaffedSite;
      case 'CRITICAL_INCIDENT':
        return AlertType.criticalIncident;
      default:
        throw ArgumentError('Unknown AlertType: "$value"');
    }
  }

  /// Safely attempts to parse string into [AlertType], returning `null` on failure.
  static AlertType? tryFromMapString(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return fromMapString(value);
    } catch (_) {
      return null;
    }
  }
}
