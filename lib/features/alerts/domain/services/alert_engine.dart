import '../../../attendance/domain/entities/attendance_record.dart';
import '../../../incidents/domain/entities/incident.dart';
import '../../../shifts/domain/entities/shift.dart';
import '../entities/alert.dart';
import '../policies/late_check_in_policy.dart';
import '../policies/missed_shift_policy.dart';
import '../policies/site_coverage_provider.dart';
import '../repositories/alert_repository.dart';
import '../rules/critical_incident_rule.dart';
import '../rules/late_check_in_rule.dart';
import '../rules/missed_shift_rule.dart';
import '../rules/understaffed_site_rule.dart';
import 'clock.dart';
import 'notification_adapter.dart';

/// Central coordinator for the Cipher-X Alert Engine.
///
/// Fully decoupled from UI, schedulers, and specific notification providers.
/// Enforces idempotent alert persistence and graceful notification dispatch.
class AlertEngine {
  final AlertRepository repository;
  final NotificationAdapter notificationAdapter;
  final Clock clock;

  final MissedShiftRule missedShiftRule;
  final LateCheckInRule lateCheckInRule;
  final UnderstaffedSiteRule understaffedSiteRule;
  final CriticalIncidentRule criticalIncidentRule;

  AlertEngine({
    required this.repository,
    required this.notificationAdapter,
    this.clock = const SystemClock(),
    MissedShiftPolicy missedShiftPolicy = const DefaultMissedShiftPolicy(),
    LateCheckInPolicy lateCheckInPolicy = const DefaultLateCheckInPolicy(),
    SiteCoverageProvider siteCoverageProvider =
        const StaticSiteCoverageProvider(),
  })  : missedShiftRule = MissedShiftRule(policy: missedShiftPolicy),
        lateCheckInRule = LateCheckInRule(policy: lateCheckInPolicy),
        understaffedSiteRule =
            UnderstaffedSiteRule(coverageProvider: siteCoverageProvider),
        criticalIncidentRule = const CriticalIncidentRule();

  /// Evaluates and idempotently registers a missed shift alert if conditions are met.
  Future<Alert?> evaluateMissedShift({
    required Shift shift,
    required List<AttendanceRecord> attendanceRecords,
    required String organizationId,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? clock.now();
    final alertCandidate = await missedShiftRule.evaluate(
      MissedShiftInput(
        shift: shift,
        attendanceRecords: attendanceRecords,
        targetOrganizationId: organizationId,
      ),
      evaluationTime: now,
    );

    if (alertCandidate == null) return null;
    return _persistAndDispatch(alertCandidate);
  }

  /// Evaluates and idempotently registers a late check-in alert if conditions are met.
  Future<Alert?> evaluateLateCheckIn({
    required Shift shift,
    required List<AttendanceRecord> attendanceRecords,
    required String organizationId,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? clock.now();
    final alertCandidate = await lateCheckInRule.evaluate(
      LateCheckInInput(
        shift: shift,
        attendanceRecords: attendanceRecords,
        targetOrganizationId: organizationId,
      ),
      evaluationTime: now,
    );

    if (alertCandidate == null) return null;
    return _persistAndDispatch(alertCandidate);
  }

  /// Evaluates and idempotently registers an understaffed site alert.
  Future<Alert?> evaluateUnderstaffedSite({
    required String organizationId,
    required String siteId,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? clock.now();
    final alertCandidate = await understaffedSiteRule.evaluate(
      UnderstaffedSiteInput(
        organizationId: organizationId,
        siteId: siteId,
      ),
      evaluationTime: now,
    );

    if (alertCandidate == null) return null;
    return _persistAndDispatch(alertCandidate);
  }

  /// Evaluates and idempotently registers a critical incident alert.
  Future<Alert?> evaluateCriticalIncident({
    required Incident incident,
    required String organizationId,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? clock.now();
    final alertCandidate = await criticalIncidentRule.evaluate(
      CriticalIncidentInput(
        incident: incident,
        targetOrganizationId: organizationId,
      ),
      evaluationTime: now,
    );

    if (alertCandidate == null) return null;
    return _persistAndDispatch(alertCandidate);
  }

  /// Evaluates all four alert conditions across provided domain records.
  Future<List<Alert>> evaluateAll({
    required String organizationId,
    required List<Shift> shifts,
    required List<AttendanceRecord> attendanceRecords,
    required List<String> siteIds,
    required List<Incident> incidents,
    DateTime? evaluationTime,
  }) async {
    final now = evaluationTime ?? clock.now();
    final createdAlerts = <Alert>[];

    // 1. Evaluate missed shifts
    for (final shift in shifts) {
      final alert = await evaluateMissedShift(
        shift: shift,
        attendanceRecords: attendanceRecords,
        organizationId: organizationId,
        evaluationTime: now,
      );
      if (alert != null) createdAlerts.add(alert);
    }

    // 2. Evaluate late check-ins
    for (final shift in shifts) {
      final alert = await evaluateLateCheckIn(
        shift: shift,
        attendanceRecords: attendanceRecords,
        organizationId: organizationId,
        evaluationTime: now,
      );
      if (alert != null) createdAlerts.add(alert);
    }

    // 3. Evaluate understaffed sites
    for (final siteId in siteIds) {
      final alert = await evaluateUnderstaffedSite(
        organizationId: organizationId,
        siteId: siteId,
        evaluationTime: now,
      );
      if (alert != null) createdAlerts.add(alert);
    }

    // 4. Evaluate critical incidents
    for (final incident in incidents) {
      final alert = await evaluateCriticalIncident(
        incident: incident,
        organizationId: organizationId,
        evaluationTime: now,
      );
      if (alert != null) createdAlerts.add(alert);
    }

    return createdAlerts;
  }

  /// Helper to persist with deduplication and safely notify downstream subscribers.
  Future<Alert?> _persistAndDispatch(Alert candidate) async {
    // 1. Idempotently persist in repository
    final persisted = await repository.createIfAbsent(candidate);

    // If already existed, do not duplicate notification
    if (persisted == null) {
      return null;
    }

    // 2. Dispatch notification safely without failing alert creation
    try {
      await notificationAdapter.notify(persisted);
    } catch (_) {
      // Notification failure does not invalidate alert persistence
    }

    return persisted;
  }
}
