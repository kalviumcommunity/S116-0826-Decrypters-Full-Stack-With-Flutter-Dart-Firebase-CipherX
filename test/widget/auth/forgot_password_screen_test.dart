import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/domain/repositories/auth_repository.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/auth/presentation/screens/forgot_password_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepository)],
      child: const MaterialApp(home: ForgotPasswordScreen()),
    );
  }

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('renders ForgotPasswordScreen elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Forgot Your Password?'), findsOneWidget);
      expect(find.byKey(const Key('reset_email_field')), findsOneWidget);
      expect(find.byKey(const Key('reset_submit_button')), findsOneWidget);
    });

    testWidgets('triggers email validation error on empty submit', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byKey(const Key('reset_submit_button')));
      await tester.pump();

      expect(find.text('Email address is required.'), findsOneWidget);
      verifyNever(
        () => mockRepository.sendPasswordResetEmail(email: any(named: 'email')),
      );
    });

    testWidgets(
      'calls sendPasswordResetEmail and renders success feedback banner',
      (WidgetTester tester) async {
        when(
          () =>
              mockRepository.sendPasswordResetEmail(email: 'guard@cipherx.com'),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(buildTestableWidget());

        await tester.enterText(
          find.byKey(const Key('reset_email_field')),
          'guard@cipherx.com',
        );

        await tester.tap(find.byKey(const Key('reset_submit_button')));
        await tester.pumpAndSettle();

        verify(
          () =>
              mockRepository.sendPasswordResetEmail(email: 'guard@cipherx.com'),
        ).called(1);
        expect(
          find.byKey(const Key('reset_email_sent_banner')),
          findsOneWidget,
        );
      },
    );
  });
}
