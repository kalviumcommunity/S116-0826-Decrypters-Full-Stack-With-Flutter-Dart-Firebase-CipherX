import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/evidence_item.dart';
import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';
import '../providers/admin_incident_providers.dart';
import '../providers/evidence_providers.dart';
import '../widgets/admin_evidence_viewer_dialog.dart';
import '../widgets/admin_resolve_incident_dialog.dart';

/// Screen presenting complete operational details of an incident for administrator review,
/// status advancement, attached evidence inspection, and resolution.
class AdminIncidentDetailScreen extends ConsumerWidget {
  final String incidentId;
  final Incident? initialIncident;

  const AdminIncidentDetailScreen({
    super.key,
    required this.incidentId,
    this.initialIncident,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final liveIncidentAsync =
        ref.watch(adminIncidentDetailStreamProvider(incidentId));
    final actionState = ref.watch(adminIncidentActionControllerProvider);
    final evidenceAsync = ref.watch(incidentEvidenceListProvider(incidentId));

    final incident = liveIncidentAsync.asData?.value ?? initialIncident;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Details'),
      ),
      body: incident == null
          ? (liveIncidentAsync.isLoading
              ? const Center(child: CircularProgressIndicator())
              : const Center(
                  child: Text('Incident not found or access denied.'),
                ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Action error notification
                  if (actionState.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              actionState.errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Header Card
                  _buildHeaderCard(context, incident),
                  const SizedBox(height: 16),

                  // Operational Information Card
                  _buildOperationalCard(context, incident),
                  const SizedBox(height: 16),

                  // Resolution Information Card (if resolved)
                  if (incident.status == IncidentStatus.resolved) ...[
                    _buildResolutionCard(context, incident),
                    const SizedBox(height: 16),
                  ],

                  // Attached Evidence Section (PR #27 Integration)
                  _buildEvidenceSection(context, ref, evidenceAsync),
                  const SizedBox(height: 24),

                  // Lifecycle Action Buttons
                  _buildActionButtons(context, ref, incident, actionState),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Incident incident) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    incident.type,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:
                        _statusColor(incident.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _statusColor(incident.status)),
                  ),
                  child: Text(
                    incident.status.name.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _statusColor(incident.status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _severityColor(incident.severity)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Severity: ${incident.severity.name.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _severityColor(incident.severity),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  incident.createdAt.toLocal().toString().substring(0, 16),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              incident.description,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationalCard(BuildContext context, Incident incident) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operational Metadata',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            _infoRow(Icons.location_city, 'Site ID', incident.siteId),
            const SizedBox(height: 8),
            _infoRow(Icons.person_outline, 'Reported By', incident.reportedBy),
            const SizedBox(height: 8),
            _infoRow(
              Icons.my_location,
              'Coordinates',
              incident.hasLocation
                  ? '${incident.latitude!.toStringAsFixed(5)}, ${incident.longitude!.toStringAsFixed(5)}'
                  : 'Not provided',
            ),
            const SizedBox(height: 8),
            _infoRow(
              Icons.update,
              'Last Updated',
              incident.updatedAt.toLocal().toString().substring(0, 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionCard(BuildContext context, Incident incident) {
    return Card(
      elevation: 1,
      color: Colors.green.shade50.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Resolution Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow(
                Icons.person, 'Resolved By', incident.resolvedBy ?? 'Unknown'),
            const SizedBox(height: 8),
            _infoRow(
              Icons.done_all,
              'Resolved At',
              incident.resolvedAt?.toLocal().toString().substring(0, 16) ??
                  'N/A',
            ),
            if (incident.resolution != null &&
                incident.resolution!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Resolution Notes:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                incident.resolution!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<EvidenceItem>> evidenceAsync,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attached Evidence',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                evidenceAsync.maybeWhen(
                  data: (items) => Text(
                    '${items.length} files',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            evidenceAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Failed to load evidence: $err',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No evidence files uploaded for this incident.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    final isPdf = item.contentType == 'application/pdf';

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isPdf ? Icons.picture_as_pdf : Icons.image,
                        color: isPdf ? Colors.red : Colors.blue,
                      ),
                      title: Text(
                        item.fileName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: Text(
                        '${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AdminEvidenceViewerDialog(item: item),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    Incident incident,
    AdminIncidentActionState actionState,
  ) {
    final busy = actionState.isSubmitting;

    if (incident.status == IncidentStatus.resolved) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'This incident has been resolved and closed.',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incident.status == IncidentStatus.open)
          ElevatedButton.icon(
            key: const Key('start_investigation_button'),
            icon: const Icon(Icons.search),
            label: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Investigation'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: busy
                ? null
                : () async {
                    await ref
                        .read(adminIncidentActionControllerProvider.notifier)
                        .updateStatus(
                          incidentId: incident.incidentId,
                          newStatus: IncidentStatus.investigating,
                        );
                  },
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          key: const Key('resolve_incident_button'),
          icon: const Icon(Icons.check_circle_outline),
          label: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Resolve Incident'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: busy
              ? null
              : () async {
                  await showDialog(
                    context: context,
                    builder: (_) => AdminResolveIncidentDialog(
                      incidentId: incident.incidentId,
                      isSubmitting: busy,
                      onResolve: (notes) async {
                        return await ref
                            .read(
                                adminIncidentActionControllerProvider.notifier)
                            .resolveIncident(
                              incidentId: incident.incidentId,
                              resolutionText: notes,
                            );
                      },
                    ),
                  );
                },
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
