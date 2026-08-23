import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/domain/failures/auth_failure.dart';
import 'package:cipher_x/features/auth/domain/repositories/auth_repository.dart';
import 'package:cipher_x/features/auth/presentation/providers/auth_providers.dart';
import 'package:cipher_x/features/auth/presentation/screens/login_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  const tUser = AuthUser(uid: 'u1', email: 'guard@cipherx.com');

  setUp(() {
    mockRepository = MockAuthRepository();
    when(() => mockRepository.authStateChanges)
        .thenAnswer((_) => Stream.value(null));
  });

  Widget buildTestableWidget() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepository),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders all essential LoginScreen elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('CIPHER-X'), findsOneWidget);
      expect(find.text('Security Workforce Authentication'), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_button')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('register_navigation_link')), findsOneWidget);
    });

    testWidgets('triggers client validation errors when submitted empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pump();

      expect(find.text('Email address is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
      verifyNever(() => mockRepository.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('submits credentials to repository when form inputs are valid',
        (WidgetTester tester) async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: 'guard@cipherx.com',
            password: 'password123',
          )).thenAnswer((_) async => tUser);

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'guard@cipherx.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockRepository.signInWithEmailAndPassword(
            email: 'guard@cipherx.com',
            password: 'password123',
          )).called(1);
    });

    testWidgets('displays mapped AuthFailure message when login fails',
        (WidgetTester tester) async {
      when(() => mockRepository.signInWithEmailAndPassword(
            email: 'guard@cipherx.com',
            password: 'wrongpassword',
          )).thenThrow(const InvalidCredentialsFailure());

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'guard@cipherx.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );

      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email or password is incorrect.'), findsOneWidget);
    });
  });
}
