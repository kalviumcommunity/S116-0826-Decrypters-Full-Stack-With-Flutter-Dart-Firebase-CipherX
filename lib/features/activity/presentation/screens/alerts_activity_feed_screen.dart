import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/presentation/widgets/attendance_card.dart';
import '../../../incidents/presentation/widgets/incident_card.dart';
import '../providers/activity_feed_providers.dart';
import '../widgets/activity_item_card.dart';
import '../widgets/alert_item_card.dart';

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

  Future<void> _refreshAllFeeds() async {
    ref.invalidate(recentAlertsFeedProvider);
    ref.invalidate(recentIncidentsFeedProvider);
    ref.invalidate(recentAttendanceFeedProvider);
    ref.invalidate(recentAuditActivityProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts & Activity Feed'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.notifications_active), text: 'Alerts'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Incidents'),
            Tab(icon: Icon(Icons.how_to_reg), text: 'Attendance'),
            Tab(icon: Icon(Icons.history), text: 'Activity Audit'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAllFeeds,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAlertsSection(theme),
            _buildIncidentsSection(theme),
            _buildAttendanceSection(theme),
            _buildActivitySection(theme),
          ],
        ),
      ),
    );
  }

  // 1. Recent Alerts Section
  Widget _buildAlertsSection(ThemeData theme) {
    final alertsAsync = ref.watch(recentAlertsFeedProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return _buildEmptySection(
            icon: Icons.notifications_off_outlined,
            title: 'No Recent Operational Alerts',
            subtitle:
                'Overdue shift notices and critical alerts will appear here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index];
            return AlertItemCard(alert: alert);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorSection(
        error: error.toString(),
        onRetry: () => ref.invalidate(recentAlertsFeedProvider),
      ),
    );
  }

  // 2. Recent Incidents Section
  Widget _buildIncidentsSection(ThemeData theme) {
    final incidentsAsync = ref.watch(recentIncidentsFeedProvider);

    return incidentsAsync.when(
      data: (incidents) {
        if (incidents.isEmpty) {
          return _buildEmptySection(
            icon: Icons.report_off_outlined,
            title: 'No Recent Incidents',
            subtitle: 'Reported security anomalies will appear here.',
          );
        }

        return ListView.builder(
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
    );
  }

  // 3. Recent Attendance Section
  Widget _buildAttendanceSection(ThemeData theme) {
    final attendanceAsync = ref.watch(recentAttendanceFeedProvider);

    return attendanceAsync.when(
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
    );
  }

  // 4. Recent Activity (Audit Log) Section
  Widget _buildActivitySection(ThemeData theme) {
    final auditAsync = ref.watch(recentAuditActivityProvider);

    return auditAsync.when(
      data: (logs) {
        if (logs.isEmpty) {
          return _buildEmptySection(
            icon: Icons.history_toggle_off,
            title: 'No Recent Audit Activity',
            subtitle: 'Operational audit event logs will appear here.',
          );
        }

        return ListView.builder(
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
        const SizedBox(height: 100),
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
