import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/shift.dart';

class FirebaseShiftDataSource {
  final FirebaseFirestore _firestore;

  FirebaseShiftDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _shiftsCollection(
    String organizationId,
  ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('shifts');
  }

  Future<Shift> createShift(Shift shift) async {
    final collection = _shiftsCollection(shift.organizationId);
    final docRef = shift.shiftId.trim().isNotEmpty
        ? collection.doc(shift.shiftId.trim())
        : collection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final prepared = shift.copyWith(
      shiftId: assignedId,
      createdAt: shift.createdAt ?? now,
      updatedAt: shift.updatedAt ?? now,
    );

    await docRef.set(prepared.toMap());
    return prepared;
  }

  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  }) async {
    final doc = await _shiftsCollection(organizationId).doc(shiftId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Shift.fromMap(doc.data()!, doc.id);
  }

  Future<List<Shift>> getShiftsByOrganization(String organizationId) async {
    final snapshot = await _shiftsCollection(organizationId).get();
    return snapshot.docs
        .map((doc) => Shift.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId,
  ) async {
    final snapshot = await _shiftsCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .get();
    return snapshot.docs
        .map((doc) => Shift.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<Shift>> watchShiftsByGuard(
    String organizationId,
    String guardId,
  ) {
    return _shiftsCollection(organizationId)
        .where('guardId', isEqualTo: guardId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Shift.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId,
  ) async {
    final snapshot = await _shiftsCollection(organizationId)
        .where('siteId', isEqualTo: siteId)
        .get();
    return snapshot.docs
        .map((doc) => Shift.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Shift> updateShift(Shift shift) async {
    final docRef = _shiftsCollection(shift.organizationId).doc(shift.shiftId);
    final updated = shift.copyWith(updatedAt: DateTime.now());
    await docRef.update(updated.toMap());
    return updated;
  }

  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async {
    final docRef = _shiftsCollection(organizationId).doc(shiftId);
    final now = DateTime.now();
    await docRef.update({
      'status': status.toMapString(),
      'updatedAt': Timestamp.fromDate(now),
    });
    final doc = await docRef.get();
    return Shift.fromMap(doc.data()!, doc.id);
  }

  Future<void> cancelShift({
    required String organizationId,
    required String shiftId,
  }) async {
    await updateShiftStatus(
      organizationId: organizationId,
      shiftId: shiftId,
      status: ShiftStatus.cancelled,
    );
  }
}
