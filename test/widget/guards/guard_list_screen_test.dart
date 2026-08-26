import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/admin/presentation/screens/guards/guard_list_screen.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/presentation/providers/guard_providers.dart';

void main() {
  final tNow = DateTime(2026, 8, 25, 12, 0, 0);

  final tGuard1 = Guard(
    guardId: 'g-001',
    organizationId: 'org-100',
    name: 'Officer John Smith',
    employeeId: 'EMP-9001',
    phone: '+1 555-0199',
    status: GuardStatus.active,
    createdAt: tNow,
  );

  final tGuard2 = Guard(
    guardId: 'g-002',
    organizationId: 'org-100',
    name: 'Officer Sarah Connor',
    employeeId: 'EMP-9002',
    phone: '+1 555-0299',
    status: GuardStatus.inactive,
    createdAt: tNow,
  );

  group('GuardListScreen Widget Tests', () {
    testWidgets('displays loading indicator when guards stream is loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider.overrideWith(
              (ref) => const Stream.empty(),
            ),
          ],
          child: const MaterialApp(
            home: GuardListScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty message when guard list is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: GuardListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('No guards yet — add your first guard'),
        findsOneWidget,
      );
    });

    testWidgets('renders list of guards and status badges',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider.overrideWith(
              (ref) => Stream.value([tGuard1, tGuard2]),
            ),
          ],
          child: const MaterialApp(
            home: GuardListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Officer John Smith'), findsOneWidget);
      expect(find.text('ID: EMP-9001'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      expect(find.text('Officer Sarah Connor'), findsOneWidget);
      expect(find.text('ID: EMP-9002'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget);
    });

    testWidgets('filters guard list by search query on name and employee ID',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider.overrideWith(
              (ref) => Stream.value([tGuard1, tGuard2]),
            ),
          ],
          child: const MaterialApp(
            home: GuardListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Sarah',
      );
      await tester.pumpAndSettle();

      expect(find.text('Officer Sarah Connor'), findsOneWidget);
      expect(find.text('Officer John Smith'), findsNothing);

      await tester.enterText(
        find.byType(TextField),
        '9001',
      );
      await tester.pumpAndSettle();

      expect(find.text('Officer John Smith'), findsOneWidget);
      expect(find.text('Officer Sarah Connor'), findsNothing);
    });

    testWidgets('displays error message and retry button when stream fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider.overrideWith(
              (ref) => Stream.error(Exception('Database network error')),
            ),
          ],
          child: const MaterialApp(
            home: GuardListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading guards'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
