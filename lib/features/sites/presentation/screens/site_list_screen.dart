import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/entities/site.dart';
import '../providers/site_providers.dart';

class SiteListScreen extends ConsumerStatefulWidget {
  const SiteListScreen({super.key});

  @override
  ConsumerState<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends ConsumerState<SiteListScreen> {
  bool _includeInactive = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(sitesListProvider(_includeInactive));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Sites',
            onPressed: () =>
                ref.invalidate(sitesListProvider(_includeInactive)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Sites',
                    hintText: 'Filter by name or address...',
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
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Show Inactive Sites',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Switch(
                      value: _includeInactive,
                      onChanged: (value) {
                        setState(() {
                          _includeInactive = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: sitesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load sites',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(sitesListProvider(_includeInactive)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (sites) {
                final filteredSites = sites.where((site) {
                  if (_searchQuery.isEmpty) return true;
                  return site.name.toLowerCase().contains(_searchQuery) ||
                      site.address.toLowerCase().contains(_searchQuery);
                }).toList();

                if (sites.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_city_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No sites yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first site to start managing your organization\'s locations.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.adminSiteCreate),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Site'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filteredSites.isEmpty) {
                  return const Center(
                    child: Text('No sites matching search query.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredSites.length,
                  itemBuilder: (context, index) {
                    final site = filteredSites[index];
                    final isActive = site.status == SiteStatus.active;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                site.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle
                                        : Icons.cancel_outlined,
                                    size: 14,
                                    color: isActive
                                        ? Colors.green[800]
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.green[800]
                                          : Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.place_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    site.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.my_location,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.radar,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${site.geofenceRadius.toStringAsFixed(0)} meters',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRoutes.adminSiteDetails,
                          extra: site,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminSiteCreate),
        icon: const Icon(Icons.add),
        label: const Text('Create Site'),
      ),
    );
  }
}
