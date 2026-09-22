import '../../../../core/demo/demo_data.dart';
import '../../domain/failures/incident_failure.dart';
import '../../domain/validators/incident_validator.dart';
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
    if (DemoData.isDemoOrg(incident.organizationId)) {
      return DemoData.addIncident(incident);
    }
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
    if (DemoData.isDemoOrg(organizationId)) {
      var list = DemoData.getIncidents();
      if (status != null) list = list.where((i) => i.status == status).toList();
      if (severity != null) list = list.where((i) => i.severity == severity).toList();
      if (limit != null && list.length > limit) list = list.sublist(0, limit);
      return list;
    }
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
    if (DemoData.isDemoOrg(organizationId)) {
      return DemoData.watchIncidents().map((list) {
        var res = list;
        if (status != null) res = res.where((i) => i.status == status).toList();
        if (severity != null) res = res.where((i) => i.severity == severity).toList();
        return res;
      });
    }
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
    String? resolution,
  }) async {
    final docRef = _incidentsCollection(organizationId).doc(incidentId);

    return await _firestore.runTransaction<Incident>((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists || doc.data() == null) {
        throw const IncidentNotFoundFailure();
      }

      final existing = Incident.fromMap(doc.data()!, doc.id);

      if (existing.organizationId != organizationId) {
        throw const InvalidOrganizationIdFailure(
          'Incident does not belong to specified organization.',
        );
      }

      // Concurrency check: enforce state transition validation
      if (existing.status == IncidentStatus.resolved &&
          status != IncidentStatus.resolved) {
        throw const IncidentAlreadyResolvedFailure();
      }

      IncidentValidator.validateStatusTransition(
        from: existing.status,
        to: status,
      );

      final now = DateTime.now();
      final updates = <String, dynamic>{
        'status': status.toMapString(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == IncidentStatus.resolved) {
        if (resolvedBy == null || resolvedBy.trim().isEmpty) {
          throw const MissingResolutionMetadataFailure(
            'Resolver ID required when resolving an incident.',
          );
        }
        if (resolution != null) {
          final resErr = IncidentValidator.validateResolution(resolution);
          if (resErr != null) {
            throw InvalidResolutionTextFailure(resErr);
          }
        }

        updates['resolvedBy'] = resolvedBy.trim();
        updates['resolvedAt'] = resolvedAt != null
            ? Timestamp.fromDate(resolvedAt)
            : FieldValue.serverTimestamp();
        updates['resolution'] = resolution?.trim();
      } else {
        updates['resolvedBy'] = null;
        updates['resolvedAt'] = null;
        updates['resolution'] = null;
      }

      transaction.update(docRef, updates);

      if (status == IncidentStatus.resolved) {
        return existing.resolve(
          resolvedBy: resolvedBy!.trim(),
          resolution: resolution?.trim(),
          resolvedAt: resolvedAt ?? now,
          updatedAt: now,
        );
      } else if (status == IncidentStatus.investigating) {
        return existing.investigate(updatedAt: now);
      } else {
        return existing.copyWith(
          status: status,
          updatedAt: now,
        );
      }
    });
  }
}
