import 'package:flutter_test/flutter_test.dart';

import 'package:cipher_x/features/admin/domain/entities/dashboard_statistics.dart';
import 'package:cipher_x/features/admin/domain/services/dashboard_statistics_service.dart';
import 'package:cipher_x/features/admin/domain/services/facility_incident_metrics_calculator.dart';
import 'package:cipher_x/features/admin/domain/services/guard_metrics_calculator.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/attendance/domain/entities/attendance_record.dart';
import 'package:cipher_x/features/guards/domain/entities/guard.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift.dart';
import 'package:cipher_x/features/shifts/domain/entities/shift_time.dart';
import 'package:cipher_x/features/sites/domain/entities/site.dart';

void main() {
  group('DashboardStatistics Entity Tests', () {
    test('empty constructor initializes all metrics to zero', () {
      const stats = DashboardStatistics.empty();
      expect(stats.totalGuards, 0);
      expect(stats.onDutyGuards, 0);
      expect(stats.absentGuards, 0);
      expect(stats.lateGuards, 0);
      expect(stats.activeSites, 0);
      expect(stats.openIncidents, 0);
      expect(stats.criticalAlerts, 0);
    });

    test('value equality and hashCode', () {
      const stats1 = DashboardStatistics(
        totalGuards: 10,
        onDutyGuards: 5,
        absentGuards: 2,
        lateGuards: 1,
        activeSites: 4,
        openIncidents: 1,
        criticalAlerts: 0,
      );

      const stats2 = DashboardStatistics(
        totalGuards: 10,
        onDutyGuards: 5,
        absentGuards: 2,
        lateGuards: 1,
        activeSites: 4,
        openIncidents: 1,
        criticalAlerts: 0,
      );

      const stats3 = DashboardStatistics(
        totalGuards: 12,
        onDutyGuards: 6,
        absentGuards: 1,
        lateGuards: 0,
        activeSites: 3,
        openIncidents: 0,
        criticalAlerts: 1,
      );

      expect(stats1, equals(stats2));
      expect(stats1.hashCode, equals(stats2.hashCode));
      expect(stats1, isNot(equals(stats3)));
    });

    test('copyWith updates properties properly', () {
      const stats = DashboardStatistics.empty();
      final updated = stats.copyWith(totalGuards: 15, onDutyGuards: 8);

      expect(updated.totalGuards, 15);
      expect(updated.onDutyGuards, 8);
      expect(updated.absentGuards, 0);
    });
  });

  group('GuardMetricsCalculator Tests', () {
    const calculator = GuardMetricsCalculator();

    test('calculateTotalGuards counts total guards in list', () {
      final guards = [
        const Guard(
          guardId: 'g1',
          name: 'Guard 1',
          employeeId: 'EMP001',
          status: GuardStatus.active,
          organizationId: 'org1',
          email: 'g1@test.com',
          phone: '+1234567890',
        ),
        const Guard(
          guardId: 'g2',
          name: 'Guard 2',
          employeeId: 'EMP002',
          status: GuardStatus.active,
          organizationId: 'org1',
          email: 'g2@test.com',
          phone: '+1234567891',
        ),
      ];

      expect(calculator.calculateTotalGuards(guards), 2);
    });

    test('calculateOnDutyGuards counts distinct active check-ins', () {
      final now = DateTime(2026, 9, 17, 10, 0);
      final attendances = [
        AttendanceRecord(
          attendanceId: 'a1',
          guardId: 'g1',
          siteId: 's1',
          organizationId: 'org1',
          shiftId: 'sh1',
          checkInTime: now.subtract(const Duration(hours: 1)),
          status: AttendanceStatus.active,
        ),
        AttendanceRecord(
          attendanceId: 'a2',
          guardId: 'g2',
          siteId: 's1',
          organizationId: 'org1',
          shiftId: 'sh2',
          checkInTime: now.subtract(const Duration(hours: 2)),
          checkOutTime: now.subtract(const Duration(hours: 1)),
          status: AttendanceStatus.completed,
        ),
      ];

      expect(calculator.calculateOnDutyGuards(attendances), 1);
    });
  });

  group('FacilityIncidentMetricsCalculator Tests', () {
    const calculator = FacilityIncidentMetricsCalculator();

    test('calculateActiveSites counts active sites', () {
      final sites = [
        const Site(
          siteId: 's1',
          name: 'Site 1',
          address: 'Address 1',
          latitude: 0,
          longitude: 0,
          geofenceRadius: 100,
          organizationId: 'org1',
          status: SiteStatus.active,
        ),
        const Site(
          siteId: 's2',
          name: 'Site 2',
          address: 'Address 2',
          latitude: 0,
          longitude: 0,
          geofenceRadius: 100,
          organizationId: 'org1',
          status: SiteStatus.inactive,
        ),
      ];

      expect(calculator.calculateActiveSites(sites), 1);
    });

    test('calculateOpenIncidents counts open and investigating incidents', () {
      final now = DateTime(2026, 9, 17, 10, 0);
      final incidents = [
        Incident(
          incidentId: 'inc1',
          organizationId: 'org1',
          siteId: 's1',
          reportedBy: 'g1',
          type: 'Security Breach',
          severity: IncidentSeverity.high,
          description: 'Gate unlocked',
          status: IncidentStatus.open,
          createdAt: now,
          updatedAt: now,
        ),
        Incident(
          incidentId: 'inc2',
          organizationId: 'org1',
          siteId: 's1',
          reportedBy: 'g1',
          type: 'Fire Alarm',
          severity: IncidentSeverity.critical,
          description: 'False alarm',
          status: IncidentStatus.resolved,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      expect(calculator.calculateOpenIncidents(incidents), 1);
    });

    test('calculateCriticalAlerts counts active critical incident alerts', () {
      final now = DateTime(2026, 9, 17, 10, 0);
      final alerts = [
        Alert(
          alertId: 'al1',
          organizationId: 'org1',
          type: AlertType.criticalIncident,
          status: AlertStatus.active,
          sourceEntityId: 'inc1',
          sourceEntityType: 'incident',
          createdAt: now,
        ),
        Alert(
          alertId: 'al2',
          organizationId: 'org1',
          type: AlertType.lateCheckIn,
          status: AlertStatus.active,
          sourceEntityId: 'sh1',
          sourceEntityType: 'shift',
          createdAt: now,
        ),
        Alert(
          alertId: 'al3',
          organizationId: 'org1',
          type: AlertType.criticalIncident,
          status: AlertStatus.resolved,
          sourceEntityId: 'inc2',
          sourceEntityType: 'incident',
          createdAt: now,
        ),
      ];

      expect(calculator.calculateCriticalAlerts(alerts), 1);
    });
  });

  group('DashboardStatisticsService Integration Tests', () {
    const service = DashboardStatisticsService();
    final evalTime = DateTime(2026, 9, 17, 10, 0);

    test('calculates complete operational KPI metrics accurately', () {
      final guards = [
        const Guard(
          guardId: 'g1',
          name: 'Guard 1',
          employeeId: 'EMP001',
          status: GuardStatus.active,
          organizationId: 'org1',
          email: 'g1@test.com',
          phone: '+1234567890',
        ),
        const Guard(
          guardId: 'g2',
          name: 'Guard 2',
          employeeId: 'EMP002',
          status: GuardStatus.active,
          organizationId: 'org1',
          email: 'g2@test.com',
          phone: '+1234567891',
        ),
      ];

      final shifts = [
        Shift(
          shiftId: 'sh1',
          guardId: 'g1',
          siteId: 's1',
          organizationId: 'org1',
          date: evalTime,
          startTime: const ShiftTime(hour: 8, minute: 0),
          endTime: const ShiftTime(hour: 16, minute: 0),
        ),
      ];

      final attendances = [
        AttendanceRecord(
          attendanceId: 'a1',
          guardId: 'g1',
          siteId: 's1',
          organizationId: 'org1',
          shiftId: 'sh1',
          checkInTime: evalTime.subtract(const Duration(hours: 2)),
          status: AttendanceStatus.active,
        ),
      ];

      final sites = [
        const Site(
          siteId: 's1',
          name: 'Site 1',
          address: 'Address 1',
          latitude: 0,
          longitude: 0,
          geofenceRadius: 100,
          organizationId: 'org1',
          status: SiteStatus.active,
        ),
      ];

      final stats = service.calculateStatistics(
        guards: guards,
        shifts: shifts,
        attendances: attendances,
        sites: sites,
        incidents: const [],
        alerts: const [],
        evaluationTime: evalTime,
      );

      expect(stats.totalGuards, 2);
      expect(stats.onDutyGuards, 1);
      expect(stats.absentGuards, 0);
      expect(stats.lateGuards, 0);
      expect(stats.activeSites, 1);
      expect(stats.openIncidents, 0);
      expect(stats.criticalAlerts, 0);
    });
  });
}
