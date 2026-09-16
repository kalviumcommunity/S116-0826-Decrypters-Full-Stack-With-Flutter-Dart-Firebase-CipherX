import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';
import '../providers/admin_incident_providers.dart';

/// Admin operational dashboard screen for managing security incidents.
class AdminIncidentListScreen extends ConsumerWidget {
  const AdminIncidentListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(adminIncidentFilterProvider);
    final incidentsAsync = ref.watch(adminIncidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(context, ref, currentFilter),
          const Divider(height: 1),
          // Incidents List / States
          Expanded(
            child: incidentsAsync.when(
              loading: () => const Center(
                key: Key('admin_incidents_loading'),
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => Center(
                key: const Key('admin_incidents_error'),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load incidents: $err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        key: const Key('admin_incidents_retry_button'),
                        onPressed: () =>
                            ref.refresh(adminIncidentsStreamProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (incidents) {
                if (incidents.isEmpty) {
                  return Center(
                    key: const Key('admin_incidents_empty'),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_turned_in_outlined,
                              size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            currentFilter == null
                                ? 'No incidents reported'
                                : 'No ${currentFilter.name.toUpperCase()} incidents',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentFilter == null
                                ? 'All security operational reports will appear here.'
                                : 'Try changing or clearing the status filter above.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminIncidentsStreamProvider);
                  },
                  child: ListView.separated(
                    key: const Key('admin_incidents_list'),
                    padding: const EdgeInsets.all(12),
                    itemCount: incidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final incident = incidents[index];
                      return _AdminIncidentCard(
                        incident: incident,
                        onTap: () {
                          context.push(
                            AppRoutes.adminIncidentDetails.replaceFirst(
                              ':incidentId',
                              incident.incidentId,
                            ),
                            extra: incident,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(
    BuildContext context,
    WidgetRef ref,
    IncidentStatus? currentFilter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: currentFilter == null,
            onSelected: () =>
                ref.read(adminIncidentFilterProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Open',
            isSelected: currentFilter == IncidentStatus.open,
            onSelected: () => ref
                .read(adminIncidentFilterProvider.notifier)
                .state = IncidentStatus.open,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Investigating',
            isSelected: currentFilter == IncidentStatus.investigating,
            onSelected: () => ref
                .read(adminIncidentFilterProvider.notifier)
                .state = IncidentStatus.investigating,
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Resolved',
            isSelected: currentFilter == IncidentStatus.resolved,
            onSelected: () => ref
                .read(adminIncidentFilterProvider.notifier)
                .state = IncidentStatus.resolved,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _AdminIncidentCard extends StatelessWidget {
  final Incident incident;
  final VoidCallback onTap;

  const _AdminIncidentCard({
    required this.incident,
    required this.onTap,
  });

  Color _severityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.green.shade600;
      case IncidentSeverity.medium:
        return Colors.orange.shade700;
      case IncidentSeverity.high:
        return Colors.deepOrange.shade600;
      case IncidentSeverity.critical:
        return Colors.red.shade700;
    }
  }

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Colors.blue.shade700;
      case IncidentStatus.investigating:
        return Colors.amber.shade800;
      case IncidentStatus.resolved:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      incident.type,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _statusColor(incident.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _statusColor(incident.status),
                      ),
                    ),
                    child: Text(
                      incident.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusColor(incident.status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _severityColor(incident.severity)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      incident.severity.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _severityColor(incident.severity),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.siteId,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  Text(
                    '${incident.createdAt.hour.toString().padLeft(2, '0')}:${incident.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
