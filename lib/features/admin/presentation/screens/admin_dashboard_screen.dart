import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cipher_x/app/router/app_router.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Admin!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              key: const Key('admin_create_shift_btn'),
              onPressed: () => context.push(AppRoutes.adminShiftCreate),
              icon: const Icon(Icons.add_alarm),
              label: const Text('Create Shift'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('admin_manage_guards_btn'),
              onPressed: () => context.push(AppRoutes.adminGuards),
              icon: const Icon(Icons.people),
              label: const Text('Manage Guards'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
