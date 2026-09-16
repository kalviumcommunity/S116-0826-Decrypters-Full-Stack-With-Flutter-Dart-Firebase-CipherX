import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/alert_type.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/firebase_alert_data_source.dart';

/// Production implementation of [AlertRepository] backed by [FirebaseAlertDataSource].
class AlertRepositoryImpl implements AlertRepository {
  final FirebaseAlertDataSource _dataSource;

  AlertRepositoryImpl({FirebaseAlertDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseAlertDataSource();

  @override
  Future<Alert?> createIfAbsent(Alert alert) {
    return _dataSource.createIfAbsent(alert);
  }

  @override
  Future<bool> existsForSource({
    required String organizationId,
    required String sourceEntityId,
    required AlertType type,
  }) {
    return _dataSource.existsForSource(
      organizationId: organizationId,
      sourceEntityId: sourceEntityId,
      type: type,
    );
  }

  @override
  Future<Alert?> getAlertById({
    required String organizationId,
    required String alertId,
  }) {
    return _dataSource.getAlertById(
      organizationId: organizationId,
      alertId: alertId,
    );
  }

  @override
  Future<List<Alert>> getAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) {
    return _dataSource.getAlerts(
      organizationId: organizationId,
      type: type,
      status: status,
    );
  }

  @override
  Stream<List<Alert>> watchAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) {
    return _dataSource.watchAlerts(
      organizationId: organizationId,
      type: type,
      status: status,
    );
  }

  @override
  Future<void> updateAlertStatus({
    required String organizationId,
    required String alertId,
    required AlertStatus status,
  }) {
    return _dataSource.updateAlertStatus(
      organizationId: organizationId,
      alertId: alertId,
      status: status,
    );
  }
}
