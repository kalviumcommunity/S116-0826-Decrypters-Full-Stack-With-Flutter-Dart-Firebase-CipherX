import '../../domain/entities/audit_log.dart';
import '../../domain/entities/operational_alert.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/firebase_activity_data_source.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final FirebaseActivityDataSource? _dataSource;

  ActivityRepositoryImpl({
    FirebaseActivityDataSource? dataSource,
  }) : _dataSource = dataSource;

  FirebaseActivityDataSource get dataSource =>
      _dataSource ?? FirebaseActivityDataSource();

  @override
  Future<List<OperationalAlert>> getRecentAlerts({
    required String organizationId,
    int limit = 10,
  }) async {
    try {
      if (organizationId.trim().isEmpty) return [];
      return await dataSource.getRecentAlerts(
        organizationId: organizationId,
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<OperationalAlert>> watchRecentAlerts({
    required String organizationId,
    int limit = 10,
  }) {
    if (organizationId.trim().isEmpty) return Stream.value([]);
    return dataSource.watchRecentAlerts(
      organizationId: organizationId,
      limit: limit,
    );
  }

  @override
  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) async {
    try {
      if (organizationId.trim().isEmpty) return [];
      return await dataSource.getRecentAuditLogs(
        organizationId: organizationId,
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  @override
  Stream<List<AuditLog>> watchRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) {
    if (organizationId.trim().isEmpty) return Stream.value([]);
    return dataSource.watchRecentAuditLogs(
      organizationId: organizationId,
      limit: limit,
    );
  }
}
