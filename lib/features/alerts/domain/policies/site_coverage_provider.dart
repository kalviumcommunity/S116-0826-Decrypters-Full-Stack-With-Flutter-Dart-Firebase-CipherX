/// Staffing metrics for a site at an evaluation moment.
class SiteCoverage {
  final String siteId;
  final String organizationId;
  final int requiredStaff;
  final int actualStaff;

  const SiteCoverage({
    required this.siteId,
    required this.organizationId,
    required this.requiredStaff,
    required this.actualStaff,
  });

  bool get isUnderstaffed => actualStaff < requiredStaff;
}

/// Abstract provider for site staffing requirements and actual active coverage.
///
/// Keeps coverage calculations decoupled from the alert detection logic.
abstract interface class SiteCoverageProvider {
  Future<SiteCoverage> getCoverage({
    required String organizationId,
    required String siteId,
    required DateTime evaluationTime,
  });
}

/// Configurable site coverage provider for runtime and test environments.
class StaticSiteCoverageProvider implements SiteCoverageProvider {
  final Map<String, int> requiredStaffBySite;
  final Map<String, int> actualStaffBySite;

  const StaticSiteCoverageProvider({
    this.requiredStaffBySite = const {},
    this.actualStaffBySite = const {},
  });

  @override
  Future<SiteCoverage> getCoverage({
    required String organizationId,
    required String siteId,
    required DateTime evaluationTime,
  }) async {
    final requiredStaff = requiredStaffBySite[siteId] ?? 1;
    final actualStaff = actualStaffBySite[siteId] ?? 0;
    return SiteCoverage(
      siteId: siteId,
      organizationId: organizationId,
      requiredStaff: requiredStaff,
      actualStaff: actualStaff,
    );
  }
}
