import '../../../alerts/domain/entities/alert.dart';
import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../guards/domain/entities/guard.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../../../sites/domain/entities/site.dart';
import '../entities/dashboard_statistics.dart';
import 'facility_incident_metrics_calculator.dart';
import 'guard_metrics_calculator.dart';

/// Pure domain service calculating all 7 core operational KPI metrics.
///
/// Fully decoupled from UI and storage drivers, enabling deterministic testing.
class DashboardStatisticsService {
  final GuardMetricsCalculator guardCalculator;
  final FacilityIncidentMetricsCalculator facilityCalculator;

  const DashboardStatisticsService({
    this.guardCalculator = const GuardMetricsCalculator(),
    this.facilityCalculator = const FacilityIncidentMetricsCalculator(),
  });

  /// Computes all 7 operational metrics for the organization.
  DashboardStatistics calculateStatistics({
    required List<Guard> guards,
    required List<Shift> shifts,
    required List<AttendanceRecord> attendances,
    required List<Site> sites,
    required List<Incident> incidents,
    required List<Alert> alerts,
    required DateTime evaluationTime,
  }) {
    final activeAttendances = attendances
        .where((a) => a.status == AttendanceStatus.active && !a.isCheckedOut)
        .toList();

    return DashboardStatistics(
      totalGuards: guardCalculator.calculateTotalGuards(guards),
      onDutyGuards: guardCalculator.calculateOnDutyGuards(activeAttendances),
      absentGuards: guardCalculator.calculateAbsentGuards(
        shifts: shifts,
        allAttendancesToday: attendances,
        evaluationTime: evaluationTime,
      ),
      lateGuards: guardCalculator.calculateLateGuards(
        shifts: shifts,
        allAttendancesToday: attendances,
        evaluationTime: evaluationTime,
      ),
      activeSites: facilityCalculator.calculateActiveSites(sites),
      openIncidents: facilityCalculator.calculateOpenIncidents(incidents),
      criticalAlerts: facilityCalculator.calculateCriticalAlerts(alerts),
    );
  }
}
