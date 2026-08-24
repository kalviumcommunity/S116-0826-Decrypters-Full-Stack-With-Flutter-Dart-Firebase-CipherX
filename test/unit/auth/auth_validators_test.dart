import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/auth/presentation/utils/auth_validators.dart';

void main() {
  group('AuthValidators Unit Tests', () {
    group('validateEmail', () {
      test('returns error when email is null or empty', () {
        expect(
          AuthValidators.validateEmail(null),
          equals('Email address is required.'),
        );
        expect(
          AuthValidators.validateEmail('   '),
          equals('Email address is required.'),
        );
      });

      test('returns error for invalid email formats', () {
        expect(
          AuthValidators.validateEmail('invalidemail'),
          equals('Enter a valid email address.'),
        );
        expect(
          AuthValidators.validateEmail('invalid@'),
          equals('Enter a valid email address.'),
        );
        expect(
          AuthValidators.validateEmail('@domain.com'),
          equals('Enter a valid email address.'),
        );
      });

      test('returns null for valid email addresses', () {
        expect(AuthValidators.validateEmail('guard@cipherx.com'), isNull);
        expect(
          AuthValidators.validateEmail('admin.user@sub.domain.org'),
          isNull,
        );
      });
    });

    group('validatePassword', () {
      test('returns error when password is null or empty', () {
        expect(
          AuthValidators.validatePassword(null),
          equals('Password is required.'),
        );
        expect(
          AuthValidators.validatePassword(''),
          equals('Password is required.'),
        );
      });

      test('returns error when password is shorter than 6 characters', () {
        expect(
          AuthValidators.validatePassword('12345'),
          equals('Password must be at least 6 characters long.'),
        );
      });

      test('returns null when password is 6 characters or longer', () {
        expect(AuthValidators.validatePassword('123456'), isNull);
        expect(AuthValidators.validatePassword('StrongP@ssw0rd!'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns error when confirm password is null or empty', () {
        expect(
          AuthValidators.validateConfirmPassword(null, 'password123'),
          equals('Please confirm your password.'),
        );
      });

      test('returns error when confirm password does not match password', () {
        expect(
          AuthValidators.validateConfirmPassword('pass1', 'pass2'),
          equals('Passwords do not match.'),
        );
      });

      test('returns null when confirm password matches password', () {
        expect(
          AuthValidators.validateConfirmPassword('pass123', 'pass123'),
          isNull,
        );
      });
    });
  });
}
