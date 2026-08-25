import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/guards/domain/failures/guard_failure.dart';
import 'package:cipher_x/features/guards/domain/validators/guard_validator.dart';

void main() {
  const tValidGuard = Guard(
    guardId: 'g123',
    organizationId: 'org_001',
    name: 'John Doe',
    employeeId: 'EMP-1001',
    phone: '+1 555-0199',
    email: 'John.Doe@CipherX.com',
    status: GuardStatus.active,
  );

  group('GuardValidator Tests', () {
    test('passes validation for valid guard and normalizes fields', () {
      final normalized = GuardValidator.validate(tValidGuard);

      expect(normalized.name, 'John Doe');
      expect(normalized.employeeId, 'EMP-1001');
      expect(normalized.phone, '+1 555-0199');
      expect(normalized.email, 'john.doe@cipherx.com');
    });

    test('throws GuardValidationFailure when organizationId is empty', () {
      final invalid = tValidGuard.copyWith(organizationId: '  ');
      expect(
        () => GuardValidator.validate(invalid),
        throwsA(
          isA<GuardValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('Organization ID cannot be empty'),
          ),
        ),
      );
    });

    test('throws GuardValidationFailure when name is empty', () {
      final invalid = tValidGuard.copyWith(name: '  ');
      expect(
        () => GuardValidator.validate(invalid),
        throwsA(
          isA<GuardValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('Guard name cannot be empty'),
          ),
        ),
      );
    });

    test('throws GuardValidationFailure when employeeId is empty', () {
      final invalid = tValidGuard.copyWith(employeeId: '  ');
      expect(
        () => GuardValidator.validate(invalid),
        throwsA(
          isA<GuardValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('Employee ID cannot be empty'),
          ),
        ),
      );
    });

    test('throws GuardValidationFailure when phone is invalid', () {
      final invalid = tValidGuard.copyWith(phone: '123');
      expect(
        () => GuardValidator.validate(invalid),
        throwsA(
          isA<GuardValidationFailure>().having(
            (e) => e.message,
            'message',
            contains('Enter a valid phone number'),
          ),
        ),
      );
    });

    test(
      'throws GuardValidationFailure when email is syntactically invalid',
      () {
        final invalid = tValidGuard.copyWith(email: 'invalid-email');
        expect(
          () => GuardValidator.validate(invalid),
          throwsA(
            isA<GuardValidationFailure>().having(
              (e) => e.message,
              'message',
              contains('Enter a valid email address'),
            ),
          ),
        );
      },
    );

    test('allows null or empty email', () {
      const noEmail = Guard(
        guardId: 'g123',
        organizationId: 'org_001',
        name: 'John Doe',
        employeeId: 'EMP-1001',
        phone: '+1 555-0199',
        email: null,
        status: GuardStatus.active,
      );
      final validated = GuardValidator.validate(noEmail);
      expect(validated.email, isNull);
    });
  });
}
