import 'package:meta/meta.dart';

/// Base class for all domain failures in the Alert subsystem.
@immutable
abstract class AlertFailure implements Exception {
  final String message;

  const AlertFailure(this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AlertFailure &&
        other.runtimeType == runtimeType &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() => '$runtimeType: $message';
}

class InvalidAlertDataFailure extends AlertFailure {
  const InvalidAlertDataFailure([super.message = 'Invalid alert data.']);
}

class AlertNotFoundFailure extends AlertFailure {
  const AlertNotFoundFailure([super.message = 'Alert not found.']);
}

class AlertDuplicateFailure extends AlertFailure {
  const AlertDuplicateFailure(
      [super.message = 'Alert already exists for this source event.']);
}

class UnauthorizedAlertActionFailure extends AlertFailure {
  const UnauthorizedAlertActionFailure(
      [super.message = 'Unauthorized alert action.']);
}

class AlertPersistenceFailure extends AlertFailure {
  const AlertPersistenceFailure(
      [super.message = 'Failed to persist alert in storage.']);
}

class NotificationDispatchFailure extends AlertFailure {
  const NotificationDispatchFailure(
      [super.message = 'Failed to dispatch notification.']);
}
