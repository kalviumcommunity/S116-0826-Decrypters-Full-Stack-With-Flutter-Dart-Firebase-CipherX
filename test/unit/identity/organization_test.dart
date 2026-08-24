import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/organization.dart';

void main() {
  const tOrg = Organization(
    id: 'org_001',
    name: 'Apex Security Services',
    code: 'ORG001',
    status: OrganizationStatus.active,
  );

  group('Organization Entity Tests', () {
    test('supports value equality', () {
      const org2 = Organization(
        id: 'org_001',
        name: 'Apex Security Services',
        code: 'ORG001',
        status: OrganizationStatus.active,
      );

      expect(tOrg, equals(org2));
    });

    test('serializes to Map correctly', () {
      final map = tOrg.toMap();

      expect(map['id'], 'org_001');
      expect(map['name'], 'Apex Security Services');
      expect(map['code'], 'ORG001');
      expect(map['status'], 'active');
    });

    test('deserializes from Map correctly', () {
      final map = {
        'id': 'org_001',
        'name': 'Apex Security Services',
        'code': 'ORG001',
        'status': 'active',
      };

      final result = Organization.fromMap(map);

      expect(result.id, 'org_001');
      expect(result.name, 'Apex Security Services');
      expect(result.code, 'ORG001');
      expect(result.status, OrganizationStatus.active);
    });

    test('handles status conversion correctly', () {
      expect(
        OrganizationStatus.fromMapString('active'),
        OrganizationStatus.active,
      );
      expect(
        OrganizationStatus.fromMapString('inactive'),
        OrganizationStatus.inactive,
      );
      expect(
        OrganizationStatus.fromMapString('unknown'),
        OrganizationStatus.active,
      );
    });

    test('copyWith creates modified copy', () {
      final updated = tOrg.copyWith(name: 'Updated Security Ltd');

      expect(updated.name, 'Updated Security Ltd');
      expect(updated.id, tOrg.id);
      expect(updated.code, tOrg.code);
    });
  });
}
