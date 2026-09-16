import '../entities/alert.dart';

/// Replaceable adapter abstraction for downstream alert notifications.
///
/// Decouples alert detection and persistence from specific delivery channels
/// (such as FCM, Push, SMS, or local notifications).
abstract interface class NotificationAdapter {
  /// Delivers notification for the given [alert].
  ///
  /// Any delivery error should be handled or wrapped, and MUST NOT fail
  /// the core alert creation or persistence.
  Future<void> notify(Alert alert);
}

/// In-memory / logging notification adapter for tests and local runtime.
class LoggingNotificationAdapter implements NotificationAdapter {
  final List<Alert> dispatchedAlerts = [];

  LoggingNotificationAdapter();

  @override
  Future<void> notify(Alert alert) async {
    dispatchedAlerts.add(alert);
  }
}

/// No-op adapter for silent operations or headless tests.
class NoOpNotificationAdapter implements NotificationAdapter {
  const NoOpNotificationAdapter();

  @override
  Future<void> notify(Alert alert) async {}
}
