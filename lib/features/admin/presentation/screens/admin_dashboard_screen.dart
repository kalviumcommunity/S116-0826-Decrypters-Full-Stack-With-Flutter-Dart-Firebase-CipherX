import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
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
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;
    final statsAsync = ref.watch(dashboardStatisticsStreamProvider);

    final profile = profileAsync.asData?.value;
    final greeting = GreetingUtils.getTimeGreeting();
    final firstName = GreetingUtils.getFirstName(
      profile: profile,
      authUser: authUser,
      defaultFallback: 'Administrator',
    );
    final adminName = firstName;
    final orgId = profile?.organizationId ?? '';


    final todayFormatted = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Scaffold(
      key: const Key('admin_command_center_screen'),
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/cipher_x_logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Command Center'),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('open_activity_feed'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            tooltip: 'Alerts & Activity Feed',
            onPressed: () => context.push(AppRoutes.adminActivityFeed),
          ),
          IconButton(
            key: const Key('refresh_command_center'),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: AppColors.textPrimaryLight,
              ),
            ),
            tooltip: 'Refresh Metrics',
            onPressed: () {
              ref.invalidate(dashboardStatisticsStreamProvider);
              ref.invalidate(siteCoverageStreamProvider);
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 18,
                color: AppColors.textSecondaryLight,
              ),
            ),
            tooltip: 'Logout',
            onPressed: () async {
              final confirmed = await AppDialogs.confirmLogout(context);
              if (confirmed) {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatisticsStreamProvider);
          ref.invalidate(siteCoverageStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.cardWineGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          adminName.isNotEmpty
                              ? adminName[0].toUpperCase()
                              : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$greeting, $adminName',
                            style: AppTextStyles.titleMedium(
                              color: AppColors.textPrimaryLight,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            todayFormatted,
                            style: AppTextStyles.bodyMedium(
                              color: AppColors.textSecondaryLight,
                            ).copyWith(fontSize: 12),
                          ),
                          if (orgId.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Organization: $orgId',
                                style: AppTextStyles.caption(
                                  color: AppColors.primary,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const SizedBox(height: 20),

              // Operations Overview / KPI Metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Operations Overview',
                    style: AppTextStyles.titleLarge(
                      color: AppColors.textPrimaryLight,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Live metrics across guards, shifts, and active facilities',
                style: AppTextStyles.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ).copyWith(fontSize: 12),
              ),
              const SizedBox(height: 14),

              statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBadgeBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Failed to load operational metrics: $error',
                          style: const TextStyle(color: AppColors.error),
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
                  _buildShortcutButton(
                    context,
                    label: 'Guards',
                    icon: Icons.shield_outlined,
                    onPressed: () => context.push(AppRoutes.adminGuards),
                  ),
                  const SizedBox(width: 10),
                  _buildShortcutButton(
                    context,
                    label: 'Sites',
                    icon: Icons.location_city_outlined,
                    onPressed: () => context.push(AppRoutes.adminSites),
                  ),
                  const SizedBox(width: 10),
                  _buildShortcutButton(
                    context,
                    label: 'Incidents',
                    icon: Icons.report_problem_outlined,
                    onPressed: () => context.push(AppRoutes.adminIncidents),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Site Staffing Coverage Section
              SiteCoverageSection(
                onSiteTap: (item) => context.push(AppRoutes.adminSites),
              ),

            ],
          ),
        ),
      ),
    );
  }


  Widget _buildShortcutButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentRose,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyles.caption(
                    color: AppColors.textPrimaryLight,
                  ).copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

