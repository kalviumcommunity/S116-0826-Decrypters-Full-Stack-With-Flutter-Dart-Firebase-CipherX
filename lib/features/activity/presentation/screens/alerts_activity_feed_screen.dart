import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/domain/entities/alert_type.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../attendance/presentation/widgets/attendance_card.dart';
import '../../../incidents/presentation/widgets/incident_card.dart';
import '../providers/activity_feed_providers.dart';
import '../widgets/activity_item_card.dart';
import '../widgets/alert_item_card.dart';

enum AlertSeverityFilter {
  all,
  critical,
  high,
  medium,
  low,
}

class AlertsActivityFeedScreen extends ConsumerStatefulWidget {
  const AlertsActivityFeedScreen({super.key});

  @override
  ConsumerState<AlertsActivityFeedScreen> createState() =>
      _AlertsActivityFeedScreenState();
}

class _AlertsActivityFeedScreenState
    extends ConsumerState<AlertsActivityFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AlertSeverityFilter _selectedAlertFilter = AlertSeverityFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Alerts & Activity Feed'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondaryLight,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active_rounded), text: 'Alerts'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Incidents'),
            Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Attendance'),
            Tab(icon: Icon(Icons.history_rounded), text: 'Activity Audit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAlertsTab(theme),
          _buildIncidentsTab(theme),
          _buildAttendanceTab(theme),
          _buildActivityTab(theme),
        ],
      ),
    );
  }

  // 1. Recent Alerts Section with Severity Filtering
  Widget _buildAlertsTab(ThemeData theme) {
    final alertsAsync = ref.watch(recentAlertsFeedProvider);

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAlertFilterChip(
                  label: 'All',
                  filter: AlertSeverityFilter.all,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _buildAlertFilterChip(
                  label: 'Critical',
                  filter: AlertSeverityFilter.critical,
                  icon: Icons.warning_rounded,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 8),
                _buildAlertFilterChip(
                  label: 'High',
                  filter: AlertSeverityFilter.high,
                  icon: Icons.priority_high_rounded,
                  color: Colors.orange.shade800,
                ),
                const SizedBox(width: 8),
                _buildAlertFilterChip(
                  label: 'Medium',
                  filter: AlertSeverityFilter.medium,
                  icon: Icons.notification_important_rounded,
                  color: Colors.amber.shade900,
                ),
                const SizedBox(width: 8),
                _buildAlertFilterChip(
                  label: 'Low',
                  filter: AlertSeverityFilter.low,
                  icon: Icons.info_outline_rounded,
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),

        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recentAlertsFeedProvider);
              await ref.read(recentAlertsFeedProvider.future);
            },
            child: alertsAsync.when(
              data: (alerts) {
                if (alerts.isEmpty) {
                  return _buildEmptySection(
                    icon: Icons.notifications_off_outlined,
                    title: 'No Recent Operational Alerts',
                    subtitle:
                        'Overdue shift notices and critical alerts will appear here.',
                  );
                }

                final filteredAlerts = alerts.where((alert) {
                  switch (_selectedAlertFilter) {
                    case AlertSeverityFilter.all:
                      return true;
                    case AlertSeverityFilter.critical:
                      return alert.type == AlertType.criticalIncident;
                    case AlertSeverityFilter.high:
                      return alert.type == AlertType.understaffedSite;
                    case AlertSeverityFilter.medium:
                      return alert.type == AlertType.missedShift;
                    case AlertSeverityFilter.low:
                      return alert.type == AlertType.lateCheckIn;
                  }
                }).toList();

                if (filteredAlerts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.filter_list_off_rounded,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'No ${_selectedAlertFilter.name.toUpperCase()} alerts found',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedAlertFilter = AlertSeverityFilter.all;
                              });
                            },
                            child: const Text('Show All Alerts'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = filteredAlerts[index];
                    return AlertItemCard(alert: alert);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorSection(
                error: error.toString(),
                onRetry: () => ref.invalidate(recentAlertsFeedProvider),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertFilterChip({
    required String label,
    required AlertSeverityFilter filter,
    required Color color,
    IconData? icon,
  }) {
    final isSelected = _selectedAlertFilter == filter;

    return ChoiceChip(
      label: Text(label),
      avatar: icon != null
          ? Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : color,
            )
          : null,
      selected: isSelected,
      selectedColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? color : AppColors.borderLight,
        ),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedAlertFilter = filter;
          });
        }
      },
    );
  }

  // 2. Recent Incidents Section
  Widget _buildIncidentsTab(ThemeData theme) {
    final incidentsAsync = ref.watch(recentIncidentsFeedProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentIncidentsFeedProvider);
        await ref.read(recentIncidentsFeedProvider.future);
      },
      child: incidentsAsync.when(
        data: (incidents) {
          if (incidents.isEmpty) {
            return _buildEmptySection(
              icon: Icons.report_off_outlined,
              title: 'No Recent Incidents',
              subtitle: 'Reported security anomalies will appear here.',
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return IncidentCard(incident: incident);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorSection(
          error: error.toString(),
          onRetry: () => ref.invalidate(recentIncidentsFeedProvider),
        ),
      ),
    );
  }

  // 3. Recent Attendance Section
  Widget _buildAttendanceTab(ThemeData theme) {
    final attendanceAsync = ref.watch(recentAttendanceFeedProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentAttendanceFeedProvider);
        await ref.read(recentAttendanceFeedProvider.future);
      },
      child: attendanceAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return _buildEmptySection(
              icon: Icons.event_available_outlined,
              title: 'No Recent Attendance Records',
              subtitle:
                  'Guard duty check-in and check-out activity will appear here.',
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return AttendanceCard(record: record);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorSection(
          error: error.toString(),
          onRetry: () => ref.invalidate(recentAttendanceFeedProvider),
        ),
      ),
    );
  }

  // 4. Recent Activity (Audit Log) Section
  Widget _buildActivityTab(ThemeData theme) {
    final auditAsync = ref.watch(recentAuditActivityProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recentAuditActivityProvider);
        await ref.read(recentAuditActivityProvider.future);
      },
      child: auditAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return _buildEmptySection(
              icon: Icons.history_toggle_off,
              title: 'No Recent Audit Activity',
              subtitle: 'Operational audit event logs will appear here.',
            );
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final auditLog = logs[index];
              return ActivityItemCard(auditLog: auditLog);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorSection(
          error: error.toString(),
          onRetry: () => ref.invalidate(recentAuditActivityProvider),
        ),
      ),
    );
  }

  Widget _buildEmptySection({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
