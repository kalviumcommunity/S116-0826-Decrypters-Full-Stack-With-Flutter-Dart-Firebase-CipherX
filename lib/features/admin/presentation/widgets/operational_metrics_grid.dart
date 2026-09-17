import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_statistics.dart';
import 'metric_card.dart';

/// Responsive grid rendering all 7 operational metrics for the Command Center.
class OperationalMetricsGrid extends StatelessWidget {
  final DashboardStatistics statistics;
  final VoidCallback? onGuardsTap;
  final VoidCallback? onSitesTap;
  final VoidCallback? onIncidentsTap;

  const OperationalMetricsGrid({
    super.key,
    required this.statistics,
    this.onGuardsTap,
    this.onSitesTap,
    this.onIncidentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 4
            : constraints.maxWidth > 500
                ? 3
                : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            MetricCard(
              key: const Key('metric_total_guards'),
              title: 'Total Guards',
              value: '${statistics.totalGuards}',
              icon: Icons.people_alt_outlined,
              color: Colors.blueGrey,
              subtitle: 'Registered Active',
              onTap: onGuardsTap,
            ),
            MetricCard(
              key: const Key('metric_on_duty'),
              title: 'On Duty',
              value: '${statistics.onDutyGuards}',
              icon: Icons.verified_user_outlined,
              color: Colors.green,
              subtitle: 'Active Shifts',
              onTap: onGuardsTap,
            ),
            MetricCard(
              key: const Key('metric_absent'),
              title: 'Absent',
              value: '${statistics.absentGuards}',
              icon: Icons.person_off_outlined,
              color: Colors.deepOrange,
              subtitle: 'Past Scheduled',
              onTap: onGuardsTap,
            ),
            MetricCard(
              key: const Key('metric_late'),
              title: 'Late',
              value: '${statistics.lateGuards}',
              icon: Icons.access_time_outlined,
              color: Colors.amber.shade800,
              subtitle: '> 15m Grace',
              onTap: onGuardsTap,
            ),
            MetricCard(
              key: const Key('metric_active_sites'),
              title: 'Active Sites',
              value: '${statistics.activeSites}',
              icon: Icons.location_city_outlined,
              color: Colors.indigo,
              subtitle: 'Operational',
              onTap: onSitesTap,
            ),
            MetricCard(
              key: const Key('metric_open_incidents'),
              title: 'Open Incidents',
              value: '${statistics.openIncidents}',
              icon: Icons.report_problem_outlined,
              color: Colors.red,
              subtitle: 'Needs Action',
              onTap: onIncidentsTap,
            ),
            MetricCard(
              key: const Key('metric_critical_alerts'),
              title: 'Critical Alerts',
              value: '${statistics.criticalAlerts}',
              icon: Icons.warning_amber_rounded,
              color: Colors.purple,
              subtitle: 'High Severity',
            ),
          ],
        );
      },
    );
  }
}
