import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';

void main() {
  const tProfile = UserProfile(
    uid: 'u123',
    email: 'guard@cipherx.com',
    displayName: 'Guard Alex',
    phone: '+1 555-0199',
    organizationId: 'org_001',
    status: UserStatus.active,
    role: UserRole.guard,
  );

  group('UserProfile Entity Tests', () {
    test('supports value equality', () {
      const profile2 = UserProfile(
        uid: 'u123',
        email: 'guard@cipherx.com',
        displayName: 'Guard Alex',
        phone: '+1 555-0199',
        organizationId: 'org_001',
        status: UserStatus.active,
        role: UserRole.guard,
      );

      expect(tProfile, equals(profile2));
    });

    test('serializes to Map correctly', () {
      final map = tProfile.toMap();

      expect(map['uid'], 'u123');
      expect(map['email'], 'guard@cipherx.com');
      expect(map['displayName'], 'Guard Alex');
      expect(map['phone'], '+1 555-0199');
      expect(map['organizationId'], 'org_001');
      expect(map['status'], 'active');
      expect(map['role'], 'guard');
    });

    test('deserializes from Map correctly', () {
      final map = {
        'uid': 'u123',
        'email': 'guard@cipherx.com',
        'displayName': 'Guard Alex',
        'phone': '+1 555-0199',
        'organizationId': 'org_001',
        'status': 'active',
        'role': 'guard',
      };

      final result = UserProfile.fromMap(map);

      expect(result.uid, 'u123');
      expect(result.email, 'guard@cipherx.com');
      expect(result.displayName, 'Guard Alex');
      expect(result.organizationId, 'org_001');
      expect(result.status, UserStatus.active);
      expect(result.role, UserRole.guard);
    });

    test('handles status string conversion correctly', () {
      expect(UserStatus.fromMapString('active'), UserStatus.active);
      expect(UserStatus.fromMapString('inactive'), UserStatus.inactive);
      expect(UserStatus.fromMapString('suspended'), UserStatus.suspended);
      expect(UserStatus.fromMapString('unknown'), UserStatus.active);
    });

    test('handles role string conversion correctly', () {
      expect(UserRole.fromMapString('admin'), UserRole.admin);
      expect(UserRole.fromMapString('supervisor'), UserRole.supervisor);
      expect(UserRole.fromMapString('guard'), UserRole.guard);
      expect(UserRole.fromMapString('unknown'), UserRole.guard);
    });

    test('copyWith creates modified copy', () {
      final updated = tProfile.copyWith(displayName: 'New Name');

      expect(updated.displayName, 'New Name');
      expect(updated.uid, tProfile.uid);
      expect(updated.organizationId, tProfile.organizationId);
    });
  });
}
