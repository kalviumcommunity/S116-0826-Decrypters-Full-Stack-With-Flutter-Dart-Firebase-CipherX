import '../entities/audit_log.dart';
import '../entities/operational_alert.dart';

abstract class ActivityRepository {
  Future<List<OperationalAlert>> getRecentAlerts({
    required String organizationId,
    int limit = 10,
  });

  Stream<List<OperationalAlert>> watchRecentAlerts({
    required String organizationId,
    int limit = 10,
  });

  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  });

  Stream<List<AuditLog>> watchRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  });
}
