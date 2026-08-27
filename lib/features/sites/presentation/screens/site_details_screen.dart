import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/site.dart';
import '../providers/site_providers.dart';

class SiteDetailsScreen extends ConsumerWidget {
  final Site site;

  const SiteDetailsScreen({
    super.key,
    required this.site,
  });

  Future<void> _showDeactivateDialog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Site?'),
        content: const Text(
          'This site will no longer be treated as active. Operational records will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(siteControllerProvider.notifier).updateSiteStatus(
                organizationId: site.organizationId,
                siteId: site.siteId,
                status: SiteStatus.inactive,
              );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Site deactivated successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to deactivate site.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = site.status == SiteStatus.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Site',
            onPressed: () => context.push(
              AppRoutes.adminSiteEdit,
              extra: site,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
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
                            site.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Chip(
                          avatar: Icon(
                            isActive ? Icons.check_circle : Icons.cancel,
                            size: 16,
                            color:
                                isActive ? Colors.green[800] : Colors.grey[800],
                          ),
                          label: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.green[800]
                                  : Colors.grey[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: isActive
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            site.address,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location & Geofence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.my_location),
                      title: const Text('Latitude'),
                      subtitle: Text(site.latitude.toString()),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.my_location_outlined),
                      title: const Text('Longitude'),
                      subtitle: Text(site.longitude.toString()),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.radar),
                      title: const Text('Geofence Radius'),
                      subtitle: Text('${site.geofenceRadius} meters'),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Metadata',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Divider(height: 24),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Created Date'),
                      subtitle: Text(
                        site.createdAt != null
                            ? site.createdAt!.toLocal().toString().split('.')[0]
                            : 'N/A',
                      ),
                      dense: true,
                    ),
                    ListTile(
                      leading: const Icon(Icons.update),
                      title: const Text('Last Updated'),
                      subtitle: Text(
                        site.updatedAt != null
                            ? site.updatedAt!.toLocal().toString().split('.')[0]
                            : 'N/A',
                      ),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(
                      AppRoutes.adminSiteEdit,
                      extra: site,
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Site'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeactivateDialog(context, ref),
                      icon: const Icon(Icons.block, color: Colors.red),
                      label: const Text(
                        'Deactivate',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
