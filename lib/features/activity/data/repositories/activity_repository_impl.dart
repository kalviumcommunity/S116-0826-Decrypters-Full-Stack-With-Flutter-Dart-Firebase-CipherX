import '../../domain/entities/audit_log.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/firebase_activity_data_source.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final FirebaseActivityDataSource _dataSource;

  ActivityRepositoryImpl({
    FirebaseActivityDataSource? dataSource,
  }) : _dataSource = dataSource ?? FirebaseActivityDataSource();

  @override
  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) async {
    if (organizationId.trim().isEmpty) return [];
    try {
      return await _dataSource.getRecentAuditLogs(
        organizationId: organizationId.trim(),
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
    return _dataSource.watchRecentAuditLogs(
      organizationId: organizationId.trim(),
      limit: limit,
    );
  }
}
