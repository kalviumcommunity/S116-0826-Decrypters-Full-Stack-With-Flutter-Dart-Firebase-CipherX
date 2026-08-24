import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/domain/failures/auth_failure.dart';
import 'package:cipher_x/features/auth/domain/repositories/auth_repository.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/auth/presentation/screens/register_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  const tUser = AuthUser(uid: 'u2', email: 'newguard@cipherx.com');

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: RegisterScreen()),
    );
  }

  group('RegisterScreen Widget Tests', () {
    testWidgets('renders all RegisterScreen fields and controls', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const Key('register_email_field')), findsOneWidget);
      expect(find.byKey(const Key('register_password_field')), findsOneWidget);
      expect(
        find.byKey(const Key('register_confirm_password_field')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('register_submit_button')), findsOneWidget);
    });

    testWidgets(
      'shows validation error when password confirmation mismatches',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestableWidget());

        await tester.enterText(
          find.byKey(const Key('register_email_field')),
          'newguard@cipherx.com',
        );
        await tester.enterText(
          find.byKey(const Key('register_password_field')),
          'password123',
        );
        await tester.enterText(
          find.byKey(const Key('register_confirm_password_field')),
          'password456',
        );

        await tester.tap(find.byKey(const Key('register_submit_button')));
        await tester.pump();

        expect(find.text('Passwords do not match.'), findsOneWidget);
        verifyNever(
          () => mockRepository.signUpWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    testWidgets('calls signUpWithEmailAndPassword on valid form submission', (
      WidgetTester tester,
    ) async {
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: 'newguard@cipherx.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => tUser);

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'newguard@cipherx.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pump();

      verify(
        () => mockRepository.signUpWithEmailAndPassword(
          email: 'newguard@cipherx.com',
          password: 'password123',
        ),
      ).called(1);
    });

    testWidgets('displays AuthFailure banner when email already in use', (
      WidgetTester tester,
    ) async {
      when(
        () => mockRepository.signUpWithEmailAndPassword(
          email: 'existing@cipherx.com',
          password: 'password123',
        ),
      ).thenThrow(const EmailAlreadyInUseFailure());

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(
        find.byKey(const Key('register_email_field')),
        'existing@cipherx.com',
      );
      await tester.enterText(
        find.byKey(const Key('register_password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('register_confirm_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('register_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('An account already exists with this email.'),
        findsOneWidget,
      );
    });
  });
}
