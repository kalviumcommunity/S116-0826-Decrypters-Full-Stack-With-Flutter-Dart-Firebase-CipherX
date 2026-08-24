import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/organization.dart';
import 'package:cipher_x/features/identity/domain/failures/identity_failure.dart';
import 'package:cipher_x/features/identity/domain/validators/organization_validator.dart';

void main() {
  group('OrganizationValidator Tests', () {
    const validOrg = Organization(
      id: 'org_001',
      name: 'Apex Security Services',
      code: 'ORG001',
    );

    test('passes validation for valid organization', () {
      expect(() => OrganizationValidator.validate(validOrg), returnsNormally);
    });

    test('throws OrganizationValidationFailure when ID is empty', () {
      final invalid = validOrg.copyWith(id: '');
      expect(
        () => OrganizationValidator.validate(invalid),
        throwsA(isA<OrganizationValidationFailure>()),
      );
    });

    test('throws OrganizationValidationFailure when name is empty', () {
      final invalid = validOrg.copyWith(name: '');
      expect(
        () => OrganizationValidator.validate(invalid),
        throwsA(isA<OrganizationValidationFailure>()),
      );
    });

    test('throws OrganizationValidationFailure when code is empty', () {
      final invalid = validOrg.copyWith(code: '');
      expect(
        () => OrganizationValidator.validate(invalid),
        throwsA(isA<OrganizationValidationFailure>()),
      );
    });
  });
}
