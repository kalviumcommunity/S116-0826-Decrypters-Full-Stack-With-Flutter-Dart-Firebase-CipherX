import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
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
      shiftId: 'shift-100',
      organizationId: 'org-test',
      siteId: 'site-001',
      guardId: 'g-101',
      date: DateTime(2026, 8, 27),
      startTime: const ShiftTime(hour: 9, minute: 0),
      endTime: const ShiftTime(hour: 17, minute: 0),
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
        startTime: const ShiftTime(hour: 17, minute: 0),
        endTime: const ShiftTime(hour: 9, minute: 0),
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
        shiftId: 'shift-099',
        organizationId: 'org-test',
        siteId: 'site-001',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
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
        shiftId: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
        status: ShiftStatus.scheduled,
      );

      final newAttemptAtSiteB = Shift(
        shiftId: 'shift-002',
        organizationId: 'org-test',
        siteId: 'site-002',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 13, minute: 0),
        endTime: const ShiftTime(hour: 18, minute: 0),
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
        shiftId: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 12, minute: 0),
        status: ShiftStatus.scheduled,
      );

      final adjacentShift = Shift(
        shiftId: 'shift-002',
        organizationId: 'org-test',
        siteId: 'site-002',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 12, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
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
        shiftId: 'shift-001',
        organizationId: 'org-test',
        siteId: 'site-001',
        guardId: 'g-101',
        date: DateTime(2026, 8, 27),
        startTime: const ShiftTime(hour: 9, minute: 0),
        endTime: const ShiftTime(hour: 17, minute: 0),
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

    group('Production Multi-Tenant & Boundary Hardening Tests', () {
      test('strictly rejects guard from differing organization with CrossOrganizationAssignmentFailure', () {
        const foreignGuard = Guard(
          guardId: 'g-foreign',
          organizationId: 'org-competitor',
          name: 'Foreign Guard',
          employeeId: 'EMP-9999',
          phone: '+1 555-9999',
          status: GuardStatus.active,
        );

        expect(
          () => ShiftAssignmentValidator.validateAssignment(
            shift: validShift,
            guard: foreignGuard,
            site: testSiteA,
            existingShifts: [],
          ),
          throwsA(isA<CrossOrganizationAssignmentFailure>()),
        );
      });

      test('strictly rejects site from differing organization with CrossOrganizationAssignmentFailure', () {
        const foreignSite = Site(
          siteId: 'site-foreign',
          organizationId: 'org-competitor',
          name: 'Foreign Site Tower',
          address: '999 Foreign Way',
          latitude: 17.50,
          longitude: 78.50,
          geofenceRadius: 100.0,
          status: SiteStatus.active,
        );

        expect(
          () => ShiftAssignmentValidator.validateAssignment(
            shift: validShift,
            guard: testGuard,
            site: foreignSite,
            existingShifts: [],
          ),
          throwsA(isA<CrossOrganizationAssignmentFailure>()),
        );
      });

      test('rejects assignment when guard status is suspended or inactive', () {
        const inactiveGuard = Guard(
          guardId: 'g-101',
          organizationId: 'org-test',
          name: 'Suspended Guard',
          employeeId: 'EMP-1001',
          phone: '+1 555-0199',
          status: GuardStatus.inactive,
        );

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

      test('rejects assignment when site status is inactive', () {
        const inactiveSite = Site(
          siteId: 'site-001',
          organizationId: 'org-test',
          name: 'Closed Facility',
          address: '123 Cyber Way',
          latitude: 17.44,
          longitude: 78.38,
          geofenceRadius: 50.0,
          status: SiteStatus.inactive,
        );

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

      test('allows new shift if existing shift for same guard was already completed earlier in the day', () {
        final completedMorningShift = Shift(
          shiftId: 'shift-morning',
          organizationId: 'org-test',
          siteId: 'site-001',
          guardId: 'g-101',
          date: DateTime(2026, 8, 27),
          startTime: const ShiftTime(hour: 6, minute: 0),
          endTime: const ShiftTime(hour: 14, minute: 0),
          status: ShiftStatus.completed,
        );

        final eveningShift = Shift(
          shiftId: 'shift-evening',
          organizationId: 'org-test',
          siteId: 'site-001',
          guardId: 'g-101',
          date: DateTime(2026, 8, 27),
          startTime: const ShiftTime(hour: 15, minute: 0),
          endTime: const ShiftTime(hour: 23, minute: 0),
          status: ShiftStatus.scheduled,
        );

        expect(
          () => ShiftAssignmentValidator.validateAssignment(
            shift: eveningShift,
            guard: testGuard,
            site: testSiteA,
            existingShifts: [completedMorningShift],
          ),
          returnsNormally,
        );
      });
    });
  });
}
