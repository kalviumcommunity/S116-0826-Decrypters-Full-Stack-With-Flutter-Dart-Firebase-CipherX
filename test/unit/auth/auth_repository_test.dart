import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cipher_x/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:cipher_x/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cipher_x/features/auth/domain/entities/auth_user.dart';
import 'package:cipher_x/features/auth/domain/failures/auth_failure.dart';

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

void main() {
  late MockFirebaseAuthDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  const tUser = AuthUser(
    uid: 'test_uid_123',
    email: 'guard@cipherx.com',
    displayName: 'Test Guard',
  );

  setUp(() {
    mockDataSource = MockFirebaseAuthDataSource();
    repository = AuthRepositoryImpl(dataSource: mockDataSource);
  });

  group('AuthRepositoryImpl Unit Tests', () {
    test('currentUser returns AuthUser from dataSource', () {
      when(() => mockDataSource.currentUser).thenReturn(tUser);

      final result = repository.currentUser;

      expect(result, equals(tUser));
      verify(() => mockDataSource.currentUser).called(1);
    });

    test('authStateChanges emits stream from dataSource', () async {
      when(() => mockDataSource.authStateChanges)
          .thenAnswer((_) => Stream.value(tUser));

      final streamResult = await repository.authStateChanges.first;

      expect(streamResult, equals(tUser));
      verify(() => mockDataSource.authStateChanges).called(1);
    });

    test('signInWithEmailAndPassword delegates to dataSource', () async {
      when(() => mockDataSource.signInWithEmailAndPassword(
            email: 'guard@cipherx.com',
            password: 'password123',
          )).thenAnswer((_) async => tUser);

      final result = await repository.signInWithEmailAndPassword(
        email: 'guard@cipherx.com',
        password: 'password123',
      );

      expect(result, equals(tUser));
      verify(() => mockDataSource.signInWithEmailAndPassword(
            email: 'guard@cipherx.com',
            password: 'password123',
          )).called(1);
    });

    test('signInWithEmailAndPassword propagates AuthFailure from dataSource',
        () async {
      when(() => mockDataSource.signInWithEmailAndPassword(
            email: 'wrong@cipherx.com',
            password: 'wrongpassword',
          )).thenThrow(const InvalidCredentialsFailure());

      expect(
        () => repository.signInWithEmailAndPassword(
          email: 'wrong@cipherx.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<InvalidCredentialsFailure>()),
      );
    });

    test('signUpWithEmailAndPassword delegates to dataSource', () async {
      when(() => mockDataSource.signUpWithEmailAndPassword(
            email: 'newguard@cipherx.com',
            password: 'password123',
          )).thenAnswer((_) async => tUser);

      final result = await repository.signUpWithEmailAndPassword(
        email: 'newguard@cipherx.com',
        password: 'password123',
      );

      expect(result, equals(tUser));
      verify(() => mockDataSource.signUpWithEmailAndPassword(
            email: 'newguard@cipherx.com',
            password: 'password123',
          )).called(1);
    });

    test('signOut delegates to dataSource', () async {
      when(() => mockDataSource.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockDataSource.signOut()).called(1);
    });

    test('sendPasswordResetEmail delegates to dataSource', () async {
      when(() =>
              mockDataSource.sendPasswordResetEmail(email: 'reset@cipherx.com'))
          .thenAnswer((_) async {});

      await repository.sendPasswordResetEmail(email: 'reset@cipherx.com');

      verify(() =>
              mockDataSource.sendPasswordResetEmail(email: 'reset@cipherx.com'))
          .called(1);
    });

    test('sendEmailVerification delegates to dataSource', () async {
      when(() => mockDataSource.sendEmailVerification())
          .thenAnswer((_) async {});

      await repository.sendEmailVerification();

      verify(() => mockDataSource.sendEmailVerification()).called(1);
    });
  });
}
