import 'package:flutter_test/flutter_test.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_status.dart';
import 'package:cipher_x/features/alerts/domain/entities/alert_type.dart';
import 'package:cipher_x/features/alerts/domain/repositories/alert_repository.dart';
import 'package:cipher_x/features/alerts/domain/services/alert_engine.dart';
import 'package:cipher_x/features/alerts/domain/services/clock.dart';
import 'package:cipher_x/features/alerts/domain/services/notification_adapter.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_severity.dart';
import 'package:cipher_x/features/incidents/domain/entities/incident_status.dart';

class InMemoryAlertRepository implements AlertRepository {
  final Map<String, Alert> _storage = {};

  @override
  Future<Alert?> createIfAbsent(Alert alert) async {
    if (_storage.containsKey(alert.alertId)) {
      return null;
    }
    _storage[alert.alertId] = alert;
    return alert;
  }

  @override
  Future<bool> existsForSource({
    required String organizationId,
    required String sourceEntityId,
    required AlertType type,
  }) async {
    return _storage.values.any(
      (a) =>
          a.organizationId == organizationId &&
          a.sourceEntityId == sourceEntityId &&
          a.type == type,
    );
  }

  @override
  Future<Alert?> getAlertById({
    required String organizationId,
    required String alertId,
  }) async {
    final alert = _storage[alertId];
    if (alert == null || alert.organizationId != organizationId) return null;
    return alert;
  }

  @override
  Future<List<Alert>> getAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) async {
    return _storage.values.where((a) {
      if (a.organizationId != organizationId) return false;
      if (type != null && a.type != type) return false;
      if (status != null && a.status != status) return false;
      return true;
    }).toList();
  }

  @override
  Stream<List<Alert>> watchAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) {
    return Stream.value(_storage.values.toList());
  }

  @override
  Future<void> updateAlertStatus({
    required String organizationId,
    required String alertId,
    required AlertStatus status,
  }) async {
    final existing = _storage[alertId];
    if (existing != null && existing.organizationId == organizationId) {
      _storage[alertId] = existing.copyWith(status: status);
    }
  }
}

class FaultyNotificationAdapter implements NotificationAdapter {
  @override
  Future<void> notify(Alert alert) async {
    throw Exception('Simulated network delivery failure');
  }
}

void main() {
  const orgId = 'org_test';

  test(
      'idempotency: evaluating same critical incident twice creates only 1 alert and 1 notification',
      () async {
    final repo = InMemoryAlertRepository();
    final notifier = LoggingNotificationAdapter();
    final fakeClock = FakeClock(DateTime.utc(2026, 9, 16, 12, 0));

    final engine = AlertEngine(
      repository: repo,
      notificationAdapter: notifier,
      clock: fakeClock,
    );

    final incident = Incident(
      incidentId: 'inc_critical_1',
      organizationId: orgId,
      reportedBy: 'guard_1',
      siteId: 'site_1',
      type: 'FIRE',
      severity: IncidentSeverity.critical,
      description: 'Fire alarm triggered in sector B.',
      status: IncidentStatus.open,
      createdAt: DateTime.utc(2026, 9, 16, 11, 55),
      updatedAt: DateTime.utc(2026, 9, 16, 11, 55),
    );

    // First evaluation: should create and notify
    final firstResult = await engine.evaluateCriticalIncident(
      incident: incident,
      organizationId: orgId,
    );
    expect(firstResult, isNotNull);
    expect(notifier.dispatchedAlerts.length, 1);

    // Second evaluation: duplicate, should return null and not notify again
    final secondResult = await engine.evaluateCriticalIncident(
      incident: incident,
      organizationId: orgId,
    );
    expect(secondResult, isNull);
    expect(notifier.dispatchedAlerts.length, 1);

    // Verify stored alert count
    final storedAlerts = await repo.getAlerts(organizationId: orgId);
    expect(storedAlerts.length, 1);
  });

  test('notification adapter failure does not prevent alert persistence',
      () async {
    final repo = InMemoryAlertRepository();
    final faultyNotifier = FaultyNotificationAdapter();

    final engine = AlertEngine(
      repository: repo,
      notificationAdapter: faultyNotifier,
    );

    final incident = Incident(
      incidentId: 'inc_crit_resilience',
      organizationId: orgId,
      reportedBy: 'guard_1',
      siteId: 'site_1',
      type: 'BURGLARY',
      severity: IncidentSeverity.critical,
      description: 'Glass break detector active.',
      status: IncidentStatus.open,
      createdAt: DateTime.utc(2026, 9, 16, 12, 0),
      updatedAt: DateTime.utc(2026, 9, 16, 12, 0),
    );

    final result = await engine.evaluateCriticalIncident(
      incident: incident,
      organizationId: orgId,
    );

    expect(result, isNotNull);
    final stored = await repo.getAlerts(organizationId: orgId);
    expect(stored.length, 1);
  });
}
