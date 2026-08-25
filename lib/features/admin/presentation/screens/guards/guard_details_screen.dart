import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/router/app_router.dart';
import '../../../../guards/domain/entities/guard.dart';
import '../../../../guards/presentation/providers/guard_providers.dart';

class GuardDetailsScreen extends ConsumerWidget {
  final Guard guard;

  const GuardDetailsScreen({super.key, required this.guard});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guard Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push(AppRoutes.adminGuardEdit, extra: guard);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage:
                  guard.photoUrl != null ? NetworkImage(guard.photoUrl!) : null,
              child: guard.photoUrl == null
                  ? Text(
                      guard.name.isNotEmpty
                          ? guard.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 48,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              guard.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildStatusBadge(context, guard.status),
            const SizedBox(height: 32),
            _buildInfoCard(context, guard),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showStatusToggleDialog(context, ref),
                icon: Icon(
                  guard.status == GuardStatus.active
                      ? Icons.block
                      : Icons.check_circle_outline,
                  color: guard.status == GuardStatus.active
                      ? Theme.of(context).colorScheme.error
                      : Colors.green,
                ),
                label: Text(
                  guard.status == GuardStatus.active
                      ? 'Deactivate Guard'
                      : 'Activate Guard',
                  style: TextStyle(
                    color: guard.status == GuardStatus.active
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, Guard guard) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              Icons.badge_outlined,
              'Employee ID',
              guard.employeeId,
            ),
            const Divider(),
            _buildInfoRow(context, Icons.phone_outlined, 'Phone', guard.phone),
            if (guard.email != null && guard.email!.isNotEmpty) ...[
              const Divider(),
              _buildInfoRow(
                context,
                Icons.email_outlined,
                'Email',
                guard.email!,
              ),
            ],
            if (guard.createdAt != null) ...[
              const Divider(),
              _buildInfoRow(
                context,
                Icons.calendar_today_outlined,
                'Joined',
                DateFormat.yMMMd().format(guard.createdAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, GuardStatus status) {
    final isActive = status == GuardStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isActive
                  ? Colors.green[800]
                  : Theme.of(context).colorScheme.onErrorContainer,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Future<void> _showStatusToggleDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final isActive = guard.status == GuardStatus.active;
    final newStatus = isActive ? GuardStatus.inactive : GuardStatus.active;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isActive ? 'Deactivate Guard?' : 'Activate Guard?'),
          content: Text(
            isActive
                ? 'Are you sure you want to deactivate ${guard.name}? They will no longer be able to log in or be assigned to shifts.'
                : 'Are you sure you want to activate ${guard.name}? They will regain access to the platform.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isActive ? Theme.of(context).colorScheme.error : null,
              ),
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(guardControllerProvider.notifier).updateGuardStatus(
                organizationId: guard.organizationId,
                guardId: guard.guardId,
                status: newStatus,
              );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Guard successfully ${isActive ? 'deactivated' : 'activated'}.',
            ),
          ),
        );
        // Navigate back as the list will update automatically.
        context.pop();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update guard status.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
