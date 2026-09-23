import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/entity_list_item.dart';
import '../../../../../core/widgets/status_badge.dart';
import '../../../../guards/domain/entities/guard.dart';
import '../../../../guards/presentation/providers/guard_providers.dart';

enum GuardFilter { all, active, inactive }

class GuardListScreen extends ConsumerStatefulWidget {
  const GuardListScreen({super.key});

  @override
  ConsumerState<GuardListScreen> createState() => _GuardListScreenState();
}

class _GuardListScreenState extends ConsumerState<GuardListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  GuardFilter _filter = GuardFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guardsAsync = ref.watch(guardsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Guards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Guards',
            onPressed: () => ref.invalidate(guardsStreamProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search guards by name or ID...',
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
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterChip('All Guards', GuardFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Active', GuardFilter.active),
                    const SizedBox(width: 8),
                    _buildFilterChip('Inactive', GuardFilter.inactive),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(guardsStreamProvider);
          await ref.read(guardsStreamProvider.future);
        },
        child: guardsAsync.when(
          data: (guards) {
            final filteredGuards = guards.where((guard) {
              // Status filter
              if (_filter == GuardFilter.active &&
                  guard.status != GuardStatus.active) {
                return false;
              }
              if (_filter == GuardFilter.inactive &&
                  guard.status != GuardStatus.inactive) {
                return false;
              }

              // Search query
              if (_searchQuery.isNotEmpty) {
                final nameMatch =
                    guard.name.toLowerCase().contains(_searchQuery);
                final idMatch =
                    guard.employeeId.toLowerCase().contains(_searchQuery);
                return nameMatch || idMatch;
              }
              return true;
            }).toList();

            if (guards.isEmpty) {
              return _buildEmptyView(
                icon: Icons.person_off_outlined,
                title: 'No guards yet — add your first guard',
                message: 'Add security officers to deploy them to duty sites.',
                showAddButton: true,
              );
            }

            if (filteredGuards.isEmpty) {
              return _buildEmptyView(
                icon: Icons.search_off_rounded,
                title: 'No guards found',
                message:
                    'No guards match your search query or selected filter.',
                showAddButton: false,
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: filteredGuards.length,
              itemBuilder: (context, index) {
                final guard = filteredGuards[index];
                return EntityListItem(
                  title: guard.name,
                  subtitle: 'ID: ${guard.employeeId}',
                  avatarUrl: guard.photoUrl,
                  badge: guard.status == GuardStatus.active
                      ? StatusBadge.active()
                      : StatusBadge.inactive(),
                  onTap: () {
                    context.push(AppRoutes.adminGuardDetails, extra: guard);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading guards: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(guardsStreamProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push(AppRoutes.adminGuardCreate);
        },
        tooltip: 'Add Guard',
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }

  Widget _buildFilterChip(String label, GuardFilter filter) {
    final isSelected = _filter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = filter;
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondaryLight,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
    );
  }

  Widget _buildEmptyView({
    required IconData icon,
    required String title,
    required String message,
    required bool showAddButton,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 56, color: AppColors.textSecondaryLight),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  if (showAddButton) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.adminGuardCreate),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Guard'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
