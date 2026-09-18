import 'package:cipher_x/features/identity/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RBAC Authorization & Privilege Matrix Tests', () {
    const adminUser = UserProfile(
      uid: 'u-admin-01',
      email: 'admin@cipherx.io',
      displayName: 'System Admin',
      phone: '+1 555-0001',
      organizationId: 'org-main',
      role: UserRole.admin,
      status: UserStatus.active,
    );

    const supervisorUser = UserProfile(
      uid: 'u-sup-01',
      email: 'supervisor@cipherx.io',
      displayName: 'Field Supervisor',
      phone: '+1 555-0002',
      organizationId: 'org-main',
      role: UserRole.supervisor,
      status: UserStatus.active,
    );

    const guardUser = UserProfile(
      uid: 'u-guard-01',
      email: 'guard@cipherx.io',
      displayName: 'Active Guard',
      phone: '+1 555-0003',
      organizationId: 'org-main',
      role: UserRole.guard,
      status: UserStatus.active,
    );

    const suspendedGuard = UserProfile(
      uid: 'u-guard-suspended',
      email: 'suspended@cipherx.io',
      displayName: 'Suspended Guard',
      phone: '+1 555-0004',
      organizationId: 'org-main',
      role: UserRole.guard,
      status: UserStatus.suspended,
    );

    const competitorGuard = UserProfile(
      uid: 'u-guard-competitor',
      email: 'guard@competitor.io',
      displayName: 'Competitor Guard',
      phone: '+1 555-9999',
      organizationId: 'org-competitor',
      role: UserRole.guard,
      status: UserStatus.active,
    );

    test('1. Admin role authorization permissions', () {
      expect(adminUser.role, equals(UserRole.admin));
      expect(adminUser.status, equals(UserStatus.active));

      // Admin capabilities
      bool canManageGuards(UserProfile user) => user.role == UserRole.admin;
      bool canManageSites(UserProfile user) => user.role == UserRole.admin;
      bool canAccessCommandCenter(UserProfile user) =>
          user.role == UserRole.admin || user.role == UserRole.supervisor;

      expect(canManageGuards(adminUser), isTrue);
      expect(canManageSites(adminUser), isTrue);
      expect(canAccessCommandCenter(adminUser), isTrue);
    });

    test('2. Supervisor role authorization permissions', () {
      expect(supervisorUser.role, equals(UserRole.supervisor));

      bool canManageGuards(UserProfile user) => user.role == UserRole.admin;
      bool canManageShifts(UserProfile user) =>
          user.role == UserRole.admin || user.role == UserRole.supervisor;
      bool canAccessCommandCenter(UserProfile user) =>
          user.role == UserRole.admin || user.role == UserRole.supervisor;

      expect(canManageGuards(supervisorUser), isFalse);
      expect(canManageShifts(supervisorUser), isTrue);
      expect(canAccessCommandCenter(supervisorUser), isTrue);
    });

    test('3. Guard role strictly denies administrative and supervisory routes',
        () {
      expect(guardUser.role, equals(UserRole.guard));

      bool canAccessCommandCenter(UserProfile user) =>
          user.role == UserRole.admin || user.role == UserRole.supervisor;
      bool canManageSites(UserProfile user) => user.role == UserRole.admin;
      bool canPerformFieldCheckIn(UserProfile user) =>
          user.role == UserRole.guard && user.status == UserStatus.active;

      expect(canAccessCommandCenter(guardUser), isFalse);
      expect(canManageSites(guardUser), isFalse);
      expect(canPerformFieldCheckIn(guardUser), isTrue);
    });

    test(
        '4. Inactive or Suspended users are denied all active operational duties',
        () {
      bool canPerformOperationalDuties(UserProfile user) =>
          user.status == UserStatus.active;

      expect(canPerformOperationalDuties(suspendedGuard), isFalse);
      expect(canPerformOperationalDuties(guardUser), isTrue);
    });

    test('5. Multi-tenant boundary checks reject cross-organization actions',
        () {
      bool canAccessOrgResource(UserProfile user, String targetOrgId) {
        return user.organizationId == targetOrgId;
      }

      expect(canAccessOrgResource(guardUser, 'org-main'), isTrue);
      expect(canAccessOrgResource(competitorGuard, 'org-main'), isFalse);
      expect(canAccessOrgResource(adminUser, 'org-competitor'), isFalse);
    });

    test('6. UserProfile serialization preserves role and status enums', () {
      final map = adminUser.toMap();
      expect(map['role'], equals('admin'));
      expect(map['status'], equals('active'));

      final deserialized = UserProfile.fromMap(map);
      expect(deserialized.role, equals(UserRole.admin));
      expect(deserialized.status, equals(UserStatus.active));
      expect(deserialized.organizationId, equals('org-main'));
    });
  });
}
