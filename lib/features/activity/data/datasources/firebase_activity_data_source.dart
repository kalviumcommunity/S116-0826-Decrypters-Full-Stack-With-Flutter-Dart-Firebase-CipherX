import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/audit_log.dart';

class FirebaseActivityDataSource {
  final FirebaseFirestore _firestore;

  FirebaseActivityDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _auditCollection(
    String organizationId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('auditLogs');
  }

  Future<List<AuditLog>> getRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) async {
    final snapshot = await _auditCollection(organizationId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<AuditLog>> watchRecentAuditLogs({
    required String organizationId,
    int limit = 10,
  }) {
    return _auditCollection(organizationId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AuditLog.fromMap(doc.data(), doc.id))
          .toList();
    });
  }
}
