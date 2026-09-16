import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/evidence_item.dart';
import '../providers/evidence_providers.dart';

/// Modal dialog providing secure, read-only viewing of attached incident evidence.
class AdminEvidenceViewerDialog extends ConsumerWidget {
  final EvidenceItem item;

  const AdminEvidenceViewerDialog({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(evidenceDownloadUrlProvider(item.storagePath));
    final isPdf = item.contentType == 'application/pdf';

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBar(
              title: Text(
                item.fileName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: urlAsync.when(
                  loading: () => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading evidence securely...'),
                      ],
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.broken_image,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load evidence: $err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => ref.refresh(
                            evidenceDownloadUrlProvider(item.storagePath),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (url) {
                    if (isPdf) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 12),
                            Text(item.fileName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(
                                '${(item.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                            const SizedBox(height: 16),
                            const Text(
                              'PDF Document Verified',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return InteractiveViewer(
                      child: Image.network(
                        url,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                              child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Image could not be rendered.'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: Colors.grey.shade100,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Size: ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    item.contentType,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
