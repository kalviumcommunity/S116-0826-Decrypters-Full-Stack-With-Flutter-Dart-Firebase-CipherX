import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/guard_shifts_provider.dart';
import '../widgets/shift_card.dart';

class GuardShiftsScreen extends ConsumerWidget {
  const GuardShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardShiftsAsync = ref.watch(guardShiftsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Shifts'),
        centerTitle: true,
      ),
      body: guardShiftsAsync.when(
        data: (data) {
          final todayShift = data.todayShift;
          final upcomingShifts = data.upcomingShifts;

          if (todayShift == null && upcomingShifts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(guardShiftsProvider);
              },
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No Shifts Assigned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You have no assigned shifts for today or upcoming days.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(guardShiftsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (todayShift != null) ...[
                  const Text(
                    "Today's Shift",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ShiftCard(shift: todayShift, isToday: true),
                  const SizedBox(height: 24),
                ],
                if (upcomingShifts.isNotEmpty) ...[
                  const Text(
                    'Upcoming Shifts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...upcomingShifts.map(
                    (shift) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ShiftCard(shift: shift),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
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
                'Error loading shifts: $error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(guardShiftsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
