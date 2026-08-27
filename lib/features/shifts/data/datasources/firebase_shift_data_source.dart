import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shift.dart';

class FirebaseShiftDataSource {
  final FirebaseFirestore _firestore;

  FirebaseShiftDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shiftsCollection =>
      _firestore.collection('shifts');

  Future<Shift> createShift(Shift shift) async {
    final docRef = shift.shiftId.trim().isNotEmpty
        ? _shiftsCollection.doc(shift.shiftId.trim())
        : _shiftsCollection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final preparedShift = shift.copyWith(
      shiftId: assignedId,
      createdAt: shift.createdAt ?? now,
      updatedAt: shift.updatedAt ?? now,
    );

    final data = preparedShift.toMap();
    await docRef.set(data);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return preparedShift;
    }
    return Shift.fromMap(snapshot.data()!);
  }

  Future<Shift?> getShift({
    required String organizationId,
    required String shiftId,
  }) async {
    final doc = await _shiftsCollection.doc(shiftId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    final shift = Shift.fromMap(doc.data()!);
    if (shift.organizationId != organizationId) {
      return null;
    }
    return shift;
  }

  Future<List<Shift>> getShiftsByOrganization(
    String organizationId, {
    DateTime? date,
    ShiftStatus? status,
  }) async {
    Query<Map<String, dynamic>> query =
        _shiftsCollection.where('organizationId', isEqualTo: organizationId);

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query.where('date', isEqualTo: dateStr);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.toMapString());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Shift.fromMap(doc.data())).toList();
  }

  Future<List<Shift>> getShiftsByGuard(
    String organizationId,
    String guardId, {
    DateTime? date,
  }) async {
    Query<Map<String, dynamic>> query = _shiftsCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('guardId', isEqualTo: guardId);

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query.where('date', isEqualTo: dateStr);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Shift.fromMap(doc.data())).toList();
  }

  Future<List<Shift>> getShiftsBySite(
    String organizationId,
    String siteId, {
    DateTime? date,
  }) async {
    Query<Map<String, dynamic>> query = _shiftsCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('siteId', isEqualTo: siteId);

    if (date != null) {
      final dateStr = date.toIso8601String().split('T')[0];
      query = query.where('date', isEqualTo: dateStr);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Shift.fromMap(doc.data())).toList();
  }

  Future<Shift> updateShift(Shift shift) async {
    final docRef = _shiftsCollection.doc(shift.shiftId);
    final now = DateTime.now();
    final updated = shift.copyWith(updatedAt: now);
    await docRef.update(updated.toMap());
    return updated;
  }

  Future<Shift> updateShiftStatus({
    required String organizationId,
    required String shiftId,
    required ShiftStatus status,
  }) async {
    final shift = await getShift(
      organizationId: organizationId,
      shiftId: shiftId,
    );
    if (shift == null) {
      throw Exception('Shift not found');
    }
    final updated = shift.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await _shiftsCollection.doc(shiftId).update({
      'status': status.toMapString(),
      'updatedAt': DateTime.now().toIso8601String()
    });
    return updated;
  }
}
