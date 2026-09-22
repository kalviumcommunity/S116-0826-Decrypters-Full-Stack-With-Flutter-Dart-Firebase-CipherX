/// Production phone validation utilities for Cipher-X.
/// Enforces 10-digit Indian mobile numbers while safely preserving
/// existing stored backend phone formats.
class PhoneValidator {
  PhoneValidator._();

  /// Regex detecting any alphabetic characters in the input
  static final RegExp _alphaRegExp = RegExp(r'[a-zA-Z]');

  /// Sanitizes raw or pasted phone input by stripping whitespace, hyphens, and parentheses.
  static String sanitize(String input) {
    return input.replaceAll(RegExp(r'[\s\-()]+'), '').trim();
  }

  /// Extracts the core 10 digits if an Indian country prefix (+91 or 91) is attached.
  static String extractTenDigits(String cleaned) {
    var digitsOnly = cleaned.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      return digitsOnly.substring(2);
    }
    if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      return digitsOnly.substring(1);
    }
    return digitsOnly;
  }

  /// Validates phone number input.
  /// Returns null if valid, or a descriptive error message if invalid.
  static String? validate(String? input, {bool isRequired = true}) {
    if (input == null || input.trim().isEmpty) {
      if (!isRequired) return null;
      return 'Phone number cannot be empty.';
    }

    final trimmed = input.trim();

    // Check for alphabetic characters
    if (_alphaRegExp.hasMatch(trimmed)) {
      return 'Phone number cannot contain letters.';
    }

    // Preserve existing international stored phone format (e.g. +1 555-0199 or legacy numbers)
    // If it starts with '+' and is not +91 (e.g., US/UK/other legacy test accounts)
    if (trimmed.startsWith('+') && !trimmed.startsWith('+91')) {
      final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
      if (digits.length >= 7 && digits.length <= 15) {
        return null;
      }
    }

    final sanitized = sanitize(trimmed);
    final coreDigits = extractTenDigits(sanitized);

    // Validate 10 digit requirement
    if (coreDigits.length < 10) {
      return 'Phone number must contain exactly 10 digits.';
    }
    if (coreDigits.length > 10) {
      return 'Phone number must contain exactly 10 digits.';
    }

    return null;
  }
}
