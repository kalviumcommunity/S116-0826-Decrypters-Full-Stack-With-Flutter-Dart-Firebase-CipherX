/// Filter criteria for site staffing coverage views.
enum SiteCoverageFilter {
  all,
  fullyStaffed,
  understaffed;

  String get displayName {
    switch (this) {
      case SiteCoverageFilter.all:
        return 'All';
      case SiteCoverageFilter.fullyStaffed:
        return 'Fully Staffed';
      case SiteCoverageFilter.understaffed:
        return 'Understaffed';
    }
  }
}
