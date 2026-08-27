import '../entities/organization.dart';
import '../failures/identity_failure.dart';

class OrganizationValidator {
  static void validate(Organization organization) {
    if (organization.id.trim().isEmpty) {
      throw const OrganizationValidationFailure(
        'Organization ID cannot be empty.',
      );
    }
    if (organization.name.trim().isEmpty) {
      throw const OrganizationValidationFailure(
        'Organization name is required.',
      );
    }
    if (organization.name.trim().length < 2) {
      throw const OrganizationValidationFailure(
        'Organization name must be at least 2 characters.',
      );
    }
    if (organization.code.trim().isEmpty) {
      throw const OrganizationValidationFailure(
        'Organization code is required.',
      );
    }
  }
}
