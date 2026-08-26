import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/admin/presentation/screens/guards/guard_details_screen.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/repositories/guard_repository.dart';
import 'package:cipher_x/features/guards/presentation/providers/guard_providers.dart';

class MockGuardRepository extends Mock implements GuardRepository {}

void main() {
  late MockGuardRepository mockRepository;

  final tNow = DateTime(2026, 8, 25, 12, 0, 0);

  final tGuard = Guard(
    guardId: 'g-100',
    organizationId: 'org-100',
    name: 'Officer David Miller',
    employeeId: 'EMP-777',
    phone: '+1 555-9988',
    email: 'david.miller@cipherx.com',
    status: GuardStatus.active,
    createdAt: tNow,
  );

  setUpAll(() {
    registerFallbackValue(GuardStatus.inactive);
  });

  setUp(() {
    mockRepository = MockGuardRepository();
  });

  group('GuardDetailsScreen Widget Tests', () {
    testWidgets('renders guard detail fields and status badge',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: GuardDetailsScreen(guard: tGuard),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Officer David Miller'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.text('EMP-777'), findsOneWidget);
      expect(find.text('+1 555-9988'), findsOneWidget);
      expect(find.text('david.miller@cipherx.com'), findsOneWidget);
      expect(find.text('Deactivate Guard'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when status toggle button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: GuardDetailsScreen(guard: tGuard),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deactivateBtn = find.text('Deactivate Guard');
      await tester.ensureVisible(deactivateBtn);
      await tester.tap(deactivateBtn);
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Guard?'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to deactivate'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Deactivate'), findsOneWidget);
    });

    testWidgets(
        'cancelling dialog dismisses confirmation without repository call',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guardRepositoryProvider.overrideWithValue(mockRepository),
          ],
          child: MaterialApp(
            home: GuardDetailsScreen(guard: tGuard),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final deactivateBtn = find.text('Deactivate Guard');
      await tester.ensureVisible(deactivateBtn);
      await tester.tap(deactivateBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Deactivate Guard?'), findsNothing);
      verifyNever(
        () => mockRepository.updateGuardStatus(
          organizationId: any(named: 'organizationId'),
          guardId: any(named: 'guardId'),
          status: any(named: 'status'),
        ),
      );
    });
  });
}
