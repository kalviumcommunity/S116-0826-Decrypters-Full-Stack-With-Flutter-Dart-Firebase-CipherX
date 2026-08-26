import '../entities/guard.dart';
import '../failures/guard_failure.dart';

class GuardValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(
    r'^\+?[0-9\s\-()]{7,20}$',
  );

  static String? validateOrganizationId(String organizationId) {
    if (organizationId.trim().isEmpty) {
      return 'Organization ID cannot be empty.';
    }
    return null;
  }

  static String? validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Guard name cannot be empty.';
    }
    if (trimmed.length < 2) {
      return 'Guard name must be at least 2 characters long.';
    }
    return null;
  }

  static String? validateEmployeeId(String employeeId) {
    if (employeeId.trim().isEmpty) {
      return 'Employee ID cannot be empty.';
    }
    return null;
  }

  static String? validatePhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) {
      return 'Phone number cannot be empty.';
    }
    if (!_phoneRegExp.hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return null;
    }
    final trimmed = email.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Normalizes string fields (trims strings, lowercases email if present)
  static Guard normalize(Guard guard) {
    return guard.copyWith(
      organizationId: guard.organizationId.trim(),
      name: guard.name.trim(),
      employeeId: guard.employeeId.trim(),
      phone: guard.phone.trim(),
      email: (guard.email != null && guard.email!.trim().isNotEmpty)
          ? guard.email!.trim().toLowerCase()
          : null,
    );
  }

  /// Validates all fields of [guard]. Throws [GuardValidationFailure] if invalid.
  /// Returns normalized [Guard] if valid.
  static Guard validate(Guard guard) {
    final orgErr = validateOrganizationId(guard.organizationId);
    if (orgErr != null) throw GuardValidationFailure(orgErr);

    final nameErr = validateName(guard.name);
    if (nameErr != null) throw GuardValidationFailure(nameErr);

    final empErr = validateEmployeeId(guard.employeeId);
    if (empErr != null) throw GuardValidationFailure(empErr);

    final phoneErr = validatePhone(guard.phone);
    if (phoneErr != null) throw GuardValidationFailure(phoneErr);

    final emailErr = validateEmail(guard.email);
    if (emailErr != null) throw GuardValidationFailure(emailErr);

    return normalize(guard);
  }
}
