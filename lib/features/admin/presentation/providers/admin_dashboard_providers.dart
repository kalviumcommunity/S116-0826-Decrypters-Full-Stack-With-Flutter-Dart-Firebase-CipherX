import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/presentation/providers/alert_providers.dart';
import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../guards/presentation/providers/guard_providers.dart';
import '../../../identity/domain/entities/user_profile.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../../../incidents/presentation/providers/incident_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../data/repositories/site_coverage_repository_impl.dart';
import '../../domain/entities/dashboard_statistics.dart';
import '../../domain/entities/site_coverage_filter.dart';
import '../../domain/entities/site_coverage_item.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/repositories/site_coverage_repository.dart';
import '../../domain/services/site_coverage_service.dart';

/// Provider for [DashboardRepository] injected with tenant-isolated sub-repositories.
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    guardRepository: ref.watch(guardRepositoryProvider),
    shiftRepository: ref.watch(shiftRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
    siteRepository: ref.watch(siteRepositoryProvider),
    incidentRepository: ref.watch(incidentRepositoryProvider),
    alertRepository: ref.watch(alertRepositoryProvider),
  );
});

/// Provider for [SiteCoverageRepository] providing real-time site staffing metrics.
final siteCoverageRepositoryProvider = Provider<SiteCoverageRepository>((ref) {
  return SiteCoverageRepositoryImpl(
    siteRepository: ref.watch(siteRepositoryProvider),
    shiftRepository: ref.watch(shiftRepositoryProvider),
    attendanceRepository: ref.watch(attendanceRepositoryProvider),
  );
});

/// Reactive stream of core operational KPI metrics for the current admin's organization.
final dashboardStatisticsStreamProvider =
    StreamProvider.autoDispose<DashboardStatistics>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value(const DashboardStatistics.empty());
  }

  // RBAC enforcement: Only admin and supervisor can access organization command center
  if (profile.role != UserRole.admin && profile.role != UserRole.supervisor) {
    return Stream.value(const DashboardStatistics.empty());
  }

  final repository = ref.watch(dashboardRepositoryProvider);
  return repository.watchStatistics(organizationId: profile.organizationId);
});

/// Selected filter state for Site Coverage list (All, Fully Staffed, Understaffed).
final siteCoverageFilterProvider =
    StateProvider<SiteCoverageFilter>((ref) => SiteCoverageFilter.all);

/// Reactive stream of all site coverage items for the current admin's organization.
final siteCoverageStreamProvider =
    StreamProvider.autoDispose<List<SiteCoverageItem>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);
  final profile = profileAsync.asData?.value;

  if (profile == null || profile.organizationId.trim().isEmpty) {
    return Stream.value(const []);
  }

  if (profile.role != UserRole.admin && profile.role != UserRole.supervisor) {
    return Stream.value(const []);
  }

  final repository = ref.watch(siteCoverageRepositoryProvider);
  return repository.watchSiteCoverage(
    organizationId: profile.organizationId,
    filter: SiteCoverageFilter.all,
  );
});

/// Computes filtered site coverage based on [siteCoverageStreamProvider] and [siteCoverageFilterProvider].
final filteredSiteCoverageProvider =
    Provider.autoDispose<AsyncValue<List<SiteCoverageItem>>>((ref) {
  final coverageAsync = ref.watch(siteCoverageStreamProvider);
  final filter = ref.watch(siteCoverageFilterProvider);

  return coverageAsync.whenData((items) {
    const service = SiteCoverageService();
    return service.filterCoverages(items, filter);
  });
});
