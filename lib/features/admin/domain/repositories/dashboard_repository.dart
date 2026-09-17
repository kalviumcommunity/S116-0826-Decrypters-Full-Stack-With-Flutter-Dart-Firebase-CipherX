import '../entities/dashboard_statistics.dart';

/// Contract for fetching and watching organization-scoped dashboard metrics.
abstract class DashboardRepository {
  /// Fetches a one-time snapshot of the operational dashboard statistics.
  Future<DashboardStatistics> getStatistics({
    required String organizationId,
    DateTime? evaluationTime,
  });

  /// Streams real-time updates of the operational dashboard statistics.
  Stream<DashboardStatistics> watchStatistics({
    required String organizationId,
    DateTime? evaluationTime,
  });
}
