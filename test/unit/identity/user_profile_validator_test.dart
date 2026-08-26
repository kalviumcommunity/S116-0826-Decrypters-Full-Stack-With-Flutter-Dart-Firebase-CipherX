import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:cipher_x/features/identity/domain/failures/identity_failure.dart';
import 'package:cipher_x/features/identity/domain/validators/user_profile_validator.dart';

void main() {
  group('UserProfileValidator Tests', () {
    const validProfile = UserProfile(
      uid: 'u123',
      email: 'guard@cipherx.com',
      displayName: 'Guard Alex',
      phone: '+1 555-0199',
      organizationId: 'org_001',
    );

    test('passes validation for valid profile', () {
      expect(
        () => UserProfileValidator.validate(validProfile),
        returnsNormally,
      );
    });

    test('throws ProfileValidationFailure when UID is empty', () {
      final invalid = validProfile.copyWith(uid: '');
      expect(
        () => UserProfileValidator.validate(invalid),
        throwsA(isA<ProfileValidationFailure>()),
      );
    });

    test('throws ProfileValidationFailure when email is invalid', () {
      final invalid = validProfile.copyWith(email: 'invalid-email');
      expect(
        () => UserProfileValidator.validate(invalid),
        throwsA(isA<ProfileValidationFailure>()),
      );
    });

    test('throws ProfileValidationFailure when displayName is empty', () {
      final invalid = validProfile.copyWith(displayName: '');
      expect(
        () => UserProfileValidator.validate(invalid),
        throwsA(isA<ProfileValidationFailure>()),
      );
    });

    test('throws ProfileValidationFailure when organizationId is empty', () {
      final invalid = validProfile.copyWith(organizationId: '');
      expect(
        () => UserProfileValidator.validate(invalid),
        throwsA(isA<ProfileValidationFailure>()),
      );
    });

    test('validateDisplayName returns error message on short input', () {
      expect(UserProfileValidator.validateDisplayName('a'), isNotNull);
      expect(UserProfileValidator.validateDisplayName('Alex'), isNull);
    });

    test('validatePhone returns error message on short input', () {
      expect(UserProfileValidator.validatePhone('123'), isNotNull);
      expect(UserProfileValidator.validatePhone('+1 555-0199'), isNull);
    });

    test('validateOrganizationCode returns error message on short input', () {
      expect(UserProfileValidator.validateOrganizationCode('ab'), isNotNull);
      expect(UserProfileValidator.validateOrganizationCode('ORG001'), isNull);
    });
  });
}
