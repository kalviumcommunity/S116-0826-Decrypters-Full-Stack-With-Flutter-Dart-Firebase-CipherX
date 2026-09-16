import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../sites/domain/entities/site.dart';
import '../entities/coverage_status.dart';
import '../entities/site_coverage_filter.dart';
import '../entities/site_coverage_item.dart';

/// Pure domain service calculating site staffing coverage ratios and applying filters.
///
/// Fully decoupled from UI and storage layers; testable with injected evaluation times.
class SiteCoverageService {
  const SiteCoverageService();

  /// Calculates coverage for a single site against active attendances and scheduled shifts.
  SiteCoverageItem calculateCoverageForSite({
    required Site site,
    required List<Shift> shifts,
    required List<AttendanceRecord> activeAttendances,
    required DateTime evaluationTime,
  }) {
    // 1. Identify scheduled shifts for this site on evaluation date
    final siteShiftsToday = shifts.where((s) {
      if (s.siteId != site.siteId) return false;
      if (s.status == ShiftStatus.cancelled) return false;
      return s.date.year == evaluationTime.year &&
          s.date.month == evaluationTime.month &&
          s.date.day == evaluationTime.day;
    }).toList();

    // Required staffing equals the distinct active/scheduled shifts for this site today
    final requiredStaff = siteShiftsToday.length;

    // 2. Identify guards currently checked in and active on this site
    final actualStaff = activeAttendances.where((a) {
      return a.siteId == site.siteId &&
          a.status == AttendanceStatus.active &&
          !a.isCheckedOut;
    }).length;

    // 3. Determine coverage status
    final CoverageStatus status;
    if (actualStaff >= requiredStaff) {
      status = CoverageStatus.fullyStaffed;
    } else {
      status = CoverageStatus.understaffed;
    }

    return SiteCoverageItem(
      siteId: site.siteId,
      siteName: site.name,
      organizationId: site.organizationId,
      actualStaff: actualStaff,
      requiredStaff: requiredStaff,
      status: status,
    );
  }

  /// Calculates coverage across a collection of sites.
  List<SiteCoverageItem> calculateAllCoverage({
    required List<Site> sites,
    required List<Shift> shifts,
    required List<AttendanceRecord> activeAttendances,
    required DateTime evaluationTime,
  }) {
    return sites.map((site) {
      return calculateCoverageForSite(
        site: site,
        shifts: shifts,
        activeAttendances: activeAttendances,
        evaluationTime: evaluationTime,
      );
    }).toList();
  }

  /// Applies user filter to a list of coverage items.
  List<SiteCoverageItem> filterCoverages(
    List<SiteCoverageItem> items,
    SiteCoverageFilter filter,
  ) {
    switch (filter) {
      case SiteCoverageFilter.all:
        return items;
      case SiteCoverageFilter.fullyStaffed:
        return items.where((i) => i.isFullyStaffed).toList();
      case SiteCoverageFilter.understaffed:
        return items.where((i) => i.isUnderstaffed).toList();
    }
  }
}
