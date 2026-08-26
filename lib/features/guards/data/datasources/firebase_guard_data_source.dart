import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/guard.dart';

class FirebaseGuardDataSource {
  final FirebaseFirestore _firestore;

  FirebaseGuardDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _guardsCollection(
          String organizationId) =>
      _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('guards');

  Future<Guard> createGuard(Guard guard) async {
    final collection = _guardsCollection(guard.organizationId);
    final docRef = guard.guardId.trim().isNotEmpty
        ? collection.doc(guard.guardId.trim())
        : collection.doc();

    final assignedId = docRef.id;
    final data = guard.copyWith(guardId: assignedId).toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return guard.copyWith(guardId: assignedId);
    }
    return Guard.fromMap(snapshot.data()!);
  }

  Future<Guard?> getGuard({
    required String organizationId,
    required String guardId,
  }) async {
    final doc = await _guardsCollection(organizationId).doc(guardId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return Guard.fromMap(doc.data()!);
  }

  Future<List<Guard>> getGuards(String organizationId) async {
    final snapshot = await _guardsCollection(organizationId)
        .where('status', isEqualTo: GuardStatus.active.toMapString())
        .get();
    return snapshot.docs.map((doc) => Guard.fromMap(doc.data())).toList();
  }

  Stream<List<Guard>> watchGuards(String organizationId) {
    return _guardsCollection(organizationId)
        .where('status', isEqualTo: GuardStatus.active.toMapString())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Guard.fromMap(doc.data())).toList();
    });
  }

  Future<Guard> updateGuard(Guard guard) async {
    final docRef = _guardsCollection(guard.organizationId).doc(guard.guardId);
    final updates = <String, dynamic>{
      'name': guard.name,
      'employeeId': guard.employeeId,
      'phone': guard.phone,
      'email': guard.email,
      'photoUrl': guard.photoUrl,
      'status': guard.status.toMapString(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.update(updates);
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      return guard;
    }
    return Guard.fromMap(snapshot.data()!);
  }

  Future<Guard> updateGuardStatus({
    required String organizationId,
    required String guardId,
    required GuardStatus status,
  }) async {
    final docRef = _guardsCollection(organizationId).doc(guardId);
    await docRef.update({
      'status': status.toMapString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'Guard document does not exist after status update.',
      );
    }
    return Guard.fromMap(snapshot.data()!);
  }

  Future<void> deleteGuard({
    required String organizationId,
    required String guardId,
  }) async {
    await updateGuardStatus(
      organizationId: organizationId,
      guardId: guardId,
      status: GuardStatus.inactive,
    );
  }
}
