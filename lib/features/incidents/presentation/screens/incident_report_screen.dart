import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../attendance/presentation/providers/attendance_providers.dart';
import '../../../sites/presentation/providers/site_providers.dart';
import '../../domain/entities/incident_severity.dart';
import '../providers/incident_providers.dart';

class IncidentReportScreen extends ConsumerStatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  ConsumerState<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState extends ConsumerState<IncidentReportScreen> {
  final _descriptionController = TextEditingController();

  static const List<String> _incidentTypes = [
    'Theft',
    'Vandalism',
    'Trespassing',
    'Equipment Failure',
    'Medical',
    'Unsecured Access',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return Colors.red.shade700;
      case IncidentSeverity.high:
        return Colors.orange.shade800;
      case IncidentSeverity.medium:
        return Colors.amber.shade800;
      case IncidentSeverity.low:
        return Colors.blue.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = ref.watch(incidentReportControllerProvider);
    final controller = ref.read(incidentReportControllerProvider.notifier);
    final activeAttendance = ref.watch(activeAttendanceProvider).asData?.value;
    final sitesAsync = ref.watch(sitesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Security Incident'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Type Section
            _buildSectionLabel(
                theme, 'Incident Classification', Icons.category),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _incidentTypes.contains(formState.type)
                  ? formState.type
                  : _incidentTypes.last,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 14.0,
                ),
              ),
              items: _incidentTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: formState.isSubmitting
                  ? null
                  : (val) {
                      if (val != null) controller.setType(val);
                    },
            ),
            const SizedBox(height: 20),

            // Site Selection Section
            _buildSectionLabel(theme, 'Associated Site', Icons.business),
            const SizedBox(height: 8),
            if (activeAttendance != null &&
                activeAttendance.siteId.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Shift Site: ${activeAttendance.siteId}',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              sitesAsync.when(
                data: (sites) {
                  if (sites.isNotEmpty) {
                    return DropdownButtonFormField<String>(
                      initialValue: (formState.siteId != null &&
                              sites.any((s) => s.siteId == formState.siteId))
                          ? formState.siteId
                          : null,
                      hint: const Text('Select a site...'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 14.0,
                        ),
                      ),
                      items: sites.map((s) {
                        return DropdownMenuItem<String>(
                          value: s.siteId,
                          child: Text('${s.name} (${s.siteId})'),
                        );
                      }).toList(),
                      onChanged: formState.isSubmitting
                          ? null
                          : (val) {
                              if (val != null) controller.setSiteId(val);
                            },
                    );
                  }
                  return TextFormField(
                    initialValue: formState.siteId ?? '',
                    decoration: InputDecoration(
                      labelText: 'Site ID',
                      hintText: 'Enter site ID...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onChanged: (val) => controller.setSiteId(val.trim()),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => TextFormField(
                  initialValue: formState.siteId ?? '',
                  decoration: InputDecoration(
                    labelText: 'Site ID',
                    hintText: 'Enter site ID...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (val) => controller.setSiteId(val.trim()),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Severity Section
            _buildSectionLabel(
                theme, 'Severity Level', Icons.warning_amber_rounded),
            const SizedBox(height: 8),
            Row(
              children: IncidentSeverity.values.map((sev) {
                final isSelected = formState.severity == sev;
                final color = _getSeverityColor(sev);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                    child: InkWell(
                      onTap: formState.isSubmitting
                          ? null
                          : () => controller.setSeverity(sev),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: color,
                            width: isSelected ? 2.0 : 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          sev.name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description Section
            _buildSectionLabel(
                theme, 'Incident Description', Icons.description),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              enabled: !formState.isSubmitting,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                hintText:
                    'Provide a clear, detailed explanation of the incident...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (val) => controller.setDescription(val),
            ),
            const SizedBox(height: 20),

            // Location Section
            _buildSectionLabel(theme, 'GPS Location', Icons.my_location),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    formState.latitude != null
                        ? Icons.location_on
                        : Icons.location_off_outlined,
                    color:
                        formState.latitude != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: formState.isFetchingLocation
                        ? const Text('Acquiring current GPS fix...')
                        : formState.latitude != null
                            ? Text(
                                'Lat: ${formState.latitude!.toStringAsFixed(4)}, Lng: ${formState.longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : const Text(
                                'Location not attached (optional)',
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

            // Submit Button
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
                                  'Incident report submitted successfully!',
                                ),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
}
