import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../core/widgets/entity_list_item.dart';
import '../../../../guards/domain/entities/guard.dart';
import '../../../../guards/presentation/providers/guard_providers.dart';

class GuardListScreen extends ConsumerStatefulWidget {
  const GuardListScreen({super.key});

  @override
  ConsumerState<GuardListScreen> createState() => _GuardListScreenState();
}

class _GuardListScreenState extends ConsumerState<GuardListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final guardsAsync = ref.watch(guardsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Guards'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or employee ID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: guardsAsync.when(
        data: (guards) {
          final filteredGuards = guards.where((guard) {
            final nameMatch = guard.name.toLowerCase().contains(_searchQuery);
            final idMatch = guard.employeeId.toLowerCase().contains(
                  _searchQuery,
                );
            return nameMatch || idMatch;
          }).toList();

          if (guards.isEmpty) {
            return const Center(
              child: Text('No guards yet — add your first guard'),
            );
          }

          if (filteredGuards.isEmpty) {
            return const Center(child: Text('No guards match your search.'));
          }

          return ListView.builder(
            itemCount: filteredGuards.length,
            itemBuilder: (context, index) {
              final guard = filteredGuards[index];
              return EntityListItem(
                title: guard.name,
                subtitle: 'ID: ${guard.employeeId}',
                avatarUrl: guard.photoUrl,
                badge: _buildStatusBadge(context, guard.status),
                onTap: () {
                  context.push(AppRoutes.adminGuardDetails, extra: guard);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading guards: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(guardsStreamProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.adminGuardCreate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GuardStatus status) {
    final isActive = status == GuardStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.2)
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: isActive
                  ? Colors.green[800]
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
