import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/failures/shift_failure.dart';
import 'package:cipher_x/features/shifts/domain/validators/shift_assignment_validator.dart';

void main() {
  group('ShiftAssignmentValidator Unit Tests', () {
    const testGuard = Guard(
      guardId: 'g-101',
      organizationId: 'org-test',
      name: 'Rahul Sharma',
      employeeId: 'EMP-1001',
      phone: '+1 555-0199',
      status: GuardStatus.active,
    );

    const testSiteA = Site(
      siteId: 'site-001',
      organizationId: 'org-test',
      name: 'Cyber Gateway Tech Park',
      address: '123 Cyber Way',
      latitude: 17.44,
      longitude: 78.38,
      geofenceRadius: 50.0,
      status: SiteStatus.active,
    );

    const testSiteB = Site(
      siteId: 'site-002',
      organizationId: 'org-test',
      name: 'Financial District Tower',
      address: '456 Wall St',
      latitude: 17.42,
      longitude: 78.37,
      geofenceRadius: 50.0,
      status: SiteStatus.active,
    );

    final validShift = Shift(
      id: 'shift-100',
      organizationId: 'org-test',
      siteId: 'site-001',
      siteName: 'Cyber Gateway Tech Park',
      guardId: 'g-101',
      guardName: 'Rahul Sharma',
      shiftDate: '2026-08-27',
      startTime: DateTime(2026, 8, 27, 9, 0),
      endTime: DateTime(2026, 8, 27, 17, 0),
      status: ShiftStatus.scheduled,
    );

    test('Valid shift assignment passes validation', () {
      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: testSiteA,
          existingShifts: [],
        ),
        returnsNormally,
      );
    });

    test('Rejects invalid time range where startTime >= endTime', () {
      final invalidTimeShift = validShift.copyWith(
        startTime: DateTime(2026, 8, 27, 17, 0),
        endTime: DateTime(2026, 8, 27, 9, 0),
      );

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: invalidTimeShift,
          guard: testGuard,
          site: testSiteA,
          existingShifts: [],
        ),
        throwsA(isA<ShiftValidationFailure>()),
      );
    });

    test('Rejects missing guard', () {
      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: null,
          site: testSiteA,
          existingShifts: [],
        ),
        throwsA(isA<GuardNotFoundFailure>()),
      );
    });

    test('Rejects inactive guard', () {
      final inactiveGuard = testGuard.copyWith(status: GuardStatus.inactive);

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: inactiveGuard,
          site: testSiteA,
          existingShifts: [],
        ),
        throwsA(isA<GuardInactiveFailure>()),
      );
    });

    test('Rejects cross-organization guard assignment', () {
      final crossOrgGuard = testGuard.copyWith(organizationId: 'org-other');

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: crossOrgGuard,
          site: testSiteA,
          existingShifts: [],
        ),
        throwsA(isA<CrossOrganizationAssignmentFailure>()),
      );
    });

    test('Rejects missing site', () {
      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: null,
          existingShifts: [],
        ),
        throwsA(isA<SiteNotFoundFailure>()),
      );
    });

    test('Rejects inactive site', () {
      final inactiveSite = testSiteA.copyWith(status: SiteStatus.inactive);

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: inactiveSite,
          existingShifts: [],
        ),
        throwsA(isA<SiteInactiveFailure>()),
      );
    });

    test('Rejects cross-organization site assignment', () {
      final crossOrgSite = testSiteA.copyWith(organizationId: 'org-other');

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: crossOrgSite,
          existingShifts: [],
        ),
        throwsA(isA<CrossOrganizationAssignmentFailure>()),
      );
    });

    test('Rejects exact duplicate shift assignment', () {
      final existingDuplicate = Shift(
        id: 'shift-099',
        organizationId: 'org-test',
        siteId: 'site-001',
        siteName: 'Cyber Gateway Tech Park',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 9, 0),
        endTime: DateTime(2026, 8, 27, 17, 0),
        status: ShiftStatus.scheduled,
      );

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: testSiteA,
          existingShifts: [existingDuplicate],
        ),
        throwsA(isA<DuplicateShiftFailure>()),
      );
    });

    test(
        'Rejects overlapping shift for same guard at different site (Critical Scenario #1)',
        () {
      final existingShiftAtSiteA = Shift(
        id: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        siteName: 'Cyber Gateway Tech Park',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 9, 0),
        endTime: DateTime(2026, 8, 27, 17, 0),
        status: ShiftStatus.scheduled,
      );

      final newAttemptAtSiteB = Shift(
        id: 'shift-002',
        organizationId: 'org-test',
        siteId: 'site-002',
        siteName: 'Financial District Tower',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 13, 0),
        endTime: DateTime(2026, 8, 27, 18, 0),
        status: ShiftStatus.scheduled,
      );

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: newAttemptAtSiteB,
          guard: testGuard,
          site: testSiteB,
          existingShifts: [existingShiftAtSiteA],
        ),
        throwsA(isA<ShiftConflictFailure>()),
      );
    });

    test('Allows adjacent shift for same guard (Critical Scenario #2)', () {
      final existingShift = Shift(
        id: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        siteName: 'Cyber Gateway Tech Park',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 9, 0),
        endTime: DateTime(2026, 8, 27, 12, 0),
        status: ShiftStatus.scheduled,
      );

      final adjacentShift = Shift(
        id: 'shift-002',
        organizationId: 'org-test',
        siteId: 'site-002',
        siteName: 'Financial District Tower',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 12, 0),
        endTime: DateTime(2026, 8, 27, 17, 0),
        status: ShiftStatus.scheduled,
      );

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: adjacentShift,
          guard: testGuard,
          site: testSiteB,
          existingShifts: [existingShift],
        ),
        returnsNormally,
      );
    });

    test('Allows shift when existing shift is CANCELLED', () {
      final cancelledShift = Shift(
        id: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        siteName: 'Cyber Gateway Tech Park',
        guardId: 'g-101',
        guardName: 'Rahul Sharma',
        shiftDate: '2026-08-27',
        startTime: DateTime(2026, 8, 27, 9, 0),
        endTime: DateTime(2026, 8, 27, 17, 0),
        status: ShiftStatus.cancelled,
      );

      expect(
        () => ShiftAssignmentValidator.validateAssignment(
          shift: validShift,
          guard: testGuard,
          site: testSiteA,
          existingShifts: [cancelledShift],
        ),
        returnsNormally,
      );
    });
  });
}
