import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/evidence_item.dart';
import '../../domain/failures/evidence_failure.dart';

/// Data source encapsulating Firestore persistence for incident evidence metadata.
class FirebaseEvidenceDataSource {
  final FirebaseFirestore _firestore;

  FirebaseEvidenceDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _evidenceCollection({
    required String organizationId,
    required String incidentId,
  }) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('incidents')
        .doc(incidentId)
        .collection('evidence');
  }

  /// Persists a new [EvidenceItem] record under the target incident.
  Future<EvidenceItem> recordEvidence(EvidenceItem item) async {
    try {
      final collection = _evidenceCollection(
        organizationId: item.organizationId,
        incidentId: item.incidentId,
      );

      final docRef = item.evidenceId.trim().isNotEmpty
          ? collection.doc(item.evidenceId.trim())
          : collection.doc();

      final assignedId = docRef.id;
      final data = item.copyWith(evidenceId: assignedId).toMap();
      data['createdAt'] = FieldValue.serverTimestamp();

      await docRef.set(data);

      return item.copyWith(evidenceId: assignedId);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const UnauthorizedFailure(
            'Permission denied recording evidence.');
      }
      throw PersistenceFailure('Firestore error: ${e.message ?? e.code}');
    } catch (e) {
      if (e is EvidenceFailure) rethrow;
      throw PersistenceFailure('Failed to record evidence metadata: $e');
    }
  }

  /// Fetches all evidence attached to an incident.
  Future<List<EvidenceItem>> getEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    try {
      final query = await _evidenceCollection(
        organizationId: organizationId,
        incidentId: incidentId,
      ).orderBy('createdAt', descending: true).get();

      return query.docs
          .map((doc) => EvidenceItem.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw PersistenceFailure('Failed to fetch evidence: $e');
    }
  }

  /// Real-time stream of evidence items for an incident.
  Stream<List<EvidenceItem>> watchEvidenceForIncident({
    required String organizationId,
    required String incidentId,
  }) {
    return _evidenceCollection(
      organizationId: organizationId,
      incidentId: incidentId,
    ).orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EvidenceItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Deletes an evidence document from Firestore.
  Future<void> deleteEvidence({
    required String organizationId,
    required String incidentId,
    required String evidenceId,
  }) async {
    try {
      await _evidenceCollection(
        organizationId: organizationId,
        incidentId: incidentId,
      ).doc(evidenceId).delete();
    } catch (e) {
      throw PersistenceFailure('Failed to delete evidence metadata: $e');
    }
  }
}
