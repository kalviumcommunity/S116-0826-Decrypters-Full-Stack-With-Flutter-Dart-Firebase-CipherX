import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/alert.dart';
import '../../domain/entities/alert_status.dart';
import '../../domain/entities/alert_type.dart';
import '../../domain/failures/alert_failure.dart';

/// Firebase Cloud Firestore datasource for operational alerts.
///
/// Stores documents scoped under `organizations/{organizationId}/alerts/{alertId}`.
/// Utilizes transactions to guarantee atomic creation and concurrency safety.
class FirebaseAlertDataSource {
  final FirebaseFirestore _firestore;

  FirebaseAlertDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _alertsCollection(String organizationId) {
    return _firestore
        .collection('organizations')
        .doc(organizationId.trim())
        .collection('alerts');
  }

  /// Atomically persists an alert if absent using a Firestore transaction.
  ///
  /// Returns the created [Alert] if absent, or `null` if the alert already exists.
  Future<Alert?> createIfAbsent(Alert alert) async {
    try {
      final docRef = _alertsCollection(alert.organizationId).doc(alert.alertId);

      return await _firestore.runTransaction<Alert?>((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          // Already created -> deduplication hit
          return null;
        }

        final data = alert.toMap();
        data['createdAt'] = FieldValue.serverTimestamp();
        transaction.set(docRef, data);
        return alert;
      });
    } on FirebaseException catch (e) {
      throw AlertPersistenceFailure('Firestore error creating alert: ${e.message}');
    } catch (e) {
      if (e is AlertFailure) rethrow;
      throw AlertPersistenceFailure('Unexpected error creating alert: $e');
    }
  }

  /// Checks if an alert already exists for the given source and type.
  Future<bool> existsForSource({
    required String organizationId,
    required String sourceEntityId,
    required AlertType type,
  }) async {
    try {
      final query = await _alertsCollection(organizationId)
          .where('sourceEntityId', isEqualTo: sourceEntityId)
          .where('type', isEqualTo: type.toMapString())
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } on FirebaseException catch (e) {
      throw AlertPersistenceFailure('Failed to check source existence: ${e.message}');
    }
  }

  /// Retrieves an alert by its document ID.
  Future<Alert?> getAlertById({
    required String organizationId,
    required String alertId,
  }) async {
    try {
      final doc = await _alertsCollection(organizationId).doc(alertId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Alert.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw AlertPersistenceFailure('Failed to retrieve alert: ${e.message}');
    }
  }

  /// Retrieves all alerts matching optional filters.
  Future<List<Alert>> getAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _alertsCollection(organizationId);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toMapString());
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.toMapString());
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => Alert.fromMap(doc.data(), doc.id))
          .toList();
    } on FirebaseException catch (e) {
      throw AlertPersistenceFailure('Failed to fetch alerts: ${e.message}');
    }
  }

  /// Real-time stream of alerts for an organization.
  Stream<List<Alert>> watchAlerts({
    required String organizationId,
    AlertType? type,
    AlertStatus? status,
  }) {
    Query<Map<String, dynamic>> query = _alertsCollection(organizationId);

    if (type != null) {
      query = query.where('type', isEqualTo: type.toMapString());
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Alert.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Updates an alert's status.
  Future<void> updateAlertStatus({
    required String organizationId,
    required String alertId,
    required AlertStatus status,
  }) async {
    try {
      final docRef = _alertsCollection(organizationId).doc(alertId);
      await docRef.update({
        'status': status.toMapString(),
      });
    } on FirebaseException catch (e) {
      throw AlertPersistenceFailure('Failed to update alert status: ${e.message}');
    }
  }
}
