/// Minimal lifecycle statuses for an Alert.
enum AlertStatus {
  active,
  acknowledged,
  resolved;

  String toMapString() => name;

  static AlertStatus fromMapString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'active':
        return AlertStatus.active;
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'resolved':
        return AlertStatus.resolved;
      default:
        return AlertStatus.active;
    }
  }
}
