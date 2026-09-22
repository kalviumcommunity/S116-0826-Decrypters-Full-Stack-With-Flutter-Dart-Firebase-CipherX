import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/greeting_utils.dart';
import '../../../../core/widgets/app_dialogs.dart';
import '../../../../core/widgets/network_status_banner.dart';
import '../../../admin/presentation/providers/admin_dashboard_providers.dart';
import '../../../admin/presentation/widgets/site_coverage_item_card.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../identity/presentation/providers/identity_providers.dart';

/// Supervisor operational dashboard providing field supervision,
/// live site coverage monitoring, incident response, and guard tracking.
class SupervisorDashboardScreen extends ConsumerWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final authUser = ref.watch(authStateProvider).asData?.value;
    final statsAsync = ref.watch(dashboardStatisticsStreamProvider);
    final coverageAsync = ref.watch(siteCoverageStreamProvider);

    final profile = profileAsync.asData?.value;
    final greeting = GreetingUtils.getTimeGreeting();
    final firstName = GreetingUtils.getFirstName(
      profile: profile,
      authUser: authUser,
      defaultFallback: 'Supervisor',
    );
    final orgId = profile?.organizationId ?? '';
    final todayFormatted = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    return Scaffold(
      key: const Key('supervisor_dashboard_screen'),
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/cipher_x_logo.png',
                width: 22,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 6),
            const Flexible(
              child: Text(
                'Supervisor Hub',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('supervisor_activity_feed_button'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            tooltip: 'Alerts & Activity',
            onPressed: () => context.push(AppRoutes.adminActivityFeed),
          ),
          IconButton(
            key: const Key('supervisor_refresh_button'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 16,
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
            key: const Key('supervisor_logout_button'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Icon(
                Icons.logout_rounded,
                size: 16,
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
        ],
      ),
      body: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardStatisticsStreamProvider);
                ref.invalidate(siteCoverageStreamProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Supervisor Personalized Greeting Card
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'S',
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
                                  '$greeting, $firstName',
                                  style: AppTextStyles.titleMedium(
                                    color: AppColors.textPrimaryLight,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Supervisor',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        todayFormatted,
                                        style: AppTextStyles.bodyMedium(
                                          color: AppColors.textSecondaryLight,
                                        ).copyWith(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
                    const SizedBox(height: 20),

                    // Operational Metrics Summary
                    Text(
                      'OPERATIONAL SUPERVISION',
                      style: AppTextStyles.caption(
                        color: AppColors.textSecondaryLight,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    statsAsync.when(
                      data: (stats) {
                        return Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Active Incidents',
                                value: stats.openIncidents.toString(),
                                icon: Icons.warning_amber_rounded,
                                color: stats.openIncidents > 0
                                    ? AppColors.error
                                    : AppColors.success,
                                onTap: () =>
                                    context.push(AppRoutes.adminIncidents),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Guards on Duty',
                                value: stats.onDutyGuards.toString(),
                                icon: Icons.shield_outlined,
                                color: AppColors.primary,
                                onTap: () =>
                                    context.push(AppRoutes.adminGuards),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        height: 90,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.errorBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Error loading metrics: $err',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Field Actions
                    Text(
                      'QUICK FIELD ACTIONS',
                      style: AppTextStyles.caption(
                        color: AppColors.textSecondaryLight,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            title: 'Incident Triage',
                            subtitle: 'Review & resolve',
                            icon: Icons.assignment_late_outlined,
                            onTap: () => context.push(AppRoutes.adminIncidents),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            title: 'Site Coverage',
                            subtitle: 'Staffing status',
                            icon: Icons.radar_outlined,
                            onTap: () => context.push(AppRoutes.adminSites),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            title: 'Guard Roster',
                            subtitle: 'View deployed guards',
                            icon: Icons.people_outline,
                            onTap: () => context.push(AppRoutes.adminGuards),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionTile(
                            context: context,
                            title: 'Activity Feed',
                            subtitle: 'Live audit log',
                            icon: Icons.history_rounded,
                            onTap: () =>
                                context.push(AppRoutes.adminActivityFeed),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Live Site Coverage Feed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LIVE SITE COVERAGE',
                          style: AppTextStyles.caption(
                            color: AppColors.textSecondaryLight,
                          ).copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push(AppRoutes.adminSites),
                          child: const Text('View All Sites'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    coverageAsync.when(
                      data: (coverages) {
                        if (coverages.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Center(
                              child: Text(
                                'No sites configured for this organization.',
                                style: TextStyle(
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          );
                        }

                        // Show top 3 sites for quick supervisor glance
                        final displayList = coverages.take(3).toList();
                        return Column(
                          children: displayList.map((coverage) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: SiteCoverageItemCard(item: coverage),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Error loading site coverage: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 22, color: color),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentRose,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
