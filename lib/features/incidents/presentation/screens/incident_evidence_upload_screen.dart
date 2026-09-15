import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/evidence_file.dart';
import '../providers/evidence_providers.dart';

/// Screen allowing authenticated guards and supervisors to attach secure evidence files
/// to an existing incident with real progress tracking and validation feedback.
class IncidentEvidenceUploadScreen extends ConsumerStatefulWidget {
  final String incidentId;

  const IncidentEvidenceUploadScreen({
    super.key,
    required this.incidentId,
  });

  @override
  ConsumerState<IncidentEvidenceUploadScreen> createState() =>
      _IncidentEvidenceUploadScreenState();
}

class _IncidentEvidenceUploadScreenState
    extends ConsumerState<IncidentEvidenceUploadScreen> {
  EvidenceFile? _selectedFile;
  String? _localValidationError;

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  /// Simulates picking a sample photo for on-device demonstration/testing,
  /// or loads bytes from a provided file.
  void _selectSampleEvidence({required String type}) {
    setState(() {
      _localValidationError = null;
    });

    if (type == 'jpeg') {
      // Valid JPEG header bytes: FF D8 FF E0 ...
      final bytes = Uint8List.fromList([
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        ...List.filled(1024, 0x55),
      ]);
      setState(() {
        _selectedFile = EvidenceFile(
          name: 'incident_photo.jpg',
          bytes: bytes,
          contentType: 'image/jpeg',
        );
      });
    } else if (type == 'png') {
      // Valid PNG header bytes: 89 50 4E 47 0D 0A 1A 0A ...
      final bytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        ...List.filled(2048, 0x77),
      ]);
      setState(() {
        _selectedFile = EvidenceFile(
          name: 'security_badge_evidence.png',
          bytes: bytes,
          contentType: 'image/png',
        );
      });
    } else if (type == 'pdf') {
      // Valid PDF header bytes: %PDF- ...
      final bytes = Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
        0x31,
        0x2E,
        0x35,
        0x0A,
        ...List.filled(4096, 0x30),
      ]);
      setState(() {
        _selectedFile = EvidenceFile(
          name: 'incident_witness_report.pdf',
          bytes: bytes,
          contentType: 'application/pdf',
        );
      });
    }
  }

  Widget _buildStatusChip(EvidenceUploadStatus status) {
    Color chipColor;
    String label;
    IconData icon;

    switch (status) {
      case EvidenceUploadStatus.validating:
        chipColor = Colors.orange;
        label = 'Validating File...';
        icon = Icons.security;
        break;
      case EvidenceUploadStatus.compressing:
        chipColor = Colors.purple;
        label = 'Optimizing Image...';
        icon = Icons.compress;
        break;
      case EvidenceUploadStatus.uploading:
        chipColor = Colors.blue;
        label = 'Uploading to Storage...';
        icon = Icons.cloud_upload;
        break;
      case EvidenceUploadStatus.persisting:
        chipColor = Colors.indigo;
        label = 'Finalizing Record...';
        icon = Icons.save;
        break;
      case EvidenceUploadStatus.success:
        chipColor = Colors.green;
        label = 'Upload Complete';
        icon = Icons.check_circle;
        break;
      case EvidenceUploadStatus.failure:
        chipColor = Colors.red;
        label = 'Upload Failed';
        icon = Icons.error;
        break;
      case EvidenceUploadStatus.idle:
        chipColor = Colors.grey;
        label = 'Ready';
        icon = Icons.upload_file;
        break;
    }

    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 16),
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: chipColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uploadState = ref.watch(evidenceUploadControllerProvider);
    final controller = ref.read(evidenceUploadControllerProvider.notifier);
    final evidenceListAsync =
        ref.watch(incidentEvidenceListProvider(widget.incidentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Evidence'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Incident Context Banner
            Card(
              elevation: 1,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        color: Colors.blue.shade800, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Incident ID: ${widget.incidentId}',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Max file size: 10 MB. Supported: JPG, PNG, WEBP, PDF.',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File Selection Section
            Text(
              'Select Evidence to Attach',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Add JPEG Photo'),
                  onPressed: uploadState.isUploading
                      ? null
                      : () => _selectSampleEvidence(type: 'jpeg'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.image, size: 18),
                  label: const Text('Add PNG Image'),
                  onPressed: uploadState.isUploading
                      ? null
                      : () => _selectSampleEvidence(type: 'png'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Add PDF Document'),
                  onPressed: uploadState.isUploading
                      ? null
                      : () => _selectSampleEvidence(type: 'pdf'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Selected File Preview Card
            if (_selectedFile != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _selectedFile!.extension == 'pdf'
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          color: _selectedFile!.extension == 'pdf'
                              ? Colors.red
                              : Colors.blue,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFile!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${_formatBytes(_selectedFile!.sizeBytes)} • ${_selectedFile!.contentType}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!uploadState.isUploading)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                controller.reset();
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Progress Section
            if (uploadState.isUploading || uploadState.isSuccess) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatusChip(uploadState.status),
                        Text(
                          '${(uploadState.progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: uploadState.progress > 0
                          ? uploadState.progress
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    if (uploadState.totalBytes > 0)
                      Text(
                        '${_formatBytes(uploadState.bytesTransferred)} of ${_formatBytes(uploadState.totalBytes)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error Message Display
            if (uploadState.errorMessage != null ||
                _localValidationError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        uploadState.errorMessage ?? _localValidationError!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedFile == null ||
                              uploadState.isUploading)
                          ? null
                          : () async {
                              final success = await controller.uploadEvidence(
                                incidentId: widget.incidentId,
                                file: _selectedFile!,
                              );
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Evidence uploaded successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState(() {
                                  _selectedFile = null;
                                });
                              }
                            },
                      icon: uploadState.isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.cloud_upload),
                      label: Text(
                        uploadState.isUploading
                            ? 'Uploading...'
                            : 'Upload Evidence',
                      ),
                    ),
                  ),
                ),
                if (uploadState.hasError && _selectedFile != null) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: uploadState.isUploading
                          ? null
                          : () => controller.retry(
                                incidentId: widget.incidentId,
                                file: _selectedFile!,
                              ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),

            // Uploaded Evidence List Section
            Text(
              'Attached Evidence Records',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            evidenceListAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.attachment_outlined,
                            size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No evidence items attached yet.',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      tileColor: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: Icon(
                        item.contentType.contains('pdf')
                            ? Icons.picture_as_pdf
                            : Icons.image,
                        color: item.contentType.contains('pdf')
                            ? Colors.red
                            : Colors.blue,
                      ),
                      title: Text(
                        item.fileName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${_formatBytes(item.sizeBytes)} • ${_formatTimestamp(item.createdAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.lock_outline, size: 18),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(
                'Error loading evidence records: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
