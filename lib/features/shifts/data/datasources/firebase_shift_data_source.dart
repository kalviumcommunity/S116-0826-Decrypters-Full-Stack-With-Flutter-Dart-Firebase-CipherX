import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shift.dart';

class FirebaseShiftDataSource {
  final FirebaseFirestore _firestore;

  FirebaseShiftDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shiftsCollection =>
      _firestore.collection('shifts');

  Future<Shift> createShift(Shift shift) async {
    final docRef = shift.id.trim().isNotEmpty
        ? _shiftsCollection.doc(shift.id.trim())
        : _shiftsCollection.doc();

    final assignedId = docRef.id;
    final now = DateTime.now();
    final preparedShift = shift.copyWith(
      id: assignedId,
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

  Future<List<Shift>> getShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) async {
    Query<Map<String, dynamic>> query =
        _shiftsCollection.where('organizationId', isEqualTo: organizationId);

    if (siteId != null && siteId.isNotEmpty) {
      query = query.where('siteId', isEqualTo: siteId);
    }
    if (guardId != null && guardId.isNotEmpty) {
      query = query.where('guardId', isEqualTo: guardId);
    }
    if (shiftDate != null && shiftDate.isNotEmpty) {
      query = query.where('shiftDate', isEqualTo: shiftDate);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Shift.fromMap(doc.data())).toList();
  }

  Stream<List<Shift>> watchShifts(
    String organizationId, {
    String? siteId,
    String? guardId,
    String? shiftDate,
  }) {
    Query<Map<String, dynamic>> query =
        _shiftsCollection.where('organizationId', isEqualTo: organizationId);

    if (siteId != null && siteId.isNotEmpty) {
      query = query.where('siteId', isEqualTo: siteId);
    }
    if (guardId != null && guardId.isNotEmpty) {
      query = query.where('guardId', isEqualTo: guardId);
    }
    if (shiftDate != null && shiftDate.isNotEmpty) {
      query = query.where('shiftDate', isEqualTo: shiftDate);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Shift.fromMap(doc.data())).toList();
    });
  }
}
