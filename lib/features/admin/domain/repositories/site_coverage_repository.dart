import '../entities/site_coverage_filter.dart';
import '../entities/site_coverage_item.dart';

/// Contract for fetching and watching real-time site staffing coverage.
abstract class SiteCoverageRepository {
  /// Fetches a one-time snapshot of site coverage for the organization.
  Future<List<SiteCoverageItem>> getSiteCoverage({
    required String organizationId,
    SiteCoverageFilter filter = SiteCoverageFilter.all,
    DateTime? evaluationTime,
  });

  /// Streams real-time updates of site coverage for the organization.
  Stream<List<SiteCoverageItem>> watchSiteCoverage({
    required String organizationId,
    SiteCoverageFilter filter = SiteCoverageFilter.all,
    DateTime? evaluationTime,
  });
}
