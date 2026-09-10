import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log.dart';
import '../../domain/entities/operational_alert.dart';

class FirebaseActivityDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseActivityDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _alertsCollection(
    String organizationId,
  ) {
    return db
        .collection('organizations')
        .doc(organizationId)
        .collection('alerts');
  }

  CollectionReference<Map<String, dynamic>> _auditCollection(
    String organizationId,
  ) {
    return db
        .collection('organizations')
        .doc(organizationId)
        .collection('auditLogs');
  }

  Future<List<OperationalAlert>> getRecentAlerts({
    required String organizationId,
    int limit = 10,
  }) async {
    final snapshot = await _alertsCollection(organizationId).limit(limit).get();
    final alerts = snapshot.docs
        .map((doc) => OperationalAlert.fromMap(doc.data(), doc.id))
        .toList();

    alerts.sort((a, b) {
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return alerts;
  }

  Stream<List<OperationalAlert>> watchRecentAlerts({
    required String organizationId,
    int limit = 10,
  }) {
    return _alertsCollection(organizationId).snapshots().map((snapshot) {
      final alerts = snapshot.docs
          .map((doc) => OperationalAlert.fromMap(doc.data(), doc.id))
          .toList();

      alerts.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return alerts.take(limit).toList();
    });
  }

  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) async {
    final snapshot = await _auditCollection(organizationId).limit(limit).get();
    final logs = snapshot.docs
        .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
        .toList();

    logs.sort((a, b) {
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return logs;
  }

  Stream<List<AuditLog>> watchRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) {
    return _auditCollection(organizationId).snapshots().map((snapshot) {
      final logs = snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
          .toList();

      logs.sort((a, b) {
        final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return logs.take(limit).toList();
    });
  }
}
