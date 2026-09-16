import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/alerts/domain/policies/late_check_in_policy.dart';
import 'package:cipher_x/features/alerts/domain/policies/site_coverage_provider.dart';
import 'package:cipher_x/features/alerts/domain/rules/critical_incident_rule.dart';
import 'package:cipher_x/features/alerts/domain/rules/late_check_in_rule.dart';
import 'package:cipher_x/features/alerts/domain/rules/missed_shift_rule.dart';
import 'package:cipher_x/features/alerts/domain/rules/understaffed_site_rule.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';

void main() {
  const orgId = 'org_test';
  final shiftDate = DateTime.utc(2026, 9, 16);

  final testShift = Shift(
    shiftId: 'shift_1',
    organizationId: orgId,
    guardId: 'guard_1',
    siteId: 'site_1',
    date: shiftDate,
    startTime: const ShiftTime(hour: 9, minute: 0),
    endTime: const ShiftTime(hour: 17, minute: 0),
    status: ShiftStatus.scheduled,
  );

  group('MissedShiftRule', () {
    const rule = MissedShiftRule();

    test('generates alert when shift end has passed without check-in',
        () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 17, 1);

      final alert = await rule.evaluate(
        MissedShiftInput(
          shift: testShift,
          attendanceRecords: const [],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNotNull);
      expect(alert!.type, AlertType.missedShift);
      expect(alert.sourceEntityId, 'shift_1');
    });

    test('does not generate alert if shift has valid check-in', () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 17, 30);
      final attendance = AttendanceRecord(
        attendanceId: 'att_1',
        organizationId: orgId,
        shiftId: 'shift_1',
        siteId: 'site_1',
        guardId: 'guard_1',
        checkInTime: DateTime.utc(2026, 9, 16, 9, 5),
        status: AttendanceStatus.active,
        verificationMethod: 'QR',
      );

      final alert = await rule.evaluate(
        MissedShiftInput(
          shift: testShift,
          attendanceRecords: [attendance],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNull);
    });

    test('does not generate alert if shift is cancelled', () async {
      final cancelledShift = testShift.copyWith(status: ShiftStatus.cancelled);
      final alert = await rule.evaluate(
        MissedShiftInput(
          shift: cancelledShift,
          attendanceRecords: const [],
          targetOrganizationId: orgId,
        ),
        evaluationTime: DateTime.utc(2026, 9, 16, 18, 0),
      );

      expect(alert, isNull);
    });

    test('does not generate alert for unrelated organization', () async {
      final alert = await rule.evaluate(
        MissedShiftInput(
          shift: testShift,
          attendanceRecords: const [],
          targetOrganizationId: 'org_other',
        ),
        evaluationTime: DateTime.utc(2026, 9, 16, 18, 0),
      );

      expect(alert, isNull);
    });
  });

  group('LateCheckInRule', () {
    const rule = LateCheckInRule(
      policy: DefaultLateCheckInPolicy(lateThreshold: Duration(minutes: 15)),
    );

    test('no alert before late threshold', () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 9, 10);

      final alert = await rule.evaluate(
        LateCheckInInput(
          shift: testShift,
          attendanceRecords: const [],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNull);
    });

    test('no alert exactly at late threshold', () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 9, 15);

      final alert = await rule.evaluate(
        LateCheckInInput(
          shift: testShift,
          attendanceRecords: const [],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNull);
    });

    test('generates alert after late threshold with no check-in', () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 9, 16);

      final alert = await rule.evaluate(
        LateCheckInInput(
          shift: testShift,
          attendanceRecords: const [],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNotNull);
      expect(alert!.type, AlertType.lateCheckIn);
      expect(alert.sourceEntityId, 'shift_1');
    });

    test('no alert if checked in within threshold', () async {
      final evaluationTime = DateTime.utc(2026, 9, 16, 9, 30);
      final attendance = AttendanceRecord(
        attendanceId: 'att_1',
        organizationId: orgId,
        shiftId: 'shift_1',
        siteId: 'site_1',
        guardId: 'guard_1',
        checkInTime: DateTime.utc(2026, 9, 16, 9, 10),
        status: AttendanceStatus.active,
        verificationMethod: 'QR',
      );

      final alert = await rule.evaluate(
        LateCheckInInput(
          shift: testShift,
          attendanceRecords: [attendance],
          targetOrganizationId: orgId,
        ),
        evaluationTime: evaluationTime,
      );

      expect(alert, isNull);
    });
  });

  group('UnderstaffedSiteRule', () {
    test('generates alert when actual staff < required staff', () async {
      const provider = StaticSiteCoverageProvider(
        requiredStaffBySite: {'site_1': 3},
        actualStaffBySite: {'site_1': 1},
      );
      const rule = UnderstaffedSiteRule(coverageProvider: provider);

      final alert = await rule.evaluate(
        const UnderstaffedSiteInput(organizationId: orgId, siteId: 'site_1'),
        evaluationTime: DateTime.utc(2026, 9, 16, 10, 0),
      );

      expect(alert, isNotNull);
      expect(alert!.type, AlertType.understaffedSite);
      expect(alert.metadata['deficit'], 2);
    });

    test('does not generate alert when staffing is sufficient', () async {
      const provider = StaticSiteCoverageProvider(
        requiredStaffBySite: {'site_1': 2},
        actualStaffBySite: {'site_1': 2},
      );
      const rule = UnderstaffedSiteRule(coverageProvider: provider);

      final alert = await rule.evaluate(
        const UnderstaffedSiteInput(organizationId: orgId, siteId: 'site_1'),
        evaluationTime: DateTime.utc(2026, 9, 16, 10, 0),
      );

      expect(alert, isNull);
    });
  });

  group('CriticalIncidentRule', () {
    const rule = CriticalIncidentRule();

    test('generates alert for CRITICAL incident in organization', () async {
      final incident = Incident(
        incidentId: 'inc_1',
        organizationId: orgId,
        reportedBy: 'guard_1',
        siteId: 'site_1',
        type: 'PERIMETER_BREACH',
        severity: IncidentSeverity.critical,
        description: 'Unauthorized forced entry at north perimeter.',
        status: IncidentStatus.open,
        createdAt: DateTime.utc(2026, 9, 16, 14, 0),
        updatedAt: DateTime.utc(2026, 9, 16, 14, 0),
      );

      final alert = await rule.evaluate(
        CriticalIncidentInput(
          incident: incident,
          targetOrganizationId: orgId,
        ),
        evaluationTime: DateTime.utc(2026, 9, 16, 14, 1),
      );

      expect(alert, isNotNull);
      expect(alert!.type, AlertType.criticalIncident);
      expect(alert.sourceEntityId, 'inc_1');
    });

    test('does not generate alert for non-critical incident', () async {
      final incident = Incident(
        incidentId: 'inc_2',
        organizationId: orgId,
        reportedBy: 'guard_1',
        siteId: 'site_1',
        type: 'LOST_ITEM',
        severity: IncidentSeverity.low,
        description: 'Lost keys reported.',
        status: IncidentStatus.open,
        createdAt: DateTime.utc(2026, 9, 16, 14, 0),
        updatedAt: DateTime.utc(2026, 9, 16, 14, 0),
      );

      final alert = await rule.evaluate(
        CriticalIncidentInput(
          incident: incident,
          targetOrganizationId: orgId,
        ),
        evaluationTime: DateTime.utc(2026, 9, 16, 14, 1),
      );

      expect(alert, isNull);
    });
  });
}
