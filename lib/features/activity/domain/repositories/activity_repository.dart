import '../entities/audit_log.dart';

/// Pure domain repository contract for operational activity and audit logging.
///
/// Enforces tenant isolation via [organizationId].
abstract class ActivityRepository {
  /// Fetches a bounded list of recent audit log records.
  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  });

  /// Streams real-time audit log updates for the organization.
  Stream<List<AuditLog>> watchRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  });
}
