import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/admin/presentation/screens/guards/guard_form_screen.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/failures/guard_failure.dart';
import 'package:cipher_x/features/guards/domain/repositories/guard_repository.dart';
import 'package:cipher_x/features/guards/presentation/providers/guard_providers.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/presentation/providers/identity_providers.dart';

class MockGuardRepository extends Mock implements GuardRepository {}

void main() {
  late MockGuardRepository mockRepository;

  const tAdminProfile = UserProfile(
    uid: 'admin-123',
    email: 'admin@cipherx.com',
    displayName: 'Admin User',
    phone: '+1 555-0000',
    organizationId: 'org-test-100',
    status: UserStatus.active,
    role: UserRole.admin,
  );

  setUpAll(() {
    registerFallbackValue(const Guard(
      guardId: 'fallback',
      organizationId: 'fallback',
      name: 'Fallback',
      employeeId: 'EMP-00',
      phone: '+1 555-0000',
    ));
  });

  setUp(() {
    mockRepository = MockGuardRepository();
  });

  Widget buildFormWidget({Guard? existingGuard}) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith(
          (ref) => const AsyncData(tAdminProfile),
        ),
        guardRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: MaterialApp(
        home: GuardFormScreen(existingGuard: existingGuard),
      ),
    );
  }

  group('GuardFormScreen Widget Tests', () {
    testWidgets('renders form fields in create mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      expect(find.text('Add New Guard'), findsOneWidget);
      expect(find.text('Create Guard'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(5));
    });

    testWidgets('shows validation errors when submitting empty form',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      final createButton = find.text('Create Guard');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Guard name cannot be empty.'), findsOneWidget);
      expect(find.text('Employee ID cannot be empty.'), findsOneWidget);
      expect(find.text('Phone number cannot be empty.'), findsOneWidget);
      verifyNever(() => mockRepository.createGuard(any()));
    });

    testWidgets('surfaces domain error message in SnackBar on submit failure',
        (WidgetTester tester) async {
      when(() => mockRepository.createGuard(any())).thenThrow(
        const GuardValidationFailure('Guard with this phone already exists.'),
      );

      await tester.pumpWidget(buildFormWidget());
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Officer John');
      await tester.enterText(textFields.at(1), 'EMP-100');
      await tester.enterText(textFields.at(2), '+15550199');

      final createButton = find.text('Create Guard');
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Guard with this phone already exists.'),
        findsOneWidget,
      );
    });
  });
}
