import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';
import '../providers/admin_incident_providers.dart';

/// Admin & Supervisor operational screen for monitoring, filtering, and resolving security incidents.
class AdminIncidentListScreen extends ConsumerStatefulWidget {
  const AdminIncidentListScreen({super.key});

  @override
  ConsumerState<AdminIncidentListScreen> createState() =>
      _AdminIncidentListScreenState();
}

class _AdminIncidentListScreenState
    extends ConsumerState<AdminIncidentListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilter = ref.watch(adminIncidentFilterProvider);
    final incidentsAsync = ref.watch(adminIncidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Incidents',
            onPressed: () => ref.invalidate(adminIncidentsStreamProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search incidents by title, description, or site...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // Filter Tabs
          _buildFilterTabs(context, currentFilter),
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
                final filteredIncidents = incidents.where((incident) {
                  if (_searchQuery.isEmpty) return true;
                  final typeMatch =
                      incident.type.toLowerCase().contains(_searchQuery);
                  final descMatch =
                      incident.description.toLowerCase().contains(_searchQuery);
                  final siteMatch =
                      incident.siteId.toLowerCase().contains(_searchQuery);
                  return typeMatch || descMatch || siteMatch;
                }).toList();

                if (incidents.isEmpty || filteredIncidents.isEmpty) {
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
                                ? (_searchQuery.isNotEmpty
                                    ? 'No matching incidents'
                                    : 'No incidents reported')
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
                                ? (_searchQuery.isNotEmpty
                                    ? 'Try adjusting your search terms.'
                                    : 'All security operational reports will appear here.')
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
                    itemCount: filteredIncidents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final incident = filteredIncidents[index];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severityColor = _getSeverityColor(incident.severity);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: incident.severity == IncidentSeverity.critical
              ? Colors.red.shade300
              : Colors.grey.shade200,
          width: incident.severity == IncidentSeverity.critical ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Status badge and Severity indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusChip(context, incident.status),
                  _buildSeverityBadge(incident.severity, severityColor),
                ],
              ),
              const SizedBox(height: 12),
              // Title / Type
              Text(
                incident.type,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Description
              Text(
                incident.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Metadata Row
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      incident.siteId,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(incident.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, IncidentStatus status) {
    Color bg;
    Color fg;
    switch (status) {
      case IncidentStatus.open:
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case IncidentStatus.investigating:
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        break;
      case IncidentStatus.resolved:
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(IncidentSeverity severity, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          severity == IncidentSeverity.critical
              ? Icons.warning_rounded
              : Icons.circle,
          size: 12,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          severity.name.toUpperCase(),
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.medium:
        return Colors.blue;
      case IncidentSeverity.high:
        return Colors.orange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
