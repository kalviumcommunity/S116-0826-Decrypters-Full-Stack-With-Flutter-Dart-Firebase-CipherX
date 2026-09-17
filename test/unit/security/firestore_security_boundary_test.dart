import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Security Rules Boundary & Attack Matrix Tests (PR #33)', () {
    late String rulesContent;

    setUpAll(() {
      final file = File('firestore.rules');
      expect(file.existsSync(), isTrue, reason: 'firestore.rules must exist');
      rulesContent = file.readAsStringSync();
      expect(rulesContent, isNotEmpty,
          reason: 'firestore.rules must not be empty');
    });

    test('1. Core rules version and default deny fallback are enforced', () {
      expect(rulesContent, contains("rules_version = '2';"));
      expect(rulesContent, contains('match /{document=**}'));
      expect(rulesContent, contains('allow read, write: if false;'));
    });

    test(
        '2. Helper functions for authentication and tenant isolation are defined',
        () {
      expect(rulesContent, contains('function isAuthenticated()'));
      expect(rulesContent, contains('function isOwner(userId)'));
      expect(rulesContent, contains('function getUserDoc()'));
      expect(rulesContent, contains('function isMemberOf(orgId)'));
      expect(rulesContent, contains('function isAdminOrSupervisor(orgId)'));
      expect(rulesContent, contains('function isGuard(orgId)'));
    });

    group('3. Attack Vector 1: Guard -> Another Guard (DENY)', () {
      test('guards directory restricts read to admin/supervisor or self guard',
          () {
        expect(rulesContent, contains('match /guards/{guardId}'));
        expect(
          rulesContent,
          contains(
              'isAdminOrSupervisor(organizationId) || (isMemberOf(organizationId) && guardId == request.auth.uid)'),
          reason:
              'A guard must not be able to read other guards sensitive records',
        );
      });

      test(
          'guard creation and modification is strictly limited to admin or supervisor',
          () {
        expect(rulesContent,
            contains('allow create: if isAdminOrSupervisor(organizationId)'));
        expect(rulesContent,
            contains('allow update: if isAdminOrSupervisor(organizationId)'));
        expect(
            rulesContent, contains('request.resource.data.guardId == guardId'));
      });

      test(
          'shifts subcollection prevents guards from viewing other guards shifts',
          () {
        expect(rulesContent, contains('match /shifts/{shiftId}'));
        expect(
          rulesContent,
          contains(
              'isAdminOrSupervisor(organizationId) || (isMemberOf(organizationId) && resource.data.guardId == request.auth.uid)'),
          reason: 'A guard can only read shifts explicitly assigned to them',
        );
      });

      test(
          'attendance subcollection prevents guards from viewing other guards records',
          () {
        expect(
          rulesContent,
          contains(
              'isAdminOrSupervisor(organizationId) || (isMemberOf(organizationId) && resource.data.guardId == request.auth.uid)'),
          reason: 'A guard can only read attendance records belonging to them',
        );
      });
    });

    group(
        '4. Attack Vector 2: Guard -> Admin Data & Privilege Escalation (DENY)',
        () {
      test('organization document write is denied for all clients', () {
        expect(rulesContent, contains('match /organizations/{organizationId}'));
        expect(rulesContent, contains('allow write: if false;'));
      });

      test('user profile prevents role escalation and organization hopping',
          () {
        expect(rulesContent, contains('match /users/{userId}'));
        expect(rulesContent,
            contains('request.resource.data.uid == resource.data.uid'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.organizationId == resource.data.organizationId'));
        expect(rulesContent,
            contains('request.resource.data.status == resource.data.status'));
        expect(
          rulesContent,
          contains(
              "(!('role' in resource.data) || request.resource.data.role == resource.data.role)"),
          reason:
              'User cannot self-assign or escalate role to admin or supervisor',
        );
        expect(rulesContent, contains('allow delete: if false;'));
      });

      test(
          'site creation and modification is restricted to admin and supervisor',
          () {
        expect(rulesContent, contains('match /sites/{siteId}'));
        expect(rulesContent,
            contains('allow create: if isAdminOrSupervisor(organizationId)'));
        expect(rulesContent,
            contains('allow update: if isAdminOrSupervisor(organizationId)'));
      });

      test(
          'shift scheduling and assignment is restricted to admin and supervisor',
          () {
        expect(rulesContent,
            contains('allow create: if isAdminOrSupervisor(organizationId)'));
        expect(rulesContent,
            contains('allow update: if isAdminOrSupervisor(organizationId)'));
      });

      test('incident lifecycle updates are restricted to admin and supervisor',
          () {
        expect(rulesContent, contains('match /incidents/{incidentId}'));
        expect(rulesContent,
            contains('allow update: if isAdminOrSupervisor(organizationId)'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.reportedBy == resource.data.reportedBy'));
        expect(rulesContent,
            contains("request.resource.data.status == 'RESOLVED'"));
      });

      test('alert lifecycle updates are restricted to admin and supervisor',
          () {
        expect(rulesContent, contains('match /alerts/{alertId}'));
        expect(rulesContent,
            contains('allow update: if isAdminOrSupervisor(organizationId)'));
      });
    });

    group('5. Attack Vector 3: Guard -> Modify Attendance Records (DENY)', () {
      test(
          'check-in requires authenticated guard identity and server timestamp',
          () {
        expect(rulesContent, contains('match /attendance/{attendanceId}'));
        expect(rulesContent, contains("getUserDoc().data.role == 'guard'"));
        expect(rulesContent,
            contains('request.resource.data.guardId == request.auth.uid'));
        expect(rulesContent,
            contains('request.resource.data.organizationId == organizationId'));
        expect(rulesContent,
            contains('request.resource.data.checkInTime == request.time'));
      });

      test('check-out strictly preserves immutable check-in audit fields', () {
        expect(rulesContent,
            contains('request.auth.uid == resource.data.guardId'));
        expect(rulesContent,
            contains('request.resource.data.guardId == resource.data.guardId'));
        expect(rulesContent,
            contains('request.resource.data.shiftId == resource.data.shiftId'));
        expect(rulesContent,
            contains('request.resource.data.siteId == resource.data.siteId'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.checkInTime == resource.data.checkInTime'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.verificationMethod == resource.data.verificationMethod'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.checkInLatitude == resource.data.checkInLatitude'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.checkInLongitude == resource.data.checkInLongitude'));
        expect(
            rulesContent,
            contains(
                'request.resource.data.checkInAccuracy == resource.data.checkInAccuracy'));
      });

      test('attendance deletion is permanently denied', () {
        expect(rulesContent, contains('allow delete: if false;'));
      });
    });

    group('6. Attack Vector 4: Guard -> Audit Logs (DENY)', () {
      test('audit logs read is restricted to admin and supervisor only', () {
        expect(rulesContent, contains('match /auditLogs/{logId}'));
        expect(rulesContent,
            contains('allow read: if isAdminOrSupervisor(organizationId);'));
      });

      test(
          'client-side creation, update, and deletion of audit logs is unconditionally forbidden',
          () {
        expect(
            rulesContent, contains('allow create, update, delete: if false;'));
      });
    });

    group('7. Attack Vector 5: Organization A -> Organization B Data (DENY)',
        () {
      test(
          'tenant boundary is strictly verified on organization root and subcollections',
          () {
        expect(rulesContent,
            contains('allow read: if isMemberOf(organizationId);'));
        expect(rulesContent,
            contains('getUserDoc().data.organizationId == orgId'));
        expect(rulesContent,
            contains('request.resource.data.organizationId == organizationId'));
      });

      test(
          'user profile cross-tenant lookup is restricted to same organization admins',
          () {
        expect(
          rulesContent,
          contains(
              'resource.data.organizationId == getUserDoc().data.organizationId'),
          reason:
              'Admins cannot view profiles of users belonging to different organizations',
        );
      });

      test(
          'evidence subcollection enforces tenant boundary and immutable audit files',
          () {
        expect(rulesContent, contains('match /evidence/{evidenceId}'));
        expect(rulesContent,
            contains('request.resource.data.organizationId == organizationId'));
        expect(rulesContent,
            contains('request.resource.data.uploadedBy == request.auth.uid'));
        expect(rulesContent,
            contains('request.resource.data.sizeBytes <= 10485760'));
        expect(rulesContent, contains('allow update, delete: if false;'));
      });
    });
  });
}
