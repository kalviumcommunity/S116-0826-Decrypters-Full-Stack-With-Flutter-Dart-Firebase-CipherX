/// Coverage status classifications for a security site.
enum CoverageStatus {
  fullyStaffed,
  understaffed;

  String get displayName {
    switch (this) {
      case CoverageStatus.fullyStaffed:
        return 'FULLY STAFFED';
      case CoverageStatus.understaffed:
        return 'UNDERSTAFFED';
    }
  }

  String toMapString() => name;

  static CoverageStatus fromMapString(String value) {
    switch (value.toLowerCase()) {
      case 'fullystaffed':
      case 'fully_staffed':
        return CoverageStatus.fullyStaffed;
      case 'understaffed':
      default:
        return CoverageStatus.understaffed;
    }
  }
}
