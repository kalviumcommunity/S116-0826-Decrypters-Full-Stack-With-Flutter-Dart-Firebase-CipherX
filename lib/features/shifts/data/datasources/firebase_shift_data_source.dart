import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/shift.dart';

class FirebaseShiftDataSource {
  final FirebaseFirestore _firestore;

  FirebaseShiftDataSource(this._firestore);

  Future<List<Shift>> getShiftsByGuard(
      String organizationId, String guardId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('shifts')
          .where('guardId', isEqualTo: guardId)
          .get();

      return snapshot.docs
          .map((doc) => Shift.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shifts: $e');
    }
  }

  Future<Shift?> getShiftById(String organizationId, String shiftId) async {
    try {
      final doc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('shifts')
          .doc(shiftId)
          .get();

      if (doc.exists && doc.data() != null) {
        return Shift.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch shift: $e');
    }
  }
}
