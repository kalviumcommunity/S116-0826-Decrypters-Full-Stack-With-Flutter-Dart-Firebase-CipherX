import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';

void main() {
  final tNow = DateTime(2026, 8, 25, 12, 0, 0);

  final tGuard = Guard(
    guardId: 'test-guard-001',
    organizationId: 'test-org-001',
    name: 'Officer John Smith',
    employeeId: 'EMP-9001',
    phone: '+1 555-0199',
    email: 'john.smith@cipherx.com',
    photoUrl: 'https://example.com/photo.jpg',
    status: GuardStatus.active,
    createdAt: tNow,
    updatedAt: tNow,
  );

  group('Guard Model Unit Tests', () {
    test('supports value equality', () {
      final guard2 = Guard(
        guardId: 'test-guard-001',
        organizationId: 'test-org-001',
        name: 'Officer John Smith',
        employeeId: 'EMP-9001',
        phone: '+1 555-0199',
        email: 'john.smith@cipherx.com',
        photoUrl: 'https://example.com/photo.jpg',
        status: GuardStatus.active,
        createdAt: tNow,
        updatedAt: tNow,
      );

      expect(tGuard, equals(guard2));
      expect(tGuard.hashCode, equals(guard2.hashCode));
    });

    test('serializes to Map correctly', () {
      final map = tGuard.toMap();

      expect(map['guardId'], 'test-guard-001');
      expect(map['organizationId'], 'test-org-001');
      expect(map['name'], 'Officer John Smith');
      expect(map['employeeId'], 'EMP-9001');
      expect(map['phone'], '+1 555-0199');
      expect(map['email'], 'john.smith@cipherx.com');
      expect(map['photoUrl'], 'https://example.com/photo.jpg');
      expect(map['status'], 'active');
      expect(map['createdAt'], tNow.toIso8601String());
      expect(map['updatedAt'], tNow.toIso8601String());
    });

    test('deserializes from Map correctly', () {
      final map = {
        'guardId': 'test-guard-001',
        'organizationId': 'test-org-001',
        'name': 'Officer John Smith',
        'employeeId': 'EMP-9001',
        'phone': '+1 555-0199',
        'email': 'john.smith@cipherx.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'status': 'active',
        'createdAt': tNow.toIso8601String(),
        'updatedAt': tNow.toIso8601String(),
      };

      final result = Guard.fromMap(map);

      expect(result.guardId, 'test-guard-001');
      expect(result.organizationId, 'test-org-001');
      expect(result.name, 'Officer John Smith');
      expect(result.employeeId, 'EMP-9001');
      expect(result.status, GuardStatus.active);
      expect(result.createdAt, tNow);
    });

    test('handles status enum conversion correctly', () {
      expect(GuardStatus.fromMapString('active'), GuardStatus.active);
      expect(GuardStatus.fromMapString('inactive'), GuardStatus.inactive);
      expect(GuardStatus.fromMapString('ACTIVE'), GuardStatus.active);
      expect(GuardStatus.fromMapString('INACTIVE'), GuardStatus.inactive);
      expect(GuardStatus.fromMapString('unknown'), GuardStatus.active);
    });

    test('copyWith creates updated Guard copy', () {
      final updated = tGuard.copyWith(
        name: 'Officer Jane Smith',
        status: GuardStatus.inactive,
      );

      expect(updated.name, 'Officer Jane Smith');
      expect(updated.status, GuardStatus.inactive);
      expect(updated.guardId, tGuard.guardId);
      expect(updated.organizationId, tGuard.organizationId);
    });
  });
}
