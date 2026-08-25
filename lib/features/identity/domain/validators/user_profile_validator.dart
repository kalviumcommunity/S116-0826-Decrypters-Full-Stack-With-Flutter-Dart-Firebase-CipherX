import '../entities/user_profile.dart';
import '../failures/identity_failure.dart';

class UserProfileValidator {
  static void validate(UserProfile profile) {
    if (profile.uid.trim().isEmpty) {
      throw const ProfileValidationFailure('User UID cannot be empty.');
    }
    if (profile.email.trim().isEmpty || !profile.email.contains('@')) {
      throw const ProfileValidationFailure(
        'A valid email address is required.',
      );
    }
    if (profile.displayName.trim().isEmpty) {
      throw const ProfileValidationFailure('Display name is required.');
    }
    if (profile.displayName.trim().length < 2) {
      throw const ProfileValidationFailure(
        'Display name must be at least 2 characters.',
      );
    }
    if (profile.organizationId.trim().isEmpty) {
      throw const ProfileValidationFailure('Organization ID is required.');
    }
  }

  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Display name is required.';
    }
    if (value.trim().length < 2) {
      return 'Display name must be at least 2 characters.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (value.trim().length < 7) {
      return 'Please enter a valid phone number.';
    }
    return null;
  }

  static String? validateOrganizationCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Organization code is required.';
    }
    if (value.trim().length < 3) {
      return 'Organization code must be at least 3 characters.';
    }
    return null;
  }
}
