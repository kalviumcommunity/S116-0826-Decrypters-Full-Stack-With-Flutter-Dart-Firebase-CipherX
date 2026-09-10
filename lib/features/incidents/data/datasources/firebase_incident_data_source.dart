import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/incident.dart';
import '../../domain/entities/incident_severity.dart';
import '../../domain/entities/incident_status.dart';

class FirebaseIncidentDataSource {
  final FirebaseFirestore _firestore;

  FirebaseIncidentDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _incidentsCollection(
    String organizationId,
  ) {
    return _firestore
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
    final data = incident
        .copyWith(
          incidentId: assignedId,
          createdAt: incident.createdAt,
          updatedAt: incident.updatedAt,
        )
        .toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);

    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return incident.copyWith(incidentId: assignedId);
    }
    return Incident.fromMap(snapshot.data()!, assignedId);
  }

  Future<Incident?> getIncident({
    required String organizationId,
    required String incidentId,
  }) async {
    final doc =
        await _incidentsCollection(organizationId).doc(incidentId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Incident.fromMap(doc.data()!, doc.id);
  }

  Future<List<Incident>> getIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _incidentsCollection(organizationId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity.toMapString());
    }
    query = query.orderBy('createdAt', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Incident.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Incident>> watchIncidentsByOrganization(
    String organizationId, {
    IncidentStatus? status,
    IncidentSeverity? severity,
  }) {
    Query<Map<String, dynamic>> query = _incidentsCollection(organizationId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }
    if (severity != null) {
      query = query.where('severity', isEqualTo: severity.toMapString());
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Incident>> getIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) async {
    Query<Map<String, dynamic>> query =
        _incidentsCollection(organizationId).where('siteId', isEqualTo: siteId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }
    query = query.orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Incident.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Incident>> watchIncidentsBySite({
    required String organizationId,
    required String siteId,
    IncidentStatus? status,
  }) {
    Query<Map<String, dynamic>> query =
        _incidentsCollection(organizationId).where('siteId', isEqualTo: siteId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }
    query = query.orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Incident>> getIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) async {
    final query = _incidentsCollection(organizationId)
        .where('reportedBy', isEqualTo: reportedBy)
        .orderBy('createdAt', descending: true);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Incident.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Incident>> watchIncidentsByReporter({
    required String organizationId,
    required String reportedBy,
  }) {
    final query = _incidentsCollection(organizationId)
        .where('reportedBy', isEqualTo: reportedBy)
        .orderBy('createdAt', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Incident.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<Incident> updateIncident(Incident incident) async {
    final docRef =
        _incidentsCollection(incident.organizationId).doc(incident.incidentId);
    final updates = <String, dynamic>{
      'description': incident.description,
      'severity': incident.severity.toMapString(),
      'latitude': incident.latitude,
      'longitude': incident.longitude,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(updates);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return incident;
    }
    return Incident.fromMap(snapshot.data()!, incident.incidentId);
  }

  Future<Incident> updateIncidentStatus({
    required String organizationId,
    required String incidentId,
    required IncidentStatus status,
    String? resolvedBy,
    DateTime? resolvedAt,
  }) async {
    final docRef = _incidentsCollection(organizationId).doc(incidentId);
    final updates = <String, dynamic>{
      'status': status.toMapString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == IncidentStatus.resolved) {
      updates['resolvedBy'] = resolvedBy;
      updates['resolvedAt'] = resolvedAt != null
          ? Timestamp.fromDate(resolvedAt)
          : FieldValue.serverTimestamp();
    } else {
      updates['resolvedBy'] = null;
      updates['resolvedAt'] = null;
    }

    await docRef.update(updates);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Incident document does not exist after status update.',
      );
    }
    return Incident.fromMap(snapshot.data()!, incidentId);
  }
}
