import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/incident.dart';
import '../providers/incident_providers.dart';

class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  ConsumerState<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final _descriptionController = TextEditingController();
  final _evidenceTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-fetch location on opening report screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(incidentReportControllerProvider.notifier)
          .fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _evidenceTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(incidentReportControllerProvider);
    final controller = ref.read(incidentReportControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Type Section
            _buildSectionLabel(theme, 'Incident Type', Icons.category),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<IncidentType>(
                  isExpanded: true,
                  value: formState.type,
                  onChanged: formState.isSubmitting
                      ? null
                      : (newType) {
                          if (newType != null) controller.setType(newType);
                        },
                  items: IncidentType.values.map((type) {
                    return DropdownMenuItem<IncidentType>(
                      value: type,
                      child: Text(type.displayName),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Severity Level Section
            _buildSectionLabel(theme, 'Severity Level', Icons.warning_amber),
            const SizedBox(height: 8),
            Row(
              children: IncidentSeverity.values.map((sev) {
                final isSelected = formState.severity == sev;
                final color = _getSeverityColor(sev);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8.0),
                      onTap: formState.isSubmitting
                          ? null
                          : () => controller.setSeverity(sev),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: isSelected
                                ? color
                                : color.withValues(alpha: 0.4),
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              sev.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description Section
            _buildSectionLabel(theme, 'Description', Icons.description),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: !formState.isSubmitting,
              maxLines: 5,
              onChanged: (val) => controller.setDescription(val),
              decoration: InputDecoration(
                hintText:
                    'Describe the incident in detail (what happened, individuals involved, immediate actions taken)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.all(12.0),
              ),
            ),
            const SizedBox(height: 20),

            // Location Section
            _buildSectionLabel(theme, 'Incident Location', Icons.location_on),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.my_location,
                      color: formState.latitude != null
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: formState.isFetchingLocation
                          ? const Text('Acquiring current GPS fix...')
                          : formState.latitude != null &&
                                  formState.longitude != null
                              ? Text(
                                  'Lat: ${formState.latitude!.toStringAsFixed(6)}, Lng: ${formState.longitude!.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : const Text(
                                  'Location not attached',
                                  style: TextStyle(color: Colors.grey),
                                ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed:
                          formState.isSubmitting || formState.isFetchingLocation
                              ? null
                              : () => controller.fetchCurrentLocation(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Evidence Entry Point Section (PR #26 Evidence Attachment Entry Point)
            _buildSectionLabel(
                theme, 'Evidence Attachments', Icons.attach_file),
            const SizedBox(height: 4),
            Text(
              'Attach photo evidence or media URL stubs for incident documentation.',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _evidenceTextController,
                    enabled: !formState.isSubmitting,
                    decoration: InputDecoration(
                      hintText: 'Enter photo/file URL or path stub...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: formState.isSubmitting
                      ? null
                      : () {
                          if (_evidenceTextController.text.trim().isNotEmpty) {
                            controller.addEvidenceUrl(
                              _evidenceTextController.text.trim(),
                            );
                            _evidenceTextController.clear();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
            if (formState.evidenceUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: formState.evidenceUrls.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final url = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image, size: 18, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              url,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.red),
                            onPressed: formState.isSubmitting
                                ? null
                                : () => controller.removeEvidenceUrl(idx),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            // Error Display
            if (formState.errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  formState.errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button with Double-Submit Prevention
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: formState.isSubmitting
                    ? null
                    : () async {
                        final success = await controller.submitIncident();
                        if (context.mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Incident report submitted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            context.pop();
                          }
                        }
                      },
                icon: formState.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  formState.isSubmitting
                      ? 'Submitting Report...'
                      : 'Submit Incident Report',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSeverityColor(formState.severity),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return Colors.red.shade700;
      case IncidentSeverity.high:
        return Colors.orange.shade800;
      case IncidentSeverity.medium:
        return Colors.amber.shade900;
      case IncidentSeverity.low:
        return Colors.blue.shade700;
    }
  }
}
