import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/incident.dart';

class FirebaseIncidentDataSource {
  final FirebaseFirestore? _firestore;

  FirebaseIncidentDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore;

  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _incidentsCollection(
    String organizationId,
  ) {
    return db
        .collection('organizations')
        .doc(organizationId)
        .collection('incidents');
  }

  Future<Incident> createIncident(Incident incident) async {
    final collection = _incidentsCollection(incident.organizationId);
    final docRef = incident.incidentId.trim().isNotEmpty
        ? collection.doc(incident.incidentId.trim())
        : collection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final prepared = incident.copyWith(
      incidentId: assignedId,
      status: IncidentStatus.open,
      createdAt: incident.createdAt ?? now,
      updatedAt: incident.updatedAt ?? now,
    );

    final mapData = prepared.toMap();
    mapData['createdAt'] = FieldValue.serverTimestamp();
    mapData['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(mapData);

    final doc = await docRef.get();
    if (doc.exists && doc.data() != null) {
      return Incident.fromMap(doc.data()!, doc.id);
    }
    return prepared;
  }

  Future<List<Incident>> getIncidentsByGuard({
    required String organizationId,
    required String guardId,
  }) async {
    final snapshot = await _incidentsCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .get();

    final records = snapshot.docs
        .map((doc) => Incident.fromMap(doc.data(), doc.id))
        .toList();

    records.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return records;
  }

  Stream<List<Incident>> watchIncidentsByGuard({
    required String organizationId,
    required String guardId,
  }) {
    return _incidentsCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .snapshots()
        .map((snapshot) {
      final records = snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .toList();

      records.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return records;
    });
  }

  Future<Incident?> getIncidentById({
    required String organizationId,
    required String incidentId,
  }) async {
    final doc =
        await _incidentsCollection(organizationId).doc(incidentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Incident.fromMap(doc.data()!, doc.id);
  }
}
