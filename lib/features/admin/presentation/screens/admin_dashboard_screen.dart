import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';
import '../providers/admin_dashboard_providers.dart';
import '../widgets/operational_metrics_grid.dart';
import '../widgets/site_coverage_section.dart';

/// Admin Command Center and Site Coverage Screen.
///
/// Serves as the primary operational nexus for administrators, displaying
/// real-time KPI metrics across guards, shifts, sites, and incidents alongside
/// site staffing coverage analytics.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final statsAsync = ref.watch(dashboardStatisticsStreamProvider);

    final profile = profileAsync.asData?.value;
    final adminName = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Administrator';
    final orgId = profile?.organizationId ?? '';

    final todayFormatted = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Scaffold(
      key: const Key('admin_command_center_screen'),
      appBar: AppBar(
        title: const Text('Command Center'),
        actions: [
          IconButton(
            key: const Key('refresh_command_center'),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Metrics',
            onPressed: () {
              ref.invalidate(dashboardStatisticsStreamProvider);
              ref.invalidate(siteCoverageStreamProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatisticsStreamProvider);
          ref.invalidate(siteCoverageStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $adminName',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            todayFormatted,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (orgId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Organization: $orgId',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Operations Overview / KPI Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operations Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Live metrics across guards, shifts, and active facilities',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed to load operational metrics: $error',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (statistics) => OperationalMetricsGrid(
                  statistics: statistics,
                  onGuardsTap: () => context.push(AppRoutes.adminGuards),
                  onSitesTap: () => context.push(AppRoutes.adminSites),
                  onIncidentsTap: () => context.push(AppRoutes.adminIncidents),
                ),
              ),

              const SizedBox(height: 24),

              // Navigation Shortcuts
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shield_outlined, size: 18),
                      label: const Text('Guards'),
                      onPressed: () => context.push(AppRoutes.adminGuards),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.location_city_outlined, size: 18),
                      label: const Text('Sites'),
                      onPressed: () => context.push(AppRoutes.adminSites),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: const Text('Incidents'),
                      onPressed: () => context.push(AppRoutes.adminIncidents),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Site Staffing Coverage Section
              SiteCoverageSection(
                onSiteTap: (item) => context.push(AppRoutes.adminSites),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
