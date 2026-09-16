import '../entities/alert.dart';
import '../entities/alert_status.dart';
import '../entities/alert_type.dart';

/// Pure domain repository contract for persisting and retrieving alerts.
///
/// Decouples business logic from Firestore and underlying storage drivers.
abstract interface class AlertRepository {
  /// Idempotently persists an alert if not already present.
  ///
  /// Returns the newly created [Alert] if it was absent, or `null` if an alert
  /// with the same deterministic [alert.alertId] already existed.
  Future<Alert?> createIfAbsent(Alert alert);

  /// Checks whether an alert already exists for the given source and type.
  Future<bool> existsForSource({
    required String organizationId,
    required String sourceEntityId,
    required AlertType type,
  });

  /// Retrieves an alert by its ID.
  Future<Alert?> getAlertById({
    required String organizationId,
    required String alertId,
  });

  /// Retrieves all alerts for an organization, optionally filtered.
  Future<List<Alert>> getAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  });

  /// Real-time stream of alerts for an organization.
  Stream<List<Alert>> watchAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  });

  /// Updates an alert status (e.g. acknowledge or resolve).
  Future<void> updateAlertStatus({
    required String organizationId,
    required String alertId,
    required AlertStatus status,
  });
}
