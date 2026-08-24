import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cipher_x/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:cipher_x/features/auth/domain/failures/auth_failure.dart';

void main() {
  group('AuthFailure Unit & Exception Mapping Tests', () {
    test('InvalidEmailFailure exposes default message & code', () {
      const failure = InvalidEmailFailure();
      expect(failure.message, equals('Enter a valid email address.'));
      expect(failure.code, equals('invalid-email'));
    });

    test('InvalidCredentialsFailure exposes default message & code', () {
      const failure = InvalidCredentialsFailure();
      expect(failure.message, equals('Email or password is incorrect.'));
      expect(failure.code, equals('invalid-credential'));
    });

    test('UserDisabledFailure exposes default message & code', () {
      const failure = UserDisabledFailure();
      expect(failure.message, equals('This account has been disabled.'));
      expect(failure.code, equals('user-disabled'));
    });

    test('NetworkRequestFailedFailure exposes default message & code', () {
      const failure = NetworkRequestFailedFailure();
      expect(
        failure.message,
        equals(
          'Unable to connect. Check your internet connection and try again.',
        ),
      );
      expect(failure.code, equals('network-request-failed'));
    });

    test('mapFirebaseAuthException maps known error codes correctly', () {
      final e1 = fb.FirebaseAuthException(
        code: 'invalid-email',
        message: 'Bad email',
      );
      final e2 = fb.FirebaseAuthException(
        code: 'user-not-found',
        message: 'No user',
      );
      final e3 = fb.FirebaseAuthException(
        code: 'wrong-password',
        message: 'Wrong pass',
      );
      final e4 = fb.FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'In use',
      );
      final e5 = fb.FirebaseAuthException(
        code: 'too-many-requests',
        message: 'Quota exceeded',
      );
      final e6 = fb.FirebaseAuthException(
        code: 'custom-unsupported-code',
        message: 'Custom error',
      );

      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e1),
        isA<InvalidEmailFailure>(),
      );
      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e2),
        isA<UserNotFoundFailure>(),
      );
      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e3),
        isA<WrongPasswordFailure>(),
      );
      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e4),
        isA<EmailAlreadyInUseFailure>(),
      );
      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e5),
        isA<TooManyRequestsFailure>(),
      );
      expect(
        FirebaseAuthDataSource.mapFirebaseAuthException(e6),
        isA<UnknownAuthFailure>(),
      );
    });
  });
}
