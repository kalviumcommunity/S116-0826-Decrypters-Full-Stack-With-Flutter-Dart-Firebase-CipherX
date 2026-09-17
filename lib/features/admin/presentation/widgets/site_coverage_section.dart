import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/site_coverage_item.dart';
import '../providers/admin_dashboard_providers.dart';
import 'site_coverage_filter_bar.dart';
import 'site_coverage_item_card.dart';

/// Site Coverage section integrating reactive stream data, status filtering,
/// and responsive item list rendering for the Command Center.
class SiteCoverageSection extends ConsumerWidget {
  final void Function(SiteCoverageItem item)? onSiteTap;

  const SiteCoverageSection({
    super.key,
    this.onSiteTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentFilter = ref.watch(siteCoverageFilterProvider);
    final coverageAsync = ref.watch(filteredSiteCoverageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Site Staffing Coverage',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time guard attendance vs scheduled requirement',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SiteCoverageFilterBar(
          currentFilter: currentFilter,
          onFilterChanged: (filter) {
            ref.read(siteCoverageFilterProvider.notifier).state = filter;
          },
        ),
        const SizedBox(height: 12),
        coverageAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to load site coverage: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.domain_disabled_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No sites match the selected filter',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All active sites for your organization will appear here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return SiteCoverageItemCard(
                  key: Key('site_coverage_item_${item.siteId}'),
                  item: item,
                  onTap: onSiteTap != null ? () => onSiteTap!(item) : null,
                );
              },
            );
          },
        ),
      ],
    );
  }
}
