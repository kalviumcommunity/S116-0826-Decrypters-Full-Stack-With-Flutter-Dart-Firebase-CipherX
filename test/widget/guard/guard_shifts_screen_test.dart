import 'package:cipher_x/features/guard/presentation/providers/guard_shifts_provider.dart';
import 'package:cipher_x/features/guard/presentation/screens/guard_shifts_screen.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GuardShiftsScreen Widget Tests', () {
    testWidgets('1. Displays loading indicator when provider is in loading state',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardShiftsProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
          child: const MaterialApp(
            home: GuardShiftsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2. Displays empty state message when no shifts are assigned',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardShiftsProvider.overrideWith(
              (ref) => Stream.value(
                const GuardShiftsData(todayShift: null, upcomingShifts: []),
              ),
            ),
          ],
          child: const MaterialApp(
            home: GuardShiftsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Shifts Assigned'), findsOneWidget);
      expect(
        find.text('You have no assigned shifts for today or upcoming days.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('3. Displays error UI with retry action on stream failure',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardShiftsProvider.overrideWith(
              (ref) => Stream.error('Network unreachable'),
            ),
          ],
          child: const MaterialApp(
            home: GuardShiftsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading shifts'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('4. Displays Today\'s Shift when active or scheduled shift exists',
        (tester) async {
      final now = DateTime.now();
      final todayShift = Shift(
        shiftId: 'shift_today_101',
        organizationId: 'org_test',
        siteId: 'site_alpha',
        guardId: 'guard_1',
        date: now,
        startTime: const ShiftTime(hour: 8, minute: 0),
        endTime: const ShiftTime(hour: 16, minute: 0),
        status: ShiftStatus.scheduled,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardShiftsProvider.overrideWith(
              (ref) => Stream.value(
                GuardShiftsData(
                  todayShift: todayShift,
                  upcomingShifts: const [],
                ),
              ),
            ),
            siteProvider.overrideWith(
              (ref, siteId) async => null,
            ),
          ],
          child: const MaterialApp(
            home: GuardShiftsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Today's Shift"), findsOneWidget);
      expect(find.text('08:00 - 16:00'), findsOneWidget);
    });
  });
}
