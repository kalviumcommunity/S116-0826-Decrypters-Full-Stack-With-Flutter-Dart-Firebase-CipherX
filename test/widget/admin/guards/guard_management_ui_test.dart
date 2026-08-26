import 'package:cipher_x/features/admin/presentation/screens/guards/guard_details_screen.dart';
import 'package:cipher_x/features/admin/presentation/screens/guards/guard_form_screen.dart';
import 'package:cipher_x/features/admin/presentation/screens/guards/guard_list_screen.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/presentation/providers/guard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Guard Management UI Widget Tests', () {
    const testGuard = Guard(
      guardId: 'g-1',
      organizationId: 'org-1',
      name: 'John Test',
      employeeId: 'EMP-001',
      phone: '1234567890',
      status: GuardStatus.active,
    );

    testWidgets('GuardListScreen shows loading and then data', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard])),
          ],
          child: const MaterialApp(home: GuardListScreen()),
        ),
      );

      // Loading state might be brief, but we can check if it renders the data
      await tester.pumpAndSettle();

      expect(find.text('Manage Guards'), findsOneWidget);
      expect(find.text('John Test'), findsOneWidget);
      expect(find.text('ID: EMP-001'), findsOneWidget);
    });

    testWidgets('GuardListScreen search filtering works', (tester) async {
      const guard2 = Guard(
        guardId: 'g-2',
        organizationId: 'org-1',
        name: 'Alice Smith',
        employeeId: 'EMP-002',
        phone: '0987654321',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardsStreamProvider
                .overrideWith((ref) => Stream.value([testGuard, guard2])),
          ],
          child: const MaterialApp(home: GuardListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('John Test'), findsOneWidget);
      expect(find.text('Alice Smith'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'alice');
      await tester.pumpAndSettle();

      expect(find.text('John Test'), findsNothing);
      expect(find.text('Alice Smith'), findsOneWidget);
    });

    testWidgets('GuardFormScreen shows validation errors', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GuardFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Guard'));
      await tester.pump();

      expect(find.text('Please enter the guard\'s full name'), findsOneWidget);
      expect(find.text('Please enter an employee ID'), findsOneWidget);
      expect(find.text('Please enter a phone number'), findsOneWidget);
    });

    testWidgets('GuardDetailsScreen shows guard info and status toggle dialog',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: GuardDetailsScreen(guard: testGuard)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('John Test'), findsOneWidget);
      expect(find.text('EMP-001'), findsOneWidget);
      expect(find.text('Deactivate Guard'), findsOneWidget);

      await tester.tap(find.text('Deactivate Guard'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Guard?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
    });
  });
}
