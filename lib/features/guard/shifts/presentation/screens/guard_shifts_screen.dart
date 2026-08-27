import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/guard_shifts_provider.dart';
import '../widgets/shift_card.dart';

class GuardShiftsScreen extends ConsumerWidget {
  const GuardShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(guardShiftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shifts'),
      ),
      body: shiftsAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            return ref.refresh(guardShiftsProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, "Today's Shift"),
              const SizedBox(height: 12),
              if (data.todayShift != null)
                ShiftCard(shift: data.todayShift!, isToday: true)
              else
                _buildEmptyState(
                  context,
                  message: 'No shift scheduled for today.',
                  icon: Icons.event_available,
                ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Upcoming Shifts'),
              const SizedBox(height: 12),
              if (data.upcomingShifts.isNotEmpty)
                ...data.upcomingShifts.map((shift) => ShiftCard(shift: shift))
              else
                _buildEmptyState(
                  context,
                  message: 'No upcoming shifts.',
                  icon: Icons.calendar_today,
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text("Couldn't load your shifts."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(guardShiftsProvider),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context,
      {required String message, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).disabledColor,
                ),
          ),
        ],
      ),
    );
  }
}
